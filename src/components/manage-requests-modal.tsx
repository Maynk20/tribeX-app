import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { createPortal } from "react-dom";
import { BadgeCheck, Check, MapPin, Navigation, Star, Trash2, UserX, X } from "lucide-react";
import { toast } from "sonner";
import {
  listActivityJoinProfiles,
  removeJoinRequest,
  respondToJoinRequest,
  type HostJoinProfile,
} from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";
import { getReliabilityTitle, formatReliabilityLabel } from "@/lib/reliability";

export function ManageRequestsModal({
  activityId,
  activityTitle,
  open,
  onClose,
}: {
  activityId: string | null;
  activityTitle?: string;
  open: boolean;
  onClose: () => void;
}) {
  const qc = useQueryClient();
  const { data: people = [], isLoading } = useQuery({
    queryKey: ["activity-join-profiles", activityId],
    queryFn: () => listActivityJoinProfiles(activityId!),
    enabled: open && !!activityId,
  });

  const respond = useMutation({
    mutationFn: ({ id, status }: { id: string; status: "accepted" | "rejected" }) =>
      respondToJoinRequest(id, status),
    onSuccess: (_d, vars) => {
      toast.success(vars.status === "accepted" ? "Request accepted" : "Request declined");
      invalidateHostPlan(qc, activityId);
    },
    onError: (e: Error) => toast.error(friendlyError(e)),
  });

  const remove = useMutation({
    mutationFn: (id: string) => removeJoinRequest(id),
    onSuccess: () => {
      toast.success("User removed from plan");
      invalidateHostPlan(qc, activityId);
    },
    onError: (e: Error) => toast.error(friendlyError(e, "Couldn't remove this user")),
  });

  if (!open || !activityId) return null;
  if (typeof document === "undefined") return null;

  const pendingCount = people.filter((p) => p.status === "pending").length;
  const acceptedCount = people.filter((p) => p.status === "accepted").length;

  return createPortal(
    <div className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm" onClick={onClose}>
      <div
        onClick={(e) => e.stopPropagation()}
        className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[92vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-5 shadow-2xl"
      >
        <div className="flex items-start justify-between gap-3">
          <div>
            <h2 className="text-base font-semibold tracking-tight">Manage joiners</h2>
            {activityTitle && <p className="mt-0.5 text-xs text-muted-foreground">{activityTitle}</p>}
            <p className="mt-1 text-[11px] text-muted-foreground">
              {pendingCount} pending · {acceptedCount} joined
            </p>
          </div>
          <button
            onClick={onClose}
            className="flex h-8 w-8 items-center justify-center rounded-full border border-border/60 transition hover:bg-accent"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="mt-4 max-h-[64vh] overflow-y-auto">
          {isLoading ? (
            <div className="flex flex-col gap-2">
              {[0, 1, 2].map((i) => <div key={i} className="h-28 animate-pulse rounded-2xl bg-secondary" />)}
            </div>
          ) : people.length === 0 ? (
            <p className="py-8 text-center text-sm text-muted-foreground">No join requests or attendees yet.</p>
          ) : (
            <ul className="flex flex-col gap-2">
              {people.map((person) => {
                const busy =
                  (respond.isPending && respond.variables?.id === person.join_request_id) ||
                  (remove.isPending && remove.variables === person.join_request_id);
                return (
                  <AttendeeRow
                    key={person.join_request_id}
                    person={person}
                    busy={busy}
                    onAccept={() => respond.mutate({ id: person.join_request_id, status: "accepted" })}
                    onDecline={() => respond.mutate({ id: person.join_request_id, status: "rejected" })}
                    onRemove={() => remove.mutate(person.join_request_id)}
                  />
                );
              })}
            </ul>
          )}
        </div>
      </div>
    </div>,
    document.body,
  );
}

function AttendeeRow({
  person,
  busy,
  onAccept,
  onDecline,
  onRemove,
}: {
  person: HostJoinProfile;
  busy: boolean;
  onAccept: () => void;
  onDecline: () => void;
  onRemove: () => void;
}) {
  const name = person.full_name || person.username || "Squad mate";
  const score = Math.round(Number(person.reliability_score ?? 100));
  const label = formatReliabilityLabel(score, getReliabilityTitle({ id: person.user_id }, null));
  const mapsHref =
    person.latitude != null && person.longitude != null
      ? `https://www.google.com/maps/search/?api=1&query=${person.latitude},${person.longitude}`
      : null;

  return (
    <li className="rounded-2xl border border-border/60 bg-background/60 p-3">
      <div className="flex items-start gap-3">
        <div className="h-11 w-11 shrink-0 overflow-hidden rounded-full bg-primary/15 text-primary">
          {person.avatar_url ? (
            <img src={person.avatar_url} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="flex h-full w-full items-center justify-center text-sm font-semibold">
              {name[0]?.toUpperCase()}
            </span>
          )}
        </div>
        <div className="min-w-0 flex-1">
          <div className="flex min-w-0 items-center gap-1.5">
            <p className="truncate text-sm font-semibold">{name}</p>
            {person.is_verified && <BadgeCheck className="h-3.5 w-3.5 shrink-0 text-primary" />}
          </div>
          <div className="mt-1 flex flex-wrap gap-1.5">
            <span className="inline-flex items-center gap-1 rounded-full bg-primary/10 px-2 py-0.5 text-[10px] font-semibold text-primary">
              <Star className="h-3 w-3 fill-current" /> {Number(person.rating ?? 5).toFixed(1)} · {person.total_reviews} reviews
            </span>
            <span className="rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-semibold text-green-600 dark:text-green-400">
              ⭐ {label}
            </span>
          </div>
          <p className="mt-1 flex items-center gap-1 text-[11px] text-muted-foreground">
            <MapPin className="h-3 w-3 shrink-0" />
            <span className="truncate">{person.city || "GPS profile location missing"}</span>
          </p>
        </div>
        <span className={`shrink-0 rounded-full px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider ${person.status === "accepted" ? "bg-green-500/15 text-green-600 dark:text-green-400" : "bg-amber-500/15 text-amber-600 dark:text-amber-400"}`}>
          {person.status === "accepted" ? "Joined" : "Pending"}
        </span>
      </div>

      <div className="mt-3 flex items-center justify-end gap-1.5">
        {mapsHref && (
          <a
            href={mapsHref}
            target="_blank"
            rel="noopener noreferrer"
            className="flex h-9 w-9 items-center justify-center rounded-full border border-border/60 text-muted-foreground transition hover:border-primary/60 hover:text-primary"
            aria-label="Open profile location"
            title="Open profile location"
          >
            <Navigation className="h-4 w-4" />
          </a>
        )}
        {person.status === "pending" ? (
          <>
            <button
              onClick={onDecline}
              disabled={busy}
              className="flex h-9 w-9 items-center justify-center rounded-full border border-border/60 text-muted-foreground transition hover:border-destructive/60 hover:text-destructive disabled:opacity-50"
              aria-label="Decline"
            >
              <UserX className="h-4 w-4" />
            </button>
            <button
              onClick={onAccept}
              disabled={busy}
              className="flex h-9 items-center gap-1 rounded-full bg-primary px-3 text-xs font-semibold text-primary-foreground transition hover:scale-105 active:scale-95 disabled:opacity-50"
            >
              <Check className="h-3.5 w-3.5" /> Accept
            </button>
          </>
        ) : (
          <button
            onClick={onRemove}
            disabled={busy}
            className="flex h-9 items-center gap-1 rounded-full border border-destructive/40 px-3 text-xs font-semibold text-destructive transition hover:bg-destructive/10 active:scale-95 disabled:opacity-50"
          >
            <Trash2 className="h-3.5 w-3.5" /> Remove
          </button>
        )}
      </div>
    </li>
  );
}

function invalidateHostPlan(qc: ReturnType<typeof useQueryClient>, activityId: string | null) {
  qc.invalidateQueries({ queryKey: ["activity-join-profiles", activityId] });
  qc.invalidateQueries({ queryKey: ["pending-requests", activityId] });
  qc.invalidateQueries({ queryKey: ["pending-requests-host"] });
  qc.invalidateQueries({ queryKey: ["attendees", activityId] });
  qc.invalidateQueries({ queryKey: ["activities"] });
  qc.invalidateQueries({ queryKey: ["user-activities"] });
}