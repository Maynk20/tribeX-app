import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { Check, Sparkles } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { getProfile, updateProfile } from "@/lib/services";
import { requestPushPermission } from "@/lib/onesignal";
import { PageLoader } from "@/components/ui/loader";

export const Route = createFileRoute("/onboarding")({
  head: () => ({
    meta: [
      { title: "Pick your interests · tribeX" },
      { name: "description", content: "Tell us what you love so we can match you to plans nearby." },
    ],
  }),
  component: Onboarding,
});

const INTERESTS: { key: string; emoji: string }[] = [
  { key: "Cricket", emoji: "🏏" },
  { key: "Football", emoji: "⚽" },
  { key: "Trek", emoji: "🥾" },
  { key: "Music", emoji: "🎸" },
  { key: "Food", emoji: "🍜" },
  { key: "Board games", emoji: "🎲" },
  { key: "Run", emoji: "🏃" },
  { key: "Cycling", emoji: "🚴" },
  { key: "Parties", emoji: "🎉" },
  { key: "Social", emoji: "🤝" },
  { key: "Outdoors", emoji: "🌄" },
  { key: "Sports", emoji: "🏅" },
];

function Onboarding() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [saving, setSaving] = useState(false);
  const [profileLoading, setProfileLoading] = useState(true);

  useEffect(() => {
    if (!loading && !user) navigate({ to: "/auth", replace: true });
  }, [loading, user, navigate]);

  useEffect(() => {
    if (!user) {
      setProfileLoading(false);
      return;
    }
    getProfile(user.id).then((p) => {
      if (p?.has_completed_onboarding) {
        navigate({ to: "/", replace: true });
        return;
      }
      if (p?.interests?.length) {
        setSelected(new Set(p.interests));
      }
      setProfileLoading(false);
    }).catch(() => {
      setProfileLoading(false);
    });
  }, [user, navigate]);

  if (loading || (user && profileLoading)) {
    return <PageLoader label="Loading onboarding" />;
  }

  function toggle(k: string) {
    setSelected((prev) => {
      const next = new Set(prev);
      if (next.has(k)) next.delete(k); else next.add(k);
      return next;
    });
  }

  async function handleSave() {
    if (!user) return;
    if (selected.size < 1) { toast.error("Pick at least one interest"); return; }
    setSaving(true);
    try {
      const updated = await updateProfile(user.id, {
        interests: Array.from(selected),
        has_completed_onboarding: true,
      });
      // Update caches synchronously so the AppShell gate sees the fresh
      // has_completed_onboarding=true before we navigate — otherwise the
      // stale profile bounces the user back to /onboarding and they'd
      // need to click Save again.
      qc.setQueryData(["profile", user.id], updated);
      qc.setQueryData(["onboarding-status", user.id], updated);
      qc.invalidateQueries({ queryKey: ["profile", user.id] });
      qc.invalidateQueries({ queryKey: ["onboarding-status", user.id] });
      toast.success("You're all set!");
      // Ask for web-push permission immediately after onboarding — best time
      // to catch enthusiastic users. Failures are non-blocking.
      requestPushPermission()
        .then((res) => {
          if (res.status === "granted") {
            toast.success("Notifications enabled — you'll hear about new plans nearby.");
          } else if (res.status === "denied") {
            toast("Notifications blocked", { description: res.message, duration: 8000 });
          }
        })
        .catch(() => {});
      navigate({ to: "/", replace: true });
    } catch (e) {
      toast.error(e instanceof Error ? e.message : "Couldn't save preferences");
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="page-in flex min-h-screen flex-col gap-6 px-5 pb-10 pt-10">
      <header className="flex flex-col gap-2">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/15 text-primary">
          <Sparkles className="h-6 w-6" />
        </div>
        <h1 className="text-3xl font-bold tracking-tight">What are you into?</h1>
        <p className="text-sm text-muted-foreground">
          Pick one or more so we can surface plans you'll actually love. You can update these later.
        </p>
      </header>

      <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-3">
        {INTERESTS.map((c) => {
          const on = selected.has(c.key);
          return (
            <button
              key={c.key}
              type="button"
              onClick={() => toggle(c.key)}
              className={`relative flex items-center gap-2 rounded-2xl border px-4 py-3.5 text-left text-sm font-medium transition active:scale-[0.98] ${
                on
                  ? "border-primary bg-primary/10 text-foreground"
                  : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"
              }`}
            >
              <span className="text-lg">{c.emoji}</span>
              <span className="flex-1">{c.key}</span>
              {on && (
                <span className="flex h-5 w-5 items-center justify-center rounded-full bg-primary text-primary-foreground">
                  <Check className="h-3 w-3" />
                </span>
              )}
            </button>
          );
        })}
      </div>

      <div className="sticky bottom-4 mt-auto flex flex-col gap-2">
        <p className="text-center text-xs text-muted-foreground">
          {selected.size === 0 ? "Select at least one to continue" : `${selected.size} selected`}
        </p>
        <button
          onClick={handleSave}
          disabled={saving || selected.size < 1}
          className="w-full rounded-2xl bg-primary py-4 text-sm font-semibold text-primary-foreground shadow-lg transition hover:scale-[1.01] active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-50"
        >
          {saving ? "Saving…" : "Save & Continue"}
        </button>
      </div>
    </div>
  );
}