-- Migration: TribeX Nearby Plans 15KM Discovery, Virtual Plan Anchor & Pagination Repair
-- 1. Updates get_nearby_activities RPC:
--    - Default radius_km = 15.0
--    - Applies circular haversine distance for in-person venue coordinates
--    - For virtual plans (is_online = true), uses creator's profile location as the discovery proximity anchor
--    - Never leaks creator's private coordinates (returns SETOF activities)
--    - Supports pagination via limit_count and offset_count
--    - Deterministic ordering: distance ASC, date_time ASC, id ASC
--    - Security Definer to securely read profiles coordinates without exposing base table

CREATE OR REPLACE FUNCTION public.get_nearby_activities(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision DEFAULT 15.0,
  limit_count integer DEFAULT 50,
  offset_count integer DEFAULT 0
)
RETURNS SETOF public.activities
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT a.*
  FROM public.activities a
  LEFT JOIN public.profiles p ON a.host_id = p.id
  WHERE a.deleted_at IS NULL
    AND (
      -- In-person activities: must have venue coordinates within radius_km
      (
        a.is_online = false
        AND a.latitude IS NOT NULL
        AND a.longitude IS NOT NULL
        AND public.haversine_m(user_lat, user_lng, a.latitude, a.longitude) <= (radius_km * 1000.0)
      )
      OR
      -- Virtual activities: anchor to creator's authorized discovery location within radius_km
      (
        a.is_online = true
        AND (
          (
            a.latitude IS NOT NULL
            AND a.longitude IS NOT NULL
            AND public.haversine_m(user_lat, user_lng, a.latitude, a.longitude) <= (radius_km * 1000.0)
          )
          OR
          (
            (a.latitude IS NULL OR a.longitude IS NULL)
            AND p.latitude IS NOT NULL
            AND p.longitude IS NOT NULL
            AND public.haversine_m(user_lat, user_lng, p.latitude, p.longitude) <= (radius_km * 1000.0)
          )
        )
      )
    )
  ORDER BY
    -- Order by proximity distance first
    CASE
      WHEN a.is_online = false AND a.latitude IS NOT NULL AND a.longitude IS NOT NULL
        THEN public.haversine_m(user_lat, user_lng, a.latitude, a.longitude)
      WHEN a.is_online = true AND a.latitude IS NOT NULL AND a.longitude IS NOT NULL
        THEN public.haversine_m(user_lat, user_lng, a.latitude, a.longitude)
      WHEN a.is_online = true AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
        THEN public.haversine_m(user_lat, user_lng, p.latitude, p.longitude)
      ELSE 999999999.0
    END ASC,
    a.date_time ASC,
    a.id ASC
  LIMIT COALESCE(limit_count, 50)
  OFFSET COALESCE(offset_count, 0);
$$;

-- Grant execution permissions to anon, authenticated and service_role
GRANT EXECUTE ON FUNCTION public.get_nearby_activities(double precision, double precision, double precision, integer, integer) TO anon, authenticated, service_role;

-- Maintain backward compatibility for 3-argument calls
CREATE OR REPLACE FUNCTION public.get_nearby_activities(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision DEFAULT 15.0
)
RETURNS SETOF public.activities
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM public.get_nearby_activities(user_lat, user_lng, radius_km, 50, 0);
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_activities(double precision, double precision, double precision) TO anon, authenticated, service_role;

