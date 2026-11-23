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
  AND status IN ('cancelled', 'rejected')
);

-- 2. DB-03: Grant SELECT on profiles_public view to anonymous users
-- The view exposes only non-sensitive public columns (id, full_name, username, avatar_url, rating, is_verified, reliability_score)
-- This allows unauthenticated guest visitors to browse the explore feed and resolve host profiles without 403 errors.
GRANT SELECT ON public.profiles_public TO anon;
GRANT SELECT ON public.profiles_public TO authenticated;

-- 3. DB-04: Enable REPLICA IDENTITY FULL and add missing tables to supabase_realtime publication
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
