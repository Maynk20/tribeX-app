// Dynamic reliability title based on the user's activity mix.
const SPORTS = new Set(["Cricket", "Football", "Run", "Cycling", "Sports", "Box Cricket"]);
const TRAVEL = new Set(["Trek", "Outdoors", "Travel", "Music", "Food", "Social"]);
const WORK = new Set(["Education", "Work", "Study", "Coworking", "Learning"]);

type Categorised = { category?: string | null };
type UserLike = { id?: string | null } | null | undefined;

export function getReliabilityTitle(
  user: UserLike,
  activities:
    | { hosted?: Categorised[]; joined?: Categorised[] }
    | Categorised[]
    | null
    | undefined,
): string {
  const hosted = Array.isArray(activities) ? [] : (activities?.hosted ?? []);
  const joined = Array.isArray(activities) ? activities : (activities?.joined ?? []);
  const all = [...hosted, ...joined];

  if (hosted.length > 0 && hosted.length / Math.max(all.length, 1) > 0.5) {
    return "100% Reliable Host";
  }

  const tally = { sports: 0, travel: 0, work: 0 };
  for (const a of all) {
    const c = a?.category ?? "";
    if (SPORTS.has(c)) tally.sports += 1;
    else if (TRAVEL.has(c)) tally.travel += 1;
    else if (WORK.has(c)) tally.work += 1;
  }

  const top = Object.entries(tally).sort((a, b) => b[1] - a[1])[0];
  if (top && top[1] > 0) {
    if (top[0] === "sports") return "100% Reliable Player";
    if (top[0] === "travel") return "100% Reliable Explorer";
    if (top[0] === "work") return "100% Reliable Partner";
  }

  void user;
  return "100% Reliable Squadmate";
}

export function formatReliabilityLabel(score: number, title: string): string {
  return title.replace(/^100%/, `${Math.round(score)}%`);
}
