import 'dart:convert';

class PollOption {
  final String id;
  final String text;
  final List<String> voterIds;

  PollOption({required this.id, required this.text, this.voterIds = const []});

  factory PollOption.fromJson(Map<String, dynamic> json) {
    final voters =
        (json['voter_ids'] as List<dynamic>?)
            ?.map((e) => e.toString().trim().toLowerCase())
            .where((e) => e.isNotEmpty)
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
  final DateTime? closedAt;
  final DateTime createdAt;
  final bool isDeleted;

  Poll({
    required this.id,
    required this.activityId,
    required this.creatorId,
    required this.question,
    required this.options,
    this.closedAt,
    required this.createdAt,
    this.isDeleted = false,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    List<dynamic> optsRaw = const [];
    if (json['options'] is List) {
      optsRaw = json['options'] as List<dynamic>;
    } else if (json['options'] is String) {
      try {
        final decoded = jsonDecode(json['options'] as String);
        if (decoded is List) optsRaw = decoded;
      } catch (_) {}
    }

    List<dynamic> votesRaw = const [];
    if (json['poll_votes'] is List) {
      votesRaw = json['poll_votes'] as List<dynamic>;
    } else if (json['votes'] is List) {
      votesRaw = json['votes'] as List<dynamic>;
    } else if (json['poll_votes'] is String) {
      try {
        final decoded = jsonDecode(json['poll_votes'] as String);
        if (decoded is List) votesRaw = decoded;
      } catch (_) {}
    }

    // Map votes by option index, guaranteeing strictly 1 active vote per user
    final Map<int, List<String>> votesByIndex = {};
    final Map<String, List<String>> votesByStrId = {};
    final Set<String> countedUserIds = {};

    // Iterate votes in reverse to retain the latest vote cast per user
    for (final v in votesRaw.reversed) {
      if (v is! Map) continue;
      final uId = v['user_id']?.toString().trim().toLowerCase() ?? '';
      if (uId.isEmpty || countedUserIds.contains(uId)) continue;
      countedUserIds.add(uId);

      if (v['option_index'] != null) {
        final rawIdx = v['option_index'];
        final int? idx = rawIdx is num
            ? rawIdx.toInt()
            : int.tryParse(rawIdx.toString());
        if (idx != null) {
          votesByIndex.putIfAbsent(idx, () => []).add(uId);
        }
      }
      final optId = v['option_id']?.toString() ?? '';
      if (optId.isNotEmpty) {
        votesByStrId.putIfAbsent(optId, () => []).add(uId);
      }
    }

    final List<PollOption> optionsList = [];
    for (int i = 0; i < optsRaw.length; i++) {
      final item = optsRaw[i];
      final text = item is String
          ? item
          : (item is Map ? (item['text'] ?? '').toString() : item.toString());
      final optId = item is Map ? (item['id'] ?? text).toString() : text;
      final voters =
          votesByIndex[i] ??
          votesByStrId[i.toString()] ??
          votesByStrId[optId] ??
          [];

      optionsList.add(
        PollOption(id: i.toString(), text: text, voterIds: voters),
      );
    }

    DateTime? closedDate;
    if (json['closed_at'] != null) {
      closedDate = DateTime.tryParse(json['closed_at'].toString());
    }

    final deleted = json['is_deleted'] == true || json['deleted_at'] != null;

    return Poll(
      id: (json['id'] ?? '') as String,
      activityId: (json['activity_id'] ?? '') as String,
      creatorId: (json['created_by'] ?? json['creator_id'] ?? '') as String,
      question: (json['question'] ?? '') as String,
      options: optionsList,
      closedAt: closedDate,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isDeleted: deleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'created_by': creatorId,
      'question': question,
      'options': options.map((o) => o.text).toList(),
      if (closedAt != null) 'closed_at': closedAt!.toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  int get totalVotes => options.fold(0, (sum, opt) => sum + opt.votes);

  bool get isClosed => closedAt != null;

  bool isCreator(String? userId) {
    if (userId == null) return false;
    return creatorId.trim().toLowerCase() == userId.trim().toLowerCase();
  }

  bool canVote(String? userId) {
    if (isClosed || isDeleted) return false;
    if (userId == null || userId.trim().isEmpty) return false;
    return true;
  }

  bool hasVoted(String userId) {
    final normalized = userId.trim().toLowerCase();
    return options.any(
      (opt) => opt.voterIds.any((v) => v.trim().toLowerCase() == normalized),
    );
  }

  String? userVotedOptionId(String userId) {
    final normalized = userId.trim().toLowerCase();
    for (final opt in options) {
      if (opt.voterIds.any((v) => v.trim().toLowerCase() == normalized)) {
        return opt.id;
      }
    }
    return null;
  }

  Poll copyWith({
    String? id,
    String? activityId,
    String? creatorId,
    String? question,
    List<PollOption>? options,
    DateTime? closedAt,
    bool clearClosedAt = false,
    DateTime? createdAt,
    bool? isDeleted,
  }) {
    return Poll(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      creatorId: creatorId ?? this.creatorId,
      question: question ?? this.question,
      options: options ?? this.options,
      closedAt: clearClosedAt ? null : (closedAt ?? this.closedAt),
      createdAt: createdAt ?? this.createdAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
