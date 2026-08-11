import { useEffect, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Bell, Check } from "lucide-react";
import { toast } from "sonner";
import { supabase } from "@/integrations/supabase/client";
import {
  listNotifications,
  markAllNotificationsRead,
  markNotificationRead,
  type Notification,
} from "@/lib/services";

function timeAgo(iso: string) {
  const s = Math.floor((Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return `${s}s`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h`;
  return `${Math.floor(h / 24)}d`;
}

export function NotificationsBell({
  userId,
  onOpenActivity,
  onOpenChat,
}: {
  userId: string;
  onOpenActivity?: (activityId: string) => void;
  onOpenChat?: (activityId: string) => void;
}) {
  const qc = useQueryClient();
  const [open, setOpen] = useState(false);
  const wrapRef = useRef<HTMLDivElement | null>(null);

  const { data: notifications = [] } = useQuery({
    queryKey: ["notifications", userId],
    queryFn: () => listNotifications(userId),
  });

  const unread = notifications.filter((n) => !n.is_read).length;

  // Close on any outside click / touch / Escape — not just on the invisible
  // backdrop, so it works even if the header sits above it.
  useEffect(() => {
    if (!open) return;
    function onDown(e: MouseEvent | TouchEvent) {
      const el = wrapRef.current;
      if (el && !el.contains(e.target as Node)) setOpen(false);
    }
    function onKey(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }
    document.addEventListener("mousedown", onDown);
    document.addEventListener("touchstart", onDown, { passive: true });
    document.addEventListener("keydown", onKey);
    return () => {
      document.removeEventListener("mousedown", onDown);
      document.removeEventListener("touchstart", onDown);
      document.removeEventListener("keydown", onKey);
    };
  }, [open]);

  // Realtime subscription — insert into cache and toast for the new one
  useEffect(() => {
    const channel = supabase
      .channel(`notifications:${userId}`)
      .on(
        "postgres_changes",
        { event: "INSERT", schema: "public", table: "notifications", filter: `user_id=eq.${userId}` },
        (payload) => {
          const n = payload.new as Notification;
          qc.setQueryData<Notification[]>(["notifications", userId], (prev) => [n, ...(prev ?? [])]);
          qc.invalidateQueries({ queryKey: ["pending-requests-host", userId] });
          qc.invalidateQueries({ queryKey: ["my-join-requests", userId] });
          const aid = n.activity_id;
          let action: { label: string; onClick: () => void } | undefined;
          if (aid) {
            if (n.type === "join_request" && onOpenActivity) {
              action = { label: "View", onClick: () => onOpenActivity(aid) };
            } else if ((n.type === "request_accepted" || n.type === "event_match") && onOpenChat) {
              action = {
                label: n.type === "request_accepted" ? "Open chat" : "View plan",
                onClick: () => onOpenChat(aid),
              };
            }
          }
          toast(n.title, { description: n.body ?? undefined, action });
        },
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [userId, qc, onOpenActivity, onOpenChat]);

  async function handleMarkAll() {
    await markAllNotificationsRead(userId);
    qc.setQueryData<Notification[]>(["notifications", userId], (prev) =>
      (prev ?? []).map((n) => ({ ...n, is_read: true })),
    );
  }

  return (
    <div className="relative" ref={wrapRef}>
      <button
        onClick={() => setOpen((v) => !v)}
        className="relative flex h-11 w-11 shrink-0 items-center justify-center rounded-full border border-border/60 bg-card transition hover:border-primary/60 active:scale-95"
        aria-label="Notifications"
      >
        <Bell className="h-5 w-5" />
        {unread > 0 && (
          <span className="absolute -right-0.5 -top-0.5 flex h-5 min-w-5 items-center justify-center rounded-full bg-primary px-1 text-[10px] font-bold text-primary-foreground ring-2 ring-background">
            {unread > 9 ? "9+" : unread}
          </span>
        )}
      </button>
      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="fixed left-2 right-2 top-16 z-50 mx-auto overflow-hidden rounded-2xl border border-border/60 bg-card shadow-xl sm:absolute sm:left-auto sm:right-0 sm:top-14 sm:mx-0 sm:w-[340px]">
            <div className="flex items-center justify-between border-b border-border/60 px-4 py-2.5">
              <h3 className="text-sm font-semibold">Notifications</h3>
              {unread > 0 && (
                <button
                  onClick={handleMarkAll}
                  className="flex items-center gap-1 text-xs font-medium text-primary transition hover:underline"
                >
                  <Check className="h-3 w-3" /> Mark all read
                </button>
              )}
            </div>
            <ul className="max-h-[80vh] overflow-y-auto">
              {notifications.length === 0 ? (
                <li className="px-4 py-8 text-center text-xs text-muted-foreground">
                  You're all caught up.
                </li>
              ) : (
                notifications.map((n) => (
                  <li
                    key={n.id}
                    className={`border-b border-border/40 px-4 py-3 last:border-0 ${!n.is_read ? "bg-primary/5" : ""}`}
                  >
                    <button
                      className="block w-full text-left"
                      onClick={() => {
                        if (!n.is_read) {
                          markNotificationRead(n.id).then(() => {
                            qc.setQueryData<Notification[]>(["notifications", userId], (prev) =>
                              (prev ?? []).map((x) => (x.id === n.id ? { ...x, is_read: true } : x)),
                            );
                          });
                        }
                        if (n.activity_id) {
                          if (n.type === "join_request" && onOpenActivity) {
                            onOpenActivity(n.activity_id);
                            setOpen(false);
                          } else if (
                            (n.type === "request_accepted" || n.type === "event_match") &&
                            onOpenChat
                          ) {
                            onOpenChat(n.activity_id);
                            setOpen(false);
                          } else {
                            setOpen(false);
                          }
                        }
                      }}
                    >
                      <div className="flex items-center justify-between gap-2">
                        <p className="text-xs font-semibold">{n.title}</p>
                        <span className="shrink-0 text-[10px] text-muted-foreground">
                          {timeAgo(n.created_at)}
                        </span>
                      </div>
                      {n.body && (
                        <p className="mt-0.5 text-xs text-muted-foreground">{n.body}</p>
                      )}
                    </button>
                  </li>
                ))
              )}
            </ul>
          </div>
        </>
      )}
    </div>
  );
}