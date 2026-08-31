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
  StreamSubscription<AuthState>? _authSubscription;
  RealtimeChannel? _blocksChannel;

  AuthState() {
    _initAuth();
  }

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get pushEnabled => _pushEnabled;
  Set<String> get blockedUserIds => _blockedUserIds;

  bool get needsProfile =>
      _currentUser != null && !_currentUser!.hasCompletedProfile;

  bool get needsOnboarding =>
      _currentUser != null &&
      _currentUser!.hasCompletedProfile &&
      !_currentUser!.hasCompletedOnboarding;

  Future<void> _initAuth() async {
    final client = SupabaseService.client;
    if (client == null) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    final session = client.auth.currentSession;
    if (session != null) {
      await _loadProfile(session.user.id, session.user.email);
    } else {
      _isLoading = false;
      notifyListeners();
    }

    client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        await _loadProfile(session.user.id, session.user.email);
      } else {
        _currentUser = null;
        _isLoading = false;
        _unsubscribeBlocks();
        notifyListeners();
      }
    });
  }

  Future<void> _loadProfile(String userId, String? email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final profile = await AuthService.fetchUserProfile(userId);
      if (profile != null) {
        _currentUser = profile;
      } else {
        _currentUser = UserProfile(
          id: userId,
          fullName: '',
          username: '',
          email: email,
          hasCompletedProfile: false,
          hasCompletedOnboarding: false,
        );
      }
      _subscribeBlocks(userId);
    } catch (_) {
      _currentUser = UserProfile(
        id: userId,
        fullName: '',
        username: '',
        email: email,
        hasCompletedProfile: false,
        hasCompletedOnboarding: false,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeBlocks(String userId) {
    _unsubscribeBlocks();
    final client = SupabaseService.client;
    if (client == null) return;

    // Load initial blocked users
    client
        .from('blocks')
        .select('blocked_id')
        .eq('blocker_id', userId)
        .then((rows) {
          _blockedUserIds.clear();
          for (final r in (rows as List<dynamic>)) {
            if (r['blocked_id'] != null) {
              _blockedUserIds.add(r['blocked_id'].toString());
            }
          }
          notifyListeners();
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
            if (payload.eventType == PostgresChangeEvent.insert) {
              final blockedId = payload.newRecord['blocked_id']?.toString();
              if (blockedId != null) _blockedUserIds.add(blockedId);
            } else if (payload.eventType == PostgresChangeEvent.delete) {
              final blockedId = payload.oldRecord['blocked_id']?.toString();
              if (blockedId != null) _blockedUserIds.remove(blockedId);
            }
            notifyListeners();
          },
        )
        .subscribe();
  }

  void _unsubscribeBlocks() {
    _blocksChannel?.unsubscribe();
    _blocksChannel = null;
  }

  Future<void> signOut() async {
    await AuthService.signOut();
    _currentUser = null;
    _unsubscribeBlocks();
    notifyListeners();
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
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    final updates = <String, dynamic>{
      'id': _currentUser!.id,
      'has_completed_profile': true,
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
      _currentUser = _currentUser!.copyWith(
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
      );
    } catch (_) {
      // ignore error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeOnboarding(List<String> interests) async {
    if (_currentUser == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.client
          ?.from('profiles')
          .update({'interests': interests, 'has_completed_onboarding': true})
          .eq('id', _currentUser!.id);

      _currentUser = _currentUser!.copyWith(
        interests: interests,
        hasCompletedOnboarding: true,
      );
    } catch (_) {
      // ignore
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void togglePush(bool value) {
    _pushEnabled = value;
    notifyListeners();
  }

  Future<void> blockUser(String targetUserId) async {
    if (_currentUser == null) return;
    _blockedUserIds.add(targetUserId);
    notifyListeners();

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
    notifyListeners();

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
    _authSubscription?.cancel();
    _unsubscribeBlocks();
    super.dispose();
  }
}
