import { useState } from "react";
import { createPortal } from "react-dom";
import { Phone, MapPin, Share2, X, ShieldAlert, Loader2 } from "lucide-react";
import { toast } from "sonner";

type Helpline = { label: string; numbers: string[]; hint: string };

const HELPLINES: Helpline[] = [
  { label: "Police", numbers: ["112", "100"], hint: "All-India emergency" },
  { label: "Ambulance", numbers: ["108"], hint: "Medical emergency" },
  { label: "Women Helpline", numbers: ["1091"], hint: "24×7 support" },
];

export function EmergencySosModal({ open, onClose }: { open: boolean; onClose: () => void }) {
  const [sharing, setSharing] = useState(false);

  if (!open) return null;

  async function shareLiveLocation() {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      toast.error("Location isn't available on this device");
      return;
    }
    setSharing(true);
    try {
      const coords = await new Promise<GeolocationCoordinates>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(
          (p) => resolve(p.coords),
          (err) => reject(new Error(err.message || "Location permission denied")),
          { enableHighAccuracy: true, timeout: 10_000, maximumAge: 0 },
        );
      });
      const { latitude, longitude } = coords;
      const mapsUrl = `https://maps.google.com/?q=${latitude},${longitude}`;
      const message = `🚨 tribeX SOS — I need help. My live location: ${mapsUrl}`;

      if (typeof navigator.share === "function") {
        try {
          await navigator.share({ title: "tribeX SOS", text: message, url: mapsUrl });
          return;
        } catch (e) {
          if ((e as DOMException)?.name === "AbortError") return;
          // fall through to WhatsApp
        }
      }
      const wa = `https://wa.me/?text=${encodeURIComponent(message)}`;
      window.open(wa, "_blank", "noopener,noreferrer");
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "Couldn't get your location");
    } finally {
      setSharing(false);
    }
  }

  if (typeof document === "undefined") return null;

  return createPortal(
    <div className="fixed inset-0 z-[99998] bg-black/80 p-4 backdrop-blur-sm" onClick={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-labelledby="sos-title"
        onClick={(e) => e.stopPropagation()}
        className="fixed left-1/2 top-1/2 z-[99999] max-h-[85vh] w-[90vw] max-w-sm -translate-x-1/2 -translate-y-1/2 overflow-y-auto rounded-2xl border border-destructive/40 bg-background p-6 shadow-2xl"
      >
        <div className="mb-4 flex items-start justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-destructive/15 text-destructive">
              <ShieldAlert className="h-6 w-6" />
            </div>
            <div>
              <h3 id="sos-title" className="text-lg font-bold">Emergency SOS</h3>
              <p className="text-xs text-muted-foreground">India helplines · live location</p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-full p-1 text-muted-foreground hover:bg-accent"
            aria-label="Close"
          >
            <X className="h-4 w-4" />
          </button>
        </div>

        <ul className="flex flex-col gap-2">
          {HELPLINES.map((h) => (
            <li key={h.label} className="flex items-center justify-between rounded-2xl border border-border/60 bg-background p-3">
              <div className="min-w-0">
                <p className="text-sm font-semibold">{h.label}</p>
                <p className="text-[11px] text-muted-foreground">{h.hint}</p>
              </div>
              <div className="flex flex-wrap justify-end gap-1.5">
                {h.numbers.map((n) => (
                  <a
                    key={n}
                    href={`tel:${n}`}
                    className="flex items-center gap-1 rounded-full bg-destructive px-3 py-1.5 text-xs font-bold text-destructive-foreground transition hover:scale-105 active:scale-95"
                  >
                    <Phone className="h-3 w-3" /> {n}
                  </a>
                ))}
              </div>
            </li>
          ))}
        </ul>

        <button
          type="button"
          onClick={shareLiveLocation}
          disabled={sharing}
          className="mt-4 flex w-full items-center justify-center gap-2 rounded-2xl bg-foreground py-3 text-sm font-semibold text-background transition hover:scale-[1.01] active:scale-95 disabled:opacity-60"
        >
          {sharing ? <Loader2 className="h-4 w-4 animate-spin" /> : <Share2 className="h-4 w-4" />}
          {sharing ? "Getting your location…" : "Share My Live Location"}
        </button>
        <p className="mt-2 flex items-center justify-center gap-1 text-[11px] text-muted-foreground">
          <MapPin className="h-3 w-3" /> Opens WhatsApp or your share sheet with GPS coordinates.
        </p>
      </div>
    </div>,
    document.body,
  );
}