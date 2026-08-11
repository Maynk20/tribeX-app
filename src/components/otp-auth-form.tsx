import { useCallback, useEffect, useState } from "react";
import { Mail, ShieldCheck, ArrowLeft, User, AtSign, AlertTriangle, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { useServerFn } from "@tanstack/react-start";
import { supabase } from "@/integrations/supabase/client";
import { friendlyError } from "@/lib/friendly-error";
import {
  requestSignInOtp,
  requestSignUpOtp,
  verifySignInOtp,
  verifySignUpOtp,
} from "@/lib/otp-auth.functions";

type Step = "email" | "code";
type Mode = "signup" | "login";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export function OtpAuthForm({
  onSuccess,
  defaultMode = "signup",
}: {
  onSuccess: () => void;
  defaultMode?: Mode;
}) {
  const [mode, setMode] = useState<Mode>(defaultMode);
  const [step, setStep] = useState<Step>("email");
  const [email, setEmail] = useState("");
  const [fullName, setFullName] = useState("");
  const [username, setUsername] = useState("");
  const [code, setCode] = useState("");
  const [busy, setBusy] = useState(false);
  const [cooldown, setCooldown] = useState(0);
  const [notice, setNotice] = useState<null | { kind: "no_account" | "account_exists" | "info"; message: string }>(null);
  const requestSignIn = useServerFn(requestSignInOtp);
  const requestSignUp = useServerFn(requestSignUpOtp);
  const verifySignIn = useServerFn(verifySignInOtp);
  const verifySignUp = useServerFn(verifySignUpOtp);

  useEffect(() => {
    if (cooldown <= 0) return;
    const t = setInterval(() => setCooldown((s) => (s <= 1 ? 0 : s - 1)), 1000);
    return () => clearInterval(t);
  }, [cooldown]);

  const resetTransient = useCallback(() => {
    setStep("email");
    setCode("");
    setBusy(false);
    setCooldown(0);
    setNotice(null);
  }, []);

  function switchMode(next: Mode) {
    setMode(next);
    resetTransient();
  }

  function onEmailChange(next: string) {
    setEmail(next);
    // Any character change invalidates the current OTP session.
    if (step !== "email") setStep("email");
    if (code) setCode("");
    if (cooldown > 0) setCooldown(0);
    if (notice) setNotice(null);
    if (busy) setBusy(false);
  }

  const trimmedEmail = email.trim().toLowerCase();
  const emailValid = EMAIL_RE.test(trimmedEmail);
  const signupValid =
    mode !== "signup" ||
    (fullName.trim().length >= 2 && /^[a-z0-9_]{3,24}$/.test(username.trim().toLowerCase()));
  const canSubmitEmail = emailValid && signupValid && !busy;

  function parseTaggedError(err: unknown, fallback: string) {
    const raw = err instanceof Error ? err.message : String(err ?? "");
    if (raw.startsWith("ACCOUNT_EXISTS:")) {
      toast.error("Account already exists! Please Log In.");
      // Auto-switch to Log In with email pre-filled.
      setMode("login");
      setStep("email");
      setCode("");
      setNotice({ kind: "account_exists", message: "Account already exists — please log in." });
      return;
    }
    if (raw.startsWith("NO_ACCOUNT:")) {
      toast.error("No account found with this email. Please Sign Up first!");
      // Auto-switch to Sign Up with email pre-filled.
      setMode("signup");
      setStep("email");
      setCode("");
      setNotice({ kind: "no_account", message: "No account found — create one to continue." });
      return;
    }
    if (raw.startsWith("USERNAME_TAKEN:")) {
      const msg = raw.slice("USERNAME_TAKEN:".length);
      setNotice({ kind: "info", message: msg });
      toast.error(msg);
      return;
    }
    toast.error(friendlyError(err, fallback));
  }

  async function sendCode(isResend = false) {
    if (busy) return; // debounce duplicate submits
    const trimmed = trimmedEmail;
    if (!EMAIL_RE.test(trimmed)) {
      toast.error("Enter a valid email address");
      return;
    }
    const normalizedUsername = username.trim().toLowerCase();
    if (mode === "signup") {
      if (fullName.trim().length < 2) {
        toast.error("Enter your full name");
        return;
      }
      if (!/^[a-z0-9_]{3,24}$/.test(normalizedUsername)) {
        toast.error("Username: 3–24 chars, lowercase letters, numbers or underscores");
        return;
      }
    }
    if (cooldown > 0) return;
    setBusy(true);
    setNotice(null);
    try {
      const res =
        mode === "signup"
          ? await requestSignUp({
              data: { email: trimmed, full_name: fullName.trim(), username: normalizedUsername },
            })
          : await requestSignIn({ data: { email: trimmed } });
      if (!res?.success) {
        const code = (res as { code?: string } | undefined)?.code;
        const message = res?.message ?? "Couldn't send security code. Please try again.";
        if (code === "ACCOUNT_EXISTS") {
          toast.error("Account already exists! Please Log In.");
          setMode("login");
          setStep("email");
          setCode("");
          setNotice({ kind: "account_exists", message: "Account already exists — please log in." });
          return;
        }
        if (code === "NO_ACCOUNT") {
          toast.error("No account found with this email. Please Sign Up first!");
          setMode("signup");
          setStep("email");
          setCode("");
          setNotice({ kind: "no_account", message: "No account found — create one to continue." });
          return;
        }
        if (code === "USERNAME_TAKEN") {
          setNotice({ kind: "info", message });
          toast.error(message);
          return;
        }
        toast.error(message);
        return;
      }
      toast.success(
        isResend
          ? "New code sent. Check your inbox and spam folder."
          : "Security code sent. Check your inbox and spam folder.",
      );
      setStep("code");
      setCooldown(60);
    } catch (err) {
      console.error("Send OTP error:", err);
      parseTaggedError(err, "Couldn't send security code. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  async function verify(e: React.FormEvent) {
    e.preventDefault();
    if (busy) return;
    if (!/^\d{6}$/.test(code)) {
      toast.error("Enter the 6-digit code sent to your email.");
      return;
    }
    setBusy(true);
    try {
      const payload = { email: trimmedEmail, code };
      const { token_hash } =
        mode === "signup"
          ? await verifySignUp({
              data: {
                ...payload,
                full_name: fullName.trim(),
                username: username.trim().toLowerCase(),
              },
            })
          : await verifySignIn({ data: payload });
      const { error } = await supabase.auth.verifyOtp({ type: "magiclink", token_hash });
      if (error) throw error;
      toast.success(mode === "signup" ? "Welcome to tribeX!" : "You're signed in!");
      onSuccess();
    } catch (err) {
      console.error("Verify OTP error:", err);
      parseTaggedError(err, "Couldn't verify code. Please try again.");
    } finally {
      setBusy(false);
    }
  }

  if (step === "email") {
    return (
      <div className="mx-auto flex w-full max-w-md flex-col gap-3 antialiased">
        <div className="mb-1">
          <h2 className="text-xl font-bold tracking-tight">
            {mode === "signup" ? "Create your account" : "Welcome back"}
          </h2>
          <p className="mt-0.5 text-xs text-muted-foreground">
            {mode === "signup"
              ? "Join tribeX — we'll email you a one-time code."
              : "Log in with a one-time code sent to your email."}
          </p>
        </div>

        {mode === "signup" && (
          <>
            <div className="flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary">
              <User className="h-4 w-4 text-muted-foreground" />
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Full name"
                autoComplete="name"
                maxLength={80}
                className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
              />
            </div>
          </>
        )}

        <div className="flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary">
          <Mail className="h-4 w-4 text-muted-foreground" />
          <input
            type="email"
            value={email}
            onChange={(e) => onEmailChange(e.target.value)}
            placeholder="Email address"
            autoComplete="email"
            inputMode="email"
            spellCheck={false}
            autoCapitalize="none"
            className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          />
        </div>

        {mode === "signup" && (
          <div className="flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 transition focus-within:border-primary">
            <AtSign className="h-4 w-4 text-muted-foreground" />
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value.toLowerCase().replace(/[^a-z0-9_]/g, "").slice(0, 24))}
              placeholder="Username"
              autoComplete="username"
              maxLength={24}
              className="w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
            />
          </div>
        )}

        {notice && (
          <div
            className={`antialiased flex items-center gap-3 rounded-xl border p-4 ${
              notice.kind === "account_exists" || notice.kind === "no_account"
                ? "border-destructive/30 bg-destructive/10"
                : "border-primary/30 bg-primary/5"
            }`}
          >
            {(notice.kind === "account_exists" || notice.kind === "no_account") && (
              <AlertTriangle className="h-5 w-5 flex-shrink-0 text-destructive" />
            )}
            <div className="min-w-0 flex-1">
              <p
                className={`text-sm font-semibold ${
                  notice.kind === "account_exists" || notice.kind === "no_account"
                    ? "text-destructive"
                    : "text-foreground"
                }`}
              >
                {notice.message}
              </p>
            </div>
            {notice.kind === "account_exists" && (
              <button
                type="button"
                onClick={() => switchMode("login")}
                className="flex-shrink-0 rounded-lg bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground shadow-sm transition-all hover:opacity-90 whitespace-nowrap"
              >
                Log In instead
              </button>
            )}
            {notice.kind === "no_account" && (
              <button
                type="button"
                onClick={() => switchMode("signup")}
                className="flex-shrink-0 rounded-lg bg-primary px-4 py-2 text-xs font-semibold text-primary-foreground shadow-sm transition-all hover:opacity-90 whitespace-nowrap"
              >
                Sign Up instead
              </button>
            )}
          </div>
        )}

        <button
          type="button"
          onClick={() => sendCode(false)}
          disabled={!canSubmitEmail}
          className="flex items-center justify-center gap-2 rounded-2xl bg-primary py-3.5 text-sm font-semibold text-primary-foreground shadow-sm transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50"
        >
          {busy && <Loader2 className="h-4 w-4 animate-spin" />}
          {busy
            ? "Sending…"
            : mode === "signup"
              ? "Sign Up & Get OTP"
              : "Log In with OTP"}
        </button>

        <p className="text-center text-xs text-muted-foreground">
          {mode === "signup" ? (
            <>
              Already have an account?{" "}
              <button
                type="button"
                onClick={() => switchMode("login")}
                className="font-semibold text-primary hover:underline"
              >
                Log In
              </button>
            </>
          ) : (
            <>
              New to tribeX?{" "}
              <button
                type="button"
                onClick={() => switchMode("signup")}
                className="font-semibold text-primary hover:underline"
              >
                Create an Account
              </button>
            </>
          )}
        </p>
      </div>
    );
  }

  return (
    <form onSubmit={verify} className="mx-auto flex w-full max-w-md flex-col gap-3 antialiased">
      <button
        type="button"
        onClick={resetTransient}
        className="mb-1 flex items-center gap-1 self-start text-xs font-medium text-muted-foreground transition hover:text-foreground"
      >
        <ArrowLeft className="h-3 w-3" /> Change email
      </button>
      <div className="flex items-center gap-2 rounded-2xl border border-primary/30 bg-primary/5 px-4 py-3 text-xs text-muted-foreground">
        <ShieldCheck className="h-4 w-4 text-primary" />
        Code sent to <span className="truncate font-semibold text-foreground">{email}</span>
      </div>
      <input
        inputMode="numeric"
        pattern="\d{6}"
        maxLength={6}
        autoFocus
        value={code}
        onChange={(e) => setCode(e.target.value.replace(/\D/g, "").slice(0, 6))}
        placeholder="6-digit code"
        className="w-full rounded-2xl border border-border/60 bg-card px-4 py-4 text-center text-2xl font-semibold tracking-[0.6em] outline-none focus:border-primary"
      />
      <button
        type="submit"
        disabled={busy || code.length !== 6}
        className="flex items-center justify-center gap-2 rounded-2xl bg-primary py-3.5 text-sm font-semibold text-primary-foreground shadow-sm transition active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50"
      >
        {busy && <Loader2 className="h-4 w-4 animate-spin" />}
        {busy ? "Verifying…" : "Verify & sign in"}
      </button>
      <button
        type="button"
        onClick={() => sendCode(true)}
        disabled={busy || cooldown > 0}
        className="text-center text-xs font-medium text-muted-foreground transition hover:text-foreground disabled:opacity-60"
      >
        {cooldown > 0 ? `Resend code in ${cooldown}s` : "Resend code"}
      </button>
    </form>
  );
}