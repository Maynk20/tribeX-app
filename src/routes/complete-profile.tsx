import { createFileRoute, useNavigate } from "@tanstack/react-router";
import { useEffect, useRef, useState } from "react";
import { useQueryClient } from "@tanstack/react-query";
import { toast } from "sonner";
import { z } from "zod";
import { Camera, Check, Loader2, MapPin, Sparkles, User, AtSign, X } from "lucide-react";
import { useAuth } from "@/hooks/use-auth";
import { getProfile, isUsernameAvailable, updateProfile, uploadAvatar } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";
import { PlaceSearch } from "@/components/place-search";
import { PageLoader } from "@/components/ui/loader";

export const Route = createFileRoute("/complete-profile")({
  head: () => ({
    meta: [
      { title: "Complete your profile · tribeX" },
      { name: "description", content: "Set your name, handle and city to start joining plans on tribeX." },
    ],
  }),
  component: CompleteProfile,
});

// Zod schema — keep validation server-safe and consistent with the profiles table constraints.
const usernameRegex = /^[a-zA-Z0-9_]{3,20}$/;
const schema = z.object({
  full_name: z.string().trim().min(2, "Full name must be at least 2 characters").max(80),
  username: z.string().trim().regex(usernameRegex, "3–20 letters, numbers, or underscores"),
  city: z.string().trim().min(2, "Pick your city").max(80),
  bio: z.string().trim().max(200).optional(),
});

type UsernameState =
  | { status: "idle" }
  | { status: "checking" }
  | { status: "available" }
  | { status: "taken" }
  | { status: "invalid"; message: string };

