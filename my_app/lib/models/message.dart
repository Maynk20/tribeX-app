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
