import { useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { BarChart3, Check, MoreVertical, Edit2, Lock, Unlock, Trash2, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { getPoll, castPollVote, retractPollVote, togglePollClosed, deletePoll } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";
import { EditPollModal } from "@/components/edit-poll-modal";

export function PollCard({ pollId, currentUserId }: { pollId: string; currentUserId: string | undefined }) {
  const qc = useQueryClient();
  const [menuOpen, setMenuOpen] = useState(false);
  const [editOpen, setEditOpen] = useState(false);
  const [votingIndex, setVotingIndex] = useState<number | null>(null);

  const { data: poll, isLoading } = useQuery({
    queryKey: ["poll", pollId],
    queryFn: () => getPoll(pollId),
    refetchInterval: 5000,
    staleTime: 3_000,
  });

  const tally = useMemo(() => {
    const counts = new Array((poll?.options.length ?? 0)).fill(0) as number[];
    for (const v of poll?.votes ?? []) {
      if (v.option_index >= 0 && v.option_index < counts.length) {
        counts[v.option_index]++;
      }
    }
    const total = counts.reduce((a, b) => a + b, 0);
    return { counts, total };
  }, [poll]);

  const myVote = useMemo(
    () => (currentUserId ? poll?.votes.find((v) => v.user_id === currentUserId)?.option_index ?? null : null),
    [poll, currentUserId],
  );

  const isCreator = Boolean(currentUserId && poll?.created_by === currentUserId);
  const isClosed = Boolean(poll?.closed_at);

  async function handleOptionClick(idx: number) {
    if (isClosed) {
      toast.info("This poll is closed for voting");
      return;
    }
    if (!currentUserId) {
      toast.error("Please sign in to vote");
      return;
    }

    setVotingIndex(idx);
    try {
      if (myVote === idx) {
        // Retract vote when clicking currently selected option (matching Android retractVote)
        await retractPollVote(pollId);
        toast.info("Vote withdrawn");
      } else {
        // Vote or switch option
        await castPollVote(pollId, idx);
      }
      await qc.invalidateQueries({ queryKey: ["poll", pollId] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't update vote"));
    } finally {
      setVotingIndex(null);
    }
  }

  async function handleToggleClose() {
    if (!poll) return;
    setMenuOpen(false);
    try {
      await togglePollClosed(pollId, !isClosed);
      toast.success(isClosed ? "Poll reopened for voting" : "Poll closed");
      await qc.invalidateQueries({ queryKey: ["poll", pollId] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't update poll status"));
    }
  }

  async function handleDelete() {
    if (!poll) return;
    setMenuOpen(false);
    if (!confirm("Delete this poll? This cannot be undone.")) return;
    try {
      await deletePoll(pollId);
      toast.success("Poll deleted");
      await qc.invalidateQueries({ queryKey: ["poll", pollId] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't delete poll"));
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
    <>
      <article className="w-full overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm">
        <header className="flex items-start justify-between gap-3 border-b border-border/60 bg-secondary/40 px-4 py-3">
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-2">
              <p className="flex items-center gap-1 text-[10px] font-semibold uppercase tracking-wider text-primary">
                <BarChart3 className="h-3 w-3" /> Group poll
              </p>
              {isClosed && (
                <span className="rounded-md bg-amber-500/15 px-1.5 py-0.5 text-[9px] font-bold text-amber-600 dark:text-amber-400">
                  Closed
                </span>
              )}
            </div>
            <h3 className="mt-0.5 text-sm font-semibold leading-snug">{poll.question}</h3>
          </div>

          {isCreator && (
            <div className="relative">
              <button
                type="button"
                onClick={() => setMenuOpen(!menuOpen)}
                className="rounded-full p-1 text-muted-foreground hover:bg-accent transition"
                title="Poll options"
                aria-label="Poll options"
              >
                <MoreVertical className="h-4 w-4" />
              </button>

              {menuOpen && (
                <>
                  <div className="fixed inset-0 z-20" onClick={() => setMenuOpen(false)} />
                  <div className="absolute right-0 top-full z-30 mt-1 w-36 rounded-xl border border-border/60 bg-popover p-1 shadow-lg text-xs">
                    <button
                      type="button"
                      onClick={() => {
                        setMenuOpen(false);
                        setEditOpen(true);
                      }}
                      className="flex w-full items-center gap-2 rounded-lg px-2.5 py-1.5 font-medium hover:bg-accent transition"
                    >
                      <Edit2 className="h-3.5 w-3.5" />
                      Edit / Manage
                    </button>
                    <button
                      type="button"
                      onClick={handleToggleClose}
                      className="flex w-full items-center gap-2 rounded-lg px-2.5 py-1.5 font-medium hover:bg-accent transition"
                    >
                      {isClosed ? (
                        <>
                          <Unlock className="h-3.5 w-3.5 text-emerald-500" />
                          Reopen voting
                        </>
                      ) : (
                        <>
                          <Lock className="h-3.5 w-3.5 text-amber-500" />
                          Close voting
                        </>
                      )}
                    </button>
                    <button
                      type="button"
                      onClick={handleDelete}
                      className="flex w-full items-center gap-2 rounded-lg px-2.5 py-1.5 font-medium text-destructive hover:bg-destructive/10 transition"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                      Delete poll
                    </button>
                  </div>
                </>
              )}
            </div>
          )}
        </header>

        <ul className="flex flex-col gap-1.5 px-3 py-3">
          {poll.options.map((opt, i) => {
            const count = tally.counts[i] ?? 0;
            const pct = tally.total ? Math.round((count / tally.total) * 100) : 0;
            const mine = myVote === i;
            const isVotingThis = votingIndex === i;

            return (
              <li key={i}>
                <button
                  type="button"
                  disabled={votingIndex !== null}
                  onClick={() => handleOptionClick(i)}
                  className={`relative w-full overflow-hidden rounded-xl border px-3 py-2.5 text-left text-sm transition active:scale-[0.99] disabled:opacity-60 ${
                    mine ? "border-primary bg-primary/10" : "border-border/60 bg-background hover:bg-accent"
                  }`}
                >
                  <div
                    className={`absolute inset-y-0 left-0 -z-0 transition-all duration-300 ${mine ? "bg-primary/20" : "bg-secondary"}`}
                    style={{ width: `${pct}%` }}
                  />
                  <div className="relative z-10 flex items-center gap-2">
                    <span
                      className={`flex h-5 w-5 shrink-0 items-center justify-center rounded-full border transition ${
                        mine ? "border-primary bg-primary text-primary-foreground" : "border-border"
                      }`}
                    >
                      {isVotingThis ? (
                        <Loader2 className="h-3 w-3 animate-spin" />
                      ) : mine ? (
                        <Check className="h-3 w-3" />
                      ) : null}
                    </span>
                    <span className="min-w-0 flex-1 truncate font-medium">{opt}</span>
                    <span className="tabular-nums text-[11px] font-semibold text-muted-foreground">{pct}%</span>
                  </div>
                </button>
              </li>
            );
          })}
        </ul>

        <p className="border-t border-border/60 px-4 py-2 text-[10px] text-muted-foreground flex items-center justify-between">
          <span>
            {tally.total} vote{tally.total === 1 ? "" : "s"}
          </span>
          <span>
            {isClosed ? "Voting closed" : myVote !== null ? "Tap your choice to withdraw vote" : "Tap an option to vote"}
          </span>
        </p>
      </article>

      {editOpen && poll && (
        <EditPollModal
          open={editOpen}
          poll={poll}
          onClose={() => setEditOpen(false)}
          onUpdated={() => qc.invalidateQueries({ queryKey: ["poll", pollId] })}
        />
      )}
    </>
  );
}

export function isPollMessage(text: string): string | null {
  const m = text.match(/^\[\[poll:([0-9a-fA-F-]{36})\]\]/);
  return m ? m[1] : null;
}
