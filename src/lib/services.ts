import { supabase } from "@/integrations/supabase/client";
import type { Database } from "@/integrations/supabase/types";

export type Profile = Database["public"]["Tables"]["profiles"]["Row"];
export type Activity = Database["public"]["Tables"]["activities"]["Row"];
export type JoinRequest = Database["public"]["Tables"]["join_requests"]["Row"];
export type Message = Database["public"]["Tables"]["messages"]["Row"];
export type Notification = Database["public"]["Tables"]["notifications"]["Row"];

// Only these fields are safe to expose cross-user (via public.profiles_public view).
export type PublicProfile = Pick<Profile, "id" | "full_name" | "username" | "avatar_url" | "rating" | "is_verified"> & {
  reliability_score?: number | null;
};
export type ActivityWithHost = Activity & { host: PublicProfile | null };
export type JoinRequestWithUser = JoinRequest & { user: PublicProfile | null };
export type HostJoinProfile = {
  join_request_id: string;
  activity_id: string;
  user_id: string;
  status: JoinRequest["status"];
  checked_in_at: string | null;
  no_show: boolean;
  requested_at: string;
  full_name: string | null;
  username: string | null;
  avatar_url: string | null;
  rating: number;
  reliability_score: number;
  is_verified: boolean;
  city: string | null;
  latitude: number | null;
  longitude: number | null;
  total_reviews: number;
};
export type JoinedActivity = ActivityWithHost & {
  checked_in_at: string | null;
  join_status: "accepted" | "pending";
};

async function fetchPublicProfiles(ids: string[]): Promise<Map<string, PublicProfile>> {
  const unique = Array.from(new Set(ids.filter(Boolean)));
  if (unique.length === 0) return new Map();
  const map = new Map<string, PublicProfile>();
  try {
    const { data, error } = await (supabase as unknown as {
      from: (t: string) => { select: (c: string) => { in: (col: string, v: string[]) => Promise<{ data: PublicProfile[] | null; error: unknown }> } };
    })
      .from("profiles_public")
      .select("id, full_name, username, avatar_url, rating, is_verified, reliability_score")
      .in("id", unique);
    if (error) {
      console.warn("[fetchPublicProfiles] view read failed — falling back to nulls", error);
      return map;
    }
    for (const row of data ?? []) map.set(row.id, row);
  } catch (err) {
    console.warn("[fetchPublicProfiles] threw — falling back to nulls", err);
  }
  return map;
}

async function attachHosts(rows: Activity[]): Promise<ActivityWithHost[]> {
  const hosts = await fetchPublicProfiles(rows.map((a) => a.host_id));
  return rows.map((a) => ({ ...a, host: hosts.get(a.host_id) ?? null }));
}

export const CATEGORY_EMOJI: Record<string, string> = {
  Cricket: "🏏",
  Football: "⚽",
  Trek: "🥾",
  Music: "🎸",
  Food: "🍜",
  "Board games": "🎲",
  Run: "🏃",
  Cycling: "🚴",
  Sports: "🏅",
  Outdoors: "🌄",
  Social: "🎉",
};

export function emojiFor(cat: string) {
  return CATEGORY_EMOJI[cat] ?? "✨";
}

function cleanPublicProfile(raw: unknown): PublicProfile | null {
  if (!raw) return null;
  const p = (Array.isArray(raw) ? raw[0] : raw) as Partial<PublicProfile>;
  if (!p || !p.id) return null;
  return {
    id: String(p.id),
    full_name: p.full_name ?? null,
    username: p.username ?? null,
    avatar_url: p.avatar_url ?? null,
    rating: Number(p.rating ?? 5),
    is_verified: Boolean(p.is_verified),
    reliability_score: p.reliability_score != null ? Number(p.reliability_score) : null,
  };
}

// ---------- Activities ----------
export async function listActivities(): Promise<ActivityWithHost[]> {
  try {
    const { data, error } = await supabase
      .from("activities")
      .select(
        "id, host_id, title, description, category, date_time, location, latitude, longitude, total_slots, slots_left, cost_per_head, image_url, women_only, verified_only, is_urgent, urgent_until, is_online, amenities, topic_tags, created_at, updated_at, deleted_at, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url, rating, is_verified, reliability_score)",
      )
      .is("deleted_at", null)
      .order("date_time", { ascending: true })
      .limit(25);
    if (!error && data) {
      return data.map((r) => ({
        ...r,
        meeting_link: null,
        host: cleanPublicProfile(r.host),
      })) as ActivityWithHost[];
    }
  } catch (err) {
    console.warn("[listActivities] join query failed, falling back to flat fetch", err);
  }

  // Fallback: fetch activities without profile join, then attach hosts via profiles_public view
  const { data, error } = await supabase
    .from("activities")
    .select(
      "id, host_id, title, description, category, date_time, location, latitude, longitude, total_slots, slots_left, cost_per_head, image_url, women_only, verified_only, is_urgent, urgent_until, is_online, amenities, topic_tags, created_at, updated_at, deleted_at",
    )
    .is("deleted_at", null)
    .order("date_time", { ascending: true })
    .limit(25);

  if (error) {
    console.error("[listActivities] fallback fetch failed", error);
    return [];
  }
  const rows = (data ?? []) as Activity[];
  return attachHosts(rows);
}

export type NewActivity = {
  title: string;
  description: string;
  category: string;
  date_time: string;
  location: string;
  total_slots: number;
  cost_per_head: number;
  image_url?: string | null;
  latitude?: number | null;
  longitude?: number | null;
  women_only?: boolean;
  verified_only?: boolean;
  is_online?: boolean;
  meeting_link?: string | null;
  amenities?: string[];
  topic_tags?: string[];
};