function CompleteProfile() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();

  const [fullName, setFullName] = useState("");
  const [username, setUsername] = useState("");
  const [city, setCity] = useState("");
  const [coords, setCoords] = useState<{ lat: number; lon: number } | null>(null);
  const [bio, setBio] = useState("");
  const [avatarUrl, setAvatarUrl] = useState<string | null>(null);
  const [avatarUploading, setAvatarUploading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [usernameState, setUsernameState] = useState<UsernameState>({ status: "idle" });
  const [profileLoading, setProfileLoading] = useState(true);
  const fileRef = useRef<HTMLInputElement>(null);

  // Redirect out if not signed in.
  useEffect(() => {
    if (!loading && !user) navigate({ to: "/auth", replace: true });
  }, [loading, user, navigate]);

  // Prefill from existing profile row. Skip if already complete.
  useEffect(() => {
    if (!user) {
      setProfileLoading(false);
      return;
    }
    getProfile(user.id)
      .then((p) => {
        if (!p) {
          setProfileLoading(false);
          return;
        }
        const already = (p as unknown as { has_completed_profile?: boolean }).has_completed_profile;
        if (already) {
          navigate({ to: "/", replace: true });
          return;
        }
        // Only prefill full_name if it looks like a real name (handle_new_user seeds it from the email prefix).
        const emailPrefix = user.email ? user.email.split("@")[0] : "";
        if (p.full_name && p.full_name !== emailPrefix) setFullName(p.full_name);
        if (p.username && p.username !== emailPrefix) setUsername(p.username);
        if (p.city) setCity(p.city);
        const pp = p as unknown as { latitude?: number | null; longitude?: number | null };
        if (pp.latitude != null && pp.longitude != null) setCoords({ lat: pp.latitude, lon: pp.longitude });
        if (p.bio) setBio(p.bio);
        if (p.avatar_url) setAvatarUrl(p.avatar_url);
        setProfileLoading(false);
      })
      .catch(() => {
        setProfileLoading(false);
      });
  }, [user, navigate]);

  if (loading || (user && profileLoading)) {
    return <PageLoader label="Checking profile status" />;
  }

  // Debounced username availability check.
  useEffect(() => {
    const trimmed = username.trim();
    if (!trimmed) { setUsernameState({ status: "idle" }); return; }
    if (!usernameRegex.test(trimmed)) {
      setUsernameState({ status: "invalid", message: "3–20 letters, numbers, or underscores" });
      return;
    }
    setUsernameState({ status: "checking" });
    const handle = setTimeout(async () => {
      try {
        const ok = await isUsernameAvailable(trimmed, user?.id);
        setUsernameState({ status: ok ? "available" : "taken" });
      } catch {
        setUsernameState({ status: "idle" });
      }
    }, 350);
    return () => clearTimeout(handle);
  }, [username, user?.id]);

  async function onPickAvatar(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !user) return;
    // Client-side MIME + size check per project rules.
    const okType = ["image/jpeg", "image/png", "image/webp"].includes(file.type);
    if (!okType) { toast.error("Use a JPG, PNG or WEBP image"); return; }
    if (file.size > 5 * 1024 * 1024) { toast.error("Image must be under 5MB"); return; }
    setAvatarUploading(true);
    try {
      const url = await uploadAvatar(user.id, file);
      setAvatarUrl(url);
      toast.success("Photo uploaded");
    } catch (err) {
      toast.error(friendlyError(err));
    } finally {
      setAvatarUploading(false);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    const parsed = schema.safeParse({ full_name: fullName, username, city, bio });
    if (!parsed.success) {
      toast.error(parsed.error.issues[0]?.message ?? "Please fix the highlighted fields");
      return;
    }
    if (usernameState.status === "taken") { toast.error("That username is already taken"); return; }
    if (usernameState.status === "invalid") { toast.error(usernameState.message); return; }
    if (usernameState.status === "checking") { toast.error("Checking username, please wait…"); return; }

    setSaving(true);
    try {
      // Double-check availability just before writing to close the race window.
      const ok = await isUsernameAvailable(parsed.data.username, user.id);
      if (!ok) {
        setUsernameState({ status: "taken" });
        toast.error("That username was just taken — pick another");
        return;
      }
      await updateProfile(user.id, {
        full_name: parsed.data.full_name,
        username: parsed.data.username,
        city: parsed.data.city,
        bio: parsed.data.bio?.trim() || null,
        has_completed_profile: true,
        ...(coords ? { latitude: coords.lat, longitude: coords.lon } : {}),
      } as Parameters<typeof updateProfile>[1]);
      await qc.invalidateQueries({ queryKey: ["profile", user.id] });
      await qc.invalidateQueries({ queryKey: ["onboarding-status", user.id] });
      toast.success("Welcome to tribeX 🎉");
      navigate({ to: "/", replace: true });
    } catch (err) {
      toast.error(friendlyError(err));
    } finally {
      setSaving(false);
    }
  }

  const initial = (fullName || user?.email || "U")[0]?.toUpperCase() ?? "U";

  return (
    <div className="page-in flex min-h-screen flex-col gap-6 px-5 pb-10 pt-10">
      <header className="flex flex-col gap-2">
        <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-primary/15 text-primary">
          <Sparkles className="h-6 w-6" />
        </div>
        <h1 className="text-3xl font-bold tracking-tight">Complete your profile</h1>
        <p className="text-sm text-muted-foreground">
          Just a few details so your squad knows who they're meeting.
        </p>
      </header>

      <form onSubmit={handleSubmit} className="flex flex-col gap-5">
        {/* Avatar picker */}
        <div className="flex items-center gap-4">
          <div className="relative shrink-0">
            <div className="flex h-20 w-20 items-center justify-center overflow-hidden rounded-full bg-primary text-2xl font-bold text-primary-foreground">
              {avatarUrl ? (
                <img src={avatarUrl} alt="" className="h-full w-full object-cover" />
              ) : (
                initial
              )}
            </div>
            <button
              type="button"
              onClick={() => fileRef.current?.click()}
              disabled={avatarUploading}
              className="absolute -bottom-1 -right-1 flex h-8 w-8 items-center justify-center rounded-full border border-border bg-background text-foreground shadow transition hover:scale-105 active:scale-95 disabled:opacity-60"
              aria-label="Upload photo"
            >
              {avatarUploading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Camera className="h-4 w-4" />}
            </button>
            <input ref={fileRef} type="file" accept="image/jpeg,image/png,image/webp" className="hidden" onChange={onPickAvatar} />
          </div>
          <div>
            <p className="text-sm font-semibold">Profile photo</p>
            <p className="text-xs text-muted-foreground">Optional · JPG, PNG or WEBP up to 5MB</p>
          </div>
        </div>

        {/* Full name */}
        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Full name <span className="text-destructive">*</span>
          </span>
          <div className="flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-3 focus-within:border-primary">
            <User className="h-4 w-4 text-muted-foreground" />
            <input
              value={fullName}
              onChange={(e) => setFullName(e.target.value)}
              maxLength={80}
              required
              placeholder="Ananya Rao"
              className="w-full bg-transparent py-3 text-sm outline-none placeholder:text-muted-foreground"
            />
          </div>
        </label>

        {/* Username */}
        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Username <span className="text-destructive">*</span>
          </span>
          <div className={`flex items-center gap-2 rounded-2xl border bg-card px-3 focus-within:border-primary ${
            usernameState.status === "taken" || usernameState.status === "invalid"
              ? "border-destructive/60"
              : usernameState.status === "available"
                ? "border-green-500/60"
                : "border-border/60"
          }`}>
            <AtSign className="h-4 w-4 text-muted-foreground" />
            <input
              value={username}
              onChange={(e) => setUsername(e.target.value.replace(/\s+/g, ""))}
              maxLength={20}
              required
              placeholder="ananya_r"
              autoCapitalize="off"
              autoCorrect="off"
              spellCheck={false}
              className="w-full bg-transparent py-3 text-sm lowercase outline-none placeholder:text-muted-foreground"
            />
            {usernameState.status === "checking" && <Loader2 className="h-4 w-4 animate-spin text-muted-foreground" />}
            {usernameState.status === "available" && <Check className="h-4 w-4 text-green-500" />}
            {(usernameState.status === "taken" || usernameState.status === "invalid") && (
              <X className="h-4 w-4 text-destructive" />
            )}
          </div>
          <span className="min-h-[1rem] text-[11px]">
            {usernameState.status === "available" && (
              <span className="text-green-600 dark:text-green-400">Available</span>
            )}
            {usernameState.status === "taken" && (
              <span className="text-destructive">That username is already taken</span>
            )}
            {usernameState.status === "invalid" && (
              <span className="text-destructive">{usernameState.message}</span>
            )}
            {usernameState.status === "idle" && (
              <span className="text-muted-foreground">3–20 letters, numbers or underscores</span>
            )}
          </span>
        </label>

        {/* City */}
        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            City <span className="text-destructive">*</span>
          </span>
          <div className="flex items-center gap-2 rounded-2xl border border-border/60 bg-card px-3 focus-within:border-primary">
            <MapPin className="h-4 w-4 shrink-0 text-muted-foreground" />
            <div className="flex-1 py-1.5">
              <PlaceSearch
                variant="input"
                value={city}
                placeholder="Search your city or pincode"
                onSelect={(p) => {
                  setCity(p.short || p.city || "");
                  setCoords({ lat: p.lat, lon: p.lon });
                }}
              />
            </div>
          </div>
        </div>

        {/* Bio */}
        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
            Short bio <span className="text-muted-foreground/70">(optional)</span>
          </span>
          <textarea
            value={bio}
            onChange={(e) => setBio(e.target.value)}
            maxLength={200}
            rows={3}
            placeholder="Weekend cricketer, coffee snob, always down for a trek."
            className="resize-none rounded-2xl border border-border/60 bg-card px-3 py-3 text-sm outline-none placeholder:text-muted-foreground focus:border-primary"
          />
          <span className="text-right text-[10px] text-muted-foreground">{bio.length}/200</span>
        </label>

        <button
          type="submit"
          disabled={saving || usernameState.status === "checking"}
          className="mt-2 w-full rounded-2xl bg-primary py-4 text-sm font-semibold text-primary-foreground shadow-lg transition hover:scale-[1.01] active:scale-[0.99] disabled:cursor-not-allowed disabled:opacity-50"
        >
          {saving ? "Saving…" : "Continue"}
        </button>
      </form>
    </div>
  );
}