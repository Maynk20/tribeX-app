import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  ArrowLeft,
  Send,
  MapPin,
  Clock,
  IndianRupee,
  ShieldCheck,
  MapPinned,
  UserX,
  CheckCircle2,
  Loader2,
  Plus,
  Flag,
  LogOut,
  ShieldAlert,
} from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import { useAuth } from "@/hooks/use-auth";
import {
  listMessages,
  sendMessage,
  emojiFor,
  listAttendees,
  checkInActivity,
  markNoShow,
  blockUser,
  leaveActivity,
  type MessageWithSender,
  type JoinRequestWithUser,
} from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";
import { ExpenseCard, isExpenseMessage } from "@/components/expense-card";
import { SplitExpenseModal } from "@/components/split-expense-modal";
import { ReportModal } from "@/components/report-modal";
import { MemoryBanner } from "@/components/memory-banner";
import { PageLoader } from "@/components/ui/loader";

export const Route = createFileRoute("/chat/$activityId")({
  head: () => ({ meta: [{ title: "Chat · tribeX" }] }),
  component: ChatPage,
});

function ChatPage() {
  const { activityId } = Route.useParams();
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [text, setText] = useState("");
  const [sending, setSending] = useState(false);
  const [splitOpen, setSplitOpen] = useState(false);
  const [attachOpen, setAttachOpen] = useState(false);
  const [reportOpen, setReportOpen] = useState(false);
  const [showLeaveConfirm, setShowLeaveConfirm] = useState(false);
  const [showBlockConfirm, setShowBlockConfirm] = useState(false);
  const [isLeaving, setIsLeaving] = useState(false);
  const bottomRef = useRef<HTMLDivElement>(null);

  const { data: activity, isLoading: isActivityLoading } = useQuery({
    queryKey: ["activity", activityId],
    queryFn: async () => {
      const { data, error } = await supabase
        .from("activities")
        .select(
          "id, title, category, location, date_time, host_id, latitude, longitude, host:profiles!activities_host_id_fkey(id, full_name, username, avatar_url)",
        )
        .eq("id", activityId)
        .maybeSingle();
      if (error) throw error;
      return data;
    },
  });

  const { data: attendees = [], refetch: refetchAttendees } = useQuery({
    queryKey: ["attendees", activityId],
    queryFn: () => listAttendees(activityId),
    enabled: !!user,
  });

  const {
    data: messages = [],
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ["messages", activityId],
    queryFn: () => listMessages(activityId),
    enabled: !!user,
    refetchInterval: 10000,
  });

  // Realtime WebSocket subscription for instant message updates (matching Android ChatState)
  useEffect(() => {
    if (!activityId) return;
    const channel = supabase
      .channel(`chat-realtime:${activityId}`)
      .on(
        "postgres_changes",
        {
          event: "*",
          schema: "public",
          table: "messages",
          filter: `activity_id=eq.${activityId}`,
        },
        () => {
          qc.invalidateQueries({ queryKey: ["messages", activityId] });
        },
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [activityId, qc]);

  const blockMut = useMutation({
    mutationFn: (targetId: string) => blockUser(targetId),
    onSuccess: () => {
      toast.success("Host blocked");
      qc.invalidateQueries({ queryKey: ["blocked-ids", user?.id] });
      qc.invalidateQueries({ queryKey: ["activities"] });
      navigate({ to: "/" });
    },
    onError: (e: Error) => toast.error(friendlyError(e)),
  });

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages.length]);

  const canPost = !!user && !!activity;
  const hostName = activity?.host?.full_name || activity?.host?.username || "Host";
  const isHost = !!user && !!activity && activity.host_id === user.id;
  const myRequest = useMemo(
    () => (user ? attendees.find((r) => r.user_id === user.id) : undefined),
    [attendees, user],
  );
  const isMember = isHost || !!myRequest;

  const when = useMemo(() => {
    if (!activity?.date_time) return "";
    const d = new Date(activity.date_time);
    return d.toLocaleString([], {
      weekday: "short",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
    });
  }, [activity?.date_time]);

  if (!loading && !user) {
    return (
      <div className="page-in flex flex-col items-start gap-4 px-5 pt-8">
        <h1 className="text-2xl font-bold tracking-tight">Sign in to chat</h1>
        <p className="text-sm text-muted-foreground">
          You need an account to message hosts and squads.
        </p>
        <button
          onClick={() => navigate({ to: "/auth" })}
          className="rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground"
        >
          Sign in
        </button>
      </div>
    );
  }

  if (isActivityLoading) {
    return <PageLoader label="Opening chat" />;
  }

  async function onSend(e: React.FormEvent) {
    e.preventDefault();
    const trimmed = text.trim();
    if (!trimmed || !canPost) return;
    setSending(true);
    try {
      await sendMessage(activityId, trimmed);
      setText("");
      await qc.invalidateQueries({ queryKey: ["messages", activityId] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't send message"));
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="page-in flex h-dvh flex-col">
      <header className="flex shrink-0 items-center gap-3 border-b border-border/60 bg-background/90 px-4 py-3 backdrop-blur">
        <Link
          to="/messages"
          className="rounded-full p-1.5 transition hover:bg-accent active:scale-95"
          aria-label="Back"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-2xl bg-secondary text-lg">
          {activity ? emojiFor(activity.category) : "💬"}
        </div>
        <div className="min-w-0 flex-1">
          <h1 className="truncate text-sm font-semibold">{activity?.title ?? "Chat"}</h1>
          <p className="flex items-center gap-2 truncate text-[11px] text-muted-foreground">
            <span className="truncate">Host · {hostName}</span>
            {activity?.location && (
              <span className="hidden items-center gap-0.5 sm:inline-flex">
                <MapPin className="h-3 w-3" /> {activity.location}
              </span>
            )}
            {when && (
              <span className="hidden items-center gap-0.5 sm:inline-flex">
                <Clock className="h-3 w-3" /> {when}
              </span>
            )}
          </p>
        </div>
        {!isHost && activity?.host_id && (
          <div className="flex items-center gap-1.5">
            {myRequest && (
              <button
                onClick={() => setShowLeaveConfirm(true)}
                className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95"
                title="Leave plan"
                aria-label="Leave plan"
              >
                <LogOut className="h-3.5 w-3.5" />
              </button>
            )}
            <button
              onClick={() => setReportOpen(true)}
              className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95"
              title="Report content or user"
              aria-label="Report"
            >
              <Flag className="h-3.5 w-3.5" />
            </button>
            <button
              onClick={() => setShowBlockConfirm(true)}
              disabled={blockMut.isPending}
              className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-border/60 bg-background text-muted-foreground transition hover:border-destructive/60 hover:text-destructive active:scale-95"
              title={`Block ${hostName}`}
              aria-label={`Block ${hostName}`}
            >
              <UserX className="h-4 w-4" />
            </button>
          </div>
        )}
      </header>

      <div className="flex-1 min-h-0 overflow-y-auto px-4 py-4">
        {activity && (
          <CheckInPanel
            activity={activity}
            isHost={isHost}
            attendees={attendees}
            myRequest={myRequest}
            onChanged={() => refetchAttendees()}
          />
        )}
        {activity && isMember && (
          <MemoryBanner activity={activity} canUpload={isMember} userId={user?.id} />
        )}
        {isLoading ? (
          <div className="flex flex-col gap-2">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-12 animate-pulse rounded-2xl bg-card" />
            ))}
          </div>
        ) : error ? (
          <div className="rounded-2xl border border-destructive/40 bg-destructive/10 p-4 text-sm text-destructive">
            <p className="mb-2">{friendlyError(error, "Couldn't load messages.")}</p>
            <button
              onClick={() => refetch()}
              className="rounded-full bg-destructive px-3 py-1.5 text-xs font-semibold text-destructive-foreground"
            >
              Retry
            </button>
          </div>
        ) : messages.length === 0 ? (
          <div className="mt-10 rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground">
            No messages yet. Say hi to {hostName} 👋
          </div>
        ) : (
          <ul className="flex flex-col gap-2">
            {messages.map((m) => {
              const expId = isExpenseMessage(m.text);
              if (expId) {
                return (
                  <li key={m.id} className="flex justify-center">
                    <div className="w-full max-w-sm">
                      <ExpenseCard expenseId={expId} currentUserId={user?.id} />
                    </div>
                  </li>
                );
              }
              return <MessageBubble key={m.id} m={m} mine={m.sender_id === user!.id} />;
            })}
            <div ref={bottomRef} />
          </ul>
        )}
      </div>

      <form
        onSubmit={onSend}
        className="relative shrink-0 flex items-center gap-2 border-t border-border/60 bg-background px-4 py-3"
      >
        {attachOpen && (
          <>
            <button
              type="button"
              aria-label="Close attach menu"
              onClick={() => setAttachOpen(false)}
              className="fixed inset-0 z-30 cursor-default bg-transparent"
            />
            <div className="absolute bottom-full left-3 z-40 mb-2 w-56 overflow-hidden rounded-2xl border border-border/60 bg-popover shadow-xl">
              <button
                type="button"
                onClick={() => {
                  setAttachOpen(false);
                  setSplitOpen(true);
                }}
                className="flex w-full items-center gap-3 px-4 py-3 text-left text-sm transition hover:bg-accent"
              >
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-emerald-500/15 text-emerald-500">
                  <IndianRupee className="h-4 w-4" />
                </span>
                <span>
                  <span className="block font-semibold">Split expense</span>
                  <span className="block text-[11px] text-muted-foreground">
                    Post a bill with UPI split
                  </span>
                </span>
              </button>
            </div>
          </>
        )}
        <button
          type="button"
          onClick={() => setAttachOpen((v) => !v)}
          disabled={!canPost}
          title="Add"
          aria-label="Add attachment"
          aria-expanded={attachOpen}
          className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-border/60 bg-card text-foreground transition hover:bg-accent active:scale-95 disabled:opacity-50 ${attachOpen ? "rotate-45" : ""}`}
        >
          <Plus className="h-5 w-5" />
        </button>
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder={canPost ? `Message ${hostName}…` : "Join this plan to chat"}
          maxLength={1000}
          disabled={!canPost || sending}
          className="flex-1 rounded-full border border-border/60 bg-card px-4 py-3 text-sm outline-none transition focus:border-primary disabled:opacity-60"
        />
        <button
          type="submit"
          disabled={!canPost || sending || !text.trim()}
          className="flex h-11 w-11 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground transition hover:scale-105 active:scale-95 disabled:opacity-50 disabled:hover:scale-100"
          aria-label="Send"
        >
          <Send className="h-4 w-4" />
        </button>
      </form>

      <SplitExpenseModal
        activityId={activityId}
        open={splitOpen}
        onOpenChange={setSplitOpen}
        currentUserId={user?.id}
      />
      <ReportModal
        open={reportOpen}
        onClose={() => setReportOpen(false)}
        targetType="activity"
        targetId={activityId}
        targetTitle={activity?.title ?? "Activity"}
      />

      {showLeaveConfirm &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => !isLeaving && setShowLeaveConfirm(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="flex flex-col items-center gap-3 text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive">
                  <LogOut className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-bold text-foreground">Leave this plan?</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">
                  You will be removed from this plan and will lose access to the squad chat.
                </p>
              </div>
              <div className="mt-6 flex flex-col gap-2">
                <button
                  disabled={isLeaving}
                  onClick={async () => {
                    setIsLeaving(true);
                    try {
                      await leaveActivity(activityId);
                      toast.success("You left the plan");
                      qc.invalidateQueries({ queryKey: ["user-activities", user?.id] });
                      qc.invalidateQueries({ queryKey: ["activities"] });
                      navigate({ to: "/messages" });
                    } catch (err) {
                      toast.error(friendlyError(err, "Couldn't leave plan"));
                      setIsLeaving(false);
                      setShowLeaveConfirm(false);
                    }
                  }}
                  className="w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-50"
                >
                  {isLeaving ? "Leaving…" : "Yes, Leave Plan"}
                </button>
                <button
                  disabled={isLeaving}
                  onClick={() => setShowLeaveConfirm(false)}
                  className="w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>,
          document.body,
        )}

      {showBlockConfirm &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => !blockMut.isPending && setShowBlockConfirm(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="flex flex-col items-center gap-3 text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive">
                  <ShieldAlert className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-bold text-foreground">Block {hostName}?</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">
                  You won't see their events or messages anymore. You can unblock them anytime from
                  Settings.
                </p>
              </div>
              <div className="mt-6 flex flex-col gap-2">
                <button
                  disabled={blockMut.isPending}
                  onClick={() => {
                    if (activity?.host_id) {
                      blockMut.mutate(activity.host_id);
                    }
                  }}
                  className="w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-50"
                >
                  {blockMut.isPending ? "Blocking…" : `Yes, Block ${hostName}`}
                </button>
                <button
                  disabled={blockMut.isPending}
                  onClick={() => setShowBlockConfirm(false)}
                  className="w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </div>
  );
}

function MessageBubble({ m, mine }: { m: MessageWithSender; mine: boolean }) {
  const time = new Date(m.created_at).toLocaleTimeString([], {
    hour: "numeric",
    minute: "2-digit",
  });
  const rawName = m.sender?.full_name?.trim();
  const rawUname = m.sender?.username?.trim();
  const isGeneric =
    !rawName ||
    ["user", "squad member", "squad mate", "unknown user"].includes(rawName.toLowerCase());
  const senderName = !isGeneric ? rawName : rawUname ? `@${rawUname}` : mine ? "You" : "Member";
  const avatarUrl = m.sender?.avatar_url;
  const initial = (senderName.replace(/^@/, "") || "U")[0]?.toUpperCase() ?? "U";

  return (
    <li className={`flex gap-2 ${mine ? "justify-end" : "justify-start"}`}>
      {!mine && (
        <div className="flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/15 text-[10px] font-bold text-primary self-end mb-1">
          {avatarUrl ? (
            <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
          ) : (
            initial
          )}
        </div>
      )}
      <div
        className={`max-w-[80%] rounded-2xl px-4 py-2 text-sm ${mine ? "bg-primary text-primary-foreground" : "bg-card border border-border/60"}`}
      >
        {!mine && <p className="mb-0.5 text-[11px] font-semibold text-primary">{senderName}</p>}
        <p className="whitespace-pre-wrap break-words">{m.text}</p>
        <p
          className={`mt-1 text-[10px] ${mine ? "text-primary-foreground/70" : "text-muted-foreground"}`}
        >
          {time}
        </p>
      </div>
    </li>
  );
}

// Attendance panel: shows a GPS check-in button for the current viewer (host
// or accepted attendee) once the event is close to starting, and — for hosts
// — a compact roster with Green Verified / Pending / No-show badges plus a
// "Mark no-show" action for attendees who never checked in.
function CheckInPanel({
  activity,
  isHost,
  attendees,
  myRequest,
  onChanged,
}: {
  activity: {
    id: string;
    date_time: string;
    latitude: number | null;
    longitude: number | null;
    host_id: string;
  };
  isHost: boolean;
  attendees: JoinRequestWithUser[];
  myRequest: JoinRequestWithUser | undefined;
  onChanged: () => void;
}) {
  const [busy, setBusy] = useState(false);
  const [busyNoShow, setBusyNoShow] = useState<string | null>(null);
  const hasPin = activity.latitude !== null && activity.longitude !== null;
  const start = new Date(activity.date_time).getTime();
  const now = Date.now();
  const inWindow = now >= start - 2 * 60 * 60 * 1000 && now <= start + 6 * 60 * 60 * 1000;
  // Hosts don't need to check themselves in — they run the plan.
  const canCheckIn =
    hasPin && inWindow && !isHost && !!myRequest && !myRequest.checked_in_at && !myRequest.no_show;
  const alreadyCheckedIn = !isHost && !!myRequest?.checked_in_at;

  async function handleCheckIn() {
    setBusy(true);
    try {
      const res = await checkInActivity(activity.id);
      if (res.status === "checked_in") {
        toast.success(`✅ Checked in · ${Math.round(res.distance_m)} m from venue`);
        onChanged();
      } else if (res.status === "already") {
        toast.info("You're already checked in for this plan.");
      } else if (res.status === "too_far") {
        toast.error(
          `Too far — you're ${Math.round(res.distance_m)} m from the venue (150 m limit).`,
        );
      }
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't check you in"));
    } finally {
      setBusy(false);
    }
  }

  async function handleNoShow(reqId: string) {
    setBusyNoShow(reqId);
    try {
      await markNoShow(reqId);
      toast.success("Marked as no-show");
      onChanged();
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't update attendee"));
    } finally {
      setBusyNoShow(null);
    }
  }

  if (!hasPin && !isHost) return null;

  return (
    <div className="mb-3 rounded-2xl border border-border/60 bg-card p-3">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            <ShieldCheck className="h-3.5 w-3.5 text-primary" /> Venue check-in
          </p>
          <p className="mt-0.5 text-[11px] text-muted-foreground">
            {!hasPin
              ? "Host hasn't pinned the venue coordinates yet."
              : alreadyCheckedIn
                ? "You're verified as present. Enjoy the plan!"
                : inWindow
                  ? "Tap check-in when you arrive (must be within 150 m)."
                  : "Opens 2 hours before the plan starts."}
          </p>
        </div>
        {canCheckIn && !alreadyCheckedIn && (
          <button
            onClick={handleCheckIn}
            disabled={busy}
            className="flex shrink-0 items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95 disabled:opacity-50 disabled:hover:scale-100"
          >
            {busy ? (
              <Loader2 className="h-3.5 w-3.5 animate-spin" />
            ) : (
              <MapPinned className="h-3.5 w-3.5" />
            )}
            {busy ? "Checking…" : "Check in"}
          </button>
        )}
        {alreadyCheckedIn && (
          <span className="flex shrink-0 items-center gap-1 rounded-full bg-green-500/15 px-3 py-1.5 text-xs font-semibold text-green-600 dark:text-green-400">
            <CheckCircle2 className="h-3.5 w-3.5" /> Verified
          </span>
        )}
      </div>

      {isHost && attendees.length > 0 && (
        <div className="mt-3 flex flex-col gap-1.5 border-t border-border/60 pt-3">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-muted-foreground">
            Attendee roster
          </p>
          <ul className="flex flex-col gap-1.5">
            {attendees.map((r) => {
              const name = r.user?.full_name || r.user?.username || "Player";
              const verified = !!r.checked_in_at;
              const noShow = r.no_show;
              return (
                <li
                  key={r.id}
                  className="flex items-center gap-2 rounded-xl bg-background/60 px-2.5 py-1.5"
                >
                  <div className="flex h-7 w-7 shrink-0 items-center justify-center overflow-hidden rounded-full bg-primary/15 text-[10px] font-bold text-primary">
                    {r.user?.avatar_url ? (
                      <img src={r.user.avatar_url} alt="" className="h-full w-full object-cover" />
                    ) : (
                      name[0]?.toUpperCase()
                    )}
                  </div>
                  <span className="min-w-0 flex-1 truncate text-xs">{name}</span>
                  {verified ? (
                    <span className="flex items-center gap-1 rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-semibold text-green-600 dark:text-green-400">
                      <CheckCircle2 className="h-3 w-3" /> Verified
                    </span>
                  ) : noShow ? (
                    <span className="flex items-center gap-1 rounded-full bg-red-500/15 px-2 py-0.5 text-[10px] font-semibold text-red-600 dark:text-red-400">
                      <UserX className="h-3 w-3" /> No-show
                    </span>
                  ) : (
                    <span className="rounded-full bg-secondary px-2 py-0.5 text-[10px] font-semibold text-muted-foreground">
                      Pending
                    </span>
                  )}
                  {!verified && !noShow && (
                    <button
                      onClick={() => handleNoShow(r.id)}
                      disabled={busyNoShow === r.id}
                      title="Mark as no-show"
                      className="rounded-full border border-border/60 px-2 py-0.5 text-[10px] font-semibold text-muted-foreground transition hover:border-red-500/60 hover:text-red-500 active:scale-95 disabled:opacity-50"
                    >
                      {busyNoShow === r.id ? "…" : "No-show"}
                    </button>
                  )}
                </li>
              );
            })}
          </ul>
        </div>
      )}
    </div>
  );
}
