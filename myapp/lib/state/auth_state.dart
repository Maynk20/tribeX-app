import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

class AuthState extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = true;
  String? _error;
  bool _pushEnabled = true;
  final Set<String> _blockedUserIds = {};
  StreamSubscription<dynamic>? _authSubscription;
  RealtimeChannel? _blocksChannel;
  bool _isDisposed = false;
  int _authRequestVersion = 0;

  AuthState() {
    _initAuth();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get pushEnabled => _pushEnabled;
  Set<String> get blockedUserIds => Set.unmodifiable(_blockedUserIds);

  bool get needsProfile =>
      _currentUser != null && !_currentUser!.hasCompletedProfile;

  bool get needsOnboarding =>
      _currentUser != null &&
      _currentUser!.hasCompletedProfile &&
      !_currentUser!.hasCompletedOnboarding;

  /// TanStack: `!user || (!!profile.city && latitude != null && longitude != null)`.
  /// Signed-out viewers are treated as "has location" so the card shows the
  /// normal Join button (which routes to sign-in).
  bool get hasProfileGpsLocation {
    final u = _currentUser;
    if (u == null) return true;
    return (u.city?.trim().isNotEmpty ?? false) &&
        u.latitude != null &&
        u.longitude != null;
  }

  bool _isSavingLocation = false;
  bool get isSavingLocation => _isSavingLocation;

  /// User id for which the silent GPS refresh was already attempted during
  /// this app session (TanStack uses sessionStorage `tribex:gps-tried:<id>`).
  String? _gpsTriedForUserId;

  bool _isProfileLoading = false;

  Future<void> _initAuth() async {
    final client = SupabaseService.client;
    if (client == null) {
      _isLoading = false;
      if (!_isDisposed) notifyListeners();
      return;
    }

    _authSubscription = client.auth.onAuthStateChange.listen((data) async {
      if (_isDisposed) return;
      final session = data.session;
      final event = data.event;

      if (event == AuthChangeEvent.signedOut || session == null) {
        _handleSignedOut();
      } else {
        final requestVersion = ++_authRequestVersion;
        await _loadProfile(
          session.user.id,
          session.user.email,
          userMetadata: session.user.userMetadata,
          requestVersion: requestVersion,
        );
      }
    });

    final session = client.auth.currentSession;
    if (session != null) {
      await _loadProfile(
        session.user.id,
        session.user.email,
        userMetadata: session.user.userMetadata,
        requestVersion: ++_authRequestVersion,
      );
    } else {
      _handleSignedOut();
    }
  }

  bool _mockMode = false;

  void _handleSignedOut() {
    if (_mockMode) return;
    _authRequestVersion++;
    _currentUser = null;
    _isLoading = false;
    _isProfileLoading = false;
    _gpsTriedForUserId = null;
    _blockedUserIds.clear();
    _unsubscribeBlocks();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _loadProfile(
    String userId,
    String? email, {
    Map<String, dynamic>? userMetadata,
    required int requestVersion,
  }) async {
    if (_isProfileLoading &&
        _currentUser != null &&
        _currentUser!.id == userId) {
      return;
    }
    _isProfileLoading = true;
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final profile = await AuthService.fetchUserProfile(userId);
      if (_isDisposed || requestVersion != _authRequestVersion) return;

      final metaName = (userMetadata?['full_name'] as String?)?.trim() ?? '';
      final metaUname = (userMetadata?['username'] as String?)?.trim() ?? '';

      if (profile != null) {
        _currentUser = profile.copyWith(
          fullName: profile.fullName.isNotEmpty ? profile.fullName : metaName,
          username: profile.username.isNotEmpty ? profile.username : metaUname,
          email: profile.email ?? email,
        );
      } else {
        _currentUser = UserProfile(
          id: userId,
          fullName: metaName,
          username: metaUname,
          email: email,
          hasCompletedProfile: false,
          hasCompletedOnboarding: false,
        );
      }
      _subscribeBlocks(userId);
    } catch (_) {
      if (_isDisposed || requestVersion != _authRequestVersion) return;
      final metaName = (userMetadata?['full_name'] as String?)?.trim() ?? '';
      final metaUname = (userMetadata?['username'] as String?)?.trim() ?? '';
      _currentUser = UserProfile(
        id: userId,
        fullName: metaName,
        username: metaUname,
        email: email,
        hasCompletedProfile: false,
        hasCompletedOnboarding: false,
      );
    } finally {
      _isProfileLoading = false;
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
    _maybeSilentGpsRefresh();
  }

  /// Best-effort silent GPS refresh once per signed-in session, only when the
  /// profile has no verified location yet. Failures (denied permission, GPS
  /// off) are swallowed — the join flow still shows a clear prompt.
  /// Mirrors the effect in TanStack `src/routes/__root.tsx`.
  void _maybeSilentGpsRefresh() {
    final u = _currentUser;
    if (_isDisposed || u == null) return;
    if (!u.hasCompletedProfile || !u.hasCompletedOnboarding) return;
    if (hasProfileGpsLocation) return;
    if (_gpsTriedForUserId == u.id) return;
    _gpsTriedForUserId = u.id;
    unawaited(saveVerifiedProfileLocation().then((_) {}, onError: (_) {}));
  }

  /// Read the device location, reverse-geocode it into a city label and save
  /// `city`, `latitude`, `longitude` on the profile. Returns `null` on success
  /// or a user-facing error message. Port of TanStack
  /// `saveVerifiedProfileLocation` (src/lib/services.ts).
  Future<String?> saveVerifiedProfileLocation() async {
    final u = _currentUser;
    final client = SupabaseService.client;
    if (u == null || client == null || _isDisposed) {
      return "Couldn't fetch your location";
    }
    if (_isSavingLocation) return null;
    _isSavingLocation = true;
    if (!_isDisposed) notifyListeners();
    try {
      final coords = await LocationService.getProfileCoords();
      if (!coords.isSuccess) {
        return coords.error ?? "Couldn't fetch your location";
      }
      final lat = coords.latitude!;
      final lon = coords.longitude!;
      final city = await LocationService.resolveProfileCity(lat, lon);
      if (_isDisposed) return null;

      await client
          .from('profiles')
          .update({'city': city, 'latitude': lat, 'longitude': lon})
          .eq('id', u.id);

      // Only apply if the same user is still signed in.
      if (_isDisposed || _currentUser?.id != u.id) return null;
      _currentUser = _currentUser!.copyWith(
        city: city,
        latitude: lat,
        longitude: lon,
      );
      return null;
    } catch (e) {
      debugPrint('saveVerifiedProfileLocation failed');
      return 'Unable to save your location right now. Please try again.';
    } finally {
      _isSavingLocation = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _subscribeBlocks(String userId) {
    _unsubscribeBlocks();
    final client = SupabaseService.client;
    if (client == null || _isDisposed) return;

    // Load initial blocked users
    client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', userId)
        .then((rows) {
          if (_isDisposed) return;
          _blockedUserIds.clear();
          for (final r in (rows as List<dynamic>)) {
            if (r['blocked_id'] != null) {
              _blockedUserIds.add(r['blocked_id'].toString());
            }
          }
          if (!_isDisposed) notifyListeners();
        })
        .catchError((_) {});

    // Realtime channel
    _blocksChannel = client
        .channel('public:blocks:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'blocks',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'blocker_id',
            value: userId,
          ),
          callback: (payload) {
            if (_isDisposed) return;
            if (payload.eventType == PostgresChangeEvent.insert) {
              final blockedId = payload.newRecord['blocked_id']?.toString();
              if (blockedId != null) _blockedUserIds.add(blockedId);
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final blockedId = payload.oldRecord['blocked_id']?.toString();
              if (blockedId != null) _blockedUserIds.remove(blockedId);
            }
            if (!_isDisposed) notifyListeners();
          },
        )
        .subscribe();
  }

  void _unsubscribeBlocks() {
    _blocksChannel?.unsubscribe();
    _blocksChannel = null;
  }

  Future<void> signOut() async {
    _handleSignedOut();
    try {
      await AuthService.signOut();
    } catch (_) {}
  }

  Future<bool> deleteAccount() async {
    if (_currentUser == null) return false;

    try {
      final client = SupabaseService.client;
      if (client == null) return false;

      // The SQL function delete_user_account() takes no parameters — it uses
      // auth.uid() internally via SECURITY DEFINER.
      await client.rpc('delete_user_account');
      await signOut();
      return true;
    } catch (e) {
      debugPrint('deleteAccount failed: $e');
      return false;
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? gender,
    String? city,
    String? bio,
    String? avatarUrl,
    double? latitude,
    double? longitude,
  }) async {
    if (_currentUser == null || _isDisposed) return false;

    final cur = _currentUser!;
    final hasChanges =
        (fullName != null && fullName != cur.fullName) ||
        (username != null && username != cur.username) ||
        (phone != null && phone != cur.phone) ||
        (gender != null && gender != cur.gender) ||
        (city != null && city != cur.city) ||
        (bio != null && bio != cur.bio) ||
        (avatarUrl != null && avatarUrl != cur.avatarUrl) ||
        (latitude != null && latitude != cur.latitude) ||
        (longitude != null && longitude != cur.longitude) ||
        !cur.hasCompletedProfile;

    if (!hasChanges) return true;

    _isLoading = true;
    _error = null;
    if (!_isDisposed) notifyListeners();

    final now = DateTime.now();
    final termsAcceptedAt = cur.termsAcceptedAt ?? now;

    final updates = <String, dynamic>{
      'id': cur.id,
      'has_completed_profile': true,
      'terms_accepted_at': termsAcceptedAt.toIso8601String(),
      'terms_version': 'v1.0',
      if (fullName != null) ...{'full_name': fullName},
      if (username != null) ...{'username': username},
      if (phone != null) ...{'phone': phone},
      if (gender != null) ...{'gender': gender},
      if (city != null) ...{'city': city},
      if (bio != null) ...{'bio': bio},
      if (avatarUrl != null) ...{'avatar_url': avatarUrl},
      if (latitude != null) ...{'latitude': latitude},
      if (longitude != null) ...{'longitude': longitude},
    };

    try {
      final client = SupabaseService.client;
      if (client == null) return false;
      await client.from('profiles').upsert(updates);
      if (_isDisposed) return false;
      _currentUser = cur.copyWith(
        fullName: fullName,
        username: username,
        phone: phone,
        gender: gender,
        city: city,
        bio: bio,
        avatarUrl: avatarUrl,
        latitude: latitude,
        longitude: longitude,
        hasCompletedProfile: true,
        termsAcceptedAt: termsAcceptedAt,
        termsVersion: 'v1.0',
      );
      return true;
    } catch (e) {
      debugPrint('updateProfile error: $e');
      _error = 'Unable to save your profile right now.';
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> completeOnboarding(List<String> interests) async {
    if (_currentUser == null || _isDisposed) return;
    final client = SupabaseService.client;
    if (client == null) return;
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      await client
          .from('profiles')
          .update({'interests': interests, 'has_completed_onboarding': true})
          .eq('id', _currentUser!.id);

      if (_isDisposed) return;
      _currentUser = _currentUser!.copyWith(
        interests: interests,
        hasCompletedOnboarding: true,
      );
    } catch (_) {
      // ignore
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
    _maybeSilentGpsRefresh();
  }

  void togglePush(bool value) {
    _pushEnabled = value;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> blockUser(String targetUserId) async {
    if (_currentUser == null) return;
    final client = SupabaseService.client;
    if (client == null) return;
    _blockedUserIds.add(targetUserId);
    if (!_isDisposed) notifyListeners();

    try {
      await client.from('blocks').insert({
        'blocker_id': _currentUser!.id,
        'blocked_id': targetUserId,
      });
    } catch (_) {
      _blockedUserIds.remove(targetUserId);
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    if (_currentUser == null) return;
    final client = SupabaseService.client;
    if (client == null) return;
    _blockedUserIds.remove(targetUserId);
    if (!_isDisposed) notifyListeners();

    try {
      await client
          .from('blocks')
          .delete()
          .eq('blocker_id', _currentUser!.id)
          .eq('blocked_id', targetUserId);
    } catch (_) {
      _blockedUserIds.add(targetUserId);
      if (!_isDisposed) notifyListeners();
    }
  }

  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  @visibleForTesting
  void setMockUser(UserProfile? user) {
    _mockMode = true;
    _currentUser = user;
    _isLoading = false;
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _unsubscribeBlocks();
    super.dispose();
  }
}
