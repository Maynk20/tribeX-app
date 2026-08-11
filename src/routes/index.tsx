import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { ListSkeleton } from "../components/ui/loader";
import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import {
  MapPin,
  Star,
  Users,
  Clock,
  Search,
  ArrowUpDown,
  LogIn,
  Navigation,
  Check,
  MessageCircle,
  X,
  Hourglass,
  Bell,
  Zap,
  Shield,
  Monitor,
  Globe,
  Hash,
  Pencil,
  Trash2,
  BadgeCheck,
  SlidersHorizontal,
  IndianRupee,
  CalendarDays,
  Sparkles,
  UserX,
} from "lucide-react";
import {
  listActivities,
  requestToJoin,
  getUserActivities,
  listMyJoinRequests,
  listPendingRequestsForHost,
  setActivityUrgent,
  isUrgentActive,
  maskActivityForViewer,
  hasSafetyShield,
  deleteActivity,
  getProfile,
  getBlockedIds,
  blockUser,
  type ActivityWithHost,
  type MaskedActivity,
  type Activity,
} from "@/lib/services";
import { supabase } from "@/integrations/supabase/client";
import { CATEGORIES, CATEGORY_GROUPS, emojiForCategory, AMENITY_MAP, type AmenityKey } from "@/lib/categories";
import { notifyUrgentSpot } from "@/lib/urgent-push.functions";
import { useAuth } from "@/hooks/use-auth";
import { useLocation } from "@/hooks/use-location";
import { friendlyError } from "@/lib/friendly-error";
import { PlaceSearch } from "@/components/place-search";
import { SafetyDisclaimerModal } from "@/components/safety-disclaimer-modal";
import { NotificationsBell } from "@/components/notifications-bell";
import { ManageRequestsModal } from "@/components/manage-requests-modal";
import { EditPlanModal } from "@/components/edit-plan-modal";

export const Route = createFileRoute("/")({
  component: Explore,
});

type SortKey = "date" | "distance" | "popularity";
type ModeFilter = "all" | "in_person" | "online";
type Scope = "discover" | "joined" | "hosting";
const SORTS: { key: SortKey; label: string }[] = [
  { key: "date", label: "Date" },
  { key: "distance", label: "Distance" },
  { key: "popularity", label: "Popularity" },
];

function formatWhen(iso: string): string {
  const d = new Date(iso);
  const now = new Date();
  const sameDay = d.toDateString() === now.toDateString();
  const tomorrow = new Date(now); tomorrow.setDate(now.getDate() + 1);
  const isTom = d.toDateString() === tomorrow.toDateString();
  const time = d.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });
  if (sameDay) return `Today · ${time}`;
  if (isTom) return `Tomorrow · ${time}`;
  return `${d.toLocaleDateString([], { weekday: "short", month: "short", day: "numeric" })} · ${time}`;
}

