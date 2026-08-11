// Unified place search provider. Uses Photon (OSM) by default for hyper-local
// POIs, temples, landmarks, villages, etc. Falls back to Google Places
// Autocomplete when VITE_GOOGLE_PLACES_API_KEY is provided.
import type { Place } from "@/components/place-search";

export type PlaceResult = {
  id: string;
  title: string;              // primary label e.g. "Gangeswar Mahadev Temple"
  subtitle: string;           // hierarchical: locality, town, state
  full: string;               // full display string
  lat: number;
  lon: number;
  city: string;
  state?: string;
  postcode?: string;
  kind?: string;              // e.g. "temple", "park", "village"
};

export function toPlace(r: PlaceResult): Place {
  return {
    display_name: r.full,
    short: r.title,
    lat: r.lat,
    lon: r.lon,
    city: r.city,
    state: r.state,
    postcode: r.postcode,
  };
}

export function activeProvider(): "google" | "photon" {
  const key = (import.meta.env.VITE_GOOGLE_PLACES_API_KEY as string | undefined) || "";
  return key.trim() ? "google" : "photon";
}

// ---------------- Photon ----------------
type PhotonFeature = {
  geometry: { coordinates: [number, number] };
  properties: {
    osm_id?: number;
    osm_type?: string;
    name?: string;
    country?: string;
    countrycode?: string;
    state?: string;
    county?: string;
    city?: string;
    town?: string;
    village?: string;
    hamlet?: string;
    suburb?: string;
    district?: string;
    locality?: string;
    street?: string;
    postcode?: string;
    osm_key?: string;
    osm_value?: string;
    type?: string;
  };
};

function photonToResult(f: PhotonFeature, idx: number): PlaceResult {
  const p = f.properties;
  const [lon, lat] = f.geometry.coordinates;
  const locality = p.suburb || p.locality || p.district || p.village || p.hamlet || p.town || "";
  const city = p.city || p.town || p.village || p.hamlet || p.county || p.state || "";
  const title = p.name || p.street || locality || city || "Unnamed place";
  const subtitleParts = [
    locality && locality !== title ? locality : "",
    city && city !== locality ? city : "",
    p.state && p.state !== city ? p.state : "",
  ].filter(Boolean);
  const subtitle = subtitleParts.join(", ") || p.country || "";
  const full = [title, ...subtitleParts, p.country].filter(Boolean).join(", ");
  return {
    id: `${p.osm_type || "n"}-${p.osm_id ?? idx}-${lat}-${lon}`,
    title,
    subtitle,
    full,
    lat,
    lon,
    city,
    state: p.state,
    postcode: p.postcode,
    kind: p.osm_value || p.type,
  };
}

async function searchPhoton(q: string, signal: AbortSignal): Promise<PlaceResult[]> {
  // Bias to India roughly (centroid) — Photon accepts lat/lon bias, not a hard filter.
  const params = new URLSearchParams({
    q,
    lang: "en",
    limit: "12",
    lat: "22.35",
    lon: "78.66",
    location_bias_scale: "0.4",
  });
  const url = `https://photon.komoot.io/api/?${params.toString()}`;
  const res = await fetch(url, { signal, headers: { Accept: "application/json" } });
  if (!res.ok) throw new Error("Photon search failed");
  const data = (await res.json()) as { features: PhotonFeature[] };
  // Prefer India results; keep others as tail so obscure landmark spellings still surface.
  const inIndia = data.features.filter((f) => (f.properties.countrycode || "").toUpperCase() === "IN");
  const rest = data.features.filter((f) => (f.properties.countrycode || "").toUpperCase() !== "IN");
  return [...inIndia, ...rest].map(photonToResult);
}

