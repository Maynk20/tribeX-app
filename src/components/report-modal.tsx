import { useState } from "react";
import { createPortal } from "react-dom";
import { Flag, X, ShieldAlert, Check } from "lucide-react";
import { toast } from "sonner";
import { submitReport, type ReportReason } from "@/lib/services";
import { useAuth } from "@/hooks/use-auth";

interface ReportOption {
  value: ReportReason;
  label: string;
}

const REPORT_REASONS: ReportOption[] = [
  { value: "harassment", label: "Harassment or Bullying" },
  { value: "unsafe_behavior", label: "Unsafe or Dangerous Behavior" },
  { value: "fake_profile", label: "Fake Profile or Impersonation" },
  { value: "inappropriate_content", label: "Inappropriate Content" },
  { value: "spam", label: "Spam or Commercial Promotion" },
  { value: "other", label: "Other Concern" },
];

export function ReportModal({
  open,
  onClose,
  targetType,
  targetId,
  targetTitle,
}: {
  open: boolean;
  onClose: () => void;
  targetType: "user" | "activity" | "chat_message";
  targetId: string;
  targetTitle: string;
}) {
  const { user } = useAuth();
  const [selectedReason, setSelectedReason] = useState<ReportReason>("harassment");
  const [notes, setNotes] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);

  if (!open || typeof document === "undefined") return null;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) {
      toast.error("Please sign in to report content.");
      return;
    }
    setIsSubmitting(true);
    try {
      const ok = await submitReport({
        targetType,
        targetId,
        reason: selectedReason,
        notes,
      });
      if (ok) {
        toast.success("Thanks, we've received your report. Our team will review it.");
        setNotes("");
        onClose();
      } else {
        toast.error("Couldn't send report right now. Please try again.");
      }
    } catch {
      toast.error("Couldn't send report right now. Please try again.");
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
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-destructive/15 text-destructive">
              <ShieldAlert className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-base font-bold">Report Content</h3>
              <p className="text-xs text-muted-foreground truncate max-w-[240px]">
                {targetTitle}
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

        <form onSubmit={handleSubmit} className="mt-4 flex flex-col gap-4">
          <div>
            <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Select Reason
            </label>
            <div className="mt-2 space-y-1.5">
              {REPORT_REASONS.map((r) => {
                const isSelected = selectedReason === r.value;
                return (
                  <button
                    key={r.value}
                    type="button"
                    onClick={() => setSelectedReason(r.value)}
                    className={`flex w-full items-center justify-between rounded-xl border px-3.5 py-2.5 text-left text-xs font-medium transition ${
                      isSelected
                        ? "border-primary bg-primary/10 text-foreground"
                        : "border-border/60 bg-background/50 hover:bg-accent text-muted-foreground"
                    }`}
                  >
                    <span>{r.label}</span>
                    {isSelected && (
                      <span className="flex h-4 w-4 items-center justify-center rounded-full bg-primary text-primary-foreground">
                        <Check className="h-2.5 w-2.5" />
                      </span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>

          <div>
            <label className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
              Additional Details (Optional)
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Provide any relevant details to help our safety team investigate..."
              rows={3}
              maxLength={500}
              className="mt-1.5 w-full resize-none rounded-xl border border-border/60 bg-background px-3 py-2 text-xs outline-none focus:border-primary placeholder:text-muted-foreground"
            />
          </div>

          <div className="flex items-center justify-end gap-2 pt-2 border-t border-border/60">
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
              className="flex items-center gap-1.5 rounded-full bg-destructive px-5 py-2 text-xs font-semibold text-destructive-foreground hover:scale-105 active:scale-95 transition disabled:opacity-50"
            >
              <Flag className="h-3 w-3" />
              {isSubmitting ? "Submitting…" : "Submit Report"}
            </button>
          </div>
        </form>
      </div>
    </>,
    document.body
  );
}