function Explore() {
  // View is list-only; map view removed.
  const [active, setActive] = useState("All");
  const [activeGroup, setActiveGroup] = useState<string>("All");
  const [modeFilter, setModeFilter] = useState<ModeFilter>("all");
  const [query, setQuery] = useState("");
  const [sort, setSort] = useState<SortKey>("date");
  const [sortOpen, setSortOpen] = useState(false);
  const [freeOnly, setFreeOnly] = useState(false);
  const [spotsOnly, setSpotsOnly] = useState(false);
  const [todayOnly, setTodayOnly] = useState(false);
  const [weekendOnly, setWeekendOnly] = useState(false);
  const [verifiedHostsOnly, setVerifiedHostsOnly] = useState(false);
  const sortPanelRef = useRef<HTMLDivElement | null>(null);
  const [scope, setScope] = useState<Scope>("discover");
  const [lightbox, setLightbox] = useState<string | null>(null);
  const { user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();
  // Scope switches read from cache — TanStack Query already keeps them fresh
  // via staleTime + focus refetch. Extra invalidation on every tap made the
  // whole UI feel laggy.
  const { location, setPlace, requestBrowserLocation, requesting } = useLocation();
  const [pendingJoinId, setPendingJoinId] = useState<string | null>(null);
  const [manageActivityId, setManageActivityId] = useState<string | null>(null);
  const [urgentBusyId, setUrgentBusyId] = useState<string | null>(null);
  const [editingPlan, setEditingPlan] = useState<Activity | null>(null);
  const [deletingPlan, setDeletingPlan] = useState<Activity | null>(null);

  const { data: activities = [], isLoading, error, refetch } = useQuery({
    queryKey: ["activities"],
    queryFn: listActivities,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });

  const { data: mineJoined, error: mineError } = useQuery({
    queryKey: ["user-activities", user?.id],
    queryFn: () => getUserActivities(user!.id),
    enabled: !!user,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });
  useEffect(() => {
    if (mineError) console.error("[explore] user-activities failed", mineError);
  }, [mineError]);
  const mineIds = useMemo(() => new Set((mineJoined?.hosted ?? []).map((a) => a.id)), [mineJoined]);
  const joinedIds = useMemo(() => new Set((mineJoined?.joined ?? []).map((a) => a.id)), [mineJoined]);

  const { data: myRequests = [] } = useQuery({
    queryKey: ["my-join-requests", user?.id],
    queryFn: () => listMyJoinRequests(user!.id),
    enabled: !!user,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });
  const { data: viewerProfile } = useQuery({
    queryKey: ["profile", user?.id],
    queryFn: () => getProfile(user!.id),
    enabled: !!user,
    staleTime: 5 * 60 * 1000,
  });
  const viewerIsFemale = (() => {
    const g = (viewerProfile?.gender ?? "").toLowerCase().trim();
    return ["female", "woman", "f", "w"].includes(g);
  })();
  const viewerIsVerified = !!viewerProfile?.is_verified;
  const hasProfileGpsLocation = !user || (!!viewerProfile?.city && viewerProfile.latitude != null && viewerProfile.longitude != null);
  const requestedIds = useMemo(
    () => new Set(myRequests.filter((r) => r.status === "pending").map((r) => r.activity_id)),
    [myRequests],
  );
  const acceptedRequestIds = useMemo(
    () => new Set(myRequests.filter((r) => r.status === "accepted").map((r) => r.activity_id)),
    [myRequests],
  );

  const { data: hostPending = [] } = useQuery({
    queryKey: ["pending-requests-host", user?.id],
    queryFn: () => listPendingRequestsForHost(user!.id),
    enabled: !!user,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });
  const pendingByActivity = useMemo(() => {
    const m = new Map<string, number>();
    hostPending.forEach((r) => m.set(r.activity_id, (m.get(r.activity_id) ?? 0) + 1));
    return m;
  }, [hostPending]);

  const { data: blockedIds = new Set<string>() } = useQuery({
    queryKey: ["blocked-ids", user?.id],
    queryFn: () => getBlockedIds(user!.id),
    enabled: !!user,
    staleTime: 5 * 60 * 1000,
  });

  const blockHostMut = useMutation({
    mutationFn: (hostId: string) => blockUser(hostId),
    onSuccess: () => {
      toast.success("Host blocked — their plans will no longer appear in your feed.");
      qc.invalidateQueries({ queryKey: ["blocked-ids", user?.id] });
      qc.invalidateQueries({ queryKey: ["blocked-users", user?.id] });
      qc.invalidateQueries({ queryKey: ["activities"] });
      qc.invalidateQueries({ queryKey: ["my-join-requests", user?.id] });
    },
    onError: (e: Error) => toast.error(friendlyError(e)),
  });

  useEffect(() => {
    const actChannel = supabase
      .channel("public:activities")
      .on(
        "postgres_changes",
        { event: "*", schema: "public", table: "activities" },
        () => {
          qc.invalidateQueries({ queryKey: ["activities"] });
          if (user?.id) {
            qc.invalidateQueries({ queryKey: ["user-activities", user.id] });
          }
        },
      )
      .subscribe();

    let blockChannel: ReturnType<typeof supabase.channel> | null = null;
    if (user?.id) {
      blockChannel = supabase
        .channel(`blocks:${user.id}`)
        .on(
          "postgres_changes",
          { event: "*", schema: "public", table: "blocks" },
          () => {
            qc.invalidateQueries({ queryKey: ["blocked-ids", user.id] });
            qc.invalidateQueries({ queryKey: ["activities"] });
            qc.invalidateQueries({ queryKey: ["my-join-requests", user.id] });
          },
        )
        .subscribe();
    }

    return () => {
      supabase.removeChannel(actChannel);
      if (blockChannel) supabase.removeChannel(blockChannel);
    };
  }, [qc, user?.id]);

  const join = useMutation({
    mutationFn: (id: string) => requestToJoin(id),
    onSuccess: () => {
      toast.success("Request sent to host");
      qc.invalidateQueries({ queryKey: ["activities"] });
      qc.invalidateQueries({ queryKey: ["my-join-requests", user?.id] });
      qc.invalidateQueries({ queryKey: ["user-activities", user?.id] });
    },
    onError: (e: Error) => toast.error(friendlyError(e)),
  });

  const deleteMut = useMutation({
    mutationFn: (id: string) => deleteActivity(id),
    onSuccess: async () => {
      toast.success("Plan deleted");
      setDeletingPlan(null);
      await Promise.all([
        qc.refetchQueries({ queryKey: ["activities"] }),
        qc.refetchQueries({ queryKey: ["user-activities", user?.id] }),
        qc.invalidateQueries({ queryKey: ["user-stats", user?.id] }),
        qc.invalidateQueries({ queryKey: ["profile", user?.id] }),
      ]);
    },
    onError: (e: unknown) => {
      console.error("[delete-plan] failed", e);
      toast.error(friendlyError(e, "Couldn't delete plan. Please try again."));
    },
  });

  async function handleToggleUrgent(a: ActivityWithHost) {
    const active = isUrgentActive(a);
    setUrgentBusyId(a.id);
    try {
      await setActivityUrgent(a.id, !active, 30);
      if (!active) {
        toast.success("⚡ Urgent alert sent to nearby players");
        try {
          const res = await notifyUrgentSpot({ data: { activityId: a.id } });
          if (res?.success && (res.sent ?? 0) > 0) {
            toast.success(`Notified ${res.sent} nearby ${res.sent === 1 ? "player" : "players"}`);
          }
        } catch (err) {
          console.error("[urgent] push dispatch failed", err);
        }
      } else {
        toast.success("Urgent mode cleared");
      }
      qc.invalidateQueries({ queryKey: ["activities"] });
    } catch (e) {
      toast.error(friendlyError(e as Error));
    } finally {
      setUrgentBusyId(null);
    }
  }

  // Deep-link handler: /?activity=<id>&join=1 (from urgent push notification).
  // Opens the safety disclaimer for one-tap request-to-join.
  useEffect(() => {
    if (typeof window === "undefined" || !user) return;
    const params = new URLSearchParams(window.location.search);
    const aid = params.get("activity");
    const join = params.get("join");
    if (aid && join === "1") {
      setPendingJoinId(aid);
      const url = new URL(window.location.href);
      url.searchParams.delete("activity");
      url.searchParams.delete("join");
      window.history.replaceState({}, "", url.pathname + (url.search || ""));
    }
  }, [user]);

  // Close the filter panel on any outside click / Escape
  useEffect(() => {
    if (!sortOpen) return;
    function onDown(e: MouseEvent | TouchEvent) {
      const el = sortPanelRef.current;
      if (el && !el.contains(e.target as Node)) setSortOpen(false);
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") setSortOpen(false);
    }
    document.addEventListener("mousedown", onDown);
    document.addEventListener("touchstart", onDown, { passive: true });
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("touchstart", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [sortOpen]);

  const activeFilterCount =
    (freeOnly ? 1 : 0) +
    (spotsOnly ? 1 : 0) +
    (todayOnly ? 1 : 0) +
    (weekendOnly ? 1 : 0) +
    (verifiedHostsOnly ? 1 : 0);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    const city = (location || "").trim().toLowerCase();
    const nowMs = Date.now();
    // For the Hosting tab we always source from the user's own hosted list
    // (getUserActivities) so a plan is visible even when the public feed
    // filters it out (past date, safety flags, RLS narrowing, etc).
    const source: ActivityWithHost[] =
      scope === "hosting" && user
        ? ((mineJoined?.hosted ?? []) as ActivityWithHost[])
        : activities;
    const base = source.filter((a) => {
      // Hide events that have already started/ended from Discover so the
      // feed only surfaces upcoming plans.
      if (scope === "discover" && new Date(a.date_time).getTime() < nowMs) return false;
      if (user) {
        if (blockedIds.has(a.host_id)) return false;
        const hostedByMe = a.host_id === user.id || mineIds.has(a.id);
        if (scope === "hosting" && !hostedByMe) return false;
        if (scope === "joined" && !joinedIds.has(a.id)) return false;
        if (scope === "discover") {
          if (hostedByMe) return false;
          if (joinedIds.has(a.id)) return false;
          if (requestedIds.has(a.id)) return false;
        }
      }
      if (active !== "All" && a.category !== active) return false;
      if (activeGroup !== "All") {
        const g = CATEGORIES.find((c) => c.key === a.category)?.group;
        if (g !== activeGroup) return false;
      }
      if (modeFilter === "in_person" && a.is_online) return false;
      if (modeFilter === "online" && !a.is_online) return false;
      if (freeOnly && (a.cost_per_head ?? 0) > 0) return false;
      if (spotsOnly && (a.slots_left ?? 0) <= 0) return false;
      if (todayOnly) {
        const d = new Date(a.date_time);
        const now = new Date();
        if (d.toDateString() !== now.toDateString()) return false;
      }
      if (weekendOnly) {
        const day = new Date(a.date_time).getDay();
        if (day !== 0 && day !== 6) return false;
      }
      if (verifiedHostsOnly && !a.host?.is_verified) return false;
      if ((!user || scope === "discover") && city && !a.location.toLowerCase().includes(city)) {
        // allow first token match (e.g. "Delhi NCR" -> "Delhi")
        const firstToken = city.split(/[\s,]/)[0];
        if (!firstToken || !a.location.toLowerCase().includes(firstToken)) return false;
      }
      if (!q) return true;
      return (
        a.title.toLowerCase().includes(q) ||
        a.location.toLowerCase().includes(q) ||
        a.category.toLowerCase().includes(q) ||
        (a.topic_tags ?? []).some((t) => t.toLowerCase().includes(q))
      );
    });
    const sorted = [...base];
    if (sort === "date") {
      sorted.sort((a, b) => (a.date_time < b.date_time ? -1 : 1));
    } else if (sort === "popularity") {
      // Fewest slots left = highest demand
      sorted.sort((a, b) => {
        const ra = a.total_slots > 0 ? a.slots_left / a.total_slots : 1;
        const rb = b.total_slots > 0 ? b.slots_left / b.total_slots : 1;
        return ra - rb;
      });
    } else if (sort === "distance") {
      sorted.sort((a, b) => a.location.localeCompare(b.location));
    }
    // Apply Safety Shield masking last so sort keys use the true location.
    return sorted.map((a) => maskActivityForViewer(a, user?.id ?? null, acceptedRequestIds));
  }, [activities, mineJoined, active, activeGroup, modeFilter, query, sort, location, scope, mineIds, joinedIds, requestedIds, user, acceptedRequestIds, freeOnly, spotsOnly, todayOnly, weekendOnly, verifiedHostsOnly]);

  async function handleUseGPS() {
    try {
      await requestBrowserLocation();
      toast.success("Location updated");
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Couldn't get your location");
    }
  }

  return (
    <div className="page-in flex flex-col gap-5 px-5 pt-6">
      <header className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex-1">
          {user ? (
            <div className="flex items-center gap-2">
              <PlaceSearch
                value={location}
                onSelect={(p) => { setPlace(p); toast.success(`Showing plans near ${p.short}`); }}
              />
              <button
                onClick={handleUseGPS}
                disabled={requesting}
                className="text-muted-foreground/70 transition hover:text-primary disabled:opacity-50"
                aria-label="Use current location"
                title="Use my location"
              >
                <Navigation className={`h-3 w-3 ${requesting ? "animate-pulse" : ""}`} />
              </button>
            </div>
          ) : (
            <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">
              Discover plans nearby
            </p>
          )}
          <h1 className="mt-1 font-brand text-3xl font-black tracking-tight text-primary">
            tribe<span className="text-black dark:text-white">X</span>
          </h1>
        </div>
        {authLoading ? (
          <div className="h-11 w-11 shrink-0 animate-pulse rounded-full bg-card" />
        ) : user ? (
          <div className="flex shrink-0 items-center gap-2">
            <NotificationsBell
              userId={user.id}
              onOpenActivity={(id) => setManageActivityId(id)}
              onOpenChat={(id) => navigate({ to: "/chat/$activityId", params: { activityId: id } })}
            />
            <button
            onClick={() => navigate({ to: "/profile" })}
            className="h-11 w-11 shrink-0 overflow-hidden rounded-full bg-primary text-primary-foreground font-semibold transition hover:scale-105 active:scale-95"
            aria-label="Open profile"
            >
            {viewerProfile?.avatar_url ? (
              <img
                src={viewerProfile.avatar_url}
                alt=""
                className="h-full w-full object-cover"
              />
            ) : (
              <span className="flex h-full w-full items-center justify-center">
                {(viewerProfile?.full_name ||
                  (user.user_metadata?.full_name as string | undefined) ||
                  user.email ||
                  "U")[0]?.toUpperCase()}
              </span>
            )}
            </button>
          </div>
        ) : (
          <button
            onClick={() => navigate({ to: "/auth" })}
            className="flex shrink-0 items-center gap-1.5 rounded-full bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95"
          >
            <LogIn className="h-3.5 w-3.5" /> Sign in
          </button>
        )}
      </header>

      <div className="flex items-center gap-2">
        <label className="flex flex-1 items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary">
          <Search className="h-4 w-4 text-muted-foreground" />
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search plans, sports, spots…"
            className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          />
        </label>
        <div className="relative" ref={sortPanelRef}>
          <button
            onClick={() => setSortOpen((v) => !v)}
            aria-label="Sort & filter"
            className="relative flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl border border-border/60 bg-card transition hover:border-primary active:scale-95"
          >
            <SlidersHorizontal className="h-4 w-4" />
            {activeFilterCount > 0 && (
              <span className="absolute -right-1 -top-1 flex h-4 min-w-4 items-center justify-center rounded-full bg-primary px-1 text-[9px] font-bold text-primary-foreground ring-2 ring-background">
                {activeFilterCount}
              </span>
            )}
          </button>
          {sortOpen && (
            <div className="absolute right-0 top-14 z-30 w-72 overflow-hidden rounded-2xl border border-border/60 bg-card shadow-xl">
              <div className="flex items-center justify-between border-b border-border/60 px-4 py-2.5">
                <p className="text-[10px] font-bold uppercase tracking-wider text-muted-foreground">Sort & Filter</p>
                {(activeFilterCount > 0 || sort !== "date") && (
                  <button
                    onClick={() => {
                      setSort("date");
                      setFreeOnly(false); setSpotsOnly(false);
                      setTodayOnly(false); setWeekendOnly(false);
                      setVerifiedHostsOnly(false);
                    }}
                    className="text-[10px] font-semibold uppercase tracking-wider text-primary hover:underline"
                  >
                    Reset
                  </button>
                )}
              </div>
              <div className="px-4 pt-3">
                <p className="mb-2 flex items-center gap-1.5 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
                  <ArrowUpDown className="h-3 w-3" /> Sort by
                </p>
                <div className="grid grid-cols-3 gap-1.5">
                  {SORTS.map((s) => (
                    <button
                      key={s.key}
                      onClick={() => setSort(s.key)}
                      className={`rounded-lg border px-2 py-1.5 text-[11px] font-semibold transition ${
                        sort === s.key
                          ? "border-primary bg-primary/10 text-primary"
                          : "border-border/60 bg-background text-muted-foreground hover:border-primary/60"
                      }`}
                    >
                      {s.label}
                    </button>
                  ))}
                </div>
              </div>
              <div className="px-4 pb-4 pt-3">
                <p className="mb-2 text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">Quick filters</p>
                <div className="flex flex-col gap-1.5">
                  {[
                    { k: "free", label: "Free entry", icon: IndianRupee, on: freeOnly, set: setFreeOnly },
                    { k: "spots", label: "Has open spots", icon: Users, on: spotsOnly, set: setSpotsOnly },
                    { k: "today", label: "Today only", icon: Clock, on: todayOnly, set: setTodayOnly },
                    { k: "weekend", label: "This weekend", icon: CalendarDays, on: weekendOnly, set: setWeekendOnly },
                    { k: "verified", label: "Verified hosts only", icon: BadgeCheck, on: verifiedHostsOnly, set: setVerifiedHostsOnly },
                  ].map(({ k, label, icon: Icon, on, set }) => (
                    <button
                      key={k}
                      onClick={() => set((v: boolean) => !v)}
                      className={`flex items-center justify-between rounded-lg border px-3 py-2 text-xs font-medium transition ${
                        on
                          ? "border-primary bg-primary/10 text-primary"
                          : "border-border/60 bg-background text-foreground hover:border-primary/50"
                      }`}
                    >
                      <span className="flex items-center gap-2">
                        <Icon className="h-3.5 w-3.5" />
                        {label}
                      </span>
                      <span
                        className={`flex h-4 w-4 items-center justify-center rounded-full border ${
                          on ? "border-primary bg-primary text-primary-foreground" : "border-border"
                        }`}
                      >
                        {on && <Check className="h-2.5 w-2.5" strokeWidth={3} />}
                      </span>
                    </button>
                  ))}
                </div>
                <button
                  onClick={() => setSortOpen(false)}
                  className="mt-3 flex w-full items-center justify-center gap-1.5 rounded-lg bg-primary py-2 text-xs font-semibold text-primary-foreground transition hover:bg-primary/90"
                >
                  <Sparkles className="h-3.5 w-3.5" /> Apply
                </button>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="flex items-center justify-between">
        <div className="-mx-5 flex gap-2 overflow-x-auto px-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          <button
            onClick={() => { setActiveGroup("All"); setActive("All"); }}
            className={`shrink-0 rounded-full border px-4 py-1.5 text-xs font-semibold transition-all active:scale-95 ${
              activeGroup === "All" && active === "All"
                ? "border-primary bg-primary text-primary-foreground shadow-sm"
                : "border-border/60 bg-card text-muted-foreground hover:border-primary/60"
            }`}
          >
            All
          </button>
          {CATEGORY_GROUPS.map((g) => (
            <button
              key={g}
              onClick={() => { setActiveGroup(g); setActive("All"); }}
              className={`shrink-0 rounded-full border px-4 py-1.5 text-xs font-semibold uppercase tracking-wider transition-all active:scale-95 ${
                activeGroup === g
                  ? "border-primary bg-primary text-primary-foreground shadow-sm"
                  : "border-border/60 bg-card text-muted-foreground hover:border-primary/60"
              }`}
            >
              {g}
            </button>
          ))}
        </div>
      </div>

      {activeGroup !== "All" && (
        <div className="-mx-5 flex gap-2 overflow-x-auto px-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
          <button
            onClick={() => setActive("All")}
            className={`shrink-0 rounded-full border px-3 py-1 text-[11px] font-medium transition ${
              active === "All" ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground"
            }`}
          >
            All in group
          </button>
          {CATEGORIES.filter((c) => c.group === activeGroup).map((c) => {
            const Icon = c.icon;
            const on = active === c.key;
            return (
              <button
                key={c.key}
                onClick={() => setActive(c.key)}
                className={`flex shrink-0 items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-medium transition ${
                  on ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"
                }`}
              >
                <Icon className="h-3.5 w-3.5" />
                {c.label}
              </button>
            );
          })}
        </div>
      )}

      <div className="flex rounded-full border border-border/60 bg-card p-1 text-xs">
        {([
          { k: "all", label: "All", icon: null },
          { k: "in_person", label: "In-Person", icon: <MapPin className="h-3 w-3" /> },
          { k: "online", label: "Virtual", icon: <Monitor className="h-3 w-3" /> },
        ] as { k: ModeFilter; label: string; icon: React.ReactNode }[]).map((m) => (
          <button
            key={m.k}
            onClick={() => setModeFilter(m.k)}
            className={`flex flex-1 items-center justify-center gap-1 rounded-full px-3 py-1.5 font-semibold transition ${
              modeFilter === m.k ? "bg-foreground text-background" : "text-muted-foreground"
            }`}
          >
            {m.icon}
            {m.label}
          </button>
        ))}
      </div>

      {user && (
        <div className="flex rounded-full border border-border/60 bg-card p-1 text-xs">
          {([
            { k: "discover", label: "Discover" },
            { k: "joined", label: "Joined" },
            { k: "hosting", label: "Hosting" },
          ] as { k: Scope; label: string }[]).map((s) => (
            <button
              key={s.k}
              onClick={() => setScope(s.k)}
              className={`flex-1 rounded-full px-3 py-1.5 font-medium transition ${
                scope === s.k ? "bg-foreground text-background" : "text-muted-foreground"
              }`}
            >
              {s.label}
            </button>
          ))}
        </div>
      )}

      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold tracking-tight">
          {!user || scope === "discover"
            ? "Happening nearby"
            : scope === "joined"
              ? "Plans you've joined"
              : "Plans you're hosting"}
        </h2>
      </div>

      {isLoading ? (
        <ListSkeleton count={3} variant="card" />
      ) : error ? (
        !user ? (
          <div className="flex flex-col items-start gap-3 rounded-2xl border border-border/60 bg-card p-4 text-sm">
            <p className="font-semibold">Sign in to see plans near you</p>
            <p className="text-xs text-muted-foreground">Join the tribe to discover activities, chat with hosts, and RSVP in seconds.</p>
            <button
              onClick={() => navigate({ to: "/auth" })}
              className="rounded-full bg-primary px-4 py-1.5 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95"
            >
              Sign in to continue
            </button>
          </div>
        ) : (
          <div className="flex flex-col items-start gap-3 rounded-2xl border border-border/60 bg-card p-4 text-sm">
            <p className="font-semibold">We couldn't load plans right now</p>
            <p className="text-xs text-muted-foreground">Check your connection and try again.</p>
            <button
              onClick={() => refetch()}
              className="rounded-full bg-primary px-4 py-1.5 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95"
            >
              Retry
            </button>
          </div>
        )
      ) : filtered.length === 0 ? (
        <div className="flex flex-col items-center gap-2 rounded-3xl border border-dashed border-border bg-card/40 py-10 text-center">
          <p className="text-sm text-muted-foreground">
            {scope === "hosting"
              ? "You haven't hosted any plans yet."
              : scope === "joined"
                ? "You haven't joined any plans yet."
                : "No plans match your filters right now."}
          </p>
          <p className="text-[11px] text-muted-foreground/70">Tap the + button above or the Create tab to post one.</p>
        </div>
      ) : (
        <ul className="grid grid-cols-1 gap-3 sm:grid-cols-2 md:gap-4 lg:grid-cols-3">
          {filtered.map((a) => (
            <ActivityCard
              key={a.id}
              activity={a}
              onImage={(url) => setLightbox(url)}
              isHost={a.host_id === user?.id || mineIds.has(a.id)}
              hasRequested={requestedIds.has(a.id)}
              viewerIsFemale={viewerIsFemale}
              viewerIsVerified={viewerIsVerified}
              hasProfileGpsLocation={hasProfileGpsLocation}
              myStatus={
                a.host_id === user?.id || mineIds.has(a.id)
                  ? "hosting"
                  : acceptedRequestIds.has(a.id) || joinedIds.has(a.id)
                    ? "confirmed"
                    : requestedIds.has(a.id)
                      ? "pending"
                      : null
              }
              pendingCount={pendingByActivity.get(a.id) ?? 0}
              onManage={() => setManageActivityId(a.id)}
              onEdit={() => {
                const full = activities.find((x) => x.id === a.id);
                if (full) setEditingPlan(full);
              }}
              onDelete={() => {
                const full = activities.find((x) => x.id === a.id);
                if (full) setDeletingPlan(full);
              }}
              onToggleUrgent={() => handleToggleUrgent(a)}
              urgentBusy={urgentBusyId === a.id}
              onJoin={() => {
                if (!user) { navigate({ to: "/auth" }); return; }
                if (!hasProfileGpsLocation) {
                  toast.error("Add your GPS profile location first", {
                    description: "Open Profile → Edit details → Use current location.",
                  });
                  return;
                }
                setPendingJoinId(a.id);
              }}
              onMessage={() => {
                if (!user) { navigate({ to: "/auth" }); return; }
                navigate({ to: "/chat/$activityId", params: { activityId: a.id } });
              }}
              joining={join.isPending}
            />
          ))}
        </ul>
      )}
      <SafetyDisclaimerModal
        open={pendingJoinId !== null}
        onCancel={() => setPendingJoinId(null)}
        onAgree={() => {
          const id = pendingJoinId;
          setPendingJoinId(null);
          if (id) join.mutate(id);
        }}
      />
      <ManageRequestsModal
        activityId={manageActivityId}
        activityTitle={activities.find((a) => a.id === manageActivityId)?.title}
        open={manageActivityId !== null}
        onClose={() => setManageActivityId(null)}
      />
      <EditPlanModal
        open={!!editingPlan}
        activity={editingPlan}
        onClose={() => setEditingPlan(null)}
      />
      {deletingPlan && typeof document !== "undefined" && createPortal(
        <>
          <div
            className="fixed inset-0 z-[99998] bg-black/80 backdrop-blur-md"
            onClick={() => !deleteMut.isPending && setDeletingPlan(null)}
          />
          <div
            onClick={(e) => e.stopPropagation()}
            className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[99999] w-[92vw] max-w-sm rounded-2xl p-6 bg-card border shadow-2xl max-h-[85vh] overflow-y-auto"
          >
            <h3 className="text-lg font-bold">Delete this plan?</h3>
            <p className="mt-1 text-sm text-muted-foreground">
              "{deletingPlan.title}" will be removed for everyone. This can't be undone.
            </p>
            <div className="mt-5 flex items-center justify-end gap-2">
              <button
                onClick={() => setDeletingPlan(null)}
                disabled={deleteMut.isPending}
                className="rounded-full border border-border/60 px-4 py-2 text-xs font-semibold transition hover:bg-accent disabled:opacity-60"
              >
                Cancel
              </button>
              <button
                onClick={() => deleteMut.mutate(deletingPlan.id)}
                disabled={deleteMut.isPending}
                className="flex items-center gap-1.5 rounded-full bg-destructive px-4 py-2 text-xs font-semibold text-destructive-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60"
              >
                <Trash2 className="h-3.5 w-3.5" />
                {deleteMut.isPending ? "Deleting…" : "Delete"}
              </button>
            </div>
          </div>
        </>,
        document.body,
      )}
      {lightbox && (
        <div
          className="fixed inset-0 z-[80] flex items-center justify-center bg-black/90 p-4 backdrop-blur-sm"
          onClick={() => setLightbox(null)}
        >
          <button
            aria-label="Close preview"
            className="absolute right-4 top-4 flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white transition hover:bg-white/20"
            onClick={() => setLightbox(null)}
          >
            <X className="h-5 w-5" />
          </button>
          <img src={lightbox} alt="" className="max-h-full max-w-full rounded-2xl object-contain" />
        </div>
      )}
    </div>
  );
}

function ActivityCard({
  activity: a,
  onJoin,
  onMessage,
  joining,
  onImage,
  isHost,
  hasRequested,
  viewerIsFemale,
  viewerIsVerified,
  hasProfileGpsLocation,
  myStatus,
  pendingCount,
  onManage,
  onToggleUrgent,
  urgentBusy,
  onEdit,
  onDelete,
}: {
  activity: MaskedActivity<ActivityWithHost>;
  onJoin: () => void;
  onMessage: () => void;
  joining: boolean;
  onImage: (url: string) => void;
  isHost: boolean;
  hasRequested: boolean;
  viewerIsFemale: boolean;
  viewerIsVerified: boolean;
  hasProfileGpsLocation: boolean;
  myStatus: "hosting" | "confirmed" | "pending" | null;
  pendingCount: number;
  onManage: () => void;
  onToggleUrgent: () => void;
  urgentBusy: boolean;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const accent = "bg-primary/15 text-primary";
  const urgent = a.slots_left <= 3;
  const hostName = a.host?.full_name || a.host?.username || "Host";
  const urgentActive = isUrgentActive(a);
  const shielded = hasSafetyShield(a);
  const shieldLabel = a.women_only && a.verified_only
    ? "Women & verified only"
    : a.women_only ? "Women only" : a.verified_only ? "Verified only" : null;
  // Safety gate: block join if viewer doesn't meet the plan's restrictions.
  const blockedByWomenOnly = !!a.women_only && !viewerIsFemale;
  const blockedByVerified = !!a.verified_only && !viewerIsVerified;
  const safetyBlock = blockedByWomenOnly
    ? "Women Only Plan"
    : blockedByVerified
      ? "Verification Required"
      : !hasProfileGpsLocation
        ? "Add GPS Location"
      : null;

  return (
    <li className="group relative flex h-full flex-col overflow-hidden rounded-3xl border border-border/60 bg-card p-4 transition-all hover:-translate-y-0.5 hover:border-primary/40 hover:shadow-md active:scale-[0.99]">
      {isHost && pendingCount > 0 && (
        <button
          onClick={onManage}
          className="absolute right-3 top-3 z-10 flex items-center gap-1 rounded-full bg-primary px-2.5 py-1 text-[10px] font-bold text-primary-foreground shadow-md ring-2 ring-background transition hover:scale-105 active:scale-95"
          aria-label={`${pendingCount} pending requests`}
        >
          <Bell className="h-3 w-3" />
          {pendingCount} pending
        </button>
      )}
      {urgentActive && (
        <div
          className="absolute left-3 top-3 z-10 flex items-center gap-1 rounded-full bg-red-500 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider text-white shadow-lg ring-2 ring-background animate-pulse"
          aria-label="Urgent: spot needed"
        >
          <Zap className="h-3 w-3 fill-current" />
          Urgent · Spot needed
        </div>
      )}
      {a.image_url && (
        <button
          type="button"
          onClick={(e) => { e.stopPropagation(); onImage(a.image_url!); }}
          className="-mx-4 -mt-4 mb-3 block h-36 w-[calc(100%+2rem)] overflow-hidden bg-secondary"
          aria-label="View photo"
        >
          <img
            src={a.image_url}
            alt={a.title}
            loading="lazy"
            className="h-full w-full object-cover transition duration-300 group-hover:scale-105"
          />
        </button>
      )}
      <div className="flex items-start gap-3">
        <div className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl text-2xl leading-none transition group-hover:scale-105 ${accent}`}>
          <span aria-hidden>{emojiForCategory(a.category)}</span>
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-1.5">
            <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider ${accent}`}>
              {a.category}
            </span>
            {a.is_online && (
              <span className="flex shrink-0 items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-emerald-600 dark:text-emerald-400">
                <Globe className="h-2.5 w-2.5" /> Virtual
              </span>
            )}
            {myStatus === "confirmed" && (
              <span className="shrink-0 rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-green-600 dark:text-green-400">
                Confirmed
              </span>
            )}
            {myStatus === "pending" && (
              <span className="shrink-0 rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-amber-600 dark:text-amber-400">
                Awaiting approval
              </span>
            )}
            {myStatus === "hosting" && (
              <span className="shrink-0 rounded-full bg-primary/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-primary">
                Hosting
              </span>
            )}
            {shielded && shieldLabel && (
              <span
                className="flex shrink-0 items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary"
                title={a.is_masked ? "Exact venue hidden until host approves" : shieldLabel}
              >
                <Shield className="h-2.5 w-2.5" /> {shieldLabel}
              </span>
            )}
          </div>
          <h3 className="mt-1.5 line-clamp-2 text-base font-semibold tracking-tight">{a.title}</h3>
          <p className="mt-0.5 flex items-center gap-1 truncate text-xs text-muted-foreground">
            <MapPin className="h-3 w-3 shrink-0" />
            <span className="truncate">{a.is_masked ? "~ " : ""}{a.location}</span>
          </p>
          <p className="mt-0.5 flex items-center gap-1 text-xs text-muted-foreground">
            <Clock className="h-3 w-3" /> {formatWhen(a.date_time)}
          </p>
          {((a.amenities ?? []).length > 0 || (a.topic_tags ?? []).length > 0) && (
            <div className="mt-2 flex flex-wrap items-center gap-1.5">
              {(a.amenities ?? []).slice(0, 4).map((k) => {
                const meta = AMENITY_MAP[k as AmenityKey];
                if (!meta) return null;
                return (
                  <span key={k} className="rounded-full bg-secondary px-2 py-0.5 text-[10px] font-medium text-foreground/80">
                    {meta.badge}
                  </span>
                );
              })}
              {(a.topic_tags ?? []).slice(0, 3).map((t) => (
                <span key={t} className="flex items-center gap-0.5 rounded-full border border-border/60 bg-background px-2 py-0.5 text-[10px] font-medium text-muted-foreground">
                  <Hash className="h-2.5 w-2.5" />{t}
                </span>
              ))}
            </div>
          )}
        </div>
      </div>

      <div className="mt-auto flex flex-col gap-3 border-t border-border/60 pt-3">
        <div className="flex items-center gap-x-2 gap-y-1 text-xs overflow-hidden">
          <span className="flex shrink-0 items-center gap-1 text-muted-foreground">
            <Users className="h-3.5 w-3.5" />
            <span className={urgent ? "font-semibold text-primary" : ""}>
              {a.slots_left}/{a.total_slots}
            </span>
          </span>
          <span className="flex shrink-0 items-center gap-1 text-muted-foreground">
            <Star className="h-3.5 w-3.5 fill-current text-primary" />
            {Number(a.host?.rating ?? 5).toFixed(1)}
          </span>
          <span className="flex min-w-0 flex-1 items-center gap-1 text-muted-foreground">
            <span aria-hidden className="shrink-0">·</span>
            {a.host?.avatar_url ? (
              <img
                src={a.host.avatar_url}
                alt=""
                loading="lazy"
                className="h-4 w-4 shrink-0 rounded-full object-cover"
              />
            ) : (
              <span className="flex h-4 w-4 shrink-0 items-center justify-center rounded-full bg-primary/20 text-[9px] font-bold text-primary">
                {hostName[0]?.toUpperCase() ?? "H"}
              </span>
            )}
            <span className="truncate">{hostName}</span>
            {a.host?.is_verified && (
              <BadgeCheck className="h-3 w-3 shrink-0 text-primary" aria-label="Verified host" />
            )}
          </span>
        </div>
        <div className="flex w-full flex-wrap items-center gap-1.5">
          {isHost && a.slots_left > 0 && (
            <button
              onClick={onToggleUrgent}
              disabled={urgentBusy}
              title={urgentActive ? "Cancel urgent alert" : "Send urgent spot alert to nearby players"}
              className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full transition active:scale-95 disabled:opacity-50 ${
                urgentActive
                  ? "bg-red-500 text-white shadow-sm animate-pulse hover:bg-red-600"
                  : "border border-amber-500/60 bg-amber-500/10 text-amber-600 hover:bg-amber-500/20 dark:text-amber-400"
              }`}
              aria-label={urgentActive ? "Urgent on" : "Urgent fill"}
            >
              <Zap className="h-3.5 w-3.5" />
            </button>
          )}
          {isHost ? (
            <>
              <button
                onClick={onManage}
                className="min-w-0 flex-1 truncate whitespace-nowrap rounded-full border border-primary/40 bg-primary/10 px-3 py-2 text-xs font-semibold text-primary transition hover:scale-[1.02] active:scale-95"
              >
                Manage
              </button>
              <button
                onClick={onMessage}
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95"
                aria-label="Group chat"
                title="Group chat"
              >
                <MessageCircle className="h-3.5 w-3.5" />
              </button>
              {new Date(a.date_time).getTime() > Date.now() && (
                <button
                  onClick={onEdit}
                  className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95"
                  aria-label="Edit plan"
                  title="Edit plan"
                >
                  <Pencil className="h-3.5 w-3.5" />
                </button>
              )}
              <button
                onClick={onDelete}
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95"
                aria-label="Delete plan"
                title="Delete plan"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </>
          ) : (
            <>
              <button
                onClick={onMessage}
                className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95"
                aria-label="Message host"
                title="Chat"
              >
                <MessageCircle className="h-3.5 w-3.5" />
              </button>
              {myStatus === "pending" || hasRequested ? (
            <button
              disabled
              className="flex min-w-0 flex-1 items-center justify-center gap-1 truncate rounded-full border border-border/60 bg-secondary px-3 py-2 text-xs font-semibold text-muted-foreground disabled:cursor-not-allowed"
            >
              <Hourglass className="h-3 w-3" /> Request Pending
            </button>
          ) : myStatus === "confirmed" ? (
            <button
              onClick={onMessage}
              className="flex min-w-0 flex-1 items-center justify-center gap-1 truncate rounded-full bg-emerald-500/15 px-4 py-2 text-xs font-semibold text-emerald-600 dark:text-emerald-400 transition hover:bg-emerald-500/25 active:scale-95"
            >
              <Check className="h-3.5 w-3.5" /> Joined
            </button>
          ) : safetyBlock ? (
            <button
              disabled
              title={safetyBlock}
              className="flex min-w-0 flex-1 items-center justify-center gap-1 truncate rounded-full border border-border/60 bg-secondary px-3 py-2 text-xs font-semibold text-muted-foreground disabled:cursor-not-allowed"
            >
              <Shield className="h-3 w-3" /> {safetyBlock}
            </button>
          ) : (
            <button
              onClick={onJoin}
              disabled={joining || a.slots_left <= 0}
              className="min-w-0 flex-1 truncate rounded-full bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground transition-transform hover:scale-[1.02] active:scale-95 disabled:cursor-not-allowed disabled:opacity-50 disabled:hover:scale-100"
            >
              {a.slots_left <= 0 ? "Full" : joining ? "…" : "Request to Join"}
            </button>
          )}
            </>
          )}
        </div>
      </div>
    </li>
  );
}
