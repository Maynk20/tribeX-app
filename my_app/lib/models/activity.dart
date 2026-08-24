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
