import 'user_profile.dart';

enum JoinStatus { pending, accepted, rejected }

class JoinRequest {
  final String id;
  final String activityId;
  final String userId;
  final JoinStatus status;
  final DateTime requestedAt;
  final DateTime? checkedInAt;
  final bool noShow;
  final UserProfile? user;

  JoinRequest({
    required this.id,
    required this.activityId,
    required this.userId,
    required this.status,
    required this.requestedAt,
    this.checkedInAt,
    this.noShow = false,
    this.user,
  });

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    JoinStatus st = JoinStatus.pending;
    final stStr = json['status'] as String? ?? '';
    if (stStr == 'accepted') st = JoinStatus.accepted;
    if (stStr == 'rejected') st = JoinStatus.rejected;

    UserProfile? userObj;
    if (json['user'] != null && json['user'] is Map<String, dynamic>) {
      userObj = UserProfile.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['profiles'] != null &&
        json['profiles'] is Map<String, dynamic>) {
      userObj = UserProfile.fromJson(json['profiles'] as Map<String, dynamic>);
    } else if (json['profiles_public'] != null &&
        json['profiles_public'] is Map<String, dynamic>) {
      userObj = UserProfile.fromJson(
        json['profiles_public'] as Map<String, dynamic>,
      );
    }

    return JoinRequest(
      id: json['id'] as String? ?? '',
      activityId:
          json['activity_id'] as String? ?? json['activityId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      status: st,
      requestedAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['requestedAt'] != null
                ? DateTime.parse(json['requestedAt'] as String)
                : DateTime.now()),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.parse(json['checked_in_at'] as String)
          : null,
      noShow: json['no_show'] as bool? ?? false,
      user: userObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activity_id': activityId,
      'user_id': userId,
      'status': status.name,
      'created_at': requestedAt.toIso8601String(),
      'checked_in_at': checkedInAt?.toIso8601String(),
      'no_show': noShow,
    };
  }

  bool get isCheckedIn => checkedInAt != null;

  JoinRequest copyWith({
    String? id,
    String? activityId,
    String? userId,
    JoinStatus? status,
    DateTime? requestedAt,
    DateTime? checkedInAt,
    bool? noShow,
    UserProfile? user,
  }) {
    return JoinRequest(
      id: id ?? this.id,
      activityId: activityId ?? this.activityId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      noShow: noShow ?? this.noShow,
      user: user ?? this.user,
    );
  }
}
