
-- 1. Activity coordinates (optional; existing rows stay NULL)
ALTER TABLE public.activities
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision;

-- 2. Attendance tracking on join_requests
ALTER TABLE public.join_requests
  ADD COLUMN IF NOT EXISTS checked_in_at timestamptz,
  ADD COLUMN IF NOT EXISTS no_show boolean NOT NULL DEFAULT false;

-- 3. Reliability score on profiles + public view
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS reliability_score integer NOT NULL DEFAULT 100
    CHECK (reliability_score BETWEEN 0 AND 100);

DROP VIEW IF EXISTS public.profiles_public;
CREATE VIEW public.profiles_public
WITH (security_invoker = true) AS
SELECT id, full_name, username, avatar_url, rating, is_verified, reliability_score
FROM public.profiles;

GRANT SELECT ON public.profiles_public TO authenticated, anon;

-- 4. Haversine distance in meters
CREATE OR REPLACE FUNCTION public.haversine_m(
  lat1 double precision, lon1 double precision,
  lat2 double precision, lon2 double precision
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

-- 5. Check-in RPC — must be accepted attendee, within 150 m, event within window
CREATE OR REPLACE FUNCTION public.check_in_activity(
  _activity_id uuid,
  _lat double precision,
  _lon double precision
) RETURNS TABLE (status text, distance_m double precision)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_act public.activities;
  v_req public.join_requests;
  v_dist double precision;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Sign in to check in';
  END IF;

  SELECT * INTO v_act FROM public.activities WHERE id = _activity_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Plan not found'; END IF;

  IF v_act.latitude IS NULL OR v_act.longitude IS NULL THEN
    RAISE EXCEPTION 'This plan has no pinned location yet — ask the host to add one.';
  END IF;

  -- Only accepted attendees or the host may check in
  IF v_act.host_id = v_uid THEN
    -- Host checks in against their own row; no join_request update needed.
    v_dist := public.haversine_m(v_act.latitude, v_act.longitude, _lat, _lon);
    IF v_dist > 150 THEN
      RETURN QUERY SELECT 'too_far'::text, v_dist;
      RETURN;
    END IF;
    UPDATE public.profiles
       SET reliability_score = LEAST(100, reliability_score + 2)
     WHERE id = v_uid;
    RETURN QUERY SELECT 'checked_in'::text, v_dist;
    RETURN;
  END IF;

  SELECT * INTO v_req
    FROM public.join_requests
   WHERE activity_id = _activity_id
     AND user_id = v_uid
     AND status = 'accepted'
   LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Only confirmed attendees can check in';
  END IF;

  -- Check-in window: 2h before → 6h after event start
  IF now() < v_act.date_time - INTERVAL '2 hours'
     OR now() > v_act.date_time + INTERVAL '6 hours' THEN
    RAISE EXCEPTION 'Check-in is open from 2 hours before the plan starts.';
  END IF;

  IF v_req.checked_in_at IS NOT NULL THEN
    RETURN QUERY SELECT 'already'::text, 0::double precision;
    RETURN;
  END IF;

  v_dist := public.haversine_m(v_act.latitude, v_act.longitude, _lat, _lon);
  IF v_dist > 150 THEN
    RETURN QUERY SELECT 'too_far'::text, v_dist;
    RETURN;
  END IF;

  UPDATE public.join_requests
     SET checked_in_at = now(), no_show = false
   WHERE id = v_req.id;

  UPDATE public.profiles
     SET reliability_score = LEAST(100, reliability_score + 2)
   WHERE id = v_uid;

  RETURN QUERY SELECT 'checked_in'::text, v_dist;
END;
$$;

REVOKE ALL ON FUNCTION public.check_in_activity(uuid, double precision, double precision) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.check_in_activity(uuid, double precision, double precision) TO authenticated;

-- 6. Host-only "mark no-show" RPC
CREATE OR REPLACE FUNCTION public.mark_no_show(_req_id uuid)
RETURNS public.join_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_req public.join_requests;
  v_act public.activities;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'Sign in required'; END IF;
  SELECT * INTO v_req FROM public.join_requests WHERE id = _req_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Request not found'; END IF;
  SELECT * INTO v_act FROM public.activities WHERE id = v_req.activity_id;
  IF v_act.host_id <> v_uid THEN
    RAISE EXCEPTION 'Only the host can mark no-shows';
  END IF;
  IF v_req.status <> 'accepted' THEN
    RAISE EXCEPTION 'Only accepted attendees can be marked no-show';
  END IF;
  IF v_req.checked_in_at IS NOT NULL THEN
    RAISE EXCEPTION 'This attendee already checked in';
  END IF;

  UPDATE public.join_requests SET no_show = true WHERE id = _req_id
    RETURNING * INTO v_req;

  UPDATE public.profiles
     SET reliability_score = GREATEST(0, reliability_score - 10)
   WHERE id = v_req.user_id;

  RETURN v_req;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_no_show(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.mark_no_show(uuid) TO authenticated;
