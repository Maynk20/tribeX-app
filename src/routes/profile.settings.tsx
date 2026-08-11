import { createFileRoute, useNavigate, Link } from "@tanstack/react-router";
import { useQuery, useQueryClient, useMutation } from "@tanstack/react-query";
import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import {
  ArrowLeft,
  Camera,
  User,
  Bell,
  BellOff,
  UserX,
  LifeBuoy,
  ShieldAlert,
  FileText,
  Trash2,
  Check,
  Loader2,
  X,
  ChevronRight,
  ChevronDown,
  Info,
  MapPin,
  Navigation,
} from "lucide-react";
import {
  getProfile,
  updateProfile,
  uploadAvatar,
  listBlockedUsers,
  unblockUser,
  saveVerifiedProfileLocation,
} from "@/lib/services";
import {
  disablePushForCurrentUser,
  getPushStatus,
  isOneSignalConfigured,
  requestPushPermission,
} from "@/lib/onesignal";
import { supabase } from "@/integrations/supabase/client";
import { toast } from "sonner";
import { friendlyError } from "@/lib/friendly-error";
import { PageLoader } from "@/components/ui/loader";

export const Route = createFileRoute("/profile/settings")({
  head: () => ({
    meta: [
      { title: "Settings · tribeX" },
      { name: "description", content: "Manage your account, notifications, and privacy." },
    ],
  }),
  component: SettingsPage,
});

