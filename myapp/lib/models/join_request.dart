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

    Map<String, dynamic>? extractMap(dynamic val) {
      if (val is Map<String, dynamic>) return val;
      if (val is Map) return Map<String, dynamic>.from(val);
      if (val is List && val.isNotEmpty) {
        final first = val.first;
        if (first is Map<String, dynamic>) return first;
        if (first is Map) return Map<String, dynamic>.from(first);
      }
      return null;
    }

    final userRaw = extractMap(json['user']) ??
        extractMap(json['profiles']) ??
        extractMap(json['profiles_public']);
    final UserProfile? userObj =
        userRaw != null ? UserProfile.fromJson(userRaw) : null;

    return JoinRequest(
      id: json['id'] as String? ?? '',
      activityId:
          json['activity_id'] as String? ?? json['activityId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      status: st,
      requestedAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['requestedAt'] != null
                ? (DateTime.tryParse(json['requestedAt'].toString()) ??
                      DateTime.now())
                : DateTime.now()),
      checkedInAt: json['checked_in_at'] != null
          ? DateTime.tryParse(json['checked_in_at'].toString())
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
