import { useEffect, useMemo, useRef, useState } from "react";
import { ChevronsUpDown, Loader2, MapPin, Search, X } from "lucide-react";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { cn } from "@/lib/utils";
import { searchPlaces, toPlace, activeProvider, type PlaceResult } from "@/lib/place-providers";

export type Place = {
  display_name: string;
  short: string;
  lat: number;
  lon: number;
  city: string;
  state?: string;
  postcode?: string;
};

type Props = {
  value: string;
  onSelect: (place: Place) => void;
  className?: string;
  variant?: "chip" | "input";
  placeholder?: string;
};

export function PlaceSearch({ value, onSelect, className, variant = "chip", placeholder = "Search place or pincode" }: Props) {
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [results, setResults] = useState<PlaceResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement | null>(null);
  const provider = useMemo(() => activeProvider(), []);

  useEffect(() => {
    const term = q.trim();
    if (!open) return;
    if (term.length < 2) {
      setResults([]);
      setError(null);
      return;
    }
    const ctrl = new AbortController();
    setLoading(true);
    setError(null);
    const t = setTimeout(async () => {
      try {
        const data = await searchPlaces(term, ctrl.signal);
        setResults(data);
      } catch (e) {
        if ((e as Error).name !== "AbortError") setError("Couldn't reach the place search service");
      } finally {
        setLoading(false);
      }
    }, 300);
    return () => {
      clearTimeout(t);
      ctrl.abort();
    };
  }, [q, open]);

  useEffect(() => {
    if (open) setTimeout(() => inputRef.current?.focus(), 30);
    else { setQ(""); setResults([]); }
  }, [open]);

  const trigger =
    variant === "chip" ? (
      <button
        type="button"
        className={cn(
          "inline-flex max-w-[220px] items-center gap-1 text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground transition hover:text-primary",
          className,
        )}
        aria-label="Change location"
      >
        <MapPin className="h-3 w-3 shrink-0" />
        <span className="truncate normal-case tracking-normal">{value || placeholder}</span>
        <ChevronsUpDown className="h-3 w-3 shrink-0 opacity-60" />
      </button>
    ) : (
      <button
        type="button"
        className={cn(
          "flex w-full items-center justify-between gap-2 rounded-2xl border border-border/60 bg-card px-4 py-3 text-left text-sm transition focus:border-primary",
          !value && "text-muted-foreground",
          className,
        )}
      >
        <span className="flex items-center gap-2 truncate">
          <MapPin className="h-4 w-4 text-muted-foreground" />
          <span className="truncate">{value || placeholder}</span>
        </span>
        <ChevronsUpDown className="h-4 w-4 shrink-0 text-muted-foreground" />
      </button>
    );

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>{trigger}</PopoverTrigger>
      <PopoverContent align="start" className="w-[320px] p-0">
        <div className="flex items-center gap-2 border-b border-border/60 px-3 py-2">
          <Search className="h-3.5 w-3.5 shrink-0 text-muted-foreground" />
          <input
            ref={inputRef}
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Try Madhapar, Bhuj or 370020"
            className="h-8 w-full bg-transparent text-sm outline-none placeholder:text-muted-foreground"
          />
          {q && (
            <button onClick={() => setQ("")} aria-label="Clear" className="text-muted-foreground hover:text-foreground">
              <X className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
        <div className="max-h-72 overflow-y-auto">
          {loading && (
            <div className="flex items-center gap-2 px-3 py-4 text-xs text-muted-foreground">
              <Loader2 className="h-3.5 w-3.5 animate-spin" /> Searching India…
            </div>
          )}
          {!loading && error && (
            <p className="px-3 py-4 text-xs text-destructive">{error}</p>
          )}
          {!loading && !error && q.trim().length >= 2 && results.length === 0 && (
            <p className="px-3 py-4 text-xs text-muted-foreground">No matching places.</p>
          )}
          {!loading && q.trim().length < 2 && (
            <div className="px-3 py-4 text-xs text-muted-foreground">
              <p>Type a temple, park, landmark, village, or 6-digit pincode.</p>
              <p className="mt-1 text-[10px] uppercase tracking-wider opacity-60">
                Powered by {provider === "google" ? "Google Places" : "Photon · OpenStreetMap"}
              </p>
            </div>
          )}
          {!loading && results.length > 0 && (
            <ul className="py-1">
              {results.map((r) => {
                const p = toPlace(r);
                return (
                  <li key={r.id}>
                    <button
                      type="button"
                      onClick={() => {
                        onSelect(p);
                        setOpen(false);
                      }}
                      className="flex w-full items-start gap-2 px-3 py-2 text-left text-sm transition hover:bg-accent"
                    >
                      <MapPin className="mt-0.5 h-3.5 w-3.5 shrink-0 text-primary" />
                      <span className="min-w-0 flex-1">
                        <span className="flex items-center gap-1.5">
                          <span className="truncate font-medium">{r.title}</span>
                          {r.kind && (
                            <span className="shrink-0 rounded-full bg-primary/10 px-1.5 py-0.5 text-[9px] font-semibold uppercase tracking-wider text-primary">
                              {r.kind}
                            </span>
                          )}
                        </span>
                        {r.subtitle && (
                          <span className="block truncate text-[11px] text-muted-foreground">
                            {r.subtitle}
                          </span>
                        )}
                        <span className="mt-0.5 block truncate text-[10px] text-muted-foreground/70">
                          {p.lat.toFixed(4)}, {p.lon.toFixed(4)}
                        </span>
                      </span>
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </PopoverContent>
    </Popover>
  );
}