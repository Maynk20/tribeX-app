import { useCallback, useEffect, useState } from "react";
import { DEFAULT_CITY } from "@/lib/india-cities";
import type { Place } from "@/components/place-search";

const KEY = "lobby:location";
const PLACE_KEY = "lobby:place";
const DEFAULT = DEFAULT_CITY;

export function useLocation() {
  const [location, setLocationState] = useState<string>(DEFAULT);
  const [place, setPlaceState] = useState<Place | null>(null);
  const [requesting, setRequesting] = useState(false);

  useEffect(() => {
    if (typeof window === "undefined") return;
    const saved = window.localStorage.getItem(KEY);
    if (saved) setLocationState(saved);
    const savedPlace = window.localStorage.getItem(PLACE_KEY);
    if (savedPlace) {
      try { setPlaceState(JSON.parse(savedPlace) as Place); } catch { /* ignore */ }
    }
  }, []);

  const setLocation = useCallback((next: string) => {
    const value = next.trim() || DEFAULT;
    setLocationState(value);
    try {
      window.localStorage.setItem(KEY, value);
    } catch {
      // storage unavailable — safe to ignore
    }
  }, []);

  const setPlace = useCallback((next: Place) => {
    setPlaceState(next);
    const label = next.short || next.city || next.display_name.split(",")[0];
    setLocationState(label);
    try {
      window.localStorage.setItem(KEY, label);
      window.localStorage.setItem(PLACE_KEY, JSON.stringify(next));
    } catch { /* ignore */ }
  }, []);

  const requestBrowserLocation = useCallback(async (): Promise<string | null> => {
    if (typeof navigator === "undefined" || !navigator.geolocation) {
      throw new Error("Location isn't available on this device");
    }
    setRequesting(true);
    try {
      const coords = await new Promise<GeolocationCoordinates>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(
          (p) => resolve(p.coords),
          (err) => reject(new Error(err.message || "Location permission denied")),
          { enableHighAccuracy: false, timeout: 8000, maximumAge: 60_000 },
        );
      });
      // Reverse geocode via Nominatim to get a human-friendly Indian place name.
      try {
        const url = `https://nominatim.openstreetmap.org/reverse?format=json&addressdetails=1&lat=${coords.latitude}&lon=${coords.longitude}&accept-language=en`;
        const res = await fetch(url, { headers: { Accept: "application/json" } });
        if (res.ok) {
          const data = await res.json() as { display_name: string; address?: Record<string,string> };
          const a = data.address ?? {};
          const city = a.city || a.town || a.village || a.hamlet || a.suburb || a.county || a.state || "";
          const short = a.suburb || a.neighbourhood || a.village || a.hamlet || a.town || a.city || city;
          const label = short && city && short !== city ? `${short}, ${city}` : (short || city || "Your location");
          setPlace({
            display_name: data.display_name,
            short: label,
            lat: coords.latitude,
            lon: coords.longitude,
            city: (city || "").toString(),
            state: a.state,
            postcode: a.postcode,
          });
          return label;
        }
      } catch { /* fall through */ }
      const fallback = `Near ${coords.latitude.toFixed(2)}, ${coords.longitude.toFixed(2)}`;
      setLocation(fallback);
      return fallback;
    } finally {
      setRequesting(false);
    }
  }, [setLocation, setPlace]);

  const clearLocation = useCallback(() => {
    setLocationState(DEFAULT);
    setPlaceState(null);
    try {
      window.localStorage.removeItem(KEY);
      window.localStorage.removeItem(PLACE_KEY);
    } catch {
      // ignore
    }
  }, []);

  return { location, place, setLocation, setPlace, requestBrowserLocation, requesting, clearLocation };
}