export async function createActivity(input: NewActivity) {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("You must be signed in to post a plan");
  const { data, error } = await supabase
    .from("activities")
    .insert({ ...input, host_id: uid, slots_left: input.total_slots })
    .select()
    .single();
  if (error) throw error;
  return data;
}

// Fetches the private meeting link for an online plan. The RPC only returns
// a value when the caller is the host or an accepted attendee — otherwise
// it returns null. Safe to call for any signed-in user.
export async function getMeetingLink(activityId: string): Promise<string | null> {
  const { data, error } = await (supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: string | null; error: unknown }>;
  }).rpc("get_meeting_link", { _activity_id: activityId });
  if (error) throw error;
  return data ?? null;
}

export type UpdateActivity = Partial<NewActivity> & { total_slots?: number };

export async function updateActivity(id: string, patch: UpdateActivity) {
  // Keep slots_left in sync when total_slots grows/shrinks
  const { data: current, error: curErr } = await supabase
    .from("activities")
    .select("total_slots, slots_left")
    .eq("id", id)
    .single();
  if (curErr) throw curErr;
  const next: Database["public"]["Tables"]["activities"]["Update"] = { ...patch };
  if (typeof patch.total_slots === "number" && patch.total_slots !== current.total_slots) {
    // Number of members already accepted into the plan.
    const accepted = Math.max(0, current.total_slots - current.slots_left);
    // Never let the new capacity fall below accepted attendees — silently
    // clamping would leave the plan over-booked with 0 free slots and the
    // host would have no signal that they need to remove someone first.
    if (patch.total_slots < accepted) {
      throw new Error(
        `Can't shrink below ${accepted} — that many members have already joined. Remove someone first.`,
      );
    }
    next.slots_left = Math.max(0, patch.total_slots - accepted);
  }
  const { data, error } = await supabase
    .from("activities")
    .update(next)
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function deleteActivity(id: string) {
  // Soft delete: keep row for referential integrity, hide from feeds.
  const { error } = await supabase
    .from("activities")
    .update({ deleted_at: new Date().toISOString() } as never)
    .eq("id", id);
  if (error) throw error;
  return true;
}

// ---------- Urgent mode ----------
// Marks a plan as URGENT for `minutes` (default 30). Only the host may call
// this — RLS on activities enforces it. Clearing sets both fields to off.
export async function setActivityUrgent(id: string, urgent: boolean, minutes = 30) {
  const patch = urgent
    ? {
        is_urgent: true,
        urgent_until: new Date(Date.now() + minutes * 60_000).toISOString(),
      }
    : { is_urgent: false, urgent_until: null };
  const { data, error } = await supabase
    .from("activities")
    .update(patch as never)
    .eq("id", id)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export function isUrgentActive(a: { is_urgent?: boolean | null; urgent_until?: string | null }) {
  if (!a.is_urgent || !a.urgent_until) return false;
  return new Date(a.urgent_until).getTime() > Date.now();
}

export async function uploadActivityImage(userId: string, file: File): Promise<string> {
  const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
  const path = `${userId}/plan-${Date.now()}.${ext}`;
  const { error: upErr } = await supabase.storage.from("activity-images").upload(path, file, {
    cacheControl: "3600",
    upsert: false,
    contentType: file.type,
  });
  if (upErr) throw upErr;
  // Private bucket — mint a long-lived signed URL to save on the row.
  const { data: signed, error: signErr } = await supabase.storage
    .from("activity-images")
    .createSignedUrl(path, 60 * 60 * 24 * 365);
  if (signErr) throw signErr;
  return signed.signedUrl;
}

// ---------- Join requests ----------
export async function requestToJoin(activityId: string) {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to request to join");
  const profile = await getProfile(uid);
  if (!profile?.city || profile.latitude == null || profile.longitude == null) {
    throw new Error("Add your GPS profile location before requesting to join.");
  }
  // Guard against re-joining: host or existing request.
  const { data: act } = await supabase
    .from("activities")
    .select("host_id")
    .eq("id", activityId)
    .maybeSingle();
  if (act?.host_id === uid) throw new Error("You're the host of this plan.");
  if (act?.host_id) {
    const blocked = await isUserBlocked(uid, act.host_id);
    if (blocked) throw new Error("You cannot interact with this host.");
  }
  const { data: existing } = await supabase
    .from("join_requests")
    .select("id, status")
    .eq("activity_id", activityId)
    .eq("user_id", uid)
    .maybeSingle();
  if (existing) {
    if (existing.status === "accepted") throw new Error("You've already joined this plan!");
    throw new Error("You've already requested to join this plan!");
  }
  const { data, error } = await supabase
    .from("join_requests")
    .insert({ activity_id: activityId, user_id: uid })
    .select()
    .single();
  if (error) {
    const code = (error as { code?: string }).code;
    console.error("[requestToJoin] supabase error", { code, error });
    if (code === "23505") throw new Error("You've already requested to join this plan!");
    if (code === "42501" || /row-level security/i.test((error as { message?: string }).message ?? "")) {
      throw new Error("Add your GPS profile location first, or this plan has safety restrictions you don't meet.");
    }
    throw error;
  }
  return data;
}

export async function listMyJoinRequests(userId: string): Promise<JoinRequest[]> {
  const { data, error } = await supabase
    .from("join_requests")
    .select("*")
    .eq("user_id", userId)
    .limit(25);
  if (error) throw error;
  return data ?? [];
}

export async function listPendingRequestsForHost(hostId: string): Promise<JoinRequestWithUser[]> {
  // RLS: host can see requests for their activities. Filter to pending only.
  const { data: hosted, error: hErr } = await supabase
    .from("activities")
    .select("id")
    .eq("host_id", hostId)
    .limit(25);
  if (hErr) throw hErr;
  const ids = (hosted ?? []).map((a) => a.id);
  if (ids.length === 0) return [];
  const { data, error } = await supabase
    .from("join_requests")
    .select("*")
    .in("activity_id", ids)
    .eq("status", "pending")
    .order("created_at", { ascending: false })
    .limit(25);
  if (error) throw error;
  const rows = (data ?? []) as JoinRequest[];
  const users = await fetchPublicProfiles(rows.map((r) => r.user_id));
  return rows.map((r) => ({ ...r, user: users.get(r.user_id) ?? null }));
}

// ---------- Safety Shield masking ----------
// A plan has a Safety Shield when it is women-only OR verified-only.
// Non-approved viewers see an approximate area (~1 km jitter) and a
// coarse address so exact meeting points stay private until the host
// accepts the join request.
export function hasSafetyShield(a: { women_only?: boolean | null; verified_only?: boolean | null }): boolean {
  return !!(a.women_only || a.verified_only);
}

// Deterministic ~1 km jitter derived from the activity id so the fake
// point stays stable across renders instead of jumping every refresh.
function seededJitter(seed: string): { dLat: number; dLon: number } {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) | 0;
  // Convert to two pseudo-random values in [-1, 1]
  const r1 = ((h & 0xffff) / 0xffff) * 2 - 1;
  const r2 = (((h >>> 16) & 0xffff) / 0xffff) * 2 - 1;
  // ~0.009° ≈ 1 km at the equator
  return { dLat: r1 * 0.009, dLon: r2 * 0.009 };
}

export type MaskedActivity<T extends { id: string; location: string; latitude: number | null; longitude: number | null; women_only?: boolean | null; verified_only?: boolean | null; host_id?: string }> = T & {
  is_masked: boolean;
};

// Applies Safety Shield masking to one activity given the viewer + their accepted-request set.
export function maskActivityForViewer<T extends { id: string; location: string; latitude: number | null; longitude: number | null; women_only?: boolean | null; verified_only?: boolean | null; host_id?: string }>(
  a: T,
  viewerId: string | null,
  acceptedActivityIds: Set<string>,
): MaskedActivity<T> {
  const approved = !!viewerId && (a.host_id === viewerId || acceptedActivityIds.has(a.id));
  if (!hasSafetyShield(a) || approved) {
    return { ...a, is_masked: false };
  }
  const { dLat, dLon } = seededJitter(a.id);
  // Coarse label: keep everything after the first comma (area, city).
  const parts = a.location.split(",").map((s) => s.trim()).filter(Boolean);
  const coarse = parts.length > 1 ? `Near ${parts.slice(-2).join(", ")}` : `Near ${a.location}`;
  return {
    ...a,
    location: coarse,
    latitude: a.latitude !== null ? a.latitude + dLat : null,
    longitude: a.longitude !== null ? a.longitude + dLon : null,
    is_masked: true,
  };
}

export async function listPendingRequestsForActivity(activityId: string): Promise<JoinRequestWithUser[]> {
  const { data, error } = await supabase
    .from("join_requests")
    .select("*")
    .eq("activity_id", activityId)
    .eq("status", "pending")
    .order("created_at", { ascending: false });
  if (error) throw error;
  const rows = (data ?? []) as JoinRequest[];
  const users = await fetchPublicProfiles(rows.map((r) => r.user_id));
  return rows.map((r) => ({ ...r, user: users.get(r.user_id) ?? null }));
}

export async function listActivityJoinProfiles(activityId: string): Promise<HostJoinProfile[]> {
  const { data, error } = await (supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: HostJoinProfile[] | null; error: unknown }>;
  }).rpc("list_activity_join_profiles", { _activity_id: activityId });
  if (error) throw error;
  return data ?? [];
}

