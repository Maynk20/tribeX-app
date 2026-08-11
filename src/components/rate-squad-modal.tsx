import { useEffect, useMemo, useState } from "react";
import { createPortal } from "react-dom";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { X, Star, Check, Loader2 } from "lucide-react";
import { toast } from "sonner";
import {
  listMyRatingsForPlan,
  listRateableParticipants,
  upsertRating,
  RATING_BADGES,
  type PublicProfile,
  type Rating,
} from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

type Draft = { rating: number; badges: string[]; comment: string };
const EMPTY: Draft = { rating: 0, badges: [], comment: "" };

export function RateSquadModal({
  open,
  onClose,
  planId,
  planTitle,
  hostId,
  viewerId,
}: {
  open: boolean;
  onClose: () => void;
  planId: string | null;
  planTitle?: string;
  hostId: string | null;
  viewerId: string | null;
}) {
  const qc = useQueryClient();
  const enabled = !!(open && planId && hostId && viewerId);

  const { data: participants = [], isLoading: loadingPeople } = useQuery({
    queryKey: ["rate-participants", planId, viewerId],
    queryFn: () => listRateableParticipants(planId!, hostId!, viewerId!),
    enabled,
    staleTime: 60_000,
  });

  const { data: existing = [], isLoading: loadingRatings } = useQuery({
    queryKey: ["my-ratings", planId, viewerId],
    queryFn: () => listMyRatingsForPlan(planId!, viewerId!),
    enabled,
    staleTime: 60_000,
  });

  const existingMap = useMemo(() => {
    const m = new Map<string, Rating>();
    existing.forEach((r) => m.set(r.reviewee_id, r));
    return m;
  }, [existing]);

  const [drafts, setDrafts] = useState<Record<string, Draft>>({});

  useEffect(() => {
    if (!enabled) return;
    // Preserve any in-progress drafts across background refetches — only
    // seed a participant's draft if we don't already have one for them.
    // Otherwise a stale-time refetch would wipe half-typed ratings.
    setDrafts((prev) => {
      const next: Record<string, Draft> = { ...prev };
      participants.forEach((p) => {
        if (next[p.id]) return;
        const r = existingMap.get(p.id);
        next[p.id] = r
          ? { rating: r.rating, badges: r.badges ?? [], comment: r.comment ?? "" }
          : { ...EMPTY };
      });
      return next;
    });
  }, [enabled, participants, existingMap]);

  const [savingId, setSavingId] = useState<string | null>(null);
  const save = useMutation({
    mutationFn: async ({ revieweeId, draft }: { revieweeId: string; draft: Draft }) => {
      return upsertRating({
        plan_id: planId!,
        reviewee_id: revieweeId,
        rating: draft.rating,
        badges: draft.badges,
        comment: draft.comment,
      });
    },
    onSuccess: (_data, vars) => {
      toast.success("Rating saved");
      qc.invalidateQueries({ queryKey: ["my-ratings", planId, viewerId] });
      qc.invalidateQueries({ queryKey: ["profile", vars.revieweeId] });
    },
    onError: (e: Error) => toast.error(friendlyError(e)),
    onSettled: () => setSavingId(null),
  });

  if (!open || !planId || !viewerId) return null;
  const loading = loadingPeople || loadingRatings;

  if (typeof document === "undefined") return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm antialiased"
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-5 shadow-2xl"
      >
        <div className="mb-3 flex items-start justify-between gap-3">
          <div>
            <h3 className="text-base font-bold tracking-tight">Rate your squad</h3>
            {planTitle && (
              <p className="mt-0.5 truncate text-xs text-muted-foreground">{planTitle}</p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full p-1 hover:bg-accent"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        {loading ? (
          <div className="flex flex-col gap-3">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-28 animate-pulse rounded-2xl border border-border/60 bg-background" />
            ))}
          </div>
        ) : participants.length === 0 ? (
          <p className="rounded-2xl border border-dashed border-border bg-background p-6 text-center text-sm text-muted-foreground">
            No other participants to rate for this plan.
          </p>
        ) : (
          <ul className="flex flex-col gap-3">
            {participants.map((p) => (
              <ParticipantRow
                key={p.id}
                person={p}
                isHost={p.id === hostId}
                submitted={existingMap.has(p.id)}
                draft={drafts[p.id] ?? EMPTY}
                onChange={(next) => setDrafts((d) => ({ ...d, [p.id]: next }))}
                saving={savingId === p.id && save.isPending}
                onSubmit={() => {
                  const d = drafts[p.id];
                  if (!d || d.rating < 1) {
                    toast.error("Pick a star rating first");
                    return;
                  }
                  setSavingId(p.id);
                  save.mutate({ revieweeId: p.id, draft: d });
                }}
              />
            ))}
          </ul>
        )}
      </div>
    </div>,
    document.body,
  );
}

