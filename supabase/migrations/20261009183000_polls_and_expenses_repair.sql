-- Migration: 20261009183000_polls_and_expenses_repair.sql
-- Purpose:
-- 1. Ensure public.polls and public.poll_votes RLS policies allow any confirmed squad member (via has_activity_access) to view, create, vote, and retract votes.
-- 2. Ensure Realtime is enabled with FULL replica identity on polls and poll_votes.

-- ============ 1. POLLS RLS ============
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Plan members can view polls" ON public.polls;
CREATE POLICY "Plan members can view polls"
  ON public.polls FOR SELECT TO authenticated
  USING (
    created_by = auth.uid() 
    OR public.has_activity_access(activity_id, auth.uid())
  );

DROP POLICY IF EXISTS "Plan members can create polls" ON public.polls;
CREATE POLICY "Plan members can create polls"
  ON public.polls FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = created_by 
    AND public.has_activity_access(activity_id, auth.uid())
  );

DROP POLICY IF EXISTS "Creator can close/edit own polls" ON public.polls;
CREATE POLICY "Creator can close/edit own polls"
  ON public.polls FOR UPDATE TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Creator can delete own polls" ON public.polls;
CREATE POLICY "Creator can delete own polls"
  ON public.polls FOR DELETE TO authenticated
  USING (auth.uid() = created_by);

-- ============ 2. POLL VOTES RLS ============
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Plan members can view poll votes" ON public.poll_votes;
CREATE POLICY "Plan members can view poll votes"
  ON public.poll_votes FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_votes.poll_id 
        AND (p.created_by = auth.uid() OR public.has_activity_access(p.activity_id, auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Plan members can cast their own vote" ON public.poll_votes;
CREATE POLICY "Plan members can cast their own vote"
  ON public.poll_votes FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id 
    AND EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_votes.poll_id 
        AND (p.created_by = auth.uid() OR public.has_activity_access(p.activity_id, auth.uid()))
    )
  );

DROP POLICY IF EXISTS "Users can change their own vote" ON public.poll_votes;
CREATE POLICY "Users can change their own vote"
  ON public.poll_votes FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can retract their own vote" ON public.poll_votes;
CREATE POLICY "Users can retract their own vote"
  ON public.poll_votes FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============ 3. REALTIME ============
DO $$ BEGIN
  ALTER TABLE public.polls REPLICA IDENTITY FULL;
  ALTER TABLE public.poll_votes REPLICA IDENTITY FULL;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'polls'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.polls;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'poll_votes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_votes;
  END IF;
END $$;