export async function respondToJoinRequest(requestId: string, status: "accepted" | "rejected") {
  if (status === "accepted") {
    // Atomic path: locks the activity row, checks slots_left, updates status
    // and (via trigger) decrements slots_left in one transaction.
    const { data, error } = await (supabase as unknown as {
      rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: JoinRequest | null; error: unknown }>;
    }).rpc("accept_join_request", { _req_id: requestId });
    if (error) throw error;
    return data as JoinRequest;
  }
  const { data, error } = await supabase
    .from("join_requests")
    .update({ status })
    .eq("id", requestId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

export async function removeJoinRequest(requestId: string): Promise<JoinRequest> {
  const { data, error } = await (supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: JoinRequest | null; error: unknown }>;
  }).rpc("remove_join_request", { _req_id: requestId });
  if (error) throw error;
  return data as JoinRequest;
}

// ---------- Notifications ----------
export async function listNotifications(userId: string): Promise<Notification[]> {
  const { data, error } = await supabase
    .from("notifications")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(25);
  if (error) throw error;
  return data ?? [];
}

export async function markAllNotificationsRead(userId: string) {
  const { error } = await supabase
    .from("notifications")
    .update({ is_read: true })
    .eq("user_id", userId)
    .eq("is_read", false);
  if (error) throw error;
}

export async function markNotificationRead(id: string) {
  const { error } = await supabase.from("notifications").update({ is_read: true }).eq("id", id);
  if (error) throw error;
}

// ---------- Profile ----------
export async function getProfile(userId: string): Promise<Profile | null> {
  const { data, error } = await supabase.from("profiles").select("*").eq("id", userId).maybeSingle();
  if (error) throw error;
  return data;
}

export async function updateProfile(
  userId: string,
  patch: Partial<
    Pick<
      Profile,
      | "full_name"
      | "username"
      | "bio"
      | "avatar_url"
      | "phone"
      | "gender"
      | "city"
      | "latitude"
      | "longitude"
    >
  > & { interests?: string[]; has_completed_onboarding?: boolean; has_completed_profile?: boolean },
) {
  const { data, error } = await supabase
    .from("profiles")
    .update(patch as never)
    .eq("id", userId)
    .select()
    .single();
  if (error) throw error;
  return data;
}

