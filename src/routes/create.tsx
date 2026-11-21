import { createFileRoute } from "@tanstack/react-router";
import { useRef, useState } from "react";
import { useNavigate } from "@tanstack/react-router";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { z } from "zod";
import { toast } from "sonner";
import { notifyMatchingUsersPush } from "@/lib/push.functions";
import { createActivity, uploadActivityImage } from "@/lib/services";
import { useAuth } from "@/hooks/use-auth";
import { PlaceSearch, type Place } from "@/components/place-search";
import { searchPlaces } from "@/lib/place-providers";
import { DEFAULT_LAT, DEFAULT_LON } from "@/lib/geo";
import { CATEGORIES, CATEGORY_GROUPS, CATEGORY_MAP, AMENITIES, type AmenityKey } from "@/lib/categories";
import {
  Calendar as CalendarIcon,
  MapPin,
  Users,
  Tag,
  ImageIcon,
  DollarSign,
  Clock,
  Type,
  AlignLeft,
  Check,
  X,
  Shield,
  BadgeCheck,
  MonitorSmartphone,
  Link as LinkIcon,
  Hash,
  Lock,
  ArrowLeft,
  ArrowRight,
  Eye,
} from "lucide-react";

export const Route = createFileRoute("/create")({
  head: () => ({
    meta: [
      { title: "Host a plan · tribeX" },
      { name: "description", content: "Post a plan and let your squad find you." },
    ],
  }),
  component: Create,
});

const planSchema = z.object({
  title: z
    .string()
    .trim()
    .min(4, { message: "Title must be at least 4 characters" })
    .max(80, { message: "Keep it under 80 characters" }),
  description: z
    .string()
    .trim()
    .min(10, { message: "Add a bit more detail (10+ chars)" })
    .max(500, { message: "Keep it under 500 characters" }),
  category: z.string().min(1, { message: "Pick a category" }),
  date: z.string().min(1, { message: "Pick a date" }),
  time: z.string().min(1, { message: "Pick a time" }),
  location: z
    .string()
    .trim()
    .max(120, { message: "Keep location under 120 characters" })
    .optional()
    .default(""),
  is_online: z.boolean(),
  meeting_link: z
    .string()
    .trim()
    .max(500, { message: "Link is too long" })
    .optional()
    .default(""),
  slots: z
    .number({ message: "Slots is required" })
    .int({ message: "Whole numbers only" })
    .gt(0, { message: "Slots must be greater than 0" })
    .max(50, { message: "Max 50 slots" }),
  cost: z
    .number({ message: "Cost is required" })
    .min(0, { message: "Cost cannot be negative" })
    .max(100000, { message: "That looks too high" }),
  topic_tags: z.string().trim().max(120).optional().default(""),
}).superRefine((val, ctx) => {
  if (val.is_online) {
    const url = val.meeting_link ?? "";
    if (!/^https?:\/\/\S+$/i.test(url)) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["meeting_link"],
        message: "Add a valid meeting URL (Meet, Discord, Zoom…)",
      });
    }
  } else {
    if ((val.location ?? "").trim().length < 3) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        path: ["location"],
        message: "Add a venue or area (at least 3 characters)",
      });
    }
  }
});

type PlanForm = {
  title: string;
  description: string;
  category: string;
  date: string;
  time: string;
  location: string;
  slots: string;
  cost: string;
  is_online: boolean;
  meeting_link: string;
  topic_tags: string;
};

type FieldErrors = Partial<Record<keyof PlanForm, string>>;

const empty: PlanForm = {
  title: "",
  description: "",
  category: "",
  date: "",
  time: "",
  location: "",
  slots: "8",
  cost: "0",
  is_online: false,
  meeting_link: "",
  topic_tags: "",
};

const STEP_TITLES = ["What & when", "Where & who", "Details & preview"];

