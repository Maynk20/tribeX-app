GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.is_activity_host(uuid, uuid) TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.has_activity_access(uuid, uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.accept_join_request(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.check_in_activity(uuid, double precision, double precision) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_meeting_link(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.mark_no_show(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.haversine_m(double precision, double precision, double precision, double precision) TO authenticated, service_role;

DROP POLICY IF EXISTS "Users can request to join" ON public.join_requests;
CREATE POLICY "Users can request to join with verified profile location"
ON public.join_requests
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.id = auth.uid()
      AND p.city IS NOT NULL
      AND length(trim(p.city)) > 0
      AND p.latitude IS NOT NULL
      AND p.longitude IS NOT NULL
  )
);

CREATE OR REPLACE FUNCTION public.list_activity_join_profiles(_activity_id uuid)
RETURNS TABLE(
  join_request_id uuid,
  activity_id uuid,
  user_id uuid,
  status public.join_status,
  checked_in_at timestamptz,
  no_show boolean,
  requested_at timestamptz,
  full_name text,
  username text,
  avatar_url text,
  rating numeric,
  reliability_score integer,
  is_verified boolean,
  city text,
  latitude double precision,
  longitude double precision,
  total_reviews integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.activities a
    WHERE a.id = _activity_id AND a.host_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Only the host can view plan request profiles';
  END IF;

  RETURN QUERY
  SELECT
    jr.id,
    jr.activity_id,
    jr.user_id,
    jr.status,
    jr.checked_in_at,
    jr.no_show,
    jr.created_at,
    p.full_name,
    p.username,
    p.avatar_url,
    p.rating,
    p.reliability_score,
    p.is_verified,
    p.city,
    p.latitude,
    p.longitude,
    p.total_reviews
  FROM public.join_requests jr
  JOIN public.profiles p ON p.id = jr.user_id
  WHERE jr.activity_id = _activity_id
    AND jr.status IN ('pending', 'accepted')
  ORDER BY
    CASE jr.status WHEN 'pending' THEN 0 WHEN 'accepted' THEN 1 ELSE 2 END,
    jr.created_at ASC
  LIMIT 25;
END;
$$;
GRANT EXECUTE ON FUNCTION public.list_activity_join_profiles(uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.remove_join_request(_req_id uuid)
RETURNS public.join_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_req public.join_requests;
  v_activity public.activities;
BEGIN
  SELECT * INTO v_req
  FROM public.join_requests
  WHERE id = _req_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  SELECT * INTO v_activity
  FROM public.activities
  WHERE id = v_req.activity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  IF v_activity.host_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only the host can remove attendees';
  END IF;

  IF v_req.status <> 'rejected' THEN
    UPDATE public.join_requests
       SET status = 'rejected'
     WHERE id = _req_id
     RETURNING * INTO v_req;

    INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
    VALUES (
      v_req.user_id,
      'removed_from_plan',
      'Removed from plan',
      'The host removed you from "' || COALESCE(v_activity.title, 'this plan') || '".',
      v_req.activity_id,
      v_req.id
    );
  END IF;

  RETURN v_req;
END;
$$;
GRANT EXECUTE ON FUNCTION public.remove_join_request(uuid) TO authenticated, service_role;

CREATE OR REPLACE FUNCTION public.tg_sync_slots_on_join_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status <> 'accepted' AND NEW.status = 'accepted' THEN
    UPDATE public.activities SET slots_left = GREATEST(slots_left - 1, 0) WHERE id = NEW.activity_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'accepted' AND NEW.status <> 'accepted' THEN
    UPDATE public.activities SET slots_left = LEAST(slots_left + 1, total_slots) WHERE id = NEW.activity_id;
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
    UPDATE public.activities SET slots_left = LEAST(slots_left + 1, total_slots) WHERE id = OLD.activity_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS sync_slots_on_join_change ON public.join_requests;
CREATE TRIGGER sync_slots_on_join_change
AFTER UPDATE OR DELETE ON public.join_requests
FOR EACH ROW
EXECUTE FUNCTION public.tg_sync_slots_on_join_change();

DROP TRIGGER IF EXISTS set_join_requests_updated_at ON public.join_requests;
CREATE TRIGGER set_join_requests_updated_at
BEFORE UPDATE ON public.join_requests
FOR EACH ROW
EXECUTE FUNCTION public.tg_set_updated_at();

DROP TRIGGER IF EXISTS set_activities_updated_at ON public.activities;
CREATE TRIGGER set_activities_updated_at
BEFORE UPDATE ON public.activities
FOR EACH ROW
EXECUTE FUNCTION public.tg_set_updated_at();

DROP TRIGGER IF EXISTS init_activity_slots_left ON public.activities;
CREATE TRIGGER init_activity_slots_left
BEFORE INSERT ON public.activities
FOR EACH ROW
EXECUTE FUNCTION public.tg_init_slots_left();

DROP TRIGGER IF EXISTS ratings_recalculate_profile ON public.ratings;
CREATE TRIGGER ratings_recalculate_profile
AFTER INSERT OR UPDATE OR DELETE ON public.ratings
FOR EACH ROW
EXECUTE FUNCTION public.tg_ratings_recalc();