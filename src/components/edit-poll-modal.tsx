import { useState } from "react";
import { createPortal } from "react-dom";
import { X, Plus, Trash2, BarChart3, AlertCircle } from "lucide-react";
import { toast } from "sonner";
import { updatePoll, togglePollClosed, deletePoll, type PollWithVotes } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

export function EditPollModal({
  open,
  onClose,
  poll,
  onUpdated,
}: {
  open: boolean;
  onClose: () => void;
  poll: PollWithVotes;
  onUpdated: () => void;
}) {
  const [question, setQuestion] = useState(poll.question);
  const [options, setOptions] = useState<string[]>([...poll.options]);
  const [isClosed, setIsClosed] = useState(Boolean(poll.closed_at));
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!open || typeof document === "undefined") return null;

  const totalVotes = poll.votes?.length ?? 0;
  const hasVotes = totalVotes > 0;

  function handleOptionChange(index: number, val: string) {
    if (hasVotes) return;
    const next = [...options];
    next[index] = val;
    setOptions(next);
  }

  function handleAddOption() {
    if (hasVotes || options.length >= 6) return;
    setOptions([...options, ""]);
  }

  function handleRemoveOption(index: number) {
    if (hasVotes || options.length <= 2) return;
    setOptions(options.filter((_, i) => i !== index));
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    const q = question.trim();
    if (q.length < 2) {
      toast.error("Question must be at least 2 characters");
      return;
    }

    const cleanedOpts = options.map((o) => o.trim()).filter(Boolean);
    if (cleanedOpts.length < 2) {
      toast.error("Poll requires at least 2 options");
      return;
    }

    setIsSubmitting(true);
    try {
      await updatePoll(poll.id, q, hasVotes ? undefined : cleanedOpts);
      if (isClosed !== Boolean(poll.closed_at)) {
        await togglePollClosed(poll.id, isClosed);
      }
      toast.success("Poll updated");
      onUpdated();
      onClose();
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't update poll"));
    } finally {
      setIsSubmitting(false);
    }
  }

  async function handleDelete() {
    if (!confirm("Are you sure you want to delete this poll? All votes will be removed.")) return;
    setIsSubmitting(true);
    try {
      await deletePoll(poll.id);
      toast.success("Poll deleted");
      onUpdated();
      onClose();
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't delete poll"));
    } finally {
      setIsSubmitting(false);
    }
  }

  return createPortal(
    <>
      <div
        className="fixed inset-0 z-[99998] bg-black/80 backdrop-blur-md transition-opacity"
        onClick={() => !isSubmitting && onClose()}
      />
      <div
        onClick={(e) => e.stopPropagation()}
        className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[99999] w-[92vw] max-w-md rounded-3xl p-6 bg-card border border-border/80 shadow-2xl max-h-[90vh] overflow-y-auto animate-in fade-in zoom-in-95 duration-200"
      >
        <div className="flex items-center justify-between border-b border-border/60 pb-3">
          <div className="flex items-center gap-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-primary/15 text-primary">
              <BarChart3 className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-base font-bold">Manage Poll</h3>
              <p className="text-xs text-muted-foreground">
                {hasVotes ? `${totalVotes} votes cast · options locked` : "Edit question & options"}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            disabled={isSubmitting}
            className="rounded-full p-1.5 text-muted-foreground hover:bg-accent transition"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <form onSubmit={handleSave} className="mt-4 flex flex-col gap-4">
          <div>
            <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Poll Question
            </label>
            <input
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              placeholder="What should we do?"
              maxLength={120}
              className="mt-1.5 w-full rounded-xl border border-border/60 bg-background px-3 py-2 text-xs font-medium outline-none focus:border-primary"
            />
          </div>

          <div>
            <div className="flex items-center justify-between">
              <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                Options ({options.length}/6)
              </label>
              {!hasVotes && options.length < 6 && (
                <button
                  type="button"
                  onClick={handleAddOption}
                  className="flex items-center gap-1 text-[11px] font-semibold text-primary hover:underline"
                >
                  <Plus className="h-3 w-3" /> Add option
                </button>
              )}
            </div>

            {hasVotes && (
              <div className="mt-1.5 flex items-center gap-1.5 rounded-lg bg-secondary/60 px-2.5 py-1.5 text-[11px] text-muted-foreground">
                <AlertCircle className="h-3.5 w-3.5 shrink-0 text-amber-500" />
                <span>Options cannot be modified after members have voted.</span>
              </div>
            )}

            <div className="mt-2 space-y-2">
              {options.map((opt, i) => (
                <div key={i} className="flex items-center gap-2">
                  <input
                    value={opt}
                    disabled={hasVotes}
                    onChange={(e) => handleOptionChange(i, e.target.value)}
                    placeholder={`Option ${i + 1}`}
                    maxLength={60}
                    className="flex-1 rounded-xl border border-border/60 bg-background px-3 py-2 text-xs outline-none focus:border-primary disabled:opacity-60"
                  />
                  {!hasVotes && options.length > 2 && (
                    <button
                      type="button"
                      onClick={() => handleRemoveOption(i)}
                      className="rounded-lg p-2 text-muted-foreground hover:bg-destructive/10 hover:text-destructive transition"
                      aria-label="Remove option"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </button>
                  )}
                </div>
              ))}
            </div>
          </div>

          <label className="flex items-center gap-2.5 rounded-xl border border-border/60 bg-background/50 p-3 cursor-pointer">
            <input
              type="checkbox"
              checked={isClosed}
              onChange={(e) => setIsClosed(e.target.checked)}
              className="h-4 w-4 rounded border-border text-primary focus:ring-primary"
            />
            <div className="text-xs">
              <span className="font-semibold text-foreground">Close poll for voting</span>
              <p className="text-[11px] text-muted-foreground">
                Members will see the final results, but no new votes or changes will be accepted.
              </p>
            </div>
          </label>

          <div className="flex items-center justify-between pt-3 border-t border-border/60">
            <button
              type="button"
              onClick={handleDelete}
              disabled={isSubmitting}
              className="flex items-center gap-1.5 rounded-full border border-destructive/40 bg-destructive/10 px-3.5 py-2 text-xs font-semibold text-destructive hover:bg-destructive/20 transition disabled:opacity-50"
            >
              <Trash2 className="h-3.5 w-3.5" />
              Delete Poll
            </button>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={onClose}
                disabled={isSubmitting}
                className="rounded-full border border-border/60 px-4 py-2 text-xs font-semibold hover:bg-accent transition disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={isSubmitting}
                className="rounded-full bg-primary px-5 py-2 text-xs font-semibold text-primary-foreground hover:scale-105 active:scale-95 transition disabled:opacity-50"
              >
                {isSubmitting ? "Saving…" : "Save Changes"}
              </button>
            </div>
          </div>
        </form>
      </div>
    </>,
    document.body
  );
}