function Create() {
  const { user, loading } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();
  const [currentStep, setCurrentStep] = useState<number>(0);
  const [form, setForm] = useState<PlanForm>(empty);
  const [errors, setErrors] = useState<FieldErrors>({});
  const fileRef = useRef<HTMLInputElement>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [uploading, setUploading] = useState(false);
  const [pinnedPlace, setPinnedPlace] = useState<Place | null>(null);
  const [womenOnly, setWomenOnly] = useState(false);
  const [verifiedOnly, setVerifiedOnly] = useState(false);
  const [amenities, setAmenities] = useState<AmenityKey[]>([]);
  const [groupFilter, setGroupFilter] = useState<string>("Sports & Outdoor");

  const mutation = useMutation({
    mutationFn: createActivity,
    onSuccess: (created) => {
      qc.invalidateQueries({ queryKey: ["activities"] });
      qc.invalidateQueries({ queryKey: ["user-activities", user?.id] });
      qc.invalidateQueries({ queryKey: ["user-stats", user?.id] });
      qc.invalidateQueries({ queryKey: ["chats", user?.id] });
      qc.invalidateQueries({ queryKey: ["profile", user?.id] });
      setForm(empty);
      setErrors({});
      setImageFile(null);
      setImagePreview(null);
      setCurrentStep(0);
      toast.success("Plan published — your squad will find you.");
      if (created?.id) {
        notifyMatchingUsersPush({ data: { activityId: created.id } }).catch(
          (e) => console.warn("[push] dispatch failed", e),
        );
      }
      navigate({ to: "/" });
    },
    onError: (e: Error) => toast.error(e.message),
  });

  const set = <K extends keyof PlanForm>(key: K, value: PlanForm[K]) => {
    setForm((f) => ({ ...f, [key]: value }));
    if (errors[key]) setErrors((e) => ({ ...e, [key]: undefined }));
  };

  function toggleAmenity(key: AmenityKey) {
    setAmenities((prev) => (prev.includes(key) ? prev.filter((k) => k !== key) : [...prev, key]));
  }

  const selectedCategoryDef = form.category ? CATEGORY_MAP[form.category] : null;
  const isIndoorCategory =
    selectedCategoryDef?.group === "Education & Skills" ||
    selectedCategoryDef?.group === "Tech & Creative";

  function onPickImage(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (!file.type.startsWith("image/")) { toast.error("Pick an image file"); return; }
    if (file.size > 5 * 1024 * 1024) { toast.error("Image must be under 5MB"); return; }
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
  }

  function clearImage() {
    if (imagePreview) URL.revokeObjectURL(imagePreview);
    setImageFile(null);
    setImagePreview(null);
  }

  function validateStep1(): boolean {
    const errs: FieldErrors = {};
    if (!form.category) errs.category = "Please select a category";
    if (form.title.trim().length < 4) errs.title = "Title must be at least 4 characters";
    if (form.description.trim().length < 10) errs.description = "Add a bit more detail (10+ characters)";
    if (!form.date) errs.date = "Pick a date";
    if (!form.time) errs.time = "Pick a time";

    setErrors(errs);
    if (Object.keys(errs).length > 0) {
      toast.error("Please fill in the required fields to continue");
      return false;
    }
    return true;
  }

  function validateStep2(): boolean {
    const errs: FieldErrors = {};
    const slotsNum = Number(form.slots);
    if (isNaN(slotsNum) || slotsNum < 1 || slotsNum > 50) {
      errs.slots = "Slots must be between 1 and 50";
    }

    if (form.is_online) {
      const link = form.meeting_link.trim();
      if (!link) {
        errs.meeting_link = "Meeting link is required for virtual plans";
      } else if (!/^https?:\/\/\S+$/i.test(link)) {
        errs.meeting_link = "Enter a valid URL (https://...)";
      }
    } else {
      if (form.location.trim().length < 3) {
        errs.location = "Add a venue or area (at least 3 characters)";
      }
    }

    setErrors(errs);
    if (Object.keys(errs).length > 0) {
      toast.error("Please fix the highlighted fields to continue");
      return false;
    }
    return true;
  }

  const onSubmit = async () => {
    if (!user) { navigate({ to: "/auth" }); return; }
    if (!validateStep1()) { setCurrentStep(0); return; }
    if (!validateStep2()) { setCurrentStep(1); return; }

    const parsed = planSchema.safeParse({
      ...form,
      slots: Number(form.slots),
      cost: Number(form.cost),
    });
    if (!parsed.success) {
      const fieldErrors: FieldErrors = {};
      for (const issue of parsed.error.issues) {
        const key = issue.path[0] as keyof PlanForm;
        if (!fieldErrors[key]) fieldErrors[key] = issue.message;
      }
      setErrors(fieldErrors);
      toast.error("Please fix the highlighted fields");
      return;
    }

    const p = parsed.data;
    const cleanTags = p.topic_tags
      ? p.topic_tags
          .split(",")
          .map((t) => t.trim())
          .filter(Boolean)
          .slice(0, 8)
      : [];

    let image_url: string | null = null;
    if (imageFile) {
      setUploading(true);
      try {
        image_url = await uploadActivityImage(user.id, imageFile);
      } catch (err) {
        setUploading(false);
        toast.error(err instanceof Error ? err.message : "Couldn't upload photo");
        return;
      }
      setUploading(false);
    }
    const safeTime = p.time.length === 5 ? `${p.time}:00` : p.time;

    let finalLat: number | null = null;
    let finalLon: number | null = null;

    if (!p.is_online) {
      if (pinnedPlace?.lat != null && pinnedPlace?.lon != null) {
        finalLat = pinnedPlace.lat;
        finalLon = pinnedPlace.lon;
      } else if (p.location.trim()) {
        try {
          const geocoded = await searchPlaces(p.location.trim());
          if (geocoded.length > 0) {
            finalLat = geocoded[0].lat;
            finalLon = geocoded[0].lon;
          }
        } catch {
          // fallback
        }
      }
      if (finalLat == null || finalLon == null) {
        finalLat = DEFAULT_LAT;
        finalLon = DEFAULT_LON;
      }
    }

    mutation.mutate({
      title: p.title,
      description: p.description,
      category: p.category,
      date_time: new Date(`${p.date}T${safeTime}`).toISOString(),
      location: p.is_online ? (p.location.trim() || "Online") : p.location,
      total_slots: p.slots,
      cost_per_head: p.cost,
      image_url: image_url ?? "https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=800&auto=format&fit=crop&q=80",
      latitude: p.is_online ? null : finalLat,
      longitude: p.is_online ? null : finalLon,
      women_only: womenOnly,
      verified_only: verifiedOnly,
      is_online: p.is_online,
      meeting_link: p.is_online ? p.meeting_link.trim() : null,
      amenities: p.is_online ? [] : amenities,
      topic_tags: cleanTags,
    });
  };

  if (!loading && !user) {
    return (
      <div className="page-in flex flex-col items-start gap-4 px-5 pt-8">
        <h1 className="text-2xl font-bold tracking-tight">Sign in to host a plan</h1>
        <p className="text-sm text-muted-foreground">Create a free account so your squad can find and join your plans.</p>
        <button onClick={() => navigate({ to: "/auth" })} className="rounded-2xl bg-primary px-5 py-3 text-sm font-semibold text-primary-foreground">
          Continue
        </button>
      </div>
    );
  }

  return (
    <div className="page-in flex flex-col gap-5 px-5 pt-6 pb-28">
      {/* Step Header matching Android CreatePlanScreen */}
      <header>
        <h1 className="text-2xl font-bold tracking-tight">Host a plan</h1>
        <p className="mt-1 text-xs font-medium text-muted-foreground">
          Step {currentStep + 1} of 3 · {STEP_TITLES[currentStep]}
        </p>
        <div className="mt-3 flex items-center gap-1.5">
          {STEP_TITLES.map((_, idx) => {
            const isCompleted = idx < currentStep;
            const isCurrent = idx === currentStep;
            return (
              <div
                key={idx}
                className={`h-1.5 flex-1 rounded-full transition-all duration-300 ${
                  isCurrent
                    ? "bg-primary"
                    : isCompleted
                      ? "bg-primary/50"
                      : "bg-secondary"
                }`}
              />
            );
          })}
        </div>
      </header>

      {/* STEP 0: What & when */}
      {currentStep === 0 && (
        <div className="flex flex-col gap-4 animate-in fade-in duration-200">
          <div>
            <Label icon={<Tag className="h-3.5 w-3.5" />}>Select Category</Label>
            <div className="-mx-5 mt-2 flex gap-1.5 overflow-x-auto px-5 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {CATEGORY_GROUPS.map((g) => (
                <button
                  type="button"
                  key={g}
                  onClick={() => setGroupFilter(g)}
                  className={`shrink-0 rounded-full border px-3 py-1 text-[11px] font-semibold uppercase tracking-wider transition ${
                    groupFilter === g
                      ? "border-primary/60 bg-primary/10 text-primary"
                      : "border-border/60 bg-card text-muted-foreground"
                  }`}
                >
                  {g}
                </button>
              ))}
            </div>
            <div className="-mx-5 mt-2 flex gap-2 overflow-x-auto px-5 pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {CATEGORIES.filter((c) => c.group === groupFilter).map((c) => {
                const active = form.category === c.key;
                const Icon = c.icon;
                return (
                  <button
                    type="button"
                    key={c.key}
                    onClick={() => {
                      set("category", c.key);
                      if (c.defaultMode === "online" && !form.is_online) set("is_online", true);
                      if (c.defaultMode === "in_person" && form.is_online) set("is_online", false);
                    }}
                    className={`flex shrink-0 items-center gap-1.5 rounded-full border px-3.5 py-2 text-xs font-medium transition ${
                      active
                        ? "border-primary bg-primary text-primary-foreground"
                        : "border-border/60 bg-card text-muted-foreground hover:border-primary/50"
                    }`}
                  >
                    <Icon className="h-3.5 w-3.5" />
                    {c.label}
                  </button>
                );
              })}
            </div>
            {errors.category && (
              <p className="mt-1.5 text-[11px] font-medium text-destructive">{errors.category}</p>
            )}
          </div>

          <Field
            label="Plan Title"
            icon={<Type className="h-3.5 w-3.5" />}
            error={errors.title}
            hint={`${form.title.length}/80`}
          >
            <input
              value={form.title}
              onChange={(e) => set("title", e.target.value)}
              maxLength={80}
              placeholder="e.g. Weekend Box Cricket Turf Match"
              className="w-full bg-transparent text-sm font-medium outline-none placeholder:text-muted-foreground"
            />
          </Field>

          <Field
            label="Description"
            icon={<AlignLeft className="h-3.5 w-3.5" />}
            error={errors.description}
            hint={`${form.description.length}/500`}
          >
            <textarea
              value={form.description}
              onChange={(e) => set("description", e.target.value)}
              maxLength={500}
              rows={3}
              placeholder="Tell attendees what to expect, skill level, what to bring, etc."
              className="w-full resize-none bg-transparent text-xs outline-none placeholder:text-muted-foreground"
            />
          </Field>

          <div className="grid grid-cols-2 gap-3">
            <Field label="Date" icon={<CalendarIcon className="h-3.5 w-3.5" />} error={errors.date}>
              <input
                type="date"
                value={form.date}
                onChange={(e) => set("date", e.target.value)}
                className="w-full bg-transparent text-xs outline-none [color-scheme:light] dark:[color-scheme:dark]"
              />
            </Field>
            <Field label="Time" icon={<Clock className="h-3.5 w-3.5" />} error={errors.time}>
              <input
                type="time"
                value={form.time}
                onChange={(e) => set("time", e.target.value)}
                className="w-full bg-transparent text-xs outline-none [color-scheme:light] dark:[color-scheme:dark]"
              />
            </Field>
          </div>

          <div>
            <Label icon={<ImageIcon className="h-3.5 w-3.5" />}>Cover Photo (Optional)</Label>
            <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onPickImage} />
            {imagePreview ? (
              <div className="relative mt-2 overflow-hidden rounded-2xl border border-border/60">
                <img src={imagePreview} alt="Cover preview" className="h-40 w-full object-cover" />
                <button
                  type="button"
                  onClick={clearImage}
                  className="absolute right-2 top-2 flex h-7 w-7 items-center justify-center rounded-full bg-background/90 shadow transition hover:scale-105 active:scale-95"
                  aria-label="Remove photo"
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </div>
            ) : (
              <button
                type="button"
                onClick={() => fileRef.current?.click()}
                className="mt-2 flex h-28 w-full items-center justify-center rounded-2xl border border-dashed border-border bg-card/50 text-muted-foreground transition hover:border-primary/60 hover:text-primary active:scale-[0.99]"
              >
                <div className="flex flex-col items-center gap-1 text-xs">
                  <ImageIcon className="h-5 w-5" />
                  <span>Tap to choose cover image</span>
                </div>
              </button>
            )}
          </div>
        </div>
      )}

      {/* STEP 1: Where & who */}
      {currentStep === 1 && (
        <div className="flex flex-col gap-4 animate-in fade-in duration-200">
          <div>
            <Label icon={<MonitorSmartphone className="h-3.5 w-3.5" />}>Format</Label>
            <div className="mt-2 grid grid-cols-2 gap-2">
              {[
                { on: false, emoji: "📍", label: "In-Person Venue" },
                { on: true, emoji: "💻", label: "Online / Virtual" },
              ].map((opt) => {
                const active = form.is_online === opt.on;
                return (
                  <button
                    type="button"
                    key={opt.label}
                    onClick={() => set("is_online", opt.on)}
                    className={`flex items-center justify-center gap-2 rounded-2xl border px-3 py-3 text-xs font-semibold transition ${
                      active
                        ? "border-primary bg-primary/10 text-primary"
                        : "border-border/60 bg-card text-muted-foreground hover:border-primary/40"
                    }`}
                  >
                    <span className="text-base leading-none">{opt.emoji}</span>
                    {opt.label}
                  </button>
                );
              })}
            </div>
          </div>

          {form.is_online ? (
            <>
              <Field
                label="Meeting URL"
                icon={<LinkIcon className="h-3.5 w-3.5" />}
                error={errors.meeting_link}
                hint="Google Meet, Discord, Zoom…"
              >
                <input
                  type="url"
                  value={form.meeting_link}
                  onChange={(e) => set("meeting_link", e.target.value)}
                  maxLength={500}
                  placeholder="https://meet.google.com/xyz-abcd-efg"
                  className="w-full bg-transparent text-xs outline-none placeholder:text-muted-foreground"
                />
              </Field>
              <p className="-mt-2 flex items-center gap-1.5 text-[11px] text-muted-foreground">
                <Lock className="h-3 w-3 text-primary shrink-0" />
                <span>Link is securely hidden until you approve attendee join requests.</span>
              </p>
            </>
          ) : (
            <>
              <Field label="Venue Location" icon={<MapPin className="h-3.5 w-3.5" />} error={errors.location}>
                <input
                  value={form.location}
                  onChange={(e) => set("location", e.target.value)}
                  maxLength={120}
                  placeholder={isIndoorCategory ? "Third Wave Coffee, Indiranagar" : "Turf Arena, Indiranagar"}
                  className="w-full bg-transparent text-xs outline-none placeholder:text-muted-foreground"
                />
              </Field>
              <div className="-mt-2 flex items-center justify-between gap-2 rounded-2xl border border-dashed border-border/60 bg-card/40 px-3 py-2 text-[11px]">
                <div className="min-w-0 flex-1">
                  <p className="font-semibold uppercase tracking-wider text-muted-foreground">Pin venue on map</p>
                  {pinnedPlace ? (
                    <p className="mt-0.5 truncate text-foreground font-medium">
                      📍 {pinnedPlace.short} ({pinnedPlace.lat.toFixed(3)}, {pinnedPlace.lon.toFixed(3)})
                    </p>
                  ) : (
                    <p className="mt-0.5 text-muted-foreground">Enables 15 km hyper-local discovery and GPS check-in.</p>
                  )}
                </div>
                <PlaceSearch
                  value={pinnedPlace?.short ?? ""}
                  onSelect={(p) => {
                    setPinnedPlace(p);
                    if (!form.location.trim()) set("location", p.short);
                  }}
                  variant="chip"
                />
              </div>
            </>
          )}

          <Field label="Available Squad Slots" icon={<Users className="h-3.5 w-3.5" />} error={errors.slots} hint="Max 50">
            <input
              type="number"
              inputMode="numeric"
              min={1}
              max={50}
              value={form.slots}
              onChange={(e) => set("slots", e.target.value)}
              className="w-full bg-transparent text-sm font-semibold outline-none"
            />
          </Field>
        </div>
      )}

      {/* STEP 2: Details & preview */}
      {currentStep === 2 && (
        <div className="flex flex-col gap-4 animate-in fade-in duration-200">
          <Field label="Cost per Attendee" icon={<DollarSign className="h-3.5 w-3.5" />} error={errors.cost} hint="0 for free plans">
            <div className="flex items-center gap-1.5">
              <span className="text-sm font-semibold text-muted-foreground">₹</span>
              <input
                type="number"
                inputMode="decimal"
                min={0}
                value={form.cost}
                onChange={(e) => set("cost", e.target.value)}
                className="w-full bg-transparent text-sm font-semibold outline-none"
              />
            </div>
          </Field>

          <Field
            label="Topic & Interest Tags"
            icon={<Hash className="h-3.5 w-3.5" />}
            hint="Comma separated"
          >
            <input
              value={form.topic_tags}
              onChange={(e) => set("topic_tags", e.target.value)}
              maxLength={120}
              placeholder="e.g. Beginners welcome, casual, weekend"
              className="w-full bg-transparent text-xs outline-none placeholder:text-muted-foreground"
            />
          </Field>

          {!form.is_online && (
            <div>
              <Label icon={<Check className="h-3.5 w-3.5" />}>Venue Amenities</Label>
              <div className="mt-2 flex flex-wrap gap-1.5">
                {AMENITIES.map((a) => {
                  const active = amenities.includes(a.key);
                  const Icon = a.icon;
                  return (
                    <button
                      key={a.key}
                      type="button"
                      onClick={() => toggleAmenity(a.key)}
                      className={`flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                        active
                          ? "border-primary bg-primary/10 text-primary"
                          : "border-border/60 bg-card text-muted-foreground"
                      }`}
                    >
                      <Icon className="h-3.5 w-3.5" />
                      {a.label}
                    </button>
                  );
                })}
              </div>
            </div>
          )}

          <div className="rounded-2xl border border-border/60 bg-card/50 p-3.5">
            <p className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
              <Shield className="h-3.5 w-3.5 text-primary" /> Safety & Audience
            </p>
            <div className="mt-3 flex flex-col gap-2">
              <SafetyToggle
                icon={<span className="text-base leading-none">♀︎</span>}
                label="Women-only plan"
                hint="Visible and joinable only by female members."
                checked={womenOnly}
                onChange={setWomenOnly}
              />
              <SafetyToggle
                icon={<BadgeCheck className="h-3.5 w-3.5" />}
                label="Verified users only"
                hint="Requires attendees to have completed verification."
                checked={verifiedOnly}
                onChange={setVerifiedOnly}
              />
            </div>
          </div>

          {/* Live Card Preview matching Android CreatePlanScreen Step 3 */}
          <div>
            <div className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground mb-2">
              <Eye className="h-3.5 w-3.5 text-primary" /> Feed Card Preview
            </div>
            <div className="overflow-hidden rounded-2xl border border-border/60 bg-card p-4 shadow-sm">
              <div className="flex items-start justify-between gap-2">
                <span className="rounded-full bg-primary/15 px-2.5 py-0.5 text-[10px] font-bold text-primary">
                  {form.category || "General"}
                </span>
                <span className="text-xs font-bold text-foreground">
                  {Number(form.cost) > 0 ? `₹${form.cost}` : "Free"}
                </span>
              </div>
              <h3 className="mt-2 text-sm font-bold line-clamp-1">{form.title || "Your Plan Title"}</h3>
              <p className="mt-1 text-xs text-muted-foreground line-clamp-2">
                {form.description || "Plan description preview..."}
              </p>
              <div className="mt-3 flex items-center justify-between border-t border-border/60 pt-2 text-[11px] text-muted-foreground">
                <span className="flex items-center gap-1">
                  <MapPin className="h-3 w-3" /> {form.is_online ? "Online event" : form.location || "Venue"}
                </span>
                <span className="flex items-center gap-1 font-semibold">
                  <Users className="h-3 w-3" /> {form.slots} spots
                </span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Fixed Bottom Wizard Navigation matching Android CreatePlanScreen */}
      <footer className="fixed inset-x-0 bottom-0 z-40 border-t border-border/60 bg-card/95 backdrop-blur-md px-5 py-3">
        <div className="mx-auto flex max-w-md items-center justify-between gap-3">
          {currentStep > 0 ? (
            <button
              type="button"
              disabled={mutation.isPending || uploading}
              onClick={() => setCurrentStep((s) => s - 1)}
              className="flex items-center gap-1.5 rounded-full border border-border/60 px-4 py-2.5 text-xs font-semibold hover:bg-accent transition active:scale-95 disabled:opacity-50"
            >
              <ArrowLeft className="h-3.5 w-3.5" /> Back
            </button>
          ) : (
            <div />
          )}

          {currentStep < 2 ? (
            <button
              type="button"
              onClick={() => {
                if (currentStep === 0 && validateStep1()) {
                  setCurrentStep(1);
                } else if (currentStep === 1 && validateStep2()) {
                  setCurrentStep(2);
                }
              }}
              className="flex items-center gap-1.5 rounded-full bg-primary px-6 py-2.5 text-xs font-semibold text-primary-foreground hover:scale-105 active:scale-95 transition"
            >
              Continue <ArrowRight className="h-3.5 w-3.5" />
            </button>
          ) : (
            <button
              type="button"
              disabled={mutation.isPending || uploading}
              onClick={onSubmit}
              className="flex items-center gap-1.5 rounded-full bg-primary px-6 py-2.5 text-xs font-semibold text-primary-foreground hover:scale-105 active:scale-95 transition disabled:opacity-50"
            >
              <Check className="h-3.5 w-3.5" />
              {uploading ? "Uploading photo…" : mutation.isPending ? "Publishing…" : "Publish plan"}
            </button>
          )}
        </div>
      </footer>
    </div>
  );
}

