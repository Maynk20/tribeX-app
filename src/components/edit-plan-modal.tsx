import { useEffect, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { X, Check, ImageIcon, Trash2, Lock, Link as LinkIcon } from "lucide-react";
import { toast } from "sonner";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { z } from "zod";
import { updateActivity, uploadActivityImage, type Activity } from "@/lib/services";
import { useAuth } from "@/hooks/use-auth";
import { friendlyError } from "@/lib/friendly-error";
import { CATEGORIES, CATEGORY_GROUPS, AMENITIES, type AmenityKey } from "@/lib/categories";

const schema = z.object({
  title: z.string().trim().min(4).max(80),
  description: z.string().trim().min(10).max(500),
  category: z.string().min(1),
  date: z.string().min(1),
  time: z.string().min(1),
  location: z.string().trim().max(120).optional().default(""),
  is_online: z.boolean(),
  meeting_link: z.string().trim().max(500).optional().default(""),
  slots: z.number().int().gt(0).max(50),
  cost: z.number().min(0).max(100000),
  topic_tags: z.string().trim().max(120).optional().default(""),
}).superRefine((val, ctx) => {
  if (val.is_online) {
    if (!/^https?:\/\/\S+$/i.test(val.meeting_link ?? "")) {
      ctx.addIssue({ code: z.ZodIssueCode.custom, path: ["meeting_link"], message: "Add a valid meeting URL" });
    }
  } else if ((val.location ?? "").trim().length < 3) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, path: ["location"], message: "Add a venue or area" });
  }
});

function toLocalDateTime(iso: string) {
  const d = new Date(iso);
  const pad = (n: number) => String(n).padStart(2, "0");
  return {
    date: `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`,
    time: `${pad(d.getHours())}:${pad(d.getMinutes())}`,
  };
}

