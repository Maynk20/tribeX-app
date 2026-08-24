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
