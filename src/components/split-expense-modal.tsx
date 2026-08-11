import { useMemo, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { IndianRupee, Users, X } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { createExpense, listPlanMembers } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

export function SplitExpenseModal({
  activityId,
  open,
  onOpenChange,
  currentUserId,
}: {
  activityId: string;
  open: boolean;
  onOpenChange: (v: boolean) => void;
  currentUserId: string | undefined;
}) {
  const qc = useQueryClient();
  const { data: members = [], isLoading } = useQuery({
    queryKey: ["plan-members", activityId],
    queryFn: () => listPlanMembers(activityId),
    enabled: open,
  });

  const [description, setDescription] = useState("");
  const [amount, setAmount] = useState("");
  const [upi, setUpi] = useState("");
  const [splitType, setSplitType] = useState<"equal" | "specific">("equal");
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);

  const effectiveIds = useMemo(() => {
    if (splitType === "equal") return members.map((m) => m.id);
    return members.filter((m) => selected.has(m.id)).map((m) => m.id);
  }, [splitType, members, selected]);

  const perHead = useMemo(() => {
    const n = effectiveIds.length;
    const t = Number(amount);
    if (!n || !t || Number.isNaN(t)) return 0;
    return Math.round((t / n) * 100) / 100;
  }, [amount, effectiveIds.length]);

  function reset() {
    setDescription(""); setAmount(""); setUpi("");
    setSplitType("equal"); setSelected(new Set());
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    const total = Number(amount);
    if (!description.trim()) return toast.error("Add a description");
    if (!(total > 0)) return toast.error("Enter a valid amount");
    if (effectiveIds.length === 0) return toast.error("Select at least one member");
    if (upi.trim() && !/^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$/.test(upi.trim())) {
      return toast.error("UPI ID looks invalid (e.g. name@upi)");
    }
    setSaving(true);
    try {
      // Both UI modes ("equal" / "specific") divide the total evenly — the
      // only difference is the member subset (see effectiveIds above), so we
      // always persist as "equal" at the DB level.
      await createExpense({
        activityId,
        description: description.trim(),
        totalAmount: total,
        upiId: upi.trim() || null,
        memberIds: effectiveIds,
        splitType: "equal",
      });
      toast.success("Expense posted to chat");
      await qc.invalidateQueries({ queryKey: ["messages", activityId] });
      reset();
      onOpenChange(false);
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't create expense"));
    } finally {
      setSaving(false);
    }
  }

  function toggle(id: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[90dvh] w-[calc(100vw-2rem)] max-w-md overflow-y-auto rounded-3xl p-0 sm:w-full">
        <DialogHeader className="border-b border-border/60 px-5 pb-3 pt-5">
          <DialogTitle className="text-base">Split an expense</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} className="flex flex-col gap-4 px-5 py-4">
          <label className="flex flex-col gap-1.5">
            <span className="text-xs font-medium text-muted-foreground">Description</span>
            <input
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              maxLength={120}
              placeholder="Turf rent, Food & drinks…"
              className="rounded-2xl border border-border/60 bg-background px-4 py-3 text-sm outline-none transition focus:border-primary"
            />
          </label>

          <div className="grid grid-cols-2 gap-3">
            <label className="flex flex-col gap-1.5">
              <span className="text-xs font-medium text-muted-foreground">Total amount</span>
              <div className="flex items-center gap-1 rounded-2xl border border-border/60 bg-background px-3 py-2.5 focus-within:border-primary">
                <IndianRupee className="h-4 w-4 text-muted-foreground" />
                <input
                  type="number" step="0.01" min="0" inputMode="decimal"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  placeholder="0.00"
                  className="w-full bg-transparent text-sm outline-none tabular-nums"
                />
              </div>
            </label>
            <label className="flex flex-col gap-1.5">
              <span className="text-xs font-medium text-muted-foreground">UPI ID (optional)</span>
              <input
                value={upi}
                onChange={(e) => setUpi(e.target.value)}
                placeholder="name@upi"
                className="rounded-2xl border border-border/60 bg-background px-3 py-2.5 text-sm outline-none transition focus:border-primary"
              />
            </label>
          </div>

          <div className="flex flex-col gap-2">
            <span className="text-xs font-medium text-muted-foreground">Split</span>
            <div className="grid grid-cols-2 gap-2 rounded-2xl bg-secondary p-1">
              {(["equal", "specific"] as const).map((t) => (
                <button
                  key={t}
                  type="button"
                  onClick={() => setSplitType(t)}
                  className={`rounded-xl px-3 py-2 text-xs font-semibold transition ${splitType === t ? "bg-background shadow-sm" : "text-muted-foreground"}`}
                >
                  {t === "equal" ? "Split equally" : "Select members"}
                </button>
              ))}
            </div>
          </div>

          <div className="rounded-2xl border border-border/60">
            <div className="flex items-center justify-between border-b border-border/60 px-3 py-2">
              <span className="flex items-center gap-1.5 text-xs font-medium text-muted-foreground">
                <Users className="h-3.5 w-3.5" /> Members ({effectiveIds.length})
              </span>
              {perHead > 0 && (
                <span className="text-[11px] font-semibold tabular-nums">₹{perHead.toFixed(2)} / person</span>
              )}
            </div>
            <ul className="max-h-48 overflow-y-auto">
              {isLoading && <li className="px-3 py-4 text-xs text-muted-foreground">Loading members…</li>}
              {!isLoading && members.length === 0 && (
                <li className="px-3 py-4 text-xs text-muted-foreground">No confirmed members yet.</li>
              )}
              {members.map((m) => {
                const included = splitType === "equal" ? true : selected.has(m.id);
                const name = m.full_name || m.username || "Member";
                return (
                  <li key={m.id}>
                    <button
                      type="button"
                      disabled={splitType === "equal"}
                      onClick={() => toggle(m.id)}
                      className={`flex w-full items-center gap-3 px-3 py-2 text-left text-sm transition hover:bg-accent disabled:cursor-default disabled:hover:bg-transparent ${included ? "" : "opacity-60"}`}
                    >
                      <span className="flex h-7 w-7 items-center justify-center overflow-hidden rounded-full bg-secondary text-[11px] font-semibold">
                        {m.avatar_url ? <img src={m.avatar_url} alt="" className="h-full w-full object-cover" /> : name.slice(0, 1).toUpperCase()}
                      </span>
                      <span className="min-w-0 flex-1 truncate">{name}{m.id === currentUserId && <span className="ml-1 text-[10px] text-muted-foreground">(you)</span>}</span>
                      <span className={`h-4 w-4 rounded border ${included ? "border-primary bg-primary" : "border-border"}`}>
                        {included && <svg viewBox="0 0 24 24" className="h-full w-full text-primary-foreground"><path fill="currentColor" d="M9 16.2 4.8 12l-1.4 1.4L9 19 21 7l-1.4-1.4z"/></svg>}
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          </div>

          <div className="flex items-center justify-end gap-2 pt-1">
            <button
              type="button"
              onClick={() => onOpenChange(false)}
              className="rounded-full px-4 py-2 text-sm font-medium text-muted-foreground transition hover:bg-accent"
            >Cancel</button>
            <button
              type="submit"
              disabled={saving}
              className="rounded-full bg-primary px-4 py-2 text-sm font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-60"
            >{saving ? "Posting…" : "Post to chat"}</button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
}