-- Migration: Virtual Plans Full System Repair
-- 1. Update get_nearby_activities to return both nearby physical plans (within radius_km) and virtual/online plans (is_online = true)
-- 2. Allow authenticated users to request joining virtual plans without physical GPS coordinates
-- 3. Ensure get_meeting_link RPC permissions and access control are intact

-- 1. get_nearby_activities RPC update
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
    AND (
      is_online = true
      OR (
        latitude IS NOT NULL
        AND longitude IS NOT NULL
        AND public.haversine_m(user_lat, user_lng, latitude, longitude) <= (radius_km * 1000.0)
      )
    )
  ORDER BY
    is_online ASC,
    CASE
      WHEN latitude IS NOT NULL AND longitude IS NOT NULL
      THEN public.haversine_m(user_lat, user_lng, latitude, longitude)
      ELSE 999999999.0
    END ASC,
    date_time ASC;
$$;

GRANT EXECUTE ON FUNCTION public.get_nearby_activities(double precision, double precision, double precision) TO anon, authenticated, service_role;

-- 2. Update join_requests INSERT policy to permit joining virtual plans without strict GPS
DROP POLICY IF EXISTS "Users can request to join with verified profile location" ON public.join_requests;
CREATE POLICY "Users can request to join with verified profile location"
ON public.join_requests
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND (
    EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = activity_id AND a.is_online = true
    )
    OR EXISTS (
      SELECT 1
      FROM public.profiles p
      WHERE p.id = auth.uid()
        AND p.city IS NOT NULL
        AND length(trim(p.city)) > 0
        AND p.latitude IS NOT NULL
        AND p.longitude IS NOT NULL
    )
  )
);

-- 3. Ensure get_meeting_link permissions
GRANT EXECUTE ON FUNCTION public.get_meeting_link(uuid) TO authenticated, service_role;
