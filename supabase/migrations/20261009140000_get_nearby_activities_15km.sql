-- Migration: Define get_nearby_activities RPC with 15km default radius
-- Safe additive migration

-- 1. Ensure haversine_m function exists
CREATE OR REPLACE FUNCTION public.haversine_m(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
) RETURNS double precision
LANGUAGE sql IMMUTABLE PARALLEL SAFE
SET search_path = public
AS $$
  SELECT 2 * 6371000 * asin(
    sqrt(
      sin(radians((lat2 - lat1) / 2)) ^ 2
      + cos(radians(lat1)) * cos(radians(lat2))
      * sin(radians((lon2 - lon1) / 2)) ^ 2
    )
  );
$$;

-- 2. Define get_nearby_activities RPC filtering activities by radius_km (default 15.0)
CREATE OR REPLACE FUNCTION public.get_nearby_activities(
  user_lat double precision,
  user_lng double precision,
  radius_km double precision DEFAULT 15.0
)
RETURNS SETOF public.activities
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT *
  FROM public.activities
  
  WHERE deleted_at IS NULL
    AND latitude IS NOT NULL
    AND longitude IS NOT NULL
    AND public.haversine_m(user_lat, user_lng, latitude, longitude) <= (radius_km * 1000.0)
  ORDER BY public.haversine_m(user_lat, user_lng, latitude, longitude) ASC;
$$;

-- 3. Grant execute permissions
GRANT EXECUTE ON FUNCTION public.get_nearby_activities(double precision, double precision, double precision) TO anon, authenticated, service_role;