// Returns true when the username is unused (or already belongs to `excludeId`).
// Case-insensitive: profiles.username is stored as text but we lowercase both sides.
export async function isUsernameAvailable(username: string, excludeId?: string): Promise<boolean> {
  const clean = username.trim().toLowerCase();
  if (!clean) return false;
  const { data, error } = await supabase
    .from("profiles")
    .select("id, username")
    .ilike("username", clean)
    .limit(1);
  if (error) throw error;
  const row = (data ?? [])[0];
  if (!row) return true;
  return excludeId ? row.id === excludeId : false;
}

export async function uploadAvatar(userId: string, file: File): Promise<string> {
  const allowed = new Set(["image/jpeg", "image/png", "image/webp"]);
  if (!allowed.has(file.type)) throw new Error("Please upload a JPG, PNG or WebP image");
  if (file.size > 5 * 1024 * 1024) throw new Error("Image must be under 5MB");
  const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
  const path = `${userId}/avatar-${Date.now()}.${ext}`;
  const { error: upErr } = await supabase.storage.from("avatars").upload(path, file, {
    cacheControl: "3600",
    upsert: true,
    contentType: file.type,
  });
  if (upErr) throw upErr;
  // Bucket is private — use a long-lived signed URL saved on the profile.
  const { data: signed, error: signErr } = await supabase.storage
    .from("avatars")
    .createSignedUrl(path, 60 * 60 * 24 * 365);
  if (signErr) throw signErr;
  await updateProfile(userId, { avatar_url: signed.signedUrl });
  return signed.signedUrl;
}

export async function saveVerifiedProfileLocation(userId: string): Promise<Profile> {
  const coords = await getCurrentCoords();
  let city = `Near ${coords.latitude.toFixed(2)}, ${coords.longitude.toFixed(2)}`;
  try {
    const url = `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${coords.latitude}&lon=${coords.longitude}&accept-language=en`;
    // Cap the reverse geocode at ~3s so the save flow never hangs on a slow
    // Nominatim response — we still have the coordinate fallback.
    const ctrl = new AbortController();
    const timer = setTimeout(() => ctrl.abort(), 3000);
    const res = await fetch(url, { headers: { Accept: "application/json" }, signal: ctrl.signal }).finally(() => clearTimeout(timer));
    if (res.ok) {
      const data = (await res.json()) as { display_name?: string; address?: Record<string, string> };
      const a = data.address ?? {};
      const locality = a.suburb || a.neighbourhood || a.village || a.hamlet || a.town || a.city;
      const cityName = a.city || a.town || a.village || a.county || a.state;
      city = locality && cityName && locality !== cityName ? `${locality}, ${cityName}` : (locality || cityName || data.display_name || city);
    }
  } catch {
    // Keep coordinate fallback when reverse geocoding fails.
  }
  return updateProfile(userId, { city, latitude: coords.latitude, longitude: coords.longitude } as Parameters<typeof updateProfile>[1]);
}

export async function getUserStats(userId: string) {
  // Mirror getUserActivities exactly so counts stay in lock-step with the
  // rendered hosted/joined lists (accepted only, exclude soft-deleted plans
  // and events archived >32h after their scheduled start).
  const { hosted, joined } = await getUserActivities(userId);
  return { hosted: hosted.length, joined: joined.length };
}

export async function getUserActivities(userId: string) {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid || uid !== userId) throw new Error("Sign in to view your plans");

  let hostedData: ActivityWithHost[] = [];
  try {
    const { data: hosted, error: e1 } = await supabase
      .from("activities")
      .select("*, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url, rating, is_verified, reliability_score)")
      .eq("host_id", userId)
      .is("deleted_at", null)
      .order("date_time", { ascending: false })
      .limit(25);
    if (!e1 && hosted) {
      hostedData = hosted.map((a) => ({ ...a, host: cleanPublicProfile(a.host) })) as ActivityWithHost[];
    } else {
      throw e1 || new Error("Failed hosted query");
    }
  } catch {
    // Fallback: fetch hosted without join and attach hosts
    const { data: plainHosted } = await supabase
      .from("activities")
      .select("*")
      .eq("host_id", userId)
      .is("deleted_at", null)
      .order("date_time", { ascending: false })
      .limit(25);
    hostedData = await attachHosts((plainHosted ?? []) as Activity[]);
  }

  let joinedResData: { status: string; checked_in_at: string | null; activity: ActivityWithHost | null }[] = [];
  try {
    const { data: joined, error: e2 } = await supabase
      .from("join_requests")
      .select("status, checked_in_at, activity:activities(*, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url, rating, is_verified, reliability_score))")
      .eq("user_id", userId)
      .eq("status", "accepted")
      .limit(25);
    if (!e2 && joined) {
      joinedResData = joined.map((r) => {
        const act = r.activity as (Activity & { host?: unknown }) | null;
        return {
          status: r.status,
          checked_in_at: r.checked_in_at,
          activity: act ? ({ ...act, host: cleanPublicProfile(act.host) } as ActivityWithHost) : null,
        };
      });
    } else {
      throw e2 || new Error("Failed joined query");
    }
  } catch {
    // Fallback: query join_requests with flat activity
    try {
      const { data: plainJoined } = await supabase
        .from("join_requests")
        .select("status, checked_in_at, activity:activities(*)")
        .eq("user_id", userId)
        .eq("status", "accepted")
        .limit(25);
      if (plainJoined) {
        const acts = (plainJoined.map((r) => r.activity).filter(Boolean) as unknown) as Activity[];
        const attached = await attachHosts(acts);
        const actMap = new Map(attached.map((a) => [a.id, a]));
        joinedResData = plainJoined.map((r) => {
          const act = r.activity as unknown as Activity | null;
          return {
            status: r.status,
            checked_in_at: r.checked_in_at,
            activity: act ? (actMap.get(act.id) ?? null) : null,
          };
        });
      }
    } catch (err) {
      console.error("[getUserActivities] joined fallback failed", err);
    }
  }

  const archiveCutoff = Date.now() - EVENT_ARCHIVE_MS;
  const hostedRows = hostedData.filter((a) => new Date(a.date_time).getTime() >= archiveCutoff);

  const joinedPairs = joinedResData.filter(
    (p) =>
      p.activity &&
      p.activity.deleted_at == null &&
      new Date(p.activity.date_time).getTime() >= archiveCutoff,
  );
  const joinedFull: JoinedActivity[] = joinedPairs.map((p) => ({
    ...p.activity!,
    checked_in_at: p.checked_in_at,
    join_status: p.status as "accepted",
  }));
  return {
    hosted: hostedRows,
    joined: joinedFull,
  };
}

