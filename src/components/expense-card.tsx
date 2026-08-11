import { useMemo } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Check, Clock, IndianRupee, Smartphone } from "lucide-react";
import { toast } from "sonner";
import { getExpense, markShareStatus, type ExpenseWithShares } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

export function ExpenseCard({ expenseId, currentUserId }: { expenseId: string; currentUserId: string | undefined }) {
  const qc = useQueryClient();
  const { data: expense, isLoading } = useQuery({
    queryKey: ["expense", expenseId],
    queryFn: () => getExpense(expenseId),
    staleTime: 15_000,
  });

  if (isLoading) {
    return <div className="h-32 w-full animate-pulse rounded-2xl bg-card" />;
  }
  if (!expense) {
    return (
      <div className="rounded-2xl border border-dashed border-border/60 bg-card/40 p-3 text-xs text-muted-foreground">
        This expense was removed.
      </div>
    );
  }

  const isCreator = currentUserId === expense.created_by;
  const total = Number(expense.total_amount) || 0;
  const totalPaid = expense.shares
    .filter((s) => s.status === "paid")
    .reduce((a, s) => a + Number(s.amount), 0);
  const pct = total > 0 ? Math.min(100, Math.round((totalPaid / total) * 100)) : 0;
  // Only show a "per person" figure when every share is within 1 paisa of
  // the smallest — equal splits routinely differ by 1 paisa due to rounding
  // remainders (e.g. ₹100 across 3 members → 33.34 / 33.33 / 33.33).
  const amounts = expense.shares.map((s) => Number(s.amount));
  const isEvenSplit =
    amounts.length > 0 &&
    Math.max(...amounts) - Math.min(...amounts) <= 0.01 + 1e-9;

  async function toggle(shareId: string, next: "paid" | "pending") {
    try {
      await markShareStatus(shareId, next);
      await qc.invalidateQueries({ queryKey: ["expense", expenseId] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't update payment status"));
    }
  }

  return (
    <article className="w-full overflow-hidden rounded-2xl border border-border/60 bg-card shadow-sm">
      <header className="flex items-start justify-between gap-3 border-b border-border/60 bg-secondary/40 px-4 py-3">
        <div className="min-w-0">
          <p className="text-[10px] font-semibold uppercase tracking-wider text-primary">Split Expense</p>
          <h3 className="mt-0.5 truncate text-sm font-semibold">{expense.description}</h3>
        </div>
        <div className="text-right">
          <p className="flex items-center justify-end text-base font-bold tabular-nums">
            <IndianRupee className="h-3.5 w-3.5" />{Number(expense.total_amount).toFixed(2)}
          </p>
          <p className="text-[10px] text-muted-foreground">
            {isEvenSplit
              ? `₹${amounts[0].toFixed(2)} / person`
              : expense.shares.length > 0
                ? `${expense.shares.length} members · custom split`
                : null}
          </p>
        </div>
      </header>

      <div className="px-4 pt-3">
        <div className="h-1.5 w-full overflow-hidden rounded-full bg-secondary">
          <div className="h-full rounded-full bg-emerald-500 transition-all" style={{ width: `${pct}%` }} />
        </div>
        <p className="mt-1.5 text-[11px] text-muted-foreground">₹{totalPaid.toFixed(2)} of ₹{Number(expense.total_amount).toFixed(2)} collected · {pct}%</p>
      </div>

      <ul className="flex flex-col divide-y divide-border/60 px-2 py-2">
        {expense.shares.map((s) => {
          const name = s.user?.full_name || s.user?.username || "Member";
          const isPaid = s.status === "paid";
          const isMine = s.user_id === currentUserId;
          const canToggle = isCreator || isMine;
          const upi = expense.upi_id;
          const upiHref = upi
            ? `upi://pay?pa=${encodeURIComponent(upi)}&pn=${encodeURIComponent(name)}&am=${Number(s.amount).toFixed(2)}&cu=INR&tn=${encodeURIComponent("tribeX Plan")}`
            : null;
          return (
            <li key={s.id} className="flex items-center gap-3 px-2 py-2">
              <div className="flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-full bg-secondary text-xs font-semibold">
                {s.user?.avatar_url
                  ? <img src={s.user.avatar_url} alt="" className="h-full w-full object-cover" />
                  : name.slice(0, 1).toUpperCase()}
              </div>
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{name}{isMine && <span className="ml-1 text-[10px] text-muted-foreground">(you)</span>}</p>
                <p className="text-[11px] text-muted-foreground tabular-nums">₹{Number(s.amount).toFixed(2)}</p>
              </div>
              {isPaid ? (
                <span className="inline-flex items-center gap-1 rounded-full bg-emerald-500/15 px-2 py-0.5 text-[10px] font-semibold text-emerald-600 dark:text-emerald-400">
                  <Check className="h-3 w-3" /> Paid
                </span>
              ) : (
                <span className="inline-flex items-center gap-1 rounded-full bg-amber-500/15 px-2 py-0.5 text-[10px] font-semibold text-amber-600 dark:text-amber-400">
                  <Clock className="h-3 w-3" /> Pending
                </span>
              )}
              {!isPaid && isMine && upiHref && (
                <a
                  href={upiHref}
                  className="ml-1 inline-flex items-center gap-1 rounded-full bg-primary px-2.5 py-1 text-[10px] font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95"
                >
                  <Smartphone className="h-3 w-3" /> Pay via UPI
                </a>
              )}
              {canToggle && (
                <button
                  onClick={() => toggle(s.id, isPaid ? "pending" : "paid")}
                  className="ml-1 rounded-full border border-border/60 px-2 py-1 text-[10px] font-medium transition hover:bg-accent"
                >
                  {isPaid ? "Undo" : "Mark paid"}
                </button>
              )}
            </li>
          );
        })}
      </ul>

      {!expense.upi_id && (
        <p className="border-t border-border/60 px-4 py-2 text-[10px] text-muted-foreground">
          Tip: add a UPI ID when creating an expense to enable one-tap payments.
        </p>
      )}
    </article>
  );
}

export function isExpenseMessage(text: string): string | null {
  const m = text.match(/^\[\[expense:([0-9a-fA-F-]{36})\]\]/);
  return m ? m[1] : null;
}

export type { ExpenseWithShares };