/**
 * Spatial calculation helpers for hyper-local 15 km discovery.
 * Matches Flutter LocationService.haversineKm precision and behaviour.
 */

// Default city center (Bengaluru) coordinates matching Android fallback.
export const DEFAULT_LAT = 12.9716;
export const DEFAULT_LON = 77.5946;
export const DEFAULT_RADIUS_KM = 15.0;

/**
 * Calculates circular great-circle distance between two GPS coordinates in kilometers
 * using the Haversine spherical formula.
 */
export function haversineKm(
  lat1: number,
  lon1: number,
  lat2: number,
  lon2: number,
): number {
  const p = Math.PI / 180;
  const c = Math.cos;
  const a =
    0.5 -
    c((lat2 - lat1) * p) / 2 +
    (c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p))) / 2;
  return 12742 * Math.asin(Math.sqrt(Math.max(0, Math.min(1, a))));
}

/**
 * Formats a distance in kilometers to a human-friendly string matching Android ActivityCard:
 * - "< 1 km" -> e.g. "850 m away"
 * - ">= 1 km" -> e.g. "2.4 km away"
 */
export function formatDistance(distanceKm: number | null | undefined): string | null {
  if (distanceKm == null || isNaN(distanceKm)) return null;
  if (distanceKm < 1) {
    const meters = Math.round(distanceKm * 1000);
    return `${meters} m away`;
  }
  return `${distanceKm.toFixed(1)} km away`;
}
