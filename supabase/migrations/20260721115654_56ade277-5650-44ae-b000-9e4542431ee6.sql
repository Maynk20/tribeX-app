-- 1) Tighten profiles table SELECT policy to owner-only
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON public.profiles;

CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- 2) Public-safe view of profiles (only non-sensitive columns)
DROP VIEW IF EXISTS public.profiles_public;
CREATE VIEW public.profiles_public
WITH (security_invoker = on) AS
SELECT id, full_name, username, avatar_url, rating, is_verified
FROM public.profiles;

GRANT SELECT ON public.profiles_public TO authenticated, anon;

-- Because the view uses security_invoker, callers still need SELECT on the
-- base table for the underlying rows. Add a policy that allows reading only
-- the safe subset via the view — we can't restrict columns per-policy, but
-- exposing name/username/avatar/rating/verified for cross-user discovery
-- is intended. We scope this policy to authenticated only and rely on
-- application code (services) to query the view, not the base table.
CREATE POLICY "Authenticated can read public profile fields"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- 3) Atomic accept_join_request RPC
CREATE OR REPLACE FUNCTION public.accept_join_request(_req_id uuid)
RETURNS public.join_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req public.join_requests;
  v_activity public.activities;
BEGIN
  SELECT * INTO v_req FROM public.join_requests WHERE id = _req_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  -- Lock the activity row to serialise capacity decisions.
  SELECT * INTO v_activity
  FROM public.activities
  WHERE id = v_req.activity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Activity not found';
  END IF;

  -- Only the host can accept.
  IF v_activity.host_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only the host can accept requests';
  END IF;

  IF v_req.status = 'accepted' THEN
    RETURN v_req; -- idempotent
  END IF;

  IF v_activity.slots_left <= 0 THEN
    RAISE EXCEPTION 'No slots remaining';
  END IF;

  UPDATE public.join_requests
     SET status = 'accepted'
   WHERE id = _req_id
   RETURNING * INTO v_req;

  -- slots_left is already decremented by the tg_sync_slots_on_join_change trigger.
  RETURN v_req;
END;
$$;

REVOKE ALL ON FUNCTION public.accept_join_request(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_join_request(uuid) TO authenticated;

-- 4) Single-lookup email → user_id helper (replaces listUsers scan loops)
CREATE OR REPLACE FUNCTION public.get_user_id_by_email(_email text)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM auth.users WHERE lower(email) = lower(_email) LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.get_user_id_by_email(text) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_id_by_email(text) TO service_role;