// ---------- Chats (activities the user is host of or accepted into) ----------
export async function listUserChats(userId: string): Promise<Activity[]> {
  const { hosted, joined } = await getUserActivities(userId);
  const map = new Map<string, Activity>();
  [...hosted, ...joined].forEach((a) => map.set(a.id, a));
  return Array.from(map.values())
    .sort((a, b) => (a.date_time < b.date_time ? 1 : -1))
    .slice(0, 25);
}

export async function listMessages(activityId: string): Promise<Message[]> {
  const { data, error } = await supabase
    .from("messages")
    .select("*")
    .eq("activity_id", activityId)
    .order("created_at", { ascending: false })
    .limit(25);
  if (error) throw error;
  // Return oldest→newest for chat rendering.
  return (data ?? []).slice().reverse();
}

export async function sendMessage(activityId: string, text: string) {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to send messages");
  const { data, error } = await supabase
    .from("messages")
    .insert({ activity_id: activityId, sender_id: uid, text })
    .select()
    .single();
  if (error) throw error;
  return data;
}

// ---------- Expenses / Bill Split ----------
export type Expense = Database["public"]["Tables"]["expenses"]["Row"];
export type ExpenseShare = Database["public"]["Tables"]["expense_shares"]["Row"];
export type ExpenseWithShares = Expense & {
  shares: (ExpenseShare & { user: PublicProfile | null })[];
};

/** Members who can be part of a split: host + accepted requesters. */
export async function listPlanMembers(activityId: string): Promise<PublicProfile[]> {
  const { data: act, error: aErr } = await supabase
    .from("activities")
    .select("host_id")
    .eq("id", activityId)
    .maybeSingle();
  if (aErr) throw aErr;
  const { data: reqs, error: rErr } = await supabase
    .from("join_requests")
    .select("user_id")
    .eq("activity_id", activityId)
    .eq("status", "accepted");
  if (rErr) throw rErr;
  const ids = [act?.host_id, ...(reqs ?? []).map((r) => r.user_id)].filter(Boolean) as string[];
  const map = await fetchPublicProfiles(ids);
  // Preserve host first ordering.
  const ordered: PublicProfile[] = [];
  const seen = new Set<string>();
  for (const id of ids) {
    if (seen.has(id)) continue;
    seen.add(id);
    const p = map.get(id);
    if (p) ordered.push(p);
  }
  return ordered;
}

export async function listExpenses(activityId: string): Promise<ExpenseWithShares[]> {
  const { data: exps, error } = await supabase
    .from("expenses")
    .select("*")
    .eq("activity_id", activityId)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) throw error;
  const expenses = (exps ?? []) as Expense[];
  if (expenses.length === 0) return [];
  const { data: shareRows, error: sErr } = await supabase
    .from("expense_shares")
    .select("*")
    .in("expense_id", expenses.map((e) => e.id));
  if (sErr) throw sErr;
  const shares = (shareRows ?? []) as ExpenseShare[];
  const profileMap = await fetchPublicProfiles(shares.map((s) => s.user_id));
  const byExpense = new Map<string, (ExpenseShare & { user: PublicProfile | null })[]>();
  for (const s of shares) {
    const list = byExpense.get(s.expense_id) ?? [];
    list.push({ ...s, user: profileMap.get(s.user_id) ?? null });
    byExpense.set(s.expense_id, list);
  }
  return expenses.map((e) => ({ ...e, shares: byExpense.get(e.id) ?? [] }));
}

export async function getExpense(expenseId: string): Promise<ExpenseWithShares | null> {
  const { data: e, error } = await supabase
    .from("expenses").select("*").eq("id", expenseId).maybeSingle();
  if (error) throw error;
  if (!e) return null;
  const { data: shareRows, error: sErr } = await supabase
    .from("expense_shares").select("*").eq("expense_id", expenseId);
  if (sErr) throw sErr;
  const shares = (shareRows ?? []) as ExpenseShare[];
  const profileMap = await fetchPublicProfiles(shares.map((s) => s.user_id));
  return { ...(e as Expense), shares: shares.map((s) => ({ ...s, user: profileMap.get(s.user_id) ?? null })) };
}