function SettingsPage() {
  const { data: session, isLoading: isSessionLoading } = useQuery({
    queryKey: ["session"],
    queryFn: async () => {
      const { data } = await supabase.auth.getSession();
      return data.session;
    },
  });
  const user = session?.user;
  const navigate = useNavigate();
  const qc = useQueryClient();

  const { data: profile, isLoading: isProfileLoading } = useQuery({
    queryKey: ["profile", user?.id],
    queryFn: () => getProfile(user!.id),
    enabled: !!user,
  });

  if (isSessionLoading || (user && isProfileLoading)) {
    return <PageLoader label="Loading settings" />;
  }

  const { data: blockedUsers = [] } = useQuery({
    queryKey: ["blocked-users", user?.id],
    queryFn: () => listBlockedUsers(user!.id),
    enabled: !!user,
  });

  // Basic info states
  const [showEditDetails, setShowEditDetails] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);
  const [fetchingGps, setFetchingGps] = useState(false);
  const [editDraft, setEditDraft] = useState({
    full_name: "",
    phone: "",
    gender: "",
    city: "",
    bio: "",
    username: "",
  });

  // Avatar uploading state
  const [uploading, setUploading] = useState(false);
  const fileRef = useRef<HTMLInputElement>(null);

  // Push notification states
  const [pushOn, setPushOn] = useState(false);
  const [pushBusy, setPushBusy] = useState(false);

  // Blocked list modal state
  const [showBlockedModal, setShowBlockedModal] = useState(false);

  // Support modals & panels
  const [showFaq, setShowFaq] = useState(false);
  const [openFaqIndex, setOpenFaqIndex] = useState<number | null>(null);
  const [showReportModal, setShowReportModal] = useState(false);
  const [reportText, setReportText] = useState("");
  const [submittingReport, setSubmittingReport] = useState(false);
  const [showFeedbackModal, setShowFeedbackModal] = useState(false);
  const [feedbackRating, setFeedbackRating] = useState(5);
  const [feedbackText, setFeedbackText] = useState("");
  const [submittingFeedback, setSubmittingFeedback] = useState(false);

  // Account deletion states
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [showDeleteFinal, setShowDeleteFinal] = useState(false);
  const [deleteInput, setDeleteInput] = useState("");

  const unblockMut = useMutation({
    mutationFn: (targetId: string) => unblockUser(targetId),
    onSuccess: () => {
      toast.success("User unblocked");
      qc.invalidateQueries({ queryKey: ["blocked-users", user?.id] });
      qc.invalidateQueries({ queryKey: ["blocked-ids", user?.id] });
      qc.invalidateQueries({ queryKey: ["activities"] });
    },
    onError: (e: Error) => toast.error(friendlyError(e)),
  });

  useEffect(() => {
    if (!user) return;
    getPushStatus()
      .then((s) => setPushOn(s.optedIn && s.permission === "granted"))
      .catch(() => {});
  }, [user]);

  async function togglePush() {
    if (!isOneSignalConfigured()) {
      setPushOn(false);
      toast("Push notifications are available on the mobile app!");
      return;
    }
    if (typeof window !== "undefined" && !("Notification" in window)) {
      setPushOn(false);
      toast("Push notifications are available on the mobile app!");
      return;
    }
    setPushBusy(true);
    try {
      if (pushOn) {
        await disablePushForCurrentUser();
        setPushOn(false);
        toast.success("Push notifications turned off");
      } else {
        const res = await requestPushPermission();
        if (res.status === "granted") {
          setPushOn(true);
          toast.success("Push notifications enabled");
        } else {
          setPushOn(false);
          if (res.status === "denied") {
            toast.error("Notifications blocked", {
              description: res.message,
              duration: 8000,
            });
          } else if (res.status === "dismissed") {
            toast("Notifications not enabled", { description: res.message });
          } else if (res.status === "unsupported") {
            toast("Push notifications are available on the mobile app!");
          } else {
            toast.error(res.message);
          }
        }
      }
    } catch (e) {
      setPushOn(false);
      toast("Push notifications are available on the mobile app!", {
        description: e instanceof Error ? e.message : undefined,
      });
    } finally {
      setPushBusy(false);
    }
  }

  async function onPickAvatar(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file || !user) return;
    if (!file.type.startsWith("image/")) {
      toast.error("Pick an image file");
      return;
    }
    if (file.size > 5 * 1024 * 1024) {
      toast.error("Image must be under 5MB");
      return;
    }
    setUploading(true);
    try {
      await uploadAvatar(user.id, file);
      await qc.invalidateQueries({ queryKey: ["profile", user.id] });
      toast.success("Avatar updated");
    } catch (err) {
      toast.error(friendlyError(err));
    } finally {
      setUploading(false);
    }
  }

  function openEdit() {
    setEditDraft({
      full_name: profile?.full_name ?? "",
      phone: profile?.phone ?? "",
      gender: profile?.gender ?? "",
      city: profile?.city ?? "",
      bio: profile?.bio ?? "",
      username: profile?.username ?? "",
    });
    setShowEditDetails(true);
  }

  async function saveEdit(e: React.FormEvent) {
    e.preventDefault();
    if (!user) return;
    const name = editDraft.full_name.trim();
    const uname = editDraft.username.trim().toLowerCase();
    if (!name) {
      toast.error("Name can't be empty");
      return;
    }
    if (!uname || uname.length < 3) {
      toast.error("Username must be at least 3 characters");
      return;
    }
    if (editDraft.phone && !/^\+?[\d\s-]{7,15}$/.test(editDraft.phone.trim())) {
      toast.error("Enter a valid phone number");
      return;
    }
    setSavingEdit(true);
    try {
      await updateProfile(user.id, {
        full_name: name,
        username: uname,
        phone: editDraft.phone.trim() || null,
        gender: editDraft.gender || null,
        city: editDraft.city || null,
        bio: editDraft.bio.trim() || null,
      } as Parameters<typeof updateProfile>[1]);
      await qc.invalidateQueries({ queryKey: ["profile", user.id] });
      setShowEditDetails(false);
      toast.success("Profile updated");
    } catch (err) {
      toast.error(friendlyError(err));
    } finally {
      setSavingEdit(false);
    }
  }

  async function handleFetchProfileGPS() {
    if (!user) return;
    setFetchingGps(true);
    try {
      const updated = await saveVerifiedProfileLocation(user.id);
      setEditDraft((d) => ({ ...d, city: updated.city ?? "" }));
      await qc.invalidateQueries({ queryKey: ["profile", user.id] });
      toast.success("Profile location verified");
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't fetch your location"));
    } finally {
      setFetchingGps(false);
    }
  }

  // Support Submission Mock-ups
  const handleReportSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reportText.trim()) return;
    setSubmittingReport(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800));
    setSubmittingReport(false);
    setShowReportModal(false);
    setReportText("");
    toast.success("Issue reported! Our support team will look into it.");
  };

  const handleFeedbackSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSubmittingFeedback(true);
    // Simulate API call
    await new Promise((resolve) => setTimeout(resolve, 800));
    setSubmittingFeedback(false);
    setShowFeedbackModal(false);
    setFeedbackText("");
    toast.success("Thank you for your feedback!");
  };

  const deleteAccountMut = useMutation({
    mutationFn: async () => {
      const { data, error } = await supabase.rpc("delete_user_account");
      if (error) throw error;
      return data;
    },
    onSuccess: async () => {
      toast.success("Account permanently deleted");
      await qc.cancelQueries();
      qc.clear();
      await supabase.auth.signOut();
      navigate({ to: "/", replace: true });
    },
    onError: (e: any) => {
      toast.error(friendlyError(e, "Account deletion failed. Try again later."));
    },
  });

  const handleDeleteFinalConfirm = () => {
    if (deleteInput.trim().toUpperCase() !== "DELETE") {
      toast.error("Please type DELETE to confirm");
      return;
    }
    setShowDeleteFinal(false);
    deleteAccountMut.mutate();
  };

  const displayName = profile?.full_name || profile?.username || "You";
  const initial = (displayName[0] ?? "U").toUpperCase();

  const faqs = [
    {
      q: "How do I join a plan?",
      a: "Tap on any plan on the Explore tab, view the details, and request to join. The host will review and approve/reject your request.",
    },
    {
      q: "How do I host a plan?",
      a: "Tap on the Create tab in the bottom bar, fill in the activity title, description, category, venue, and time, and publish it.",
    },
    {
      q: "Are payments handled in the app?",
      a: "No, tribeX does not handle payments directly. Any cost per head should be settled with the host directly.",
    },
    {
      q: "How does the Reliability Score work?",
      a: "Your Reliability Score reflects your attendance. Joining plans and attending venue check-ins increases it, while hosting/joining and failing to show up decreases it.",
    },
  ];

  return (
    <div className="page-in flex flex-col gap-5 px-5 pt-6 pb-20">
      <header className="flex items-center gap-3">
        <Link
          to="/profile"
          className="flex h-9 w-9 items-center justify-center rounded-full border border-border/60 bg-card transition hover:bg-accent active:scale-95"
        >
          <ArrowLeft className="h-4 w-4" />
        </Link>
        <div>
          <p className="text-[10px] font-medium uppercase tracking-[0.18em] text-muted-foreground">
            Settings
          </p>
          <h1 className="text-xl font-bold tracking-tight">Account & Security</h1>
        </div>
      </header>

      {/* Account Section */}
      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <h3 className="mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          Account Profile
        </h3>
        <div className="flex items-center gap-4 border-b border-border/60 pb-5">
          <div className="relative shrink-0">
            <div className="flex h-16 w-16 items-center justify-center overflow-hidden rounded-full bg-primary text-2xl font-bold text-primary-foreground">
              {profile?.avatar_url ? (
                <img src={profile.avatar_url} alt="" className="h-full w-full object-cover" />
              ) : (
                initial
              )}
            </div>
            <button
              type="button"
              onClick={() => fileRef.current?.click()}
              disabled={uploading}
              className="absolute -bottom-1 -right-1 flex h-7 w-7 items-center justify-center rounded-full border border-border bg-background text-foreground shadow transition hover:scale-105 active:scale-95 disabled:opacity-60"
              aria-label="Change avatar"
            >
              <Camera className="h-3.5 w-3.5" />
            </button>
            <input
              ref={fileRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={onPickAvatar}
            />
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="truncate text-lg font-semibold">{displayName}</h2>
            <p className="text-xs text-muted-foreground truncate">
              {user?.email || "No email linked"}
            </p>
            {profile?.username && (
              <p className="text-xs text-primary font-medium">@{profile.username}</p>
            )}
          </div>
        </div>
        <div className="mt-4 flex flex-col gap-2">
          <button
            onClick={openEdit}
            className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
          >
            <span className="flex items-center gap-3">
              <User className="h-4 w-4 text-primary" />
              Edit Basic Details
            </span>
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          </button>
        </div>
      </section>

      {/* Notifications Section */}
      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <h3 className="mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          Notifications
        </h3>
        <button
          onClick={togglePush}
          disabled={pushBusy}
          className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99] disabled:opacity-60"
        >
          <span className="flex items-center gap-3">
            {pushOn ? (
              <Bell className="h-4 w-4 text-primary" />
            ) : (
              <BellOff className="h-4 w-4 text-muted-foreground" />
            )}
            Push Notifications
          </span>
          <span className={`text-xs font-bold ${pushOn ? "text-primary" : "text-muted-foreground"}`}>
            {pushOn ? "ENABLED" : "DISABLED"}
          </span>
        </button>
      </section>

      {/* Privacy Section */}
      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <h3 className="mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          Privacy
        </h3>
        <button
          onClick={() => setShowBlockedModal(true)}
          className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
        >
          <span className="flex items-center gap-3">
            <UserX className="h-4 w-4 text-primary" />
            Blocked Users
          </span>
          <span className="text-xs font-bold text-muted-foreground">
            {blockedUsers.length} active
          </span>
        </button>
      </section>

      {/* Help & Support Section */}
      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <h3 className="mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          Help &amp; Support
        </h3>
        <div className="flex flex-col gap-2">
          <button
            onClick={() => setShowFaq(true)}
            className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
          >
            <span className="flex items-center gap-3">
              <LifeBuoy className="h-4 w-4 text-primary" />
              Frequently Asked Questions (FAQ)
            </span>
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          </button>
          <button
            onClick={() => setShowReportModal(true)}
            className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
          >
            <span className="flex items-center gap-3">
              <ShieldAlert className="h-4 w-4 text-primary" />
              Report a Problem
            </span>
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          </button>
          <button
            onClick={() => setShowFeedbackModal(true)}
            className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
          >
            <span className="flex items-center gap-3">
              <Info className="h-4 w-4 text-primary" />
              Send Feedback
            </span>
            <ChevronRight className="h-4 w-4 text-muted-foreground" />
          </button>
        </div>
      </section>

      {/* Legal Section */}
      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <h3 className="mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground">
          Legal
        </h3>
        <Link
          to="/terms-and-policies"
          className="flex items-center justify-between w-full rounded-2xl border border-border/60 bg-background/50 px-4 py-3.5 text-sm font-semibold transition hover:bg-accent active:scale-[0.99]"
        >
          <span className="flex items-center gap-3">
            <FileText className="h-4 w-4 text-primary" />
            Terms &amp; Privacy Policy
          </span>
          <ChevronRight className="h-4 w-4 text-muted-foreground" />
        </Link>
      </section>

      {/* Account Management (Delete) Section */}
      <section className="rounded-3xl border border-border/60 bg-card p-5">
        <h3 className="mb-4 text-xs font-semibold uppercase tracking-wider text-muted-foreground text-destructive">
          Danger Zone
        </h3>
        <button
          onClick={() => setShowDeleteConfirm(true)}
          className="flex items-center justify-between w-full rounded-2xl border border-destructive/30 bg-destructive/5 hover:bg-destructive/10 px-4 py-3.5 text-sm font-bold text-destructive transition active:scale-[0.99]"
        >
          <span className="flex items-center gap-3">
            <Trash2 className="h-4 w-4" />
            Delete Account
          </span>
          <ChevronRight className="h-4 w-4" />
        </button>
      </section>

      {/* Basic Details Edit Modal */}
      {showEditDetails &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowEditDetails(false)}
          >
            <form
              onSubmit={saveEdit}
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Edit Details</h3>
                <button
                  type="button"
                  onClick={() => setShowEditDetails(false)}
                  className="rounded-full p-1 hover:bg-accent"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              <div className="flex flex-col gap-3 text-sm">
                <label className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Full Name
                  </span>
                  <input
                    value={editDraft.full_name}
                    onChange={(e) =>
                      setEditDraft((d) => ({ ...d, full_name: e.target.value }))
                    }
                    maxLength={80}
                    className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
                  />
                </label>
                <label className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Username
                  </span>
                  <input
                    value={editDraft.username}
                    onChange={(e) =>
                      setEditDraft((d) => ({ ...d, username: e.target.value }))
                    }
                    maxLength={24}
                    className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
                  />
                </label>
                <label className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Phone
                  </span>
                  <input
                    value={editDraft.phone}
                    onChange={(e) => setEditDraft((d) => ({ ...d, phone: e.target.value }))}
                    placeholder="+91 98765 43210"
                    maxLength={20}
                    className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
                  />
                </label>
                <label className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Gender
                  </span>
                  <select
                    value={editDraft.gender}
                    onChange={(e) => setEditDraft((d) => ({ ...d, gender: e.target.value }))}
                    className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
                  >
                    <option value="">Prefer not to say</option>
                    <option value="female">Female</option>
                    <option value="male">Male</option>
                    <option value="non-binary">Non-binary</option>
                    <option value="other">Other</option>
                  </select>
                </label>
                <div className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Verified Profile Location
                  </span>
                  <div className="flex items-center gap-2">
                    <div className="min-w-0 flex-1 truncate rounded-2xl border border-border/60 bg-secondary/50 px-3 py-2 text-muted-foreground">
                      {editDraft.city || "Location not set"}
                    </div>
                    <button
                      type="button"
                      onClick={handleFetchProfileGPS}
                      disabled={fetchingGps || savingEdit}
                      className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-primary text-primary-foreground transition active:scale-95 disabled:opacity-60"
                    >
                      {fetchingGps ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Navigation className="h-4 w-4" />
                      )}
                    </button>
                  </div>
                </div>
                <label className="flex flex-col gap-1">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">
                    Bio
                  </span>
                  <textarea
                    value={editDraft.bio}
                    onChange={(e) => setEditDraft((d) => ({ ...d, bio: e.target.value }))}
                    maxLength={200}
                    rows={3}
                    className="resize-none rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary"
                  />
                  <span className="text-right text-[10px] text-muted-foreground">
                    {editDraft.bio.length}/200
                  </span>
                </label>
              </div>
              <div className="mt-5 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowEditDetails(false)}
                  className="rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={savingEdit}
                  className="rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60"
                >
                  {savingEdit ? "Saving…" : "Save"}
                </button>
              </div>
            </form>
          </div>,
          document.body,
        )}

      {/* Blocked Users Modal */}
      {showBlockedModal &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowBlockedModal(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Blocked Users</h3>
                <button
                  type="button"
                  onClick={() => setShowBlockedModal(false)}
                  className="rounded-full p-1 hover:bg-accent"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              {blockedUsers.length === 0 ? (
                <p className="py-8 text-center text-sm text-muted-foreground">
                  You haven't blocked anyone yet.
                </p>
              ) : (
                <ul className="flex flex-col gap-2">
                  {blockedUsers.map((u) => (
                    <li
                      key={u.id}
                      className="flex items-center justify-between gap-3 rounded-2xl border border-border/60 bg-card p-3"
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <div className="h-10 w-10 shrink-0 overflow-hidden rounded-full bg-primary/15 text-primary flex items-center justify-center text-sm font-semibold">
                          {u.avatar_url ? (
                            <img src={u.avatar_url} alt="" className="h-full w-full object-cover" />
                          ) : (
                            (u.full_name || u.username || "U")[0]?.toUpperCase()
                          )}
                        </div>
                        <div className="min-w-0">
                          <p className="truncate text-sm font-semibold">
                            {u.full_name || u.username || "User"}
                          </p>
                          {u.username && (
                            <p className="truncate text-xs text-muted-foreground">
                              @{u.username}
                            </p>
                          )}
                        </div>
                      </div>
                      <button
                        onClick={() => unblockMut.mutate(u.id)}
                        disabled={unblockMut.isPending}
                        className="rounded-full border border-border/60 px-3 py-1 text-xs font-semibold transition hover:bg-accent disabled:opacity-50"
                      >
                        Unblock
                      </button>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>,
          document.body,
        )}

      {/* FAQ Modal */}
      {showFaq &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowFaq(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Frequently Asked Questions</h3>
                <button
                  onClick={() => setShowFaq(false)}
                  className="rounded-full p-1 hover:bg-accent"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              <div className="flex flex-col gap-3">
                {faqs.map((faq, i) => (
                  <div key={i} className="border-b border-border/60 pb-3">
                    <button
                      onClick={() => setOpenFaqIndex(openFaqIndex === i ? null : i)}
                      className="flex items-center justify-between w-full text-left font-semibold text-sm py-2 hover:text-primary transition"
                    >
                      <span>{faq.q}</span>
                      {openFaqIndex === i ? (
                        <ChevronDown className="h-4 w-4 transform rotate-180 transition-transform" />
                      ) : (
                        <ChevronDown className="h-4 w-4 transition-transform" />
                      )}
                    </button>
                    {openFaqIndex === i && (
                      <p className="mt-2 text-xs text-muted-foreground leading-relaxed">
                        {faq.a}
                      </p>
                    )}
                  </div>
                ))}
              </div>
              <div className="mt-6 text-center text-xs text-muted-foreground">
                Still have questions? Contact support below.
              </div>
            </div>
          </div>,
          document.body,
        )}

      {/* Report a Problem Modal */}
      {showReportModal &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowReportModal(false)}
          >
            <form
              onSubmit={handleReportSubmit}
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Report a Problem</h3>
                <button
                  type="button"
                  onClick={() => setShowReportModal(false)}
                  className="rounded-full p-1 hover:bg-accent"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              <p className="mb-3 text-xs text-muted-foreground leading-relaxed">
                Describe the problem you're facing. Our technical crew will look into it.
              </p>
              <textarea
                value={reportText}
                onChange={(e) => setReportText(e.target.value)}
                required
                rows={4}
                maxLength={500}
                placeholder="Steps to reproduce, error message, or description..."
                className="w-full resize-none rounded-2xl border border-border/60 bg-background p-3 text-sm outline-none focus:border-primary"
              />
              <div className="mt-5 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowReportModal(false)}
                  className="rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingReport}
                  className="rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60"
                >
                  {submittingReport ? "Submitting..." : "Submit Report"}
                </button>
              </div>
            </form>
          </div>,
          document.body,
        )}

      {/* Send Feedback Modal */}
      {showFeedbackModal &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowFeedbackModal(false)}
          >
            <form
              onSubmit={handleFeedbackSubmit}
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="mb-4 flex items-center justify-between">
                <h3 className="text-lg font-bold">Send Feedback</h3>
                <button
                  type="button"
                  onClick={() => setShowFeedbackModal(false)}
                  className="rounded-full p-1 hover:bg-accent"
                >
                  <X className="h-4 w-4" />
                </button>
              </div>
              <div className="mb-4 flex items-center justify-center gap-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    type="button"
                    onClick={() => setFeedbackRating(star)}
                    className="p-1 transition active:scale-125"
                  >
                    <svg
                      className={`h-8 w-8 ${
                        star <= feedbackRating
                          ? "fill-current text-primary"
                          : "text-muted-foreground"
                      }`}
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                    >
                      <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                    </svg>
                  </button>
                ))}
              </div>
              <textarea
                value={feedbackText}
                onChange={(e) => setFeedbackText(e.target.value)}
                rows={4}
                maxLength={500}
                placeholder="What do you love? What can we do better?"
                className="w-full resize-none rounded-2xl border border-border/60 bg-background p-3 text-sm outline-none focus:border-primary"
              />
              <div className="mt-5 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowFeedbackModal(false)}
                  className="rounded-full border border-border/60 px-4 py-2 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingFeedback}
                  className="rounded-full bg-primary px-5 py-2 text-sm font-semibold text-primary-foreground transition hover:scale-[1.02] active:scale-95 disabled:opacity-60"
                >
                  {submittingFeedback ? "Submitting..." : "Submit Feedback"}
                </button>
              </div>
            </form>
          </div>,
          document.body,
        )}

      {/* Account Deletion First Confirmation */}
      {showDeleteConfirm &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowDeleteConfirm(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="flex flex-col items-center gap-3 text-center">
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-destructive/15 text-destructive">
                  <ShieldAlert className="h-6 w-6" />
                </div>
                <h3 className="text-lg font-bold text-foreground">Delete your account?</h3>
                <p className="text-sm text-muted-foreground leading-relaxed">
                  This action is permanent and cannot be undone. All your hosted plans, active
                  chats, attendance check-ins, and personal profile settings will be permanently
                  purged.
                </p>
              </div>
              <div className="mt-6 flex flex-col gap-2">
                <button
                  onClick={() => {
                    setShowDeleteConfirm(false);
                    setShowDeleteFinal(true);
                  }}
                  className="w-full rounded-full bg-destructive py-2.5 text-sm font-semibold text-destructive-foreground transition hover:opacity-90 active:scale-95"
                >
                  Yes, Continue
                </button>
                <button
                  onClick={() => setShowDeleteConfirm(false)}
                  className="w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>,
          document.body,
        )}

      {/* Account Deletion Final Confirmation */}
      {showDeleteFinal &&
        typeof document !== "undefined" &&
        createPortal(
          <div
            className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
            onClick={() => setShowDeleteFinal(false)}
          >
            <div
              onClick={(e) => e.stopPropagation()}
              className="fixed left-1/2 top-1/2 z-[99999] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
            >
              <div className="flex flex-col items-center gap-3 text-center">
                <h3 className="text-lg font-bold text-destructive">Final Confirmation</h3>
                <p className="text-xs text-muted-foreground leading-relaxed">
                  To permanently delete your user profile and all associated data, type{" "}
                  <strong className="text-destructive font-bold">DELETE</strong> in the box
                  below.
                </p>
              </div>
              <div className="mt-4">
                <input
                  type="text"
                  placeholder="Type DELETE"
                  value={deleteInput}
                  onChange={(e) => setDeleteInput(e.target.value)}
                  className="w-full text-center rounded-2xl border border-destructive/40 bg-background px-3 py-2 text-sm outline-none focus:border-destructive"
                />
              </div>
              <div className="mt-6 flex flex-col gap-2">
                <button
                  onClick={handleDeleteFinalConfirm}
                  disabled={deleteAccountMut.isPending}
                  className="flex items-center justify-center gap-1.5 w-full rounded-full bg-destructive py-2.5 text-sm font-bold text-white transition active:scale-95 disabled:opacity-60"
                >
                  {deleteAccountMut.isPending ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" /> Deleting...
                    </>
                  ) : (
                    "Delete Permanently"
                  )}
                </button>
                <button
                  onClick={() => {
                    setShowDeleteFinal(false);
                    setDeleteInput("");
                  }}
                  disabled={deleteAccountMut.isPending}
                  className="w-full rounded-full border border-border/60 py-2.5 text-sm font-semibold transition hover:bg-accent"
                >
                  Cancel
                </button>
              </div>
            </div>
          </div>,
          document.body,
        )}
    </div>
  );
}
