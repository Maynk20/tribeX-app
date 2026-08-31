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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      fullName:
          json['full_name'] as String? ?? json['fullName'] as String? ?? 'User',
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      city: json['city'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String? ?? json['avatarUrl'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      reliabilityScore:
          (json['reliability_score'] as num? ??
                  json['reliabilityScore'] as num?)
              ?.toDouble() ??
          100.0,
      isVerified:
          json['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
      hasCompletedProfile:
          json['has_completed_profile'] as bool? ??
          json['hasCompletedProfile'] as bool? ??
          true,
      hasCompletedOnboarding:
          json['has_completed_onboarding'] as bool? ??
          json['hasCompletedOnboarding'] as bool? ??
          true,
      interests:
          (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'phone': phone,
      'gender': gender,
      'city': city,
      'bio': bio,
      'avatar_url': avatarUrl,
      'rating': rating,
      'reliability_score': reliabilityScore,
      'is_verified': isVerified,
      'has_completed_profile': hasCompletedProfile,
      'has_completed_onboarding': hasCompletedOnboarding,
      'interests': interests,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

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
