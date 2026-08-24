import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'mock_data.dart';

class AuthState extends ChangeNotifier {
  UserProfile? _currentUser = MockData.currentUser;
  bool _isLoading = false;
  bool _pushEnabled = true;
  final Set<String> _blockedUserIds = {};

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

  void signIn(String email) {
    _isLoading = true;
    notifyListeners();

    _currentUser = MockData.currentUser.copyWith(email: email);
    _isLoading = false;
    notifyListeners();
  }

  void signUp({
    required String email,
    required String fullName,
    required String username,
  }) {
    _isLoading = true;
    notifyListeners();

    _currentUser = UserProfile(
      id: "user_${DateTime.now().millisecondsSinceEpoch}",
      fullName: fullName,
      username: username,
      email: email,
      hasCompletedProfile: true,
      hasCompletedOnboarding: false,
    );
    _isLoading = false;
    notifyListeners();
  }

  void signOut() {
    _currentUser = null;
    notifyListeners();
  }

  void updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? gender,
    String? city,
    String? bio,
    String? avatarUrl,
    double? latitude,
    double? longitude,
  }) {
    if (_currentUser == null) return;
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
    notifyListeners();
  }

  void completeOnboarding(List<String> interests) {
    if (_currentUser == null) return;
    _currentUser = _currentUser!.copyWith(
      interests: interests,
      hasCompletedOnboarding: true,
    );
    notifyListeners();
  }

  void togglePush(bool value) {
    _pushEnabled = value;
    notifyListeners();
  }

  void blockUser(String userId) {
    _blockedUserIds.add(userId);
    notifyListeners();
  }

  void unblockUser(String userId) {
    _blockedUserIds.remove(userId);
    notifyListeners();
  }

  bool isBlocked(String userId) => _blockedUserIds.contains(userId);
}
