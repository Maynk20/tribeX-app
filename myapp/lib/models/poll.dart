class PollOption {
  final String id;
  final String text;
  final List<String> voterIds;

  PollOption({required this.id, required this.text, this.voterIds = const []});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    final voters =
        (json['voter_ids'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return PollOption(
      id: (json['id'] ?? json['text'] ?? '') as String,
      text: (json['text'] ?? '') as String,
      voterIds: voters,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'voter_ids': voterIds};
  }

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

  factory Poll.fromJson(Map<String, dynamic> json) {
    final optsRaw = (json['options'] as List<dynamic>?) ?? [];
    final votesRaw = (json['poll_votes'] as List<dynamic>?) ?? [];

    // Map votes by option index
    final Map<int, List<String>> votesByIndex = {};
    final Map<String, List<String>> votesByStrId = {};
    for (final v in votesRaw) {
      final uId = v['user_id']?.toString() ?? '';
      if (uId.isEmpty) continue;

      if (v['option_index'] != null) {
        final idx = (v['option_index'] as num).toInt();
        votesByIndex.putIfAbsent(idx, () => []).add(uId);
      }
      final optId = v['option_id']?.toString() ?? '';
      if (optId.isNotEmpty) {
        votesByStrId.putIfAbsent(optId, () => []).add(uId);
      }
    }

    final List<PollOption> optionsList = [];
    for (int i = 0; i < optsRaw.length; i++) {
      final item = optsRaw[i];
      final text = item is String ? item : (item['text'] ?? '').toString();
      final optId = item is Map ? (item['id'] ?? text).toString() : text;
      final voters = votesByIndex[i] ??
          votesByStrId[i.toString()] ??
          votesByStrId[optId] ??
          [];

      optionsList.add(
        PollOption(
          id: i.toString(),
          text: text,
          voterIds: voters,
        ),
      );
    }

    return Poll(
      id: (json['id'] ?? '') as String,
      activityId: (json['activity_id'] ?? '') as String,
      creatorId:
          (json['created_by'] ?? json['creator_id'] ?? '') as String,
      question: (json['question'] ?? '') as String,
      options: optionsList,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'created_by': creatorId,
      'question': question,
      'options': options.map((o) => o.text).toList(),
      'created_at': createdAt.toIso8601String(),
    };
  }

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
