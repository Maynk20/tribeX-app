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

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    NotificationType nType = NotificationType.system;
    final tStr = json['type'] as String? ?? '';
    if (tStr == 'join_request') nType = NotificationType.joinRequest;
    if (tStr == 'request_accepted') nType = NotificationType.requestAccepted;
    if (tStr == 'event_match') nType = NotificationType.eventMatch;
    if (tStr == 'chat_message') nType = NotificationType.chatMessage;

    return NotificationItem(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? json['message'] as String?,
      activityId: json['activity_id'] as String?,
      type: nType,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'activity_id': activityId,
      'type': type.name,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

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
