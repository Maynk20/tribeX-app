import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { useEffect, useState } from "react";
import { toast } from "sonner";
import { useAuth } from "@/hooks/use-auth";
import { GoogleIcon } from "@/components/google-icon";
import { friendlyError } from "@/lib/friendly-error";
import { OtpAuthForm } from "@/components/otp-auth-form";
import { supabase } from "@/integrations/supabase/client";
import { PageLoader } from "@/components/ui/loader";

export const Route = createFileRoute("/auth")({
  head: () => ({ meta: [{ title: "Sign in · tribeX" }] }),
  component: AuthPage,
});

function AuthPage() {
  const navigate = useNavigate();
  const { user, loading } = useAuth();
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    if (!loading && user) navigate({ to: "/" });
  }, [user, loading, navigate]);

  if (loading || user) {
    return <PageLoader label="Checking session" />;
  }

  async function onGoogle() {
    setBusy(true);
    try {
      const { error } = await supabase.auth.signInWithOAuth({
  provider: "google",
  options: {
    redirectTo: `${window.location.origin}`,
  },
});

if (error) {
  toast.error(error.message ?? "Google sign-in failed");
  setBusy(false);
}

    } catch (err) {
      toast.error(friendlyError(err, "Google sign-in failed"));
      setBusy(false);
    }
  }

  return (
    <div className="page-in flex min-h-[80vh] flex-col justify-center gap-6 px-5 pt-6">
      <header>
        <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Get started</p>
        <h1 className="mt-1 text-3xl font-bold tracking-tight">
          Join <span className="text-primary">tribe</span>X
        </h1>
        <p className="mt-1 text-sm text-muted-foreground">
          Passwordless — we'll email you a one-time code.
        </p>
      </header>

      <button
        onClick={onGoogle}
        disabled={busy}
        className="flex w-full items-center justify-center gap-3 rounded-2xl border border-border/60 bg-card py-3 text-sm font-semibold transition hover:bg-accent active:scale-[0.98] disabled:opacity-60"
      >
        <GoogleIcon className="h-5 w-5" />
        Continue with Google
      </button>

      <div className="flex items-center gap-3 text-[11px] uppercase tracking-wider text-muted-foreground">
        <div className="h-px flex-1 bg-border/60" /> or <div className="h-px flex-1 bg-border/60" />
      </div>

      <OtpAuthForm defaultMode="signup" onSuccess={() => navigate({ to: "/" })} />

      <p className="text-center text-[11px] leading-relaxed text-muted-foreground">
        By continuing you agree to our{" "}
        <Link to="/terms-and-policies" className="font-semibold text-primary hover:underline">
          Terms & Privacy Policy
        </Link>
        .
      </p>
    </div>
  );
}