export async function createExpense(input: {
  activityId: string;
  description: string;
  totalAmount: number;
  upiId?: string | null;
  memberIds: string[]; // users included in the split (creator can include self)
  splitType: "equal" | "custom";
  customAmounts?: Record<string, number>; // only for custom
}): Promise<ExpenseWithShares> {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to create an expense");
  if (input.memberIds.length === 0) throw new Error("Select at least one member");
  // Work in whole paise for every intermediate calculation — floating point
  // rupees would drift on splits like ₹0.30 / 7 or ₹100 / 3.
  const totalPaise = Math.round(input.totalAmount * 100);
  if (!(totalPaise > 0)) throw new Error("Amount must be greater than zero");
  const total = totalPaise / 100;

  const amounts = new Map<string, number>();
  if (input.splitType === "equal") {
    const n = input.memberIds.length;
    const basePaise = Math.floor(totalPaise / n);
    let remainderPaise = totalPaise - basePaise * n; // 0..n-1 leftover paise
    for (const id of input.memberIds) {
      const extra = remainderPaise > 0 ? 1 : 0;
      if (remainderPaise > 0) remainderPaise -= 1;
      amounts.set(id, (basePaise + extra) / 100);
    }
  } else {
    let sumPaise = 0;
    for (const id of input.memberIds) {
      const paise = Math.round((input.customAmounts?.[id] ?? 0) * 100);
      sumPaise += paise;
      amounts.set(id, paise / 100);
    }
    if (sumPaise !== totalPaise) throw new Error("Custom shares must add up to the total");
  }

  const { data: exp, error: eErr } = await supabase
    .from("expenses")
    .insert({
      activity_id: input.activityId,
      created_by: uid,
      description: input.description.trim(),
      total_amount: total,
      split_type: input.splitType,
      upi_id: input.upiId?.trim() || null,
    })
    .select()
    .single();
  if (eErr) throw eErr;

  const shareRows = input.memberIds.map((user_id) => ({
    expense_id: exp.id,
    user_id,
    amount: amounts.get(user_id) ?? 0,
  }));
  const { error: sErr } = await supabase.from("expense_shares").insert(shareRows);
  if (sErr) throw sErr;

  // Drop a chat marker so the ledger card appears in the conversation stream.
  await supabase.from("messages").insert({
    activity_id: input.activityId,
    sender_id: uid,
    text: `[[expense:${exp.id}]] ${input.description.trim()} · ₹${total.toFixed(2)}`,
  });

  const full = await getExpense(exp.id);
  return full!;
}

export async function markShareStatus(shareId: string, status: "paid" | "pending") {
  const { error } = await supabase
    .from("expense_shares")
    .update({ status, paid_at: status === "paid" ? new Date().toISOString() : null })
    .eq("id", shareId);
  if (error) throw error;
}

// ---------- Attendance / Reliability ----------
// Wraps navigator.geolocation in a promise with sane options.
export function getCurrentCoords(): Promise<GeolocationCoordinates> {
  return new Promise((resolve, reject) => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      reject(new Error("Geolocation is not supported on this device"));
      return;
    }
    // Two-stage lookup: try a fast cached/low-accuracy read first, then fall
    // back to a longer window before surfacing a timeout error. Mobile GPS
    // cold-starts can easily exceed 8s, so a single short attempt was showing
    // "timeout expired" for users on the edit-profile flow.
    const opts1: PositionOptions = { enableHighAccuracy: false, timeout: 12000, maximumAge: 10 * 60 * 1000 };
    const opts2: PositionOptions = { enableHighAccuracy: false, timeout: 20000, maximumAge: Infinity };
    navigator.geolocation.getCurrentPosition(
      (pos) => resolve(pos.coords),
      () => {
        navigator.geolocation.getCurrentPosition(
          (pos) => resolve(pos.coords),
          (err) => {
            const code = (err as GeolocationPositionError).code;
            if (code === 1) reject(new Error("Location permission denied. Enable it in your browser settings."));
            else if (code === 2) reject(new Error("Location unavailable. Check that GPS is on and try again."));
            else reject(new Error("Getting your location is taking too long. Move near a window or try again."));
          },
          opts2,
        );
      },
      opts1,
    );
  });
}

export type CheckInResult = { status: "checked_in" | "already" | "too_far"; distance_m: number };

// Calls the check_in_activity RPC and returns a single result row.
export async function checkInActivity(activityId: string): Promise<CheckInResult> {
  const coords = await getCurrentCoords();
  const { data, error } = await (supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: CheckInResult[] | null; error: unknown }>;
  }).rpc("check_in_activity", {
    _activity_id: activityId,
    _lat: coords.latitude,
    _lon: coords.longitude,
  });
  if (error) throw error;
  const row = (data ?? [])[0];
  if (!row) throw new Error("Check-in did not return a result");
  return row;
}

export async function markNoShow(requestId: string): Promise<JoinRequest> {
  const { data, error } = await (supabase as unknown as {
    rpc: (fn: string, args: Record<string, unknown>) => Promise<{ data: JoinRequest | null; error: unknown }>;
  }).rpc("mark_no_show", { _req_id: requestId });
  if (error) throw error;
  return data as JoinRequest;
}

// Lists all accepted attendees for an activity + their check-in / no-show state.
// Used on the Plan chat page for the host's attendee roster and for the
// current viewer's own attendance badge.
export async function listAttendees(activityId: string): Promise<JoinRequestWithUser[]> {
  const { data, error } = await supabase
    .from("join_requests")
    .select("*")
    .eq("activity_id", activityId)
    .eq("status", "accepted")
    .order("created_at", { ascending: true });
  if (error) throw error;
  const rows = (data ?? []) as JoinRequest[];
  const users = await fetchPublicProfiles(rows.map((r) => r.user_id));
  return rows.map((r) => ({ ...r, user: users.get(r.user_id) ?? null }));
}

// ---------- Event Memories ----------
export type EventMemory = {
  id: string;
  activity_id: string;
  user_id: string;
  image_url: string;
  caption: string | null;
  created_at: string;
};

const MEMORY_MIME = new Set(["image/jpeg", "image/png", "image/webp"]);
const MEMORY_MAX_BYTES = 5 * 1024 * 1024;

