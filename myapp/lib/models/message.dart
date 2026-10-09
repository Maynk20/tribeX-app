import 'user_profile.dart';

class Message {
  final String id;
  final String activityId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final UserProfile? sender;

  final bool isSending;
  final bool isFailed;

  Message({
    required this.id,
    required this.activityId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.sender,
    this.isSending = false,
    this.isFailed = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    UserProfile? senderObj;
    if (json['sender'] != null && json['sender'] is Map<String, dynamic>) {
      senderObj = UserProfile.fromJson(json['sender'] as Map<String, dynamic>);
    } else if (json['profiles'] != null &&
        json['profiles'] is Map<String, dynamic>) {
      senderObj = UserProfile.fromJson(
        json['profiles'] as Map<String, dynamic>,
      );
    } else if (json['profiles_public'] != null &&
        json['profiles_public'] is Map<String, dynamic>) {
      senderObj = UserProfile.fromJson(
        json['profiles_public'] as Map<String, dynamic>,
      );
    }

    return Message(
      id: json['id'] as String? ?? '',
      activityId:
          json['activity_id'] as String? ?? json['activityId'] as String? ?? '',
      senderId:
          json['sender_id'] as String? ?? json['senderId'] as String? ?? '',
      text: json['text'] as String? ?? json['message'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      sender: senderObj,
      isSending: json['is_sending'] == true,
      isFailed: json['is_failed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'sender_id': senderId,
      'text': text,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? activityId,
    String? senderId,
    String? text,
    DateTime? createdAt,
    UserProfile? sender,
    bool? isSending,
    bool? isFailed,
  }) {
    return Message(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      sender: sender ?? this.sender,
      isSending: isSending ?? this.isSending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  /// Check if text is encoded expense card `[[expense:<id>]]` or `EXPENSE:<id>`
  String? get expenseId {
    final webMatch = RegExp(r'^\[\[expense:([0-9a-fA-F-]{36})\]\]')
        .firstMatch(text);
    if (webMatch != null) return webMatch.group(1);

    if (text.startsWith('EXPENSE:')) {
      final raw = text.substring('EXPENSE:'.length).trim();
      return raw.split(' ').first;
    }
    return null;
  }

  /// Check if text is encoded poll card `[[poll:<id>]]` or `POLL:<id>`
  String? get pollId {
    final webMatch = RegExp(r'^\[\[poll:([0-9a-fA-F-]{36})\]\]')
        .firstMatch(text);
    if (webMatch != null) return webMatch.group(1);

    if (text.startsWith('POLL:')) {
      final raw = text.substring('POLL:'.length).trim();
      return raw.split(' ').first;
    }
    return null;
  }
}
