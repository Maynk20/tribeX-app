-- Migration: Production Database Security, RLS Hardening & Realtime Synchronization Patch
-- Date: 2026-11-23
-- Target: Supabase / PostgreSQL 14+

-- 1. SEC-02: Fix join_requests UPDATE RLS privilege escalation
-- Drop existing over-permissive update policy
DROP POLICY IF EXISTS "Applicant or host can update join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Hosts can update join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Applicants can cancel or leave join requests" ON public.join_requests;

-- Hosts can approve, reject, or manage join requests for their own activities
CREATE POLICY "Hosts can update join requests"
ON public.join_requests
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
);

-- Applicants can only cancel a pending request or mark as rejected when leaving
-- CRITICAL SECURITY ENFORCEMENT: Applicants CANNOT set status = 'accepted'
CREATE POLICY "Applicants can cancel or leave join requests"
ON public.join_requests
FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id
)
WITH CHECK (
  auth.uid() = user_id
  AND status = 'rejected'::public.join_status
);

-- 2. DB-03: Grant SELECT on profiles_public view to anonymous users
-- The view exposes only non-sensitive public columns (id, full_name, username, avatar_url, rating, is_verified, reliability_score)
-- This allows unauthenticated guest visitors to browse the explore feed and resolve host profiles without 403 errors.
GRANT SELECT ON public.profiles_public TO anon;
GRANT SELECT ON public.profiles_public TO authenticated;

-- 4. DB-05: Ensure DELETE policies on join_requests for Host and Applicant
DROP POLICY IF EXISTS "Applicant or host can delete join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Hosts can delete join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Applicants can delete join requests" ON public.join_requests;

CREATE POLICY "Hosts can delete join requests"
ON public.join_requests
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
);

CREATE POLICY "Applicants can delete join requests"
ON public.join_requests
FOR DELETE
TO authenticated
USING (
  auth.uid() = user_id
);

-- 5. DB-06: Production-grade RPCs to remove users from created groups/activities

-- Function 1: Remove user from activity by request ID
DROP FUNCTION IF EXISTS public.remove_join_request(uuid);
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

-- Function 2: Remove user from activity by activity ID and user ID
DROP FUNCTION IF EXISTS public.remove_user_from_activity(uuid, uuid);
CREATE OR REPLACE FUNCTION public.remove_user_from_activity(_activity_id uuid, _user_id uuid)
RETURNS public.join_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_req public.join_requests;
  v_activity public.activities;
BEGIN
  SELECT * INTO v_activity
  FROM public.activities
  WHERE id = _activity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  IF v_activity.host_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only the host can remove attendees';
  END IF;

  SELECT * INTO v_req
  FROM public.join_requests
  WHERE activity_id = _activity_id
    AND user_id = _user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User is not a participant in this plan';
  END IF;

  IF v_req.status <> 'rejected' THEN
    UPDATE public.join_requests
       SET status = 'rejected'
     WHERE id = v_req.id
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
GRANT EXECUTE ON FUNCTION public.remove_user_from_activity(uuid, uuid) TO authenticated, service_role;

-- Function 3: List join profiles for host (ensuring ONLY pending and accepted are returned)
DROP FUNCTION IF EXISTS public.list_activity_join_profiles(uuid);
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
  LEFT JOIN public.profiles p ON p.id = jr.user_id
  WHERE jr.activity_id = _activity_id
    AND jr.status IN ('pending', 'accepted')
  ORDER BY jr.created_at ASC;
END;
$$;
GRANT EXECUTE ON FUNCTION public.list_activity_join_profiles(uuid) TO authenticated, service_role;
DO $$ BEGIN
  ALTER TABLE public.expense_shares REPLICA IDENTITY FULL;
  ALTER TABLE public.notifications REPLICA IDENTITY FULL;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

DO $$
BEGIN
  -- expense_shares
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'expense_shares'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.expense_shares;
  END IF;

  -- notifications
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;
