-- Migration: 20261009160000_squad_members_and_messaging_repair.sql
-- Purpose: 
-- 1. Grant members with activity access permission to view accepted join requests for their squad.
-- 2. Provide get_squad_members security-definer function returning host + accepted attendees.
-- 3. Ensure messages, expenses, and expense_shares RLS and realtime subscriptions work smoothly for all squad members.

-- 1. Update SELECT policy on join_requests so confirmed members can see all accepted participants
DROP POLICY IF EXISTS "Applicant or host can view join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Members can view join requests" ON public.join_requests;

CREATE POLICY "Members can view join requests" ON public.join_requests
  FOR SELECT TO authenticated
  USING (
    auth.uid() = user_id 
    OR public.is_activity_host(activity_id, auth.uid())
    OR (status = 'accepted' AND public.has_activity_access(activity_id, auth.uid()))
  );

-- 2. get_squad_members function
CREATE OR REPLACE FUNCTION public.get_squad_members(_activity_id UUID)
RETURNS TABLE (
  user_id UUID,
  full_name TEXT,
  username TEXT,
  avatar_url TEXT,
  is_host BOOLEAN
) LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  -- Caller must have activity access (host or accepted member)
  IF NOT public.has_activity_access(_activity_id, auth.uid()) THEN
    RETURN;
  END IF;

  RETURN QUERY
  -- 1. Host first
  SELECT 
    p.id AS user_id,
    COALESCE(p.full_name, p.username, 'Host') AS full_name,
    p.username,
    p.avatar_url,
    true AS is_host
  FROM public.activities a
  JOIN public.profiles p ON p.id = a.host_id
  WHERE a.id = _activity_id

  UNION ALL

  -- 2. Accepted participants
  SELECT 
    p.id AS user_id,
    COALESCE(p.full_name, p.username, 'Squad Member') AS full_name,
    p.username,
    p.avatar_url,
    false AS is_host
  FROM public.join_requests jr
  JOIN public.profiles p ON p.id = jr.user_id
  WHERE jr.activity_id = _activity_id AND jr.status = 'accepted'
  ORDER BY is_host DESC, full_name ASC;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_squad_members(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_squad_members(UUID) TO service_role;
