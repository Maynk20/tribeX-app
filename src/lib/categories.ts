import {
  Trophy,
  Activity as ActivityIcon,
  Dumbbell,
  Flame,
  Bike,
  Compass,
  Footprints,
  Car,
  BookOpen,
  Code2,
  Library,
  BookMarked,
  PenTool,
  Languages,
  Mic,
  Briefcase,
  Rocket,
  Laptop,
  Video,
  Palette,
  Clapperboard,
  Crown,
  Dices,
  Gamepad2,
  Music,
  UtensilsCrossed,
  Film,
  Tv,
  Sparkles,
  HeartPulse,
  Wifi,
  Plug,
  VolumeX,
  Coffee,
  Sparkle,
  type LucideIcon,
} from "lucide-react";

export type CategoryGroupKey =
  | "Sports & Outdoor"
  | "Education & Skills"
  | "Tech & Creative"
  | "Games & Entertainment"
  | "Wellness";

export type CategoryDef = {
  key: string;
  label: string;
  icon: LucideIcon;
  emoji: string;
  group: CategoryGroupKey;
  defaultMode: "in_person" | "online" | "either";
};

export const CATEGORIES: CategoryDef[] = [
  // Sports & Outdoor (existing — keep keys stable)
  { key: "Cricket", label: "Cricket", icon: Trophy, emoji: "🏏", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Football", label: "Football", icon: ActivityIcon, emoji: "⚽", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Badminton", label: "Badminton", icon: Dumbbell, emoji: "🏸", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Running", label: "Running", icon: Flame, emoji: "🏃", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Cycling", label: "Cycling", icon: Bike, emoji: "🚴", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Trekking", label: "Trekking", icon: Compass, emoji: "🏔️", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Hiking", label: "Hiking", icon: Footprints, emoji: "🥾", group: "Sports & Outdoor", defaultMode: "in_person" },
  { key: "Road Trips", label: "Road Trips", icon: Car, emoji: "🚗", group: "Sports & Outdoor", defaultMode: "in_person" },

  // Education & Skills
  { key: "Study Partner", label: "Study Partner", icon: BookOpen, emoji: "📚", group: "Education & Skills", defaultMode: "either" },
  { key: "Coding Partner", label: "Coding Partner", icon: Code2, emoji: "💻", group: "Education & Skills", defaultMode: "either" },
  { key: "Book Club", label: "Book Club", icon: Library, emoji: "📖", group: "Education & Skills", defaultMode: "either" },
  { key: "Reading Session", label: "Reading Session", icon: BookMarked, emoji: "🔖", group: "Education & Skills", defaultMode: "either" },
  { key: "Writing Club", label: "Writing Club", icon: PenTool, emoji: "✍️", group: "Education & Skills", defaultMode: "either" },
  { key: "Language Exchange", label: "Language Exchange", icon: Languages, emoji: "🗣️", group: "Education & Skills", defaultMode: "either" },
  { key: "Public Speaking", label: "Public Speaking", icon: Mic, emoji: "🎤", group: "Education & Skills", defaultMode: "either" },
  { key: "Interview Prep", label: "Interview Prep", icon: Briefcase, emoji: "💼", group: "Education & Skills", defaultMode: "either" },

  // Tech & Creative
  { key: "Startup Networking", label: "Startup Networking", icon: Rocket, emoji: "🚀", group: "Tech & Creative", defaultMode: "either" },
  { key: "Coworking Session", label: "Coworking", icon: Laptop, emoji: "💼", group: "Tech & Creative", defaultMode: "either" },
  { key: "Content Creation", label: "Content Creation", icon: Video, emoji: "🎥", group: "Tech & Creative", defaultMode: "either" },
  { key: "UI/UX Design", label: "UI/UX Design", icon: Palette, emoji: "🎨", group: "Tech & Creative", defaultMode: "either" },
  { key: "Video Editing", label: "Video Editing", icon: Clapperboard, emoji: "🎬", group: "Tech & Creative", defaultMode: "either" },

  // Games & Entertainment
  { key: "Chess", label: "Chess", icon: Crown, emoji: "♟️", group: "Games & Entertainment", defaultMode: "either" },
  { key: "Board Games", label: "Board Games", icon: Dices, emoji: "🎲", group: "Games & Entertainment", defaultMode: "in_person" },
  { key: "Esports & Gaming", label: "Esports & Gaming", icon: Gamepad2, emoji: "🎮", group: "Games & Entertainment", defaultMode: "either" },
  { key: "Music Jam", label: "Music Jam", icon: Music, emoji: "🎵", group: "Games & Entertainment", defaultMode: "either" },
  { key: "Cooking Session", label: "Cooking Session", icon: UtensilsCrossed, emoji: "🍳", group: "Games & Entertainment", defaultMode: "in_person" },
  { key: "Movie Night", label: "Movie Night", icon: Film, emoji: "🎬", group: "Games & Entertainment", defaultMode: "either" },
  { key: "Anime Watch Party", label: "Anime Watch Party", icon: Tv, emoji: "📺", group: "Games & Entertainment", defaultMode: "either" },

  // Wellness
  { key: "Meditation", label: "Meditation", icon: Sparkles, emoji: "🧘", group: "Wellness", defaultMode: "either" },
  { key: "Indoor Yoga", label: "Indoor Yoga", icon: HeartPulse, emoji: "🧘‍♀️", group: "Wellness", defaultMode: "either" },
];

export const CATEGORY_MAP: Record<string, CategoryDef> = Object.fromEntries(
  CATEGORIES.map((c) => [c.key, c]),
);

export function iconForCategory(key: string): LucideIcon {
  return CATEGORY_MAP[key]?.icon ?? Sparkle;
}

export function emojiForCategory(key: string): string {
  return CATEGORY_MAP[key]?.emoji ?? "✨";
}

export const CATEGORY_GROUPS: CategoryGroupKey[] = [
  "Sports & Outdoor",
  "Education & Skills",
  "Tech & Creative",
  "Games & Entertainment",
  "Wellness",
];

// -------- Amenities --------
export type AmenityKey = "wifi" | "power" | "quiet" | "cafe";

export const AMENITIES: { key: AmenityKey; label: string; icon: LucideIcon; badge: string }[] = [
  { key: "wifi", label: "WiFi Available", icon: Wifi, badge: "📶 WiFi" },
  { key: "power", label: "Power Outlets", icon: Plug, badge: "🔌 Power" },
  { key: "quiet", label: "Quiet Zone", icon: VolumeX, badge: "🤫 Silent Focus" },
  { key: "cafe", label: "Cafe / Snacks", icon: Coffee, badge: "☕ Cafe" },
];

export const AMENITY_MAP: Record<string, (typeof AMENITIES)[number]> = Object.fromEntries(
  AMENITIES.map((a) => [a.key, a]),
);