export async function uploadEventMemory(
  userId: string,
  activityId: string,
  file: File,
  caption?: string,
): Promise<EventMemory> {
  if (!MEMORY_MIME.has(file.type)) throw new Error("Please upload a JPG, PNG or WebP image");
  if (file.size > MEMORY_MAX_BYTES) throw new Error("Image is too large (max 5 MB)");
  const ext = (file.name.split(".").pop() || "jpg").toLowerCase();
  const path = `${userId}/memory-${activityId}-${Date.now()}.${ext}`;
  const { error: upErr } = await supabase.storage.from("event-memories").upload(path, file, {
    cacheControl: "3600",
    upsert: false,
    contentType: file.type,
  });
  if (upErr) throw upErr;
  const { data: signed, error: signErr } = await supabase.storage
    .from("event-memories")
    .createSignedUrl(path, 60 * 60 * 24 * 365);
  if (signErr) throw signErr;
  const client = supabase as unknown as {
    from: (t: string) => {
      insert: (r: Record<string, unknown>) => {
        select: () => { single: () => Promise<{ data: EventMemory | null; error: unknown }> };
      };
    };
  };
  const { data, error } = await client
    .from("event_memories")
    .insert({ activity_id: activityId, user_id: userId, image_url: signed.signedUrl, caption: caption?.trim() || null })
    .select()
    .single();
  if (error) throw error;
  return data!;
}

export async function listEventMemories(activityId: string): Promise<EventMemory[]> {
  const client = supabase as unknown as {
    from: (t: string) => {
      select: (c: string) => {
        eq: (col: string, val: string) => {
          order: (c: string, opts: { ascending: boolean }) => {
            limit: (n: number) => Promise<{ data: EventMemory[] | null; error: unknown }>;
          };
        };
      };
    };
  };
  const { data, error } = await client
    .from("event_memories")
    .select("*")
    .eq("activity_id", activityId)
    .order("created_at", { ascending: false })
    .limit(25);
  if (error) throw error;
  return data ?? [];
}

// ---------- Polls ----------
export type Poll = {
  id: string;
  activity_id: string;
  created_by: string;
  question: string;
  options: string[];
  closed_at: string | null;
  created_at: string;
};
export type PollVote = { id: string; poll_id: string; user_id: string; option_index: number; created_at: string };
export type PollWithVotes = Poll & { votes: PollVote[] };

export async function createPoll(input: {
  activityId: string;
  question: string;
  options: string[];
}): Promise<Poll> {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to create a poll");
  const q = input.question.trim();
  const opts = input.options.map((o) => o.trim()).filter(Boolean);
  if (!q) throw new Error("Poll question is required");
  if (opts.length < 2) throw new Error("Add at least 2 options");
  if (opts.length > 6) throw new Error("Max 6 options");
  const client = supabase as unknown as {
    from: (t: string) => {
      insert: (r: Record<string, unknown>) => {
        select: () => { single: () => Promise<{ data: Poll | null; error: unknown }> };
      };
    };
  };
  const { data, error } = await client
    .from("polls")
    .insert({ activity_id: input.activityId, created_by: uid, question: q, options: opts })
    .select()
    .single();
  if (error) throw error;
  // Drop a chat marker
  await supabase.from("messages").insert({
    activity_id: input.activityId,
    sender_id: uid,
    text: `[[poll:${data!.id}]] ${q}`,
  });
  return data!;
}

export async function getPoll(pollId: string): Promise<PollWithVotes | null> {
  const client = supabase as unknown as {
    from: (t: string) => {
      select: (c: string) => {
        eq: (col: string, val: string) => {
          maybeSingle?: () => Promise<{ data: Poll | null; error: unknown }>;
          order?: (c: string, o: { ascending: boolean }) => Promise<{ data: PollVote[] | null; error: unknown }>;
        };
      };
    };
  };
  const { data: poll, error } = await client.from("polls").select("*").eq("id", pollId).maybeSingle!();
  if (error) throw error;
  if (!poll) return null;
  const { data: votes, error: vErr } = await client.from("poll_votes").select("*").eq("poll_id", pollId).order!("created_at", { ascending: true });
  if (vErr) throw vErr;
  return { ...poll, votes: votes ?? [] };
}

export async function castPollVote(pollId: string, optionIndex: number): Promise<void> {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to vote");
  const client = supabase as unknown as {
    from: (t: string) => {
      upsert: (r: Record<string, unknown>, opts: { onConflict: string }) => Promise<{ error: unknown }>;
    };
  };
  const { error } = await client
    .from("poll_votes")
    .upsert({ poll_id: pollId, user_id: uid, option_index: optionIndex }, { onConflict: "poll_id,user_id" });
  if (error) throw error;
}

// ---------- Ratings (Post-Event Reviews) ----------
export type Rating = {
  id: string;
  plan_id: string;
  reviewer_id: string;
  reviewee_id: string;
  rating: number;
  badges: string[];
  comment: string | null;
  created_at: string;
  updated_at: string;
};

export const RATING_BADGES: { key: string; label: string; emoji: string }[] = [
  { key: "punctual", label: "Punctual", emoji: "⏱️" },
  { key: "friendly", label: "Friendly & Respectful", emoji: "😊" },
  { key: "team_player", label: "Great Team Player", emoji: "🤝" },
  { key: "reliable", label: "Highly Reliable", emoji: "⭐" },
];

// True when an event is considered wrapped up. We use a 3h buffer after the
// scheduled start so mid-event ratings / "post-event" actions don't unlock
// the moment the start time passes.
export const EVENT_DURATION_MS = 3 * 60 * 60 * 1000;
export function isEventEnded(a: { date_time: string }): boolean {
  return new Date(a.date_time).getTime() + EVENT_DURATION_MS < Date.now();
}

// Events auto-archive from host/joined lists 32 hours after the scheduled start.
export const EVENT_ARCHIVE_MS = 32 * 60 * 60 * 1000;
export function isEventArchived(a: { date_time: string }): boolean {
  return new Date(a.date_time).getTime() + EVENT_ARCHIVE_MS < Date.now();
}

// Join / edit window closes the moment the event starts.
export function isJoinClosed(a: { date_time: string }): boolean {
  return new Date(a.date_time).getTime() <= Date.now();
}

