import { createFileRoute, useNavigate, Link, Outlet, useRouterState } from "@tanstack/react-router";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { Star, Trophy, Calendar, MapPin, BadgeCheck, LogOut, UserCog, ShieldAlert, Trash2, Users, Sparkles, Loader2 } from "lucide-react";
import { getProfile, getUserActivities, getUserStats, emojiFor, deleteActivity, listPendingRequestsForHost, isEventEnded, type Activity } from "@/lib/services";
import { useMutation } from "@tanstack/react-query";
import { EditPlanModal } from "@/components/edit-plan-modal";
import { ManageRequestsModal } from "@/components/manage-requests-modal";
import { RateSquadModal } from "@/components/rate-squad-modal";
import { useAuth } from "@/hooks/use-auth";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { useLocation } from "@/hooks/use-location";
import { friendlyError } from "@/lib/friendly-error";
import { EmergencySosModal } from "@/components/emergency-sos-modal";
import { getReliabilityTitle, formatReliabilityLabel } from "@/lib/reliability";
import { PageLoader } from "@/components/ui/loader";

export const Route = createFileRoute("/profile")({
  head: () => ({
    meta: [
      { title: "Profile · tribeX" },
      { name: "description", content: "Your hosted plans, ratings, and squad stats." },
    ],
  }),
  component: ProfileLayout,
});

function ProfileLayout() {
  const routerState = useRouterState();
  const isSettings = routerState.location.pathname === "/profile/settings";

  if (isSettings) {
    return <Outlet />;
  }

  return <Profile />;
}

