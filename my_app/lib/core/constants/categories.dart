import 'package:flutter/material.dart';

class CategoryDef {
  final String key;
  final String label;
  final String emoji;
  final IconData icon;
  final String group;
  final String defaultMode; // 'in_person' | 'online' | 'either'

  const CategoryDef({
    required this.key,
    required this.label,
    required this.emoji,
    required this.icon,
    required this.group,
    this.defaultMode = 'in_person',
  });
}

class AmenityDef {
  final String key;
  final String label;
  final String badge;
  final IconData icon;

  const AmenityDef({
    required this.key,
    required this.label,
    required this.badge,
    required this.icon,
  });
}

class AppCategories {
  AppCategories._();

  static const List<String> groups = [
    "Sports & Outdoor",
    "Education & Skills",
    "Tech & Creative",
    "Games & Entertainment",
    "Wellness",
  ];

  static const List<CategoryDef> all = [
    // Sports & Outdoor
    CategoryDef(
      key: "Cricket",
      label: "Cricket",
      emoji: "🏏",
      icon: Icons.sports_cricket,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Football",
      label: "Football",
      emoji: "⚽",
      icon: Icons.sports_soccer,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Badminton",
      label: "Badminton",
      emoji: "🏸",
      icon: Icons.sports_tennis,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Running",
      label: "Running",
      emoji: "🏃",
      icon: Icons.directions_run,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Cycling",
      label: "Cycling",
      emoji: "🚴",
      icon: Icons.directions_bike,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Trekking",
      label: "Trekking",
      emoji: "🏔️",
      icon: Icons.terrain,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Hiking",
      label: "Hiking",
      emoji: "🥾",
      icon: Icons.hiking,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Road Trips",
      label: "Road Trips",
      emoji: "🚗",
      icon: Icons.directions_car,
      group: "Sports & Outdoor",
      defaultMode: "in_person",
    ),

    // Education & Skills
    CategoryDef(
      key: "Study Partner",
      label: "Study Partner",
      emoji: "📚",
      icon: Icons.menu_book,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Coding Partner",
      label: "Coding Partner",
      emoji: "💻",
      icon: Icons.code,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Book Club",
      label: "Book Club",
      emoji: "📖",
      icon: Icons.auto_stories,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Reading Session",
      label: "Reading Session",
      emoji: "🔖",
      icon: Icons.bookmark_border,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Writing Club",
      label: "Writing Club",
      emoji: "✍️",
      icon: Icons.edit,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Language Exchange",
      label: "Language Exchange",
      emoji: "🗣️",
      icon: Icons.translate,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Public Speaking",
      label: "Public Speaking",
      emoji: "🎤",
      icon: Icons.mic,
      group: "Education & Skills",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Interview Prep",
      label: "Interview Prep",
      emoji: "💼",
      icon: Icons.work_outline,
      group: "Education & Skills",
      defaultMode: "either",
    ),

    // Tech & Creative
    CategoryDef(
      key: "Startup Networking",
      label: "Startup Networking",
      emoji: "🚀",
      icon: Icons.rocket_launch,
      group: "Tech & Creative",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Coworking Session",
      label: "Coworking",
      emoji: "💼",
      icon: Icons.laptop_mac,
      group: "Tech & Creative",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Content Creation",
      label: "Content Creation",
      emoji: "🎥",
      icon: Icons.videocam,
      group: "Tech & Creative",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "UI/UX Design",
      label: "UI/UX Design",
      emoji: "🎨",
      icon: Icons.palette,
      group: "Tech & Creative",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Video Editing",
      label: "Video Editing",
      emoji: "🎬",
      icon: Icons.movie_creation,
      group: "Tech & Creative",
      defaultMode: "either",
    ),

    // Games & Entertainment
    CategoryDef(
      key: "Chess",
      label: "Chess",
      emoji: "♟️",
      icon: Icons.shield,
      group: "Games & Entertainment",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Board Games",
      label: "Board Games",
      emoji: "🎲",
      icon: Icons.casino,
      group: "Games & Entertainment",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Esports & Gaming",
      label: "Esports & Gaming",
      emoji: "🎮",
      icon: Icons.sports_esports,
      group: "Games & Entertainment",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Music Jam",
      label: "Music Jam",
      emoji: "🎵",
      icon: Icons.music_note,
      group: "Games & Entertainment",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Cooking Session",
      label: "Cooking Session",
      emoji: "🍳",
      icon: Icons.restaurant,
      group: "Games & Entertainment",
      defaultMode: "in_person",
    ),
    CategoryDef(
      key: "Movie Night",
      label: "Movie Night",
      emoji: "🎬",
      icon: Icons.theater_comedy,
      group: "Games & Entertainment",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Anime Watch Party",
      label: "Anime Watch Party",
      emoji: "📺",
      icon: Icons.tv,
      group: "Games & Entertainment",
      defaultMode: "either",
    ),

    // Wellness
    CategoryDef(
      key: "Meditation",
      label: "Meditation",
      emoji: "🧘",
      icon: Icons.self_improvement,
      group: "Wellness",
      defaultMode: "either",
    ),
    CategoryDef(
      key: "Indoor Yoga",
      label: "Indoor Yoga",
      emoji: "🧘‍♀️",
      icon: Icons.fitness_center,
      group: "Wellness",
      defaultMode: "either",
    ),
  ];

  static final Map<String, CategoryDef> map = {for (final c in all) c.key: c};

  static String emojiFor(String key) => map[key]?.emoji ?? "✨";
  static IconData iconFor(String key) => map[key]?.icon ?? Icons.star;

  // Amenities
  static const List<AmenityDef> amenities = [
    AmenityDef(
      key: "wifi",
      label: "WiFi Available",
      badge: "📶 WiFi",
      icon: Icons.wifi,
    ),
    AmenityDef(
      key: "power",
      label: "Power Outlets",
      badge: "🔌 Power",
      icon: Icons.power,
    ),
    AmenityDef(
      key: "quiet",
      label: "Quiet Zone",
      badge: "🤫 Silent Focus",
      icon: Icons.volume_off,
    ),
    AmenityDef(
      key: "cafe",
      label: "Cafe / Snacks",
      badge: "☕ Cafe",
      icon: Icons.local_cafe,
    ),
  ];

  static final Map<String, AmenityDef> amenityMap = {
    for (final a in amenities) a.key: a,
  };
}
