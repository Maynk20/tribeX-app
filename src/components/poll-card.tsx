import { useMemo } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { BarChart3, Check } from "lucide-react";
import { toast } from "sonner";
import { getPoll, castPollVote } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

export function PollCard({ pollId, currentUserId }: { pollId: string; currentUserId: string | undefined }) {
  const qc = useQueryClient();
  const { data: poll, isLoading } = useQuery({
    queryKey: ["poll", pollId],
    queryFn: () => getPoll(pollId),
    refetchInterval: 5000,
    staleTime: 3_000,
  });

  const tally = useMemo(() => {
    const counts = new Array((poll?.options.length ?? 0)).fill(0) as number[];
    for (const v of poll?.votes ?? []) if (v.option_index >= 0 && v.option_index < counts.length) counts[v.option_index]++;
    const total = counts.reduce((a, b) => a + b, 0);
    return { counts, total };
  }, [poll]);

  const myVote = useMemo(
    () => (currentUserId ? poll?.votes.find((v) => v.user_id === currentUserId)?.option_index ?? null : null),
    [poll, currentUserId],
  );

  async function vote(idx: number) {
    try {
      await castPollVote(pollId, idx);
      await qc.invalidateQueries({ queryKey: ["poll", pollId] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't record your vote"));
    }
  }

  if (isLoading) return <div className="h-32 w-full animate-pulse rounded-2xl bg-card" />;
  if (!poll)
    return (
      <div className="rounded-2xl border border-dashed border-border/60 bg-card/40 p-3 text-xs text-muted-foreground">
        This poll was removed.
      </div>
    );

  return (
    <article className="w-full overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm">
      <header className="flex items-start justify-between gap-3 border-b border-border/60 bg-secondary/40 px-4 py-3">
        <div className="min-w-0">
          <p className="flex items-center gap-1 text-[10px] font-semibold uppercase tracking-wider text-primary">
            <BarChart3 className="h-3 w-3" /> Group poll
          </p>
          <h3 className="mt-0.5 text-sm font-semibold leading-snug">{poll.question}</h3>
        </div>
      </header>
      <ul className="flex flex-col gap-1.5 px-3 py-3">
        {poll.options.map((opt, i) => {
          const count = tally.counts[i] ?? 0;
          const pct = tally.total ? Math.round((count / tally.total) * 100) : 0;
          const mine = myVote === i;
          return (
            <li key={i}>
              <button
                type="button"
                onClick={() => vote(i)}
                className={`relative w-full overflow-hidden rounded-xl border px-3 py-2.5 text-left text-sm transition active:scale-[0.99] ${
                  mine ? "border-primary bg-primary/10" : "border-border/60 bg-background hover:bg-accent"
                }`}
              >
                <div
                  className={`absolute inset-y-0 left-0 -z-0 transition-all ${mine ? "bg-primary/20" : "bg-secondary"}`}
                  style={{ width: `${pct}%` }}
                />
                <div className="relative z-10 flex items-center gap-2">
                  <span className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full border ${mine ? "border-primary bg-primary text-primary-foreground" : "border-border"}`}>
                    {mine && <Check className="h-3 w-3" />}
                  </span>
                  <span className="min-w-0 flex-1 truncate font-medium">{opt}</span>
                  <span className="tabular-nums text-[11px] font-semibold text-muted-foreground">{pct}%</span>
                </div>
              </button>
            </li>
          );
        })}
      </ul>
      <p className="border-t border-border/60 px-4 py-2 text-[10px] text-muted-foreground">
        {tally.total} vote{tally.total === 1 ? "" : "s"} · tap to change your pick
      </p>
    </article>
  );
}

export function isPollMessage(text: string): string | null {
  const m = text.match(/^\[\[poll:([0-9a-fA-F-]{36})\]\]/);
  return m ? m[1] : null;
}