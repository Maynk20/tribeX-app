import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class AuthState extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = true;
  bool _pushEnabled = true;
  final Set<String> _blockedUserIds = {};
  StreamSubscription<dynamic>? _authSubscription;
  RealtimeChannel? _blocksChannel;
  bool _isDisposed = false;

  AuthState() {
    _initAuth();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get pushEnabled => _pushEnabled;
  Set<String> get blockedUserIds => Set.unmodifiable(_blockedUserIds);

  bool get needsProfile =>
      _currentUser != null && !_currentUser!.hasCompletedProfile;

  bool get needsOnboarding =>
      _currentUser != null &&
      _currentUser!.hasCompletedProfile &&
      !_currentUser!.hasCompletedOnboarding;

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
        await _loadProfile(
          session.user.id,
          session.user.email,
          userMetadata: session.user.userMetadata,
        );
      }
    });

    final session = client.auth.currentSession;
    if (session != null) {
      await _loadProfile(
        session.user.id,
        session.user.email,
        userMetadata: session.user.userMetadata,
      );
    } else {
      _handleSignedOut();
    }
  }

  void _handleSignedOut() {
    _currentUser = null;
    _isLoading = false;
    _isProfileLoading = false;
    _unsubscribeBlocks();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _loadProfile(
    String userId,
    String? email, {
    Map<String, dynamic>? userMetadata,
  }) async {
    if (_isProfileLoading && _currentUser != null && _currentUser!.id == userId) {
      return;
    }
    _isProfileLoading = true;
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      final profile = await AuthService.fetchUserProfile(userId);
      if (_isDisposed) return;

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
      if (_isDisposed) return;
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
    final userId = _currentUser!.id;

    try {
      final client = SupabaseService.client;
      if (client != null) {
        try {
          await client.rpc('delete_user_account', params: {'_user_id': userId});
        } catch (_) {
          await client.from('profiles').delete().eq('id', userId);
        }
      }
      await signOut();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> updateProfile({
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
    if (_currentUser == null || _isDisposed) return;

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

    if (!hasChanges) return;

    _isLoading = true;
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
      await SupabaseService.client?.from('profiles').upsert(updates);
      if (_isDisposed) return;
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
    } catch (_) {
      // ignore error
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> completeOnboarding(List<String> interests) async {
    if (_currentUser == null || _isDisposed) return;
    _isLoading = true;
    if (!_isDisposed) notifyListeners();

    try {
      await SupabaseService.client
          ?.from('profiles')
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
  }

  void togglePush(bool value) {
    _pushEnabled = value;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> blockUser(String targetUserId) async {
    if (_currentUser == null) return;
    _blockedUserIds.add(targetUserId);
    if (!_isDisposed) notifyListeners();

    try {
      await SupabaseService.client?.from('blocks').insert({
        'blocker_id': _currentUser!.id,
        'blocked_id': targetUserId,
      });
    } catch (_) {
      // ignore
    }
  }

  Future<void> unblockUser(String targetUserId) async {
    if (_currentUser == null) return;
    _blockedUserIds.remove(targetUserId);
    if (!_isDisposed) notifyListeners();

    try {
      await SupabaseService.client
          ?.from('blocks')
          .delete()
          .eq('blocker_id', _currentUser!.id)
          .eq('blocked_id', targetUserId);
    } catch (_) {
      // ignore
    }
  }

  bool isBlocked(String userId) => _blockedUserIds.contains(userId);

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    _unsubscribeBlocks();
    super.dispose();
  }
}