export function EditPlanModal({
  activity,
  open,
  onClose,
}: {
  activity: Activity | null;
  open: boolean;
  onClose: () => void;
}) {
  const { user } = useAuth();
  const qc = useQueryClient();
  const fileRef = useRef<HTMLInputElement>(null);
  const [form, setForm] = useState({
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
  });
  const [amenities, setAmenities] = useState<AmenityKey[]>([]);
  const [groupFilter, setGroupFilter] = useState<string>("Sports & Outdoor");
  const [existingImage, setExistingImage] = useState<string | null>(null);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [imagePreview, setImagePreview] = useState<string | null>(null);
  const [imageCleared, setImageCleared] = useState(false);
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    if (!activity) return;
    const { date, time } = toLocalDateTime(activity.date_time);
    setForm({
      title: activity.title,
      description: activity.description,
      category: activity.category,
      date,
      time,
      location: activity.location,
      slots: String(activity.total_slots),
      cost: String(activity.cost_per_head),
      is_online: !!activity.is_online,
      meeting_link: activity.meeting_link ?? "",
      topic_tags: (activity.topic_tags ?? []).join(", "),
    });
    setAmenities(((activity.amenities ?? []) as AmenityKey[]));
    const g = CATEGORIES.find((c) => c.key === activity.category)?.group;
    if (g) setGroupFilter(g);
    setExistingImage(activity.image_url ?? null);
    setImageFile(null);
    setImagePreview(null);
    setImageCleared(false);
    // Only reset the form when the modal opens for a *different* plan.
    // Depending on `activity` reference re-runs whenever React Query refetches
    // that same row in the background, wiping the user's in-progress edits.
  }, [activity?.id]);

  const mutation = useMutation({
    mutationFn: async () => {
      if (!activity) throw new Error("No plan selected");
      const parsed = schema.safeParse({
        ...form,
        slots: Number(form.slots),
        cost: Number(form.cost),
      });
      if (!parsed.success) throw new Error(parsed.error.issues[0]?.message ?? "Invalid input");
      const p = parsed.data;
      const cleanTags = p.topic_tags
        ? p.topic_tags.split(",").map((t) => t.trim()).filter(Boolean).slice(0, 8)
        : [];
      let image_url: string | null | undefined = undefined;
      if (imageCleared && !imageFile) image_url = null;
      if (imageFile && user) {
        setUploading(true);
        try {
          image_url = await uploadActivityImage(user.id, imageFile);
        } finally {
          setUploading(false);
        }
      }
      return updateActivity(activity.id, {
        title: p.title,
        description: p.description,
        category: p.category,
        date_time: new Date(`${p.date}T${p.time}`).toISOString(),
        location: p.is_online ? (p.location.trim() || "Online") : p.location,
        total_slots: p.slots,
        cost_per_head: p.cost,
        is_online: p.is_online,
        meeting_link: p.is_online ? p.meeting_link.trim() : null,
        amenities: p.is_online ? [] : amenities,
        topic_tags: cleanTags,
        ...(image_url !== undefined ? { image_url } : {}),
      });
    },
    onSuccess: async () => {
      await Promise.all([
        qc.invalidateQueries({ queryKey: ["activities"] }),
        qc.invalidateQueries({ queryKey: ["user-activities", user?.id] }),
        qc.invalidateQueries({ queryKey: ["user-stats", user?.id] }),
        qc.invalidateQueries({ queryKey: ["chats", user?.id] }),
        qc.invalidateQueries({ queryKey: ["profile", user?.id] }),
      ]);
      toast.success("Plan updated");
      onClose();
    },
    onError: (e: unknown) => {
      console.error("[edit-plan] update failed", e);
      toast.error(friendlyError(e, "Couldn't update plan. Please try again."));
    },
  });

  function onPickImage(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    e.target.value = "";
    if (!file) return;
    if (!file.type.startsWith("image/")) { toast.error("Pick an image file"); return; }
    if (file.size > 5 * 1024 * 1024) { toast.error("Image must be under 5MB"); return; }
    if (imagePreview) URL.revokeObjectURL(imagePreview);
    setImageFile(file);
    setImagePreview(URL.createObjectURL(file));
    setImageCleared(false);
  }

  function clearImage() {
    if (imagePreview) URL.revokeObjectURL(imagePreview);
    setImageFile(null);
    setImagePreview(null);
    setImageCleared(true);
  }

  if (!open || !activity) return null;

  const showImage = imagePreview || (!imageCleared && existingImage);

  if (typeof document === "undefined") return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm"
      onClick={onClose}
    >
      <form
        onSubmit={(e) => { e.preventDefault(); mutation.mutate(); }}
        onClick={(e) => e.stopPropagation()}
        className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-md -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-border/60 bg-background p-6 shadow-2xl"
      >
        <div className="mb-4 flex items-center justify-between">
          <h3 className="text-lg font-bold">Edit plan</h3>
          <button type="button" onClick={onClose} className="rounded-full p-1 hover:bg-accent" aria-label="Close">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="flex flex-col gap-3 text-sm">
          <input ref={fileRef} type="file" accept="image/*" className="hidden" onChange={onPickImage} />
          {showImage ? (
            <div className="relative overflow-hidden rounded-2xl border border-border/60">
              <img src={imagePreview ?? existingImage ?? ""} alt="" className="h-40 w-full object-cover" />
              <button type="button" onClick={clearImage} className="absolute right-2 top-2 flex h-8 w-8 items-center justify-center rounded-full bg-background/90 shadow" aria-label="Remove photo">
                <Trash2 className="h-3.5 w-3.5" />
              </button>
              <button type="button" onClick={() => fileRef.current?.click()} className="absolute bottom-2 right-2 rounded-full bg-background/90 px-3 py-1 text-xs font-semibold shadow">
                Replace
              </button>
            </div>
          ) : (
            <button type="button" onClick={() => fileRef.current?.click()} className="flex h-28 w-full items-center justify-center gap-2 rounded-2xl border border-dashed border-border bg-background text-xs text-muted-foreground transition hover:border-primary/60 hover:text-primary">
              <ImageIcon className="h-4 w-4" /> Add cover photo
            </button>
          )}

          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Title</span>
            <input value={form.title} maxLength={80} onChange={(e) => setForm({ ...form, title: e.target.value })} className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
          </label>

          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Description</span>
            <textarea value={form.description} maxLength={500} rows={3} onChange={(e) => setForm({ ...form, description: e.target.value })} className="resize-none rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
          </label>

          <div className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Category</span>
            <div className="flex gap-1.5 overflow-x-auto pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {CATEGORY_GROUPS.map((g) => (
                <button
                  key={g}
                  type="button"
                  onClick={() => setGroupFilter(g)}
                  className={`shrink-0 rounded-full border px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wider transition ${
                    groupFilter === g
                      ? "border-primary/60 bg-primary/10 text-primary"
                      : "border-border/60 bg-background text-muted-foreground"
                  }`}
                >
                  {g}
                </button>
              ))}
            </div>
            <div className="flex flex-wrap gap-2">
              {CATEGORIES.filter((c) => c.group === groupFilter).map((c) => {
                const Icon = c.icon;
                const active = form.category === c.key;
                return (
                  <button
                    key={c.key}
                    type="button"
                    onClick={() => setForm({ ...form, category: c.key })}
                    className={`flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${active ? "border-primary bg-primary text-primary-foreground" : "border-border/60 bg-background text-muted-foreground"}`}
                  >
                    <Icon className="h-3.5 w-3.5" />
                    {c.label}
                  </button>
                );
              })}
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <label className="flex flex-col gap-1">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Date</span>
              <input type="date" value={form.date} onChange={(e) => setForm({ ...form, date: e.target.value })} className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary [color-scheme:light] dark:[color-scheme:dark]" />
            </label>
            <label className="flex flex-col gap-1">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Time</span>
              <input type="time" value={form.time} onChange={(e) => setForm({ ...form, time: e.target.value })} className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary [color-scheme:light] dark:[color-scheme:dark]" />
            </label>
          </div>

          <div className="grid grid-cols-2 gap-2">
            {[
              { on: false, emoji: "📍", label: "In-Person" },
              { on: true, emoji: "💻", label: "Online" },
            ].map((opt) => {
              const active = form.is_online === opt.on;
              return (
                <button
                  key={opt.label}
                  type="button"
                  onClick={() => setForm({ ...form, is_online: opt.on })}
                  className={`flex items-center justify-center gap-1.5 rounded-2xl border px-2 py-2 text-xs font-semibold transition ${active ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-background text-muted-foreground"}`}
                >
                  <span>{opt.emoji}</span> {opt.label}
                </button>
              );
            })}
          </div>

          {form.is_online ? (
            <>
              <label className="flex flex-col gap-1">
                <span className="flex items-center gap-1 text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">
                  <LinkIcon className="h-3 w-3" /> Meeting link
                </span>
                <input type="url" value={form.meeting_link} maxLength={500} onChange={(e) => setForm({ ...form, meeting_link: e.target.value })} placeholder="https://meet.google.com/…" className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
              </label>
              <p className="flex items-center gap-1.5 text-[11px] text-muted-foreground"><Lock className="h-3 w-3 text-primary" /> Only accepted attendees see this link.</p>
            </>
          ) : (
            <>
              <label className="flex flex-col gap-1">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Venue / Location</span>
                <input value={form.location} maxLength={120} onChange={(e) => setForm({ ...form, location: e.target.value })} className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
              </label>
              <div className="flex flex-col gap-1">
                <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Venue amenities</span>
                <div className="flex flex-wrap gap-2">
                  {AMENITIES.map((a) => {
                    const active = amenities.includes(a.key);
                    const Icon = a.icon;
                    return (
                      <button
                        key={a.key}
                        type="button"
                        onClick={() => setAmenities((prev) => prev.includes(a.key) ? prev.filter((k) => k !== a.key) : [...prev, a.key])}
                        className={`flex items-center gap-1.5 rounded-full border px-3 py-1 text-[11px] font-medium transition ${active ? "border-primary bg-primary/10 text-primary" : "border-border/60 bg-background text-muted-foreground"}`}
                      >
                        <Icon className="h-3 w-3" /> {a.label}
                      </button>
                    );
                  })}
                </div>
              </div>
            </>
          )}

          <label className="flex flex-col gap-1">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Topic tags (optional)</span>
            <input value={form.topic_tags} maxLength={120} onChange={(e) => setForm({ ...form, topic_tags: e.target.value })} placeholder="React, TypeScript" className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
          </label>

          <div className="grid grid-cols-2 gap-3">
            <label className="flex flex-col gap-1">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Total slots</span>
              <input type="number" min={1} max={50} value={form.slots} onChange={(e) => setForm({ ...form, slots: e.target.value })} className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
            </label>
            <label className="flex flex-col gap-1">
              <span className="text-[11px] font-semibold uppercase tracking-wider text-muted-foreground">Cost / head (₹)</span>
              <input type="number" min={0} value={form.cost} onChange={(e) => setForm({ ...form, cost: e.target.value })} className="rounded-2xl border border-border/60 bg-background px-3 py-2 outline-none focus:border-primary" />
            </label>
          </div>

          <button
            type="submit"
            disabled={mutation.isPending || uploading}
            className="mt-2 flex w-full items-center justify-center gap-2 rounded-2xl bg-primary py-3 text-sm font-semibold text-primary-foreground transition active:scale-[0.99] disabled:opacity-60"
          >
            {uploading ? "Uploading…" : mutation.isPending ? "Saving…" : (<><Check className="h-4 w-4" /> Save changes</>)}
          </button>
        </div>
      </form>
    </div>,
    document.body,
  );
}