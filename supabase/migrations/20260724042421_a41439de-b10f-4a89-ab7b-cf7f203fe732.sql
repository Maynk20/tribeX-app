CREATE OR REPLACE FUNCTION public.tg_notify_joiners_on_activity_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Only fire when a user-visible field actually changed.
  IF NEW.title IS NOT DISTINCT FROM OLD.title
     AND NEW.date_time IS NOT DISTINCT FROM OLD.date_time
     AND NEW.location IS NOT DISTINCT FROM OLD.location
     AND NEW.description IS NOT DISTINCT FROM OLD.description
     AND NEW.total_slots IS NOT DISTINCT FROM OLD.total_slots
     AND NEW.category IS NOT DISTINCT FROM OLD.category
     AND NEW.is_online IS NOT DISTINCT FROM OLD.is_online
     AND NEW.meeting_link IS NOT DISTINCT FROM OLD.meeting_link THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, type, title, body, activity_id, related_user_id)
  SELECT jr.user_id,
         'plan_updated',
         'Plan updated',
         'The host updated "' || COALESCE(NEW.title, 'this plan') || '". Tap to see what changed.',
         NEW.id,
         NEW.host_id
  FROM public.join_requests jr
  WHERE jr.activity_id = NEW.id
    AND jr.status = 'accepted'
    AND jr.user_id <> NEW.host_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_joiners_on_activity_update ON public.activities;
CREATE TRIGGER trg_notify_joiners_on_activity_update
AFTER UPDATE ON public.activities
FOR EACH ROW EXECUTE FUNCTION public.tg_notify_joiners_on_activity_update();

-- BLOCKS TABLE & FUNCTIONS
CREATE TABLE IF NOT EXISTS public.blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (blocker_id, blocked_id),
  CONSTRAINT no_self_block CHECK (blocker_id <> blocked_id)
);

CREATE INDEX IF NOT EXISTS blocks_blocker_idx ON public.blocks(blocker_id);
CREATE INDEX IF NOT EXISTS blocks_blocked_idx ON public.blocks(blocked_id);

GRANT SELECT, INSERT, DELETE ON public.blocks TO authenticated;
GRANT ALL ON public.blocks TO service_role;
ALTER TABLE public.blocks ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blocks' AND policyname = 'Users can view their own block relationships') THEN
    CREATE POLICY "Users can view their own block relationships" ON public.blocks
      FOR SELECT TO authenticated
      USING (auth.uid() = blocker_id OR auth.uid() = blocked_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blocks' AND policyname = 'Users can create blocks') THEN
    CREATE POLICY "Users can create blocks" ON public.blocks
      FOR INSERT TO authenticated
      WITH CHECK (auth.uid() = blocker_id);
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'blocks' AND policyname = 'Users can remove blocks') THEN
    CREATE POLICY "Users can remove blocks" ON public.blocks
      FOR DELETE TO authenticated
      USING (auth.uid() = blocker_id);
  END IF;
END $$;

-- RPC to block user & auto-cancel join requests
CREATE OR REPLACE FUNCTION public.block_user(_target_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _me UUID := auth.uid();
BEGIN
  IF _me IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;
  IF _me = _target_id THEN
    RAISE EXCEPTION 'Cannot block yourself';
  END IF;

  INSERT INTO public.blocks (blocker_id, blocked_id)
  VALUES (_me, _target_id)
  ON CONFLICT (blocker_id, blocked_id) DO NOTHING;

  -- Auto-reject/cancel pending join requests between caller and target in both directions
  UPDATE public.join_requests jr
  SET status = 'rejected'
  FROM public.activities a
  WHERE jr.activity_id = a.id
    AND jr.status = 'pending'
    AND (
      (jr.user_id = _target_id AND a.host_id = _me) OR
      (jr.user_id = _me AND a.host_id = _target_id)
    );
END;
$$;

-- RPC to unblock user
CREATE OR REPLACE FUNCTION public.unblock_user(_target_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  _me UUID := auth.uid();
BEGIN
  IF _me IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  DELETE FROM public.blocks
  WHERE blocker_id = _me AND blocked_id = _target_id;
END;
$$;

-- RPC to list blocked users for setting view
CREATE OR REPLACE FUNCTION public.list_blocked_users()
RETURNS TABLE (
  id UUID,
  username TEXT,
  full_name TEXT,
  avatar_url TEXT,
  rating NUMERIC(3,2),
  is_verified BOOLEAN
) LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.id, p.username, p.full_name, p.avatar_url, p.rating, p.is_verified
  FROM public.blocks b
  JOIN public.profiles p ON p.id = b.blocked_id
  WHERE b.blocker_id = auth.uid()
  ORDER BY b.created_at DESC;
$$;

-- Helper function to check if either user blocked the other
CREATE OR REPLACE FUNCTION public.is_blocked_between(_user_a UUID, _user_b UUID)
RETURNS BOOLEAN LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.blocks
    WHERE (blocker_id = _user_a AND blocked_id = _user_b)
       OR (blocker_id = _user_b AND blocked_id = _user_a)
  );
$$;