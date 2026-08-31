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

  factory RatingItem.fromJson(Map<String, dynamic> json) {
    final tagsRaw =
        (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        const [];

    return RatingItem(
      id: (json['id'] ?? '') as String,
      planId: (json['activity_id'] ?? '') as String,
      reviewerId: (json['reviewer_id'] ?? '') as String,
      revieweeId: (json['reviewee_id'] ?? '') as String,
      rating: ((json['stars'] ?? 5) as num).toInt(),
      badges: tagsRaw,
      comment: json['comment'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': planId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'stars': rating,
      'tags': badges,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

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
