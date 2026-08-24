class RatingBadge {
  final String key;
  final String label;
  final String emoji;

  const RatingBadge({
    required this.key,
    required this.label,
    required this.emoji,
  });
}

class RatingBadges {
  static const List<RatingBadge> all = [
    RatingBadge(key: "punctual", label: "Punctual", emoji: "⏰"),
    RatingBadge(key: "team_player", label: "Team Player", emoji: "🤝"),
    RatingBadge(key: "great_energy", label: "Great Energy", emoji: "⚡"),
    RatingBadge(key: "skilled", label: "Super Skilled", emoji: "🎯"),
    RatingBadge(key: "great_host", label: "Great Host", emoji: "👑"),
    RatingBadge(key: "friendly", label: "Friendly & Warm", emoji: "😊"),
  ];
}

class RatingItem {
  final String id;
  final String planId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final List<String> badges;
  final String? comment;
  final DateTime createdAt;

  RatingItem({
    required this.id,
    required this.planId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.badges = const [],
    this.comment,
    required this.createdAt,
  });

  RatingItem copyWith({
    String? id,
    String? planId,
    String? reviewerId,
    String? revieweeId,
    int? rating,
    List<String>? badges,
    String? comment,
    DateTime? createdAt,
  }) {
    return RatingItem(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      rating: rating ?? this.rating,
      badges: badges ?? this.badges,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