// Pincode: Photon coverage is spotty for Indian postcodes; hit Nominatim.
async function searchPincode(pin: string, signal: AbortSignal): Promise<PlaceResult[]> {
  const params = new URLSearchParams({
    format: "json",
    addressdetails: "1",
    countrycodes: "in",
    limit: "8",
    "accept-language": "en",
    postalcode: pin,
  });
  const res = await fetch(`https://nominatim.openstreetmap.org/search?${params.toString()}`, {
    signal,
    headers: { Accept: "application/json" },
  });
  if (!res.ok) return [];
  const data = (await res.json()) as Array<{
    display_name: string; lat: string; lon: string;
    address?: Record<string, string | undefined>;
  }>;
  return data.map((r, i) => {
    const a = r.address ?? {};
    const locality = a.suburb || a.village || a.hamlet || a.town || "";
    const city = a.city || a.town || a.village || a.hamlet || a.county || a.state || "";
    const title = locality || city || pin;
    const subtitleParts = [
      locality && locality !== title ? locality : "",
      city && city !== locality ? city : "",
      a.state,
      pin,
    ].filter(Boolean) as string[];
    return {
      id: `pin-${pin}-${i}`,
      title: `${title} (${pin})`,
      subtitle: subtitleParts.join(", "),
      full: r.display_name,
      lat: parseFloat(r.lat),
      lon: parseFloat(r.lon),
      city,
      state: a.state,
      postcode: pin,
      kind: "postcode",
    };
  });
}

// ---------------- Google Places (New) ----------------
type GAutoSuggestion = {
  placePrediction?: {
    placeId: string;
    text?: { text: string };
    structuredFormat?: {
      mainText?: { text: string };
      secondaryText?: { text: string };
    };
  };
};

async function searchGoogle(q: string, signal: AbortSignal, apiKey: string): Promise<PlaceResult[]> {
  const autoRes = await fetch("https://places.googleapis.com/v1/places:autocomplete", {
    method: "POST",
    signal,
    headers: {
      "Content-Type": "application/json",
      "X-Goog-Api-Key": apiKey,
    },
    body: JSON.stringify({
      input: q,
      includedRegionCodes: ["in"],
      languageCode: "en",
    }),
  });
  if (!autoRes.ok) throw new Error("Google Places autocomplete failed");
  const auto = (await autoRes.json()) as { suggestions?: GAutoSuggestion[] };
  const suggestions = (auto.suggestions ?? [])
    .map((s) => s.placePrediction)
    .filter((p): p is NonNullable<GAutoSuggestion["placePrediction"]> => !!p)
    .slice(0, 10);

  // Fetch coordinates for each prediction in parallel.
  const details = await Promise.all(
    suggestions.map(async (s) => {
      try {
        const r = await fetch(`https://places.googleapis.com/v1/places/${s.placeId}`, {
          signal,
          headers: {
            "X-Goog-Api-Key": apiKey,
            "X-Goog-FieldMask": "id,location,formattedAddress,addressComponents,displayName",
          },
        });
        if (!r.ok) return null;
        return (await r.json()) as {
          location?: { latitude: number; longitude: number };
          formattedAddress?: string;
          addressComponents?: Array<{ longText: string; shortText: string; types: string[] }>;
          displayName?: { text: string };
        };
      } catch {
        return null;
      }
    }),
  );

  return suggestions.map((s, i) => {
    const d = details[i];
    const comps = d?.addressComponents ?? [];
    const find = (t: string) => comps.find((c) => c.types.includes(t))?.longText;
    const city = find("locality") || find("administrative_area_level_2") || "";
    const state = find("administrative_area_level_1");
    const postcode = find("postal_code");
    const title = s.structuredFormat?.mainText?.text || d?.displayName?.text || s.text?.text || "Place";
    const subtitle = s.structuredFormat?.secondaryText?.text || d?.formattedAddress || "";
    return {
      id: s.placeId,
      title,
      subtitle,
      full: d?.formattedAddress || `${title}${subtitle ? `, ${subtitle}` : ""}`,
      lat: d?.location?.latitude ?? 0,
      lon: d?.location?.longitude ?? 0,
      city,
      state,
      postcode,
    };
  }).filter((r) => r.lat !== 0 || r.lon !== 0);
}

// ---------------- Public API ----------------
export async function searchPlaces(q: string, signal: AbortSignal): Promise<PlaceResult[]> {
  const term = q.trim();
  if (term.length < 2) return [];
  const isPincode = /^\d{6}$/.test(term);
  const key = (import.meta.env.VITE_GOOGLE_PLACES_API_KEY as string | undefined)?.trim();
  if (key) {
    try {
      const g = await searchGoogle(term, signal, key);
      if (g.length) return g;
    } catch (e) {
      if ((e as Error).name === "AbortError") throw e;
      // fall through to Photon
    }
  }
  if (isPincode) {
    const [pins, photon] = await Promise.all([
      searchPincode(term, signal).catch(() => []),
      searchPhoton(term, signal).catch(() => []),
    ]);
    return [...pins, ...photon];
  }
  return searchPhoton(term, signal);
}