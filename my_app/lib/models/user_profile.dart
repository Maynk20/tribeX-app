class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String? email;
  final String? phone;
  final String? gender;
  final String? city;
  final String? bio;
  final String? avatarUrl;
  final double rating;
  final double reliabilityScore;
  final bool isVerified;
  final bool hasCompletedProfile;
  final bool hasCompletedOnboarding;
  final List<String> interests;
  final double? latitude;
  final double? longitude;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    this.email,
    this.phone,
    this.gender,
    this.city,
    this.bio,
    this.avatarUrl,
    this.rating = 5.0,
    this.reliabilityScore = 100.0,
    this.isVerified = false,
    this.hasCompletedProfile = false,
    this.hasCompletedOnboarding = false,
    this.interests = const [],
    this.latitude,
    this.longitude,
  });

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? phone,
    String? gender,
    String? city,
    String? bio,
    String? avatarUrl,
    double? rating,
    double? reliabilityScore,
    bool? isVerified,
    bool? hasCompletedProfile,
    bool? hasCompletedOnboarding,
    List<String>? interests,
    double? latitude,
    double? longitude,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rating: rating ?? this.rating,
      reliabilityScore: reliabilityScore ?? this.reliabilityScore,
      isVerified: isVerified ?? this.isVerified,
      hasCompletedProfile: hasCompletedProfile ?? this.hasCompletedProfile,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      interests: interests ?? this.interests,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  String get reliabilityLabel {
    final score = reliabilityScore.round();
    if (score >= 95) return '$score% Reliable · Elite Host';
    if (score >= 80) return '$score% Reliable · Verified Regular';
    return '$score% Reliable';
  }
}
