import { useMemo, useRef, useState } from "react";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { Camera, Download, Share2, Sparkles, Loader2 } from "lucide-react";
import { toast } from "sonner";
import { listEventMemories, uploadEventMemory, emojiFor } from "@/lib/services";
import { friendlyError } from "@/lib/friendly-error";

type Activity = {
  id: string;
  title: string;
  category: string;
  location: string;
  date_time: string;
};

export function MemoryBanner({
  activity,
  canUpload,
  userId,
}: {
  activity: Activity;
  canUpload: boolean;
  userId: string | undefined;
}) {
  const qc = useQueryClient();
  const [uploading, setUploading] = useState(false);
  const [sharing, setSharing] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  const start = new Date(activity.date_time).getTime();
  const end = start + 6 * 60 * 60 * 1000;
  // Only consider the plan "wrapped" once the 3h event window closes so the
  // upload banner doesn't appear mid-event.
  const isPast = Date.now() >= start + 3 * 60 * 60 * 1000;

  const { data: memories = [] } = useQuery({
    queryKey: ["event-memories", activity.id],
    queryFn: () => listEventMemories(activity.id),
    enabled: isPast,
    staleTime: 30_000,
  });

  const latest = memories[0];

  async function handleFile(file: File) {
    if (!userId) return;
    setUploading(true);
    try {
      await uploadEventMemory(userId, activity.id, file);
      toast.success("Memory saved to the squad 📸");
      await qc.invalidateQueries({ queryKey: ["event-memories", activity.id] });
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't upload photo"));
    } finally {
      setUploading(false);
    }
  }

  async function exportCard(mode: "share" | "download") {
    if (!latest) return;
    setSharing(true);
    try {
      const blob = await renderMemoryCard({
        title: activity.title,
        category: activity.category,
        location: activity.location,
        date_time: activity.date_time,
        imageUrl: latest.image_url,
      });
      if (mode === "share" && typeof navigator !== "undefined" && "share" in navigator) {
        const file = new File([blob], `tribeX-${activity.id}.png`, { type: "image/png" });
        const nav = navigator as Navigator & { canShare?: (d: { files?: File[] }) => boolean };
        if (nav.canShare?.({ files: [file] })) {
          await nav.share({ files: [file], title: activity.title, text: `Played with tribeX Squad · ${activity.title}` });
          return;
        }
      }
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = `tribeX-${activity.title.replace(/[^a-z0-9]+/gi, "-")}.png`;
      a.click();
      setTimeout(() => URL.revokeObjectURL(url), 5000);
      toast.success("Card downloaded — share your story!");
    } catch (err) {
      toast.error(friendlyError(err, "Couldn't export card"));
    } finally {
      setSharing(false);
    }
  }

  if (!isPast) return null;

  return (
    <div className="mb-3 overflow-hidden rounded-2xl border border-primary/30 bg-gradient-to-br from-primary/10 via-card to-card p-3">
      <div className="flex items-start gap-2">
        <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-primary/15 text-primary">
          <Sparkles className="h-4 w-4" />
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-xs font-semibold uppercase tracking-wider text-primary">Squad Memory</p>
          <p className="text-[11px] text-muted-foreground">
            {latest
              ? "Your squad memory is ready. Share it to your story!"
              : Date.now() > end
                ? "The plan wrapped up — upload a photo to save this squad memory."
                : "Upload a photo from the plan to create a shareable memory card."}
          </p>
        </div>
      </div>

      {latest && (
        <div className="mt-3">
          <MemoryCardPreview
            title={activity.title}
            category={activity.category}
            location={activity.location}
            date_time={activity.date_time}
            imageUrl={latest.image_url}
          />
        </div>
      )}

      <div className="mt-3 flex flex-wrap gap-2">
        {canUpload && (
          <>
            <input
              ref={inputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp"
              className="hidden"
              onChange={(e) => {
                const f = e.target.files?.[0];
                if (f) handleFile(f);
                e.currentTarget.value = "";
              }}
            />
            <button
              type="button"
              onClick={() => inputRef.current?.click()}
              disabled={uploading}
              className="inline-flex items-center gap-1.5 rounded-full bg-primary px-3 py-1.5 text-xs font-semibold text-primary-foreground transition hover:opacity-90 active:scale-95 disabled:opacity-60"
            >
              {uploading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Camera className="h-3.5 w-3.5" />}
              {uploading ? "Uploading…" : latest ? "Add another photo" : "Upload event photo"}
            </button>
          </>
        )}
        {latest && (
          <>
            <button
              type="button"
              onClick={() => exportCard("share")}
              disabled={sharing}
              className="inline-flex items-center gap-1.5 rounded-full border border-border/60 bg-background px-3 py-1.5 text-xs font-semibold transition hover:bg-accent active:scale-95 disabled:opacity-60"
            >
              <Share2 className="h-3.5 w-3.5" /> Share card
            </button>
            <button
              type="button"
              onClick={() => exportCard("download")}
              disabled={sharing}
              className="inline-flex items-center gap-1.5 rounded-full border border-border/60 bg-background px-3 py-1.5 text-xs font-semibold transition hover:bg-accent active:scale-95 disabled:opacity-60"
            >
              <Download className="h-3.5 w-3.5" /> Download
            </button>
          </>
        )}
      </div>

      {memories.length > 1 && (
        <div className="mt-3 flex gap-2 overflow-x-auto pb-1">
          {memories.slice(1, 8).map((m) => (
            <img
              key={m.id}
              src={m.image_url}
              alt=""
              className="h-14 w-14 shrink-0 rounded-lg object-cover"
              loading="lazy"
            />
          ))}
        </div>
      )}
    </div>
  );

  function MemoryCardPreview(props: MemoryCardData) {
    const when = useMemo(
      () => new Date(props.date_time).toLocaleDateString([], { day: "numeric", month: "short", year: "numeric" }),
      [props.date_time],
    );
    const city = props.location.split(",").pop()?.trim() || props.location;
    return (
      <div className="relative aspect-[4/5] w-full max-w-[220px] overflow-hidden rounded-2xl bg-black shadow-lg">
        <img src={props.imageUrl} alt="" className="absolute inset-0 h-full w-full object-cover" />
        <div className="absolute inset-0 bg-gradient-to-t from-black/85 via-black/20 to-black/40" />
        <div className="absolute right-2 top-2 rounded-full bg-white/95 px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-black">
          tribeX
        </div>
        <div className="absolute inset-x-0 bottom-0 p-3 text-white">
          <p className="text-[10px] font-semibold uppercase tracking-widest text-white/70">
            {emojiFor(props.category)} {props.category}
          </p>
          <p className="mt-0.5 line-clamp-2 text-sm font-bold leading-tight">{props.title}</p>
          <p className="mt-1 text-[10px] text-white/80">{when} · {city}</p>
          <p className="mt-2 inline-block rounded-full bg-white/15 px-2 py-0.5 text-[9px] font-bold uppercase tracking-wider backdrop-blur">
            Played with tribeX Squad
          </p>
        </div>
      </div>
    );
  }
}

type MemoryCardData = {
  title: string;
  category: string;
  location: string;
  date_time: string;
  imageUrl: string;
};

// Renders the branded overlay card into a 1080x1350 PNG (Instagram story-friendly).
async function renderMemoryCard(data: MemoryCardData): Promise<Blob> {
  const W = 1080;
  const H = 1350;
  const canvas = document.createElement("canvas");
  canvas.width = W;
  canvas.height = H;
  const ctx = canvas.getContext("2d");
  if (!ctx) throw new Error("Canvas not supported");

  // Background base
  ctx.fillStyle = "#0F172A";
  ctx.fillRect(0, 0, W, H);

  // Load photo
  const img = await loadImage(data.imageUrl);
  // cover-fit
  const ratio = Math.max(W / img.width, H / img.height);
  const iw = img.width * ratio;
  const ih = img.height * ratio;
  ctx.drawImage(img, (W - iw) / 2, (H - ih) / 2, iw, ih);

  // Gradient overlay
  const grad = ctx.createLinearGradient(0, 0, 0, H);
  grad.addColorStop(0, "rgba(15,23,42,0.55)");
  grad.addColorStop(0.55, "rgba(15,23,42,0.15)");
  grad.addColorStop(1, "rgba(15,23,42,0.92)");
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, W, H);

  // tribeX badge top-right
  const badge = "tribeX";
  ctx.font = "800 42px 'Plus Jakarta Sans', system-ui, sans-serif";
  const bw = ctx.measureText(badge).width + 44;
  const bh = 62;
  roundRect(ctx, W - bw - 40, 40, bw, bh, 999);
  ctx.fillStyle = "#FFFFFF";
  ctx.fill();
  ctx.fillStyle = "#0F172A";
  ctx.textBaseline = "middle";
  ctx.textAlign = "center";
  ctx.fillText(badge, W - 40 - bw / 2, 40 + bh / 2 + 2);

  // Category chip
  const catText = `${emojiFor(data.category)}  ${data.category.toUpperCase()}`;
  ctx.font = "700 32px system-ui, sans-serif";
  ctx.textAlign = "left";
  ctx.fillStyle = "rgba(255,255,255,0.75)";
  ctx.fillText(catText, 60, H - 380);

  // Title (wrap)
  ctx.font = "800 78px 'Plus Jakarta Sans', system-ui, sans-serif";
  ctx.fillStyle = "#FFFFFF";
  wrapText(ctx, data.title, 60, H - 300, W - 120, 88, 2);

  // Date · City
  const when = new Date(data.date_time).toLocaleDateString([], {
    day: "numeric",
    month: "long",
    year: "numeric",
  });
  const city = data.location.split(",").pop()?.trim() || data.location;
  ctx.font = "500 34px system-ui, sans-serif";
  ctx.fillStyle = "rgba(255,255,255,0.82)";
  ctx.fillText(`${when}  ·  ${city}`, 60, H - 130);

  // Squad pill
  ctx.font = "800 26px 'Plus Jakarta Sans', system-ui, sans-serif";
  const pill = "PLAYED WITH TRIBEX SQUAD";
  const pw = ctx.measureText(pill).width + 44;
  const ph = 58;
  roundRect(ctx, 60, H - 90, pw, ph, 999);
  ctx.fillStyle = "#6366F1";
  ctx.fill();
  ctx.fillStyle = "#FFFFFF";
  ctx.textBaseline = "middle";
  ctx.textAlign = "center";
  ctx.fillText(pill, 60 + pw / 2, H - 90 + ph / 2 + 2);

  return await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((b) => (b ? resolve(b) : reject(new Error("Failed to export"))), "image/png", 0.95);
  });
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const im = new Image();
    im.crossOrigin = "anonymous";
    im.onload = () => resolve(im);
    im.onerror = () => reject(new Error("Image load failed"));
    im.src = src;
  });
}

function roundRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  const rr = Math.min(r, w / 2, h / 2);
  ctx.beginPath();
  ctx.moveTo(x + rr, y);
  ctx.arcTo(x + w, y, x + w, y + h, rr);
  ctx.arcTo(x + w, y + h, x, y + h, rr);
  ctx.arcTo(x, y + h, x, y, rr);
  ctx.arcTo(x, y, x + w, y, rr);
  ctx.closePath();
}

function wrapText(
  ctx: CanvasRenderingContext2D,
  text: string,
  x: number,
  y: number,
  maxWidth: number,
  lineHeight: number,
  maxLines: number,
) {
  const words = text.split(/\s+/);
  const lines: string[] = [];
  let line = "";
  for (const w of words) {
    const test = line ? `${line} ${w}` : w;
    if (ctx.measureText(test).width > maxWidth && line) {
      lines.push(line);
      line = w;
      if (lines.length === maxLines) break;
    } else {
      line = test;
    }
  }
  if (line && lines.length < maxLines) lines.push(line);
  if (lines.length === maxLines) {
    // ellipsize last line if truncated
    let last = lines[maxLines - 1];
    if (ctx.measureText(last + "…").width > maxWidth) {
      while (last.length > 0 && ctx.measureText(last + "…").width > maxWidth) last = last.slice(0, -1);
    }
    lines[maxLines - 1] = last + (words.join(" ").length > lines.join(" ").length ? "…" : "");
  }
  lines.forEach((ln, i) => ctx.fillText(ln, x, y + i * lineHeight));
}