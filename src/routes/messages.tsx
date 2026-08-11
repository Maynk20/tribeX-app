import { createFileRoute, Link, useNavigate } from "@tanstack/react-router";
import { ListSkeleton } from "../components/ui/loader";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { Search, MessageCircle } from "lucide-react";
import { listUserChats, emojiFor } from "@/lib/services";
import { useAuth } from "@/hooks/use-auth";

export const Route = createFileRoute("/messages")({
  head: () => ({
    meta: [
      { title: "Messages · tribeX" },
      { name: "description", content: "Chat with your squads and plan hosts." },
    ],
  }),
  component: Messages,
});

function Messages() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const [q, setQ] = useState("");
  const { data: chats = [], isLoading, error, refetch } = useQuery({
    queryKey: ["chats", user?.id],
    queryFn: () => listUserChats(user!.id),
    enabled: !!user,
    staleTime: 0,
    refetchOnMount: "always",
    refetchOnWindowFocus: true,
  });

  if (!loading && !user) {
    return (
      <div className="page-in flex flex-col items-start gap-4 px-5 pt-8">
        <h1 className="text-2xl font-bold tracking-tight">Your squad chats</h1>
        <p className="text-sm text-muted-foreground">Sign in to see messages from plans you host or joined.</p>
        <button onClick={() => navigate({ to: "/auth" })} className="rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground">
          Sign in
        </button>
      </div>
    );
  }

  return (
    <div className="page-in flex flex-col gap-5 px-5 pt-6">
      <header>
        <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Inbox</p>
        <h1 className="mt-1 text-3xl font-bold tracking-tight">Messages</h1>
      </header>

      <label className="flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3">
        <Search className="h-4 w-4 text-muted-foreground" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search chats"
          className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
        />
      </label>

      {isLoading ? (
        <ListSkeleton count={3} variant="row" />
      ) : error ? (
        <div className="rounded-3xl border border-destructive/30 bg-destructive/10 p-5 text-sm text-destructive">
          <p className="font-semibold">Couldn't load chats right now.</p>
          <button
            type="button"
            onClick={() => refetch()}
            className="mt-3 rounded-full bg-destructive px-4 py-2 text-xs font-bold text-destructive-foreground"
          >
            Retry
          </button>
        </div>
      ) : chats.length === 0 ? (
        <div className="rounded-3xl border border-dashed border-border bg-card/40 p-6 text-center text-sm text-muted-foreground">
          <MessageCircle className="mx-auto mb-2 h-6 w-6 text-muted-foreground/60" />
          No chats yet. Join or host a plan to start a squad chat.
        </div>
      ) : (
        <ul className="flex flex-col">
          {chats
            .filter((c) => {
              const t = q.trim().toLowerCase();
              if (!t) return true;
              return c.title.toLowerCase().includes(t) || c.location.toLowerCase().includes(t) || c.category.toLowerCase().includes(t);
            })
            .map((c) => (
              <li key={c.id}>
                <Link
                  to="/chat/$activityId"
                  params={{ activityId: c.id }}
                  className="flex items-center gap-3 border-b border-border/50 py-3 transition hover:bg-accent/30 active:scale-[0.99] last:border-b-0"
                >
                  <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-secondary text-xl">
                    {emojiFor(c.category)}
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex items-center justify-between gap-2">
                      <h3 className="truncate text-sm font-semibold">{c.title}</h3>
                      <span className="shrink-0 text-[11px] text-muted-foreground">
                        {new Date(c.date_time).toLocaleDateString([], { month: "short", day: "numeric" })}
                      </span>
                    </div>
                    <p className="truncate text-xs text-muted-foreground">{c.location}</p>
                  </div>
                </Link>
              </li>
            ))}
        </ul>
      )}
    </div>
  );
}