function ParticipantRow({
  person,
  isHost,
  submitted,
  draft,
  onChange,
  onSubmit,
  saving,
}: {
  person: PublicProfile;
  isHost: boolean;
  submitted: boolean;
  draft: Draft;
  onChange: (d: Draft) => void;
  onSubmit: () => void;
  saving: boolean;
}) {
  const name = person.full_name || person.username || "Squad mate";
  return (
    <li className="rounded-2xl border border-border/60 bg-background p-3">
      <div className="mb-2 flex items-center gap-3">
        <div className="h-9 w-9 shrink-0 overflow-hidden rounded-full bg-primary/15 text-xs font-semibold text-primary">
          {person.avatar_url ? (
            <img src={person.avatar_url} alt="" className="h-full w-full object-cover" />
          ) : (
            <span className="flex h-full w-full items-center justify-center">
              {name[0]?.toUpperCase()}
            </span>
          )}
        </div>
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-semibold">{name}</p>
          <p className="text-[11px] text-muted-foreground">{isHost ? "Host" : "Attendee"}</p>
        </div>
        {submitted && (
          <span className="flex items-center gap-1 rounded-full bg-green-500/15 px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider text-green-600 dark:text-green-400">
            <Check className="h-3 w-3" /> Submitted
          </span>
        )}
      </div>

      <div className="flex items-center gap-1">
        {[1, 2, 3, 4, 5].map((n) => (
          <button
            key={n}
            type="button"
            onClick={() => onChange({ ...draft, rating: n })}
            className="p-1 transition active:scale-90"
            aria-label={`Rate ${n} star${n === 1 ? "" : "s"}`}
          >
            <Star
              className={`h-6 w-6 ${n <= draft.rating ? "fill-amber-400 text-amber-400" : "text-muted-foreground/40"}`}
            />
          </button>
        ))}
      </div>

      <div className="mt-2 flex flex-wrap gap-1.5">
        {RATING_BADGES.map((b) => {
          const on = draft.badges.includes(b.key);
          return (
            <button
              key={b.key}
              type="button"
              onClick={() =>
                onChange({
                  ...draft,
                  badges: on ? draft.badges.filter((k) => k !== b.key) : [...draft.badges, b.key],
                })
              }
              className={`flex items-center gap-1 rounded-full border px-2.5 py-1 text-[11px] font-medium transition ${
                on
                  ? "border-primary bg-primary/10 text-primary"
                  : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"
              }`}
            >
              <span>{b.emoji}</span> {b.label}
            </button>
          );
        })}
      </div>

      <textarea
        value={draft.comment}
        onChange={(e) => onChange({ ...draft, comment: e.target.value })}
        maxLength={500}
        rows={2}
        placeholder="Optional note (private to them)…"
        className="mt-2 w-full resize-none rounded-xl border border-border/60 bg-card px-3 py-2 text-xs outline-none focus:border-primary"
      />

      <button
        type="button"
        onClick={onSubmit}
        disabled={saving || draft.rating < 1}
        className="mt-2 flex w-full items-center justify-center gap-1.5 rounded-full bg-primary py-2 text-xs font-semibold text-primary-foreground transition active:scale-[0.98] disabled:opacity-50"
      >
        {saving ? (
          <><Loader2 className="h-3.5 w-3.5 animate-spin" /> Saving…</>
        ) : submitted ? (
          "Update Rating"
        ) : (
          "Submit Rating"
        )}
      </button>
    </li>
  );
}