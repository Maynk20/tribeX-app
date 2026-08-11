import { useEffect, useState } from "react";
import { createPortal } from "react-dom";
import { ShieldAlert } from "lucide-react";

export function SafetyDisclaimerModal({
  open,
  onCancel,
  onAgree,
}: {
  open: boolean;
  onCancel: () => void;
  onAgree: () => void;
}) {
  const [secondsLeft, setSecondsLeft] = useState(6);

  useEffect(() => {
    if (!open) return;
    setSecondsLeft(6);
    const timer = setInterval(() => {
      setSecondsLeft((s) => (s <= 1 ? 0 : s - 1));
    }, 1000);
    return () => clearInterval(timer);
  }, [open]);

  if (!open) return null;
  const ready = secondsLeft === 0;

  if (typeof document === "undefined") return null;
  return createPortal(
    <>
      <div className="fixed inset-0 z-[99998] bg-black/80 backdrop-blur-md" onClick={onCancel} />
      <div
        role="alertdialog"
        aria-modal="true"
        aria-labelledby="safety-title"
        className="fixed top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 z-[99999] w-[92vw] max-w-sm rounded-2xl p-6 bg-card border shadow-2xl max-h-[85vh] overflow-y-auto"
      >
        <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-2xl bg-destructive/15 text-destructive">
          <ShieldAlert className="h-6 w-6" />
        </div>
        <h3 id="safety-title" className="text-lg font-bold">Safety Warning</h3>
        <p className="mt-2 text-sm leading-relaxed text-muted-foreground">
          You are joining this activity at your own personal risk. By proceeding, you confirm that you are
          <span className="font-semibold text-foreground"> 18+ years old</span> and assume full personal responsibility for your safety and conduct.
        </p>

        <div className="mt-4 rounded-2xl border border-border/60 bg-secondary/60 p-3 text-xs text-muted-foreground">
          Please read the warning carefully. The button will unlock in a few seconds.
        </div>

        <div className="mt-5 flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
          <button
            type="button"
            onClick={onCancel}
            className="rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent active:scale-95"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={onAgree}
            disabled={!ready}
            className="rounded-full bg-destructive px-5 py-2 text-sm font-semibold text-destructive-foreground transition hover:scale-[1.02] active:scale-95 disabled:cursor-not-allowed disabled:opacity-60 disabled:hover:scale-100"
          >
            {ready ? "I Understand & Proceed" : `Proceeding in ${secondsLeft}s…`}
          </button>
        </div>
      </div>
    </>,
    document.body,
  );
}