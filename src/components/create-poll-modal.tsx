import { useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { Plus, X, BarChart3 } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { createPoll } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

export function CreatePollModal({
  activityId,
  open,
  onOpenChange,
}: {
  activityId: string;
  open: boolean;
  onOpenChange: (v: boolean) => void;
}) {
  const qc = useQueryClient();
  const [question, setQuestion] = useState("");
  const [options, setOptions] = useState<string[]>(["", ""]);
  const [saving, setSaving] = useState(false);

  function reset() {
    setQuestion("");
    setOptions(["", ""]);
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const q = question.trim();
    const opts = options.map((o) => o.trim()).filter(Boolean);
    if (!q) return toast.error("Enter a question");
    if (opts.length < 2) return toast.error("Add at least 2 options");
    setSaving(true);
    try {
      await createPoll({ activityId, question: q, options: opts });
      toast.success("Poll posted to chat");
      await qc.invalidateQueries({ queryKey: ["messages", activityId] });
      reset();
      onOpenChange(false);
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't create poll"));
    } finally {
      setSaving(false);
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] w-[calc(100vw-2rem)] max-w-md overflow-y-auto rounded-3xl p-0 sm:w-full">
        <DialogHeader className="border-b border-border/60 px-5 pb-3 pt-5">
          <DialogTitle className="flex items-center gap-2 text-base">
            <BarChart3 className="h-4 w-4 text-primary" /> Create a group poll
          </DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} className="flex flex-col gap-4 px-5 py-4">
          <label className="flex flex-col gap-1.5">
            <span className="text-xs font-medium text-muted-foreground">Question</span>
            <input
              value={question}
              onChange={(e) => setQuestion(e.target.value)}
              maxLength={140}
              placeholder="Preferred match time?"
              className="rounded-2xl border border-border/60 bg-background px-4 py-3 text-sm outline-none transition focus:border-primary"
            />
          </label>

          <div className="flex flex-col gap-2">
            <span className="text-xs font-medium text-muted-foreground">Options (2–6)</span>
            {options.map((opt, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  value={opt}
                  onChange={(e) =>
                    setOptions((prev) => prev.map((v, idx) => (idx === i ? e.target.value : v)))
                  }
                  maxLength={80}
                  placeholder={`Option ${i + 1}`}
                  className="flex-1 rounded-2xl border border-border/60 bg-background px-4 py-2.5 text-sm outline-none transition focus:border-primary"
                />
                {options.length > 2 && (
                  <button
                    type="button"
                    onClick={() => setOptions((prev) => prev.filter((_, idx) => idx !== i))}
                    className="rounded-full border border-border/60 p-1.5 text-muted-foreground transition hover:bg-accent"
                    aria-label="Remove option"
                  >
                    <X className="h-3.5 w-3.5" />
                  </button>
                )}
              </div>
            ))}
            {options.length < 6 && (
              <button
                type="button"
                onClick={() => setOptions((prev) => [...prev, ""])}
                className="mt-1 inline-flex items-center gap-1 self-start rounded-full border border-dashed border-border/60 px-3 py-1.5 text-xs font-semibold text-muted-foreground transition hover:bg-accent"
              >
                <Plus className="h-3 w-3" /> Add option
              </button>
            )}
          </div>

          <div className="flex items-center justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => onOpenChange(false)}
              className="rounded-full px-4 py-2 text-sm font-medium text-muted-foreground transition hover:bg-accent"
            >
              Cancel
            </button>
            <button
              type="submit"
              disabled={saving}
              className="rounded-full bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-60"
            >
              {saving ? "Posting…" : "Post poll"}
            </button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}