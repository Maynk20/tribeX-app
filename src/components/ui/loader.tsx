import { Loader2 } from "lucide-react";
import { useIsFetching, useIsMutating } from "@tanstack/react-query";
import { useRouterState } from "@tanstack/react-router";
import { cn } from "@/lib/utils";

/**
 * Unified loading primitives for tribeX. All async surfaces should render one
 * of these so users see the same animation, timing, and colour treatment.
 */

export function Spinner({
  className,
  size = 16,
}: {
  className?: string;
  size?: number;
}) {
  return (
    <Loader2
      aria-hidden="true"
      style={{ width: size, height: size }}
      className={cn("animate-spin text-primary", className)}
    />
  );
}

export function InlineSpinner({ label = "Loading…" }: { label?: string }) {
  return (
    <span
      role="status"
      aria-live="polite"
      className="inline-flex items-center gap-2 text-xs font-medium text-muted-foreground"
    >
      <Spinner size={14} />
      {label}
    </span>
  );
}

/** Full-viewport loader used for route transitions and Suspense fallbacks. */
export function PageLoader({ label = "Loading" }: { label?: string }) {
  return (
    <div
      role="status"
      aria-live="polite"
      className="flex min-h-[60vh] w-full flex-col items-center justify-center gap-3 px-6 text-center animate-fade-in"
    >
      <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/10">
        <Spinner size={22} />
      </span>
      <p className="text-sm font-medium text-muted-foreground">{label}…</p>
    </div>
  );
}

/** Skeleton line/block. Composes into cards, rows, avatars. */
export function SkeletonBlock({ className }: { className?: string }) {
  return (
    <div
      aria-hidden="true"
      className={cn("animate-pulse rounded-2xl bg-card", className)}
    />
  );
}

/** Consistent card skeleton for feed / plan / chat previews. */
export function CardSkeleton({ className }: { className?: string }) {
  return (
    <div
      aria-hidden="true"
      className={cn(
        "animate-pulse rounded-3xl border border-border/60 bg-card p-4",
        className,
      )}
    >
      <div className="flex items-center gap-3">
        <div className="h-11 w-11 rounded-full bg-primary/10" />
        <div className="flex-1 space-y-2">
          <div className="h-3 w-1/2 rounded bg-primary/10" />
          <div className="h-3 w-1/3 rounded bg-primary/10" />
        </div>
      </div>
      <div className="mt-4 space-y-2">
        <div className="h-3 w-full rounded bg-primary/10" />
        <div className="h-3 w-4/5 rounded bg-primary/10" />
      </div>
    </div>
  );
}

export function ListSkeleton({
  count = 3,
  variant = "card",
  className,
}: {
  count?: number;
  variant?: "card" | "row";
  className?: string;
}) {
  return (
    <div className={cn("flex flex-col gap-3", className)} role="status" aria-live="polite">
      <span className="sr-only">Loading…</span>
      {Array.from({ length: count }).map((_, i) =>
        variant === "card" ? (
          <CardSkeleton key={i} />
        ) : (
          <SkeletonBlock key={i} className="h-16" />
        ),
      )}
    </div>
  );
}

/**
 * Thin animated progress bar shown at the top of the app whenever a route is
 * transitioning, a query is fetching, or a mutation is in-flight. Keeps the UI
 * responsive during background work without blocking interaction.
 */
export function GlobalProgressBar() {
  const isRouting = useRouterState({
    select: (s) => s.isLoading || s.isTransitioning,
  });
  const fetching = useIsFetching();
  const mutating = useIsMutating();
  const active = isRouting || fetching > 0 || mutating > 0;

  return (
    <div
      aria-hidden="true"
      className={cn(
        "pointer-events-none fixed inset-x-0 top-0 z-[100000] h-0.5 overflow-hidden transition-opacity duration-200",
        active ? "opacity-100" : "opacity-0",
      )}
    >
      <div className="h-full w-1/3 animate-[loader-slide_1.2s_ease-in-out_infinite] bg-gradient-to-r from-transparent via-primary to-transparent" />
    </div>
  );
}