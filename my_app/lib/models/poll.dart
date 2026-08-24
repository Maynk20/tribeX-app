class PollOption {
  final String id;
  final String text;
  final List<String> voterIds;

  PollOption({required this.id, required this.text, this.voterIds = const []});

  int get votes => voterIds.length;

  PollOption copyWith({String? id, String? text, List<String>? voterIds}) {
    return PollOption(
      id: id ?? this.id,
      text: text ?? this.text,
      voterIds: voterIds ?? this.voterIds,
    );
  }
}

class Poll {
  final String id;
  final String activityId;
  final String creatorId;
  final String question;
  final List<PollOption> options;
  final DateTime createdAt;

  Poll({
    required this.id,
    required this.activityId,
    required this.creatorId,
    required this.question,
    required this.options,
    required this.createdAt,
  });

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.votes);

  bool hasVoted(String userId) {
    return options.any((opt) => opt.voterIds.contains(userId));
  }

  String? userVotedOptionId(String userId) {
    for (final opt in options) {
      if (opt.voterIds.contains(userId)) return opt.id;
    }
    return null;
  }

  Poll copyWith({
    String? id,
    String? activityId,
    String? creatorId,
    String? question,
    List<PollOption>? options,
    DateTime? createdAt,
  }) {
    return Poll(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      creatorId: creatorId ?? this.creatorId,
      question: question ?? this.question,
      options: options ?? this.options,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