function Profile() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const { clearLocation } = useLocation();
  const { data: profile, isLoading: isProfileLoading } = useQuery({ queryKey: ["profile", user?.id], queryFn: () => getProfile(user!.id), enabled: !!user });
  const { data: acts, isLoading: isActsLoading } = useQuery({
    queryKey: ["user-activities", user?.id],
    queryFn: () => getUserActivities(user!.id),
    enabled: !!user,
    staleTime: 2 * 60 * 1000,
    gcTime: 10 * 60 * 1000,
  });

  useQuery({ queryKey: ["user-stats", user?.id], queryFn: () => getUserStats(user!.id), enabled: !!user });
  const [showSos, setShowSos] = useState(false);
  const [editingPlan, setEditingPlan] = useState<Activity | null>(null);
  const [deletingPlan, setDeletingPlan] = useState<Activity | null>(null);
  const [myPlansTab, setMyPlansTab] = useState<"joined" | "hosted">("joined");
  const [manageActivityId, setManageActivityId] = useState<string | null>(null);
  const [ratingPlan, setRatingPlan] = useState<Activity | null>(null);
  const [signingOut, setSigningOut] = useState(false);

  const { data: hostPending = [] } = useQuery({
    queryKey: ["pending-requests-host", user?.id],
    queryFn: () => listPendingRequestsForHost(user!.id),
    enabled: !!user,
  });
  const pendingByActivity = hostPending.reduce<Record<string, number>>((m, r) => {
    m[r.activity_id] = (m[r.activity_id] ?? 0) + 1;
    return m;
  }, {});

  const deleteMut = useMutation({
    mutationFn: (id: string) => deleteActivity(id),
    onSuccess: async () => {
      await Promise.all([
        qc.refetchQueries({ queryKey: ["user-activities", user?.id] }),
        qc.invalidateQueries({ queryKey: ["activities"] }),
        qc.invalidateQueries({ queryKey: ["user-stats", user?.id] }),
        qc.invalidateQueries({ queryKey: ["profile", user?.id] }),
      ]);
      toast.success("Plan deleted");
      setDeletingPlan(null);
    },
    onError: (e: unknown) => {
      console.error("[delete-plan] failed", e);
      toast.error(friendlyError(e, "Couldn't delete plan. Please try again."));
    },
  });

  if (!loading && !user) {
    return (
      <div className="page-in flex flex-col items-start gap-4 px-5 pt-8">
        <h1 className="text-2xl font-bold tracking-tight">Your profile</h1>
        <p className="text-sm text-muted-foreground">Sign in to see your hosted plans, ratings and squad stats.</p>
        <button onClick={() => navigate({ to: "/auth" })} className="rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground">
          Sign in
        </button>
      </div>
    );
  }

  if (isProfileLoading || isActsLoading) {
    return <PageLoader label="Loading profile" />;
  }

  const displayName = profile?.full_name || profile?.username || "You";
  const initial = (displayName[0] ?? "U").toUpperCase();
  const hosted = acts?.hosted ?? [];
  const joined = acts?.joined ?? [];
  const hostedCount = hosted.length;
  const joinedCount = joined.length;
  const rating = Number(profile?.rating ?? 5).toFixed(2);
  const reliability = Math.round(
    Number((profile as unknown as { reliability_score?: number | null } | null)?.reliability_score ?? 100),
  );
  const reliabilityTitle = getReliabilityTitle(user, { hosted, joined });
  const reliabilityLabel = formatReliabilityLabel(reliability, reliabilityTitle);
  const reliabilityTone =
    reliability >= 90
      ? "bg-green-500/15 text-green-600 dark:text-green-400"
      : reliability >= 70
      ? "bg-amber-500/15 text-amber-600 dark:text-amber-400"
      : "bg-red-500/15 text-red-600 dark:text-red-400";
  const sortByDateDesc = (a: Activity, b: Activity) => (a.date_time < b.date_time ? 1 : -1);
  const hostedSorted = [...hosted].sort(sortByDateDesc);
  const joinedSorted = [...joined].sort(sortByDateDesc);

  function directionsHref(a: Activity): string {
    if (a.latitude != null && a.longitude != null) {
      return `https://www.google.com/maps/dir/?api=1&destination=${a.latitude},${a.longitude}`;
    }
    return `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(a.location)}`;
  }

  return (
    <div className="page-in flex flex-col gap-5 px-5 pt-6">
      <header className="flex items-start justify-between">
        <div>
          <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Profile</p>
          <h1 className="mt-1 text-3xl font-bold tracking-tight">You</h1>
        </div>
        <button
          onClick={async () => {
            if (signingOut) return;
            setSigningOut(true);
            try {
              const work = (async () => {
                await qc.cancelQueries();
                qc.clear();
                clearLocation();
                const { error } = await supabase.auth.signOut();
                if (error) throw error;
              })();
              await Promise.all([work, new Promise((r) => setTimeout(r, 500))]);
              toast.success("Signed out");
              navigate({ to: "/", replace: true });
            } catch (e) {
              setSigningOut(false);
              toast.error(friendlyError(e, "Couldn't sign out. Please try again."));
            }
          }}
          disabled={signingOut}
          className="flex h-10 w-10 items-center justify-center rounded-full border border-border/60 bg-card transition hover:border-destructive/60 hover:text-destructive active:scale-95 disabled:opacity-60"
          title="Sign out"
        >
          <LogOut className="h-4 w-4" />
        </button>
      </header>

      {signingOut && typeof document !== "undefined" && createPortal(
        <>
          <div className="fixed inset-0 z-[99998] bg-black/80 backdrop-blur-sm" />
          <div className="fixed left-1/2 top-1/2 z-[99999] flex w-[90vw] max-w-xs -translate-x-1/2 -translate-y-1/2 flex-col items-center gap-3 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl">
            <Loader2 className="h-6 w-6 animate-spin text-primary" />
            <p className="text-sm font-semibold">Signing you out…</p>
          </div>
        </>,
        document.body,
      )}

      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <div className="flex items-center gap-4">
          <div className="relative shrink-0">
            <div className="flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-primary text-2xl font-bold text-primary-foreground">
              {profile?.avatar_url ? (
                <img src={profile.avatar_url} alt={displayName} className="h-full w-full object-cover" />
              ) : (
                initial
              )}
            </div>
            {profile?.is_verified && (
              <span className="absolute -top-1 -right-1 flex h-6 w-6 items-center justify-center rounded-full bg-background">
                <BadgeCheck className="h-5 w-5 fill-primary text-primary-foreground" />
              </span>
            )}
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              <h2 className="truncate text-lg font-semibold">{displayName}</h2>
              {profile?.is_verified && (
                <span className="inline-flex items-center gap-1 rounded-full bg-primary/15 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wider text-primary">
                  <BadgeCheck className="h-3 w-3" /> Verified
                </span>
              )}
            </div>
            {profile?.city && (
              <p className="flex items-center gap-1 text-xs text-muted-foreground truncate">
                <MapPin className="h-3 w-3" />
                {profile.city}
              </p>
            )}
            <p className="mt-1 flex items-center gap-1 text-xs">
              <Star className="h-3.5 w-3.5 fill-current text-primary" />
              <span className="font-semibold">{rating}</span>
              <span className="text-muted-foreground">host rating · {hostedCount} plans</span>
            </p>
            <p className={`mt-1 inline-flex w-fit items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-semibold ${reliabilityTone}`}>
              ⭐ {reliabilityLabel}
            </p>
          </div>
        </div>

        <div className="mt-4">
          <p className="text-sm leading-relaxed text-muted-foreground">
            {profile?.bio || "Tell your squad about yourself in settings."}
          </p>
        </div>

        <div className="mt-5 grid grid-cols-3 gap-2 text-center">
          <Stat label="Hosted" value={String(hostedCount)} />
          <Stat label="Joined" value={String(joinedCount)} />
          <Stat label="Rating" value={rating} />
        </div>
      </section>

      <section>
        <div className="mb-2 flex items-center justify-between">
          <h3 className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            My plans
          </h3>
        </div>
        <div className="mb-3 flex rounded-full border border-border/60 bg-card p-1 text-xs">
          {([
            { k: "joined" as const, label: `Joined · ${joinedSorted.length}` },
            { k: "hosted" as const, label: `Hosted · ${hostedSorted.length}` },
          ]).map((t) => (
            <button
              key={t.k}
              onClick={() => setMyPlansTab(t.k)}
              className={`flex-1 rounded-full px-3 py-1.5 font-medium transition ${
                myPlansTab === t.k ? "bg-foreground text-background" : "text-muted-foreground"
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>
        {myPlansTab === "joined" ? (
          joinedSorted.length === 0 ? (
            <div className="rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground">
              You haven't joined any plans yet. Discover one on the Explore tab.
            </div>
          ) : (
            <ul className="flex flex-col gap-2">
              {joinedSorted.map((p) => {
                const ended = isEventEnded(p);
                const canRate = ended && (p.is_online || !!p.checked_in_at);
                return (
                  <li key={p.id} className="flex flex-col gap-2 rounded-2xl border border-border/60 bg-card p-3">
                    <div className="flex items-center gap-3">
                      <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-lg">
                        {emojiFor(p.category)}
                      </div>
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-semibold">{p.title}</p>
                        <p className="flex items-center gap-1 text-xs text-muted-foreground">
                          <Calendar className="h-3 w-3" />
                          {new Date(p.date_time).toLocaleDateString([], { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })}
                        </p>
                      </div>
                      <div className="flex shrink-0 items-center gap-1.5">
                        <Link
                          to="/chat/$activityId"
                          params={{ activityId: p.id }}
                          className="flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95"
                          aria-label="Group chat"
                          title="Group chat"
                        >
                          <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>
                        </Link>
                        <a
                          href={directionsHref(p)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-95"
                          aria-label="Venue directions"
                          title="Venue directions"
                        >
                          <svg className="h-3.5 w-3.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="3 11 22 2 13 21 11 13 3 11"/></svg>
                        </a>
                      </div>
                    </div>
                    {canRate && (
                      <button
                        onClick={() => setRatingPlan(p)}
                        className="flex items-center justify-center gap-1.5 rounded-full bg-gradient-to-r from-amber-500 to-orange-500 px-3 py-1.5 text-[11px] font-semibold text-white shadow-sm transition active:scale-95"
                      >
                        <Sparkles className="h-3 w-3" /> Event ended · Rate your squad
                      </button>
                    )}
                    {ended && !canRate && (
                      <p className="text-center text-[10px] text-muted-foreground">
                        Rating unlocks after check-in at the venue.
                      </p>
                    )}
                  </li>
                );
              })}
            </ul>
          )
        ) : hostedSorted.length === 0 ? (
          <div className="rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground">
            You haven't hosted a plan yet. Tap Create to host one.
          </div>
        ) : (
          <ul className="flex flex-col gap-2">
            {hostedSorted.map((p) => {
              const pending = pendingByActivity[p.id] ?? 0;
              const attendees = Math.max(0, (p.total_slots ?? 0) - (p.slots_left ?? 0));
              return (
                <li key={p.id} className="flex items-center gap-3 rounded-2xl border border-border/60 bg-card p-3">
                  <div className="flex h-11 w-11 shrink-0 items-center justify-center rounded-2xl bg-primary/10 text-lg">
                    {emojiFor(p.category)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold">{p.title}</p>
                    <p className="flex flex-wrap items-center gap-x-2 gap-y-0.5 text-xs text-muted-foreground">
                      <span className="inline-flex items-center gap-1">
                        <Calendar className="h-3 w-3" />
                        {new Date(p.date_time).toLocaleDateString([], { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" })}
                      </span>
                      <span className="inline-flex items-center gap-1">
                        <Users className="h-3 w-3" />
                        {attendees}/{p.total_slots} joined
                      </span>
                      <span className="inline-flex items-center gap-1">
                        <Trophy className="h-3 w-3" /> Hosting
                      </span>
                    </p>
                  </div>
                  <div className="flex shrink-0 items-center gap-1.5">
                    <button
                      onClick={() => setManageActivityId(p.id)}
                      className={`relative flex items-center gap-1 rounded-full px-3 py-1.5 text-xs font-semibold transition active:scale-95 ${
                        pending > 0
                          ? "bg-primary text-primary-foreground hover:scale-105"
                          : "border border-border/60 bg-background text-foreground hover:border-primary/60"
                      }`}
                      title="Manage requests"
                    >
                      Manage
                      {pending > 0 && (
                        <span className="ml-0.5 rounded-full bg-background/25 px-1.5 py-0.5 text-[10px] font-bold">
                          {pending}
                        </span>
                      )}
                    </button>
                    <button
                      onClick={() => setDeletingPlan(p)}
                      className="flex h-8 w-8 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95"
                      aria-label="Delete plan"
                      title="Delete plan"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </li>
              );
            })}
          </ul>
        )}
      </section>

      <section className="mt-2 flex flex-col overflow-hidden rounded-2xl border border-border/60 bg-card">
        <Link
          to="/profile/settings"
          className="flex items-center justify-between p-4 text-left text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
        >
          <span className="flex items-center gap-3">
            <UserCog className="h-4 w-4 text-primary" />
            Settings
          </span>
          <span className="text-xs text-muted-foreground">→</span>
        </Link>
        <button
          onClick={() => setShowSos(true)}
          className="flex items-center gap-3 p-4 text-left text-sm font-bold text-destructive transition hover:bg-destructive/10 active:scale-[0.99]"
        >
          <ShieldAlert className="h-4 w-4" />
          Emergency SOS
        </button>
      </section>

      <p className="pb-6 pt-2 text-center text-[11px] text-muted-foreground/70">
        tribeX v1.0.0
      </p>

      <EmergencySosModal open={showSos} onClose={() => setShowSos(false)} />

      <ManageRequestsModal
        activityId={manageActivityId}
        activityTitle={hostedSorted.find((a) => a.id === manageActivityId)?.title}
        open={manageActivityId !== null}
        onClose={() => setManageActivityId(null)}
      />

      <RateSquadModal
        open={ratingPlan !== null}
        onClose={() => setRatingPlan(null)}
        planId={ratingPlan?.id ?? null}
        planTitle={ratingPlan?.title}
        hostId={ratingPlan?.host_id ?? null}
        viewerId={user?.id ?? null}
      />

      <EditPlanModal
        open={!!editingPlan}
        activity={editingPlan}
        onClose={() => setEditingPlan(null)}
      />

      {deletingPlan && typeof document !== "undefined" && createPortal(
        <div className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm" onClick={() => !deleteMut.isPending && setDeletingPlan(null)}>
          <div onClick={(e) => e.stopPropagation()} className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl">
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
        </div>,
        document.body,
      )}
    </div>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-primary/20 bg-primary/10 py-3">
      <p className="text-lg font-bold text-primary">{value}</p>
      <p className="text-[10px] font-medium uppercase tracking-wider text-muted-foreground">{label}</p>
    </div>
  );
}