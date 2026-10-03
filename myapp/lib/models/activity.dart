import 'user_profile.dart';

class Activity {
  final String id;
  final String hostId;
  final String title;
  final String description;
  final String category;
  final DateTime dateTime;
  final String location;
  final int totalSlots;
  final int slotsLeft;
  final double costPerHead;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool womenOnly;
  final bool verifiedOnly;
  final bool isUrgent;
  final DateTime? urgentUntil;
  final bool isOnline;
  final String? meetingLink;
  final List<String> amenities;
  final List<String> topicTags;
  final UserProfile? host;
  final List<String> photoMemories;

  Activity({
    required this.id,
    required this.hostId,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.location,
    required this.totalSlots,
    required this.slotsLeft,
    required this.costPerHead,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.womenOnly = false,
    this.verifiedOnly = false,
    this.isUrgent = false,
    this.urgentUntil,
    this.isOnline = false,
    this.meetingLink,
    this.amenities = const [],
    this.topicTags = const [],
    this.host,
    this.photoMemories = const [],
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    UserProfile? hostObj;
    if (json['host'] != null && json['host'] is Map<String, dynamic>) {
      hostObj = UserProfile.fromJson(json['host'] as Map<String, dynamic>);
    } else if (json['profiles'] != null &&
        json['profiles'] is Map<String, dynamic>) {
      hostObj = UserProfile.fromJson(json['profiles'] as Map<String, dynamic>);
    } else if (json['profiles_public'] != null &&
        json['profiles_public'] is Map<String, dynamic>) {
      hostObj = UserProfile.fromJson(
        json['profiles_public'] as Map<String, dynamic>,
      );
    }

    return Activity(
      id: json['id'] as String? ?? '',
      hostId: json['host_id'] as String? ?? json['hostId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'Social',
      dateTime: json['date_time'] != null
          ? (DateTime.tryParse(json['date_time'].toString()) ?? DateTime.now())
          : (json['dateTime'] != null
                ? (DateTime.tryParse(json['dateTime'].toString()) ??
                      DateTime.now())
                : DateTime.now()),
      location: json['location'] as String? ?? '',
      totalSlots:
          (json['total_slots'] as num? ?? json['totalSlots'] as num?)
              ?.toInt() ??
          10,
      slotsLeft:
          (json['slots_left'] as num? ?? json['slotsLeft'] as num?)?.toInt() ??
          10,
      costPerHead:
          (json['cost_per_head'] as num? ?? json['costPerHead'] as num?)
              ?.toDouble() ??
          0.0,
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      womenOnly:
          json['women_only'] as bool? ?? json['womenOnly'] as bool? ?? false,
      verifiedOnly:
          json['verified_only'] as bool? ??
          json['verifiedOnly'] as bool? ??
          false,
      isUrgent:
          json['is_urgent'] as bool? ?? json['isUrgent'] as bool? ?? false,
      urgentUntil: json['urgent_until'] != null
          ? DateTime.tryParse(json['urgent_until'].toString())
          : null,
      isOnline:
          json['is_online'] as bool? ?? json['isOnline'] as bool? ?? false,
      meetingLink:
          json['meeting_link'] as String? ?? json['meetingLink'] as String?,
      amenities:
          (json['amenities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      topicTags:
          (json['topic_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      host: hostObj,
      photoMemories:
          (json['photo_memories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'host_id': hostId,
      'title': title,
      'description': description,
      'category': category,
      'date_time': dateTime.toIso8601String(),
      'location': location,
      'total_slots': totalSlots,
      'slots_left': slotsLeft,
      'cost_per_head': costPerHead,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'women_only': womenOnly,
      'verified_only': verifiedOnly,
      'is_urgent': isUrgent,
      'urgent_until': urgentUntil?.toIso8601String(),
      'is_online': isOnline,
      'meeting_link': meetingLink,
      'amenities': amenities,
      'topic_tags': topicTags,
    };
  }

  bool get isUrgentActive {
    if (!isUrgent) return false;
    if (urgentUntil == null) return false;
    return urgentUntil!.isAfter(DateTime.now());
  }

  bool get hasSafetyShield => womenOnly || verifiedOnly;

  Activity copyWith({
    String? id,
    String? hostId,
    String? title,
    String? description,
    String? category,
    DateTime? dateTime,
    String? location,
    int? totalSlots,
    int? slotsLeft,
    double? costPerHead,
    String? imageUrl,
    double? latitude,
    double? longitude,
    bool? womenOnly,
    bool? verifiedOnly,
    bool? isUrgent,
    DateTime? urgentUntil,
    bool? isOnline,
    String? meetingLink,
    List<String>? amenities,
    List<String>? topicTags,
    UserProfile? host,
    List<String>? photoMemories,
  }) {
    return Activity(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      totalSlots: totalSlots ?? this.totalSlots,
      slotsLeft: slotsLeft ?? this.slotsLeft,
      costPerHead: costPerHead ?? this.costPerHead,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      womenOnly: womenOnly ?? this.womenOnly,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      isUrgent: isUrgent ?? this.isUrgent,
      urgentUntil: urgentUntil ?? this.urgentUntil,
      isOnline: isOnline ?? this.isOnline,
      meetingLink: meetingLink ?? this.meetingLink,
      amenities: amenities ?? this.amenities,
      topicTags: topicTags ?? this.topicTags,
      host: host ?? this.host,
      photoMemories: photoMemories ?? this.photoMemories,
    );
  }
}
