import 'user_profile.dart';

class Message {
  final String id;
  final String activityId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final UserProfile? sender;

  Message({
    required this.id,
    required this.activityId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.sender,
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
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      sender: senderObj,
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

  /// Check if text is encoded expense card `EXPENSE:<id>`
  String? get expenseId {
    if (text.startsWith('EXPENSE:')) {
      return text.substring('EXPENSE:'.length).trim();
    }
    return null;
  }

  /// Check if text is encoded poll card `POLL:<id>`
  String? get pollId {
    if (text.startsWith('POLL:')) {
      return text.substring('POLL:'.length).trim();
    }
    return null;
  }
}