function SafetyToggle({
  icon,
  label,
  hint,
  checked,
  onChange,
}: {
  icon: React.ReactNode;
  label: string;
  hint: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="flex items-center gap-3 rounded-xl bg-background/60 px-3 py-2 select-none">
      <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary">
        {icon}
      </span>
      <span className="min-w-0 flex-1">
        <span className="block text-xs font-semibold">{label}</span>
        <span className="block text-[10px] text-muted-foreground">{hint}</span>
      </span>
      <button
        type="button"
        role="switch"
        aria-checked={checked}
        aria-label={label}
        onClick={() => onChange(!checked)}
        className={`relative inline-flex h-5 w-10 shrink-0 items-center rounded-full transition ${checked ? "bg-primary" : "bg-secondary"}`}
      >
        <span className={`inline-block h-4 w-4 rounded-full bg-background shadow transition ${checked ? "translate-x-5" : "translate-x-0.5"}`} />
      </button>
    </div>
  );
}

function Label({ children, icon }: { children: React.ReactNode; icon?: React.ReactNode }) {
  return (
    <div className="flex items-center gap-1.5 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
      {icon}
      {children}
    </div>
  );
}

function Field({
  label,
  icon,
  error,
  hint,
  children,
}: {
  label: string;
  icon?: React.ReactNode;
  error?: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <div
        className={`rounded-2xl border bg-card px-4 py-3 transition ${
          error ? "border-destructive/60" : "border-border/60"
        }`}
      >
        <div className="flex items-center justify-between">
          <Label icon={icon}>{label}</Label>
          {hint && <span className="text-[10px] text-muted-foreground">{hint}</span>}
        </div>
        <div className="mt-1.5">{children}</div>
      </div>
      {error && (
        <p className="mt-1.5 pl-1 text-[11px] font-medium text-destructive">{error}</p>
      )}
    </div>
  );
}
