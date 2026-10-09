-- Migration: Enable Realtime for Messaging & Polls, Add Terms tracking columns, and grant account deletion
-- Safe additive migration

-- 1. Ensure columns exist on profiles for terms and policies tracking
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS terms_version TEXT DEFAULT 'v1.0';

-- 2. Grant execute on delete_user_account to authenticated users
DO $$ BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'delete_user_account'
  ) THEN
    GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;
  END IF;
END $$;

-- 3. Set REPLICA IDENTITY FULL to ensure Realtime change payloads contain all fields
DO $$ BEGIN
  ALTER TABLE public.messages REPLICA IDENTITY FULL;
  ALTER TABLE public.polls REPLICA IDENTITY FULL;
  ALTER TABLE public.poll_votes REPLICA IDENTITY FULL;
  ALTER TABLE public.activities REPLICA IDENTITY FULL;
EXCEPTION
  WHEN OTHERS THEN NULL;
END $$;

-- 4. Add tables to supabase_realtime publication safely
DO $$
BEGIN
  -- messages
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
  END IF;

  -- polls
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'polls'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.polls;
  END IF;

  -- poll_votes
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'poll_votes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.poll_votes;
  END IF;

  -- activities
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'activities'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.activities;
  END IF;
END $$;
