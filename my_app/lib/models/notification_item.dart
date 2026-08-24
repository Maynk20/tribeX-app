enum NotificationType {
  joinRequest,
  requestAccepted,
  eventMatch,
  chatMessage,
  system,
}

class NotificationItem {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String? activityId;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.activityId,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationItem copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? activityId,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      activityId: activityId ?? this.activityId,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