// Returns every rating the current user has already left for a plan.
export async function listMyRatingsForPlan(planId: string, reviewerId: string): Promise<Rating[]> {
  const client = supabase as unknown as {
    from: (t: string) => {
      select: (c: string) => {
        eq: (col: string, v: string) => {
          eq: (col: string, v: string) => Promise<{ data: Rating[] | null; error: unknown }>;
        };
      };
    };
  };
  const { data, error } = await client
    .from("ratings")
    .select("*")
    .eq("plan_id", planId)
    .eq("reviewer_id", reviewerId);
  if (error) throw error;
  return data ?? [];
}

export async function upsertRating(input: {
  plan_id: string;
  reviewee_id: string;
  rating: number;
  badges: string[];
  comment?: string | null;
}): Promise<Rating> {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to rate");
  if (uid === input.reviewee_id) throw new Error("You can't rate yourself");
  if (!Number.isInteger(input.rating) || input.rating < 1 || input.rating > 5) {
    throw new Error("Pick a star rating between 1 and 5");
  }
  const client = supabase as unknown as {
    from: (t: string) => {
      upsert: (r: Record<string, unknown>, opts: { onConflict: string }) => {
        select: () => { single: () => Promise<{ data: Rating | null; error: unknown }> };
      };
    };
  };
  const { data, error } = await client
    .from("ratings")
    .upsert(
      {
        plan_id: input.plan_id,
        reviewer_id: uid,
        reviewee_id: input.reviewee_id,
        rating: input.rating,
        badges: input.badges.slice(0, 8),
        comment: (input.comment ?? "").trim().slice(0, 500) || null,
      },
      { onConflict: "plan_id,reviewer_id,reviewee_id" },
    )
    .select()
    .single();
  if (error) throw error;
  return data as Rating;
}

// Lists rateable participants for a plan (host + accepted attendees), excluding self.
export async function listRateableParticipants(
  planId: string,
  hostId: string,
  viewerId: string,
): Promise<PublicProfile[]> {
  const attendees = await listAttendees(planId);
  const ids = new Set<string>();
  ids.add(hostId);
  attendees.forEach((a) => ids.add(a.user_id));
  ids.delete(viewerId);
  const map = await fetchPublicProfiles(Array.from(ids));
  return Array.from(map.values());
}

// ---------- Blocking ----------
export type Block = Database["public"]["Tables"]["blocks"]["Row"];

export async function blockUser(targetId: string): Promise<void> {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to block users");
  if (uid === targetId) throw new Error("You cannot block yourself");

  try {
    const { error } = await (supabase as unknown as {
      rpc: (fn: string, args: Record<string, unknown>) => Promise<{ error: unknown }>;
    }).rpc("block_user", { _target_id: targetId });
    if (!error) return;
  } catch {
    // Fallback if RPC not available
  }

  const { error } = await supabase
    .from("blocks")
    .insert({ blocker_id: uid, blocked_id: targetId });
  if (error && (error as { code?: string }).code !== "23505") throw error;

  try {
    const { data: userActs } = await supabase.from("activities").select("id").eq("host_id", uid);
    const actIds = (userActs ?? []).map((a) => a.id);
    if (actIds.length > 0) {
      await supabase
        .from("join_requests")
        .update({ status: "rejected" })
        .in("activity_id", actIds)
        .eq("user_id", targetId)
        .eq("status", "pending");
    }
  } catch {
    // Ignore non-fatal cleanup
  }
}

export async function unblockUser(targetId: string): Promise<void> {
  const { data: userData } = await supabase.auth.getUser();
  const uid = userData.user?.id;
  if (!uid) throw new Error("Sign in to unblock users");

  try {
    const { error } = await (supabase as unknown as {
      rpc: (fn: string, args: Record<string, unknown>) => Promise<{ error: unknown }>;
    }).rpc("unblock_user", { _target_id: targetId });
    if (!error) return;
  } catch {
    // Fallback
  }

  const { error } = await supabase
    .from("blocks")
    .delete()
    .eq("blocker_id", uid)
    .eq("blocked_id", targetId);
  if (error) throw error;
}

export async function getBlockedIds(userId: string): Promise<Set<string>> {
  if (!userId) return new Set();
  const { data, error } = await supabase
    .from("blocks")
    .select("blocker_id, blocked_id")
    .or(`blocker_id.eq.${userId},blocked_id.eq.${userId}`);
  if (error) throw error;
  const set = new Set<string>();
  for (const r of data ?? []) {
    if (r.blocker_id === userId) set.add(r.blocked_id);
    if (r.blocked_id === userId) set.add(r.blocker_id);
  }
  return set;
}

export async function listBlockedUsers(userId: string): Promise<PublicProfile[]> {
  if (!userId) return [];
  try {
    const { data, error } = await (supabase as unknown as {
      rpc: (fn: string) => Promise<{ data: PublicProfile[] | null; error: unknown }>;
    }).rpc("list_blocked_users");
    if (!error && data) return data;
  } catch {
    // Fallback
  }

  const { data: rows, error } = await supabase
    .from("blocks")
    .select("blocked_id")
    .eq("blocker_id", userId);
  if (error) throw error;
  const blockedIds = (rows ?? []).map((r) => r.blocked_id);
  if (blockedIds.length === 0) return [];
  const map = await fetchPublicProfiles(blockedIds);
  return Array.from(map.values());
}

export async function isUserBlocked(userA: string, userB: string): Promise<boolean> {
  if (!userA || !userB) return false;
  const { data, error } = await supabase
    .from("blocks")
    .select("id")
    .or(`and(blocker_id.eq.${userA},blocked_id.eq.${userB}),and(blocker_id.eq.${userB},blocked_id.eq.${userA})`)
    .limit(1);
  if (error) return false;
  return (data ?? []).length > 0;
}