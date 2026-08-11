
-- ============ EVENT MEMORIES ============
CREATE TABLE public.event_memories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  image_url text NOT NULL,
  caption text,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_event_memories_activity ON public.event_memories(activity_id, created_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.event_memories TO authenticated;
GRANT ALL ON public.event_memories TO service_role;
ALTER TABLE public.event_memories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Plan members can view memories"
  ON public.event_memories FOR SELECT TO authenticated
  USING (public.has_activity_access(activity_id, auth.uid()));

CREATE POLICY "Plan members can upload their own memories"
  ON public.event_memories FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id AND public.has_activity_access(activity_id, auth.uid()));

CREATE POLICY "Users can delete their own memories"
  ON public.event_memories FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============ POLLS ============
CREATE TABLE public.polls (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id uuid NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  created_by uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  question text NOT NULL,
  options jsonb NOT NULL, -- array of strings
  closed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_polls_activity ON public.polls(activity_id, created_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.polls TO authenticated;
GRANT ALL ON public.polls TO service_role;
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Plan members can view polls"
  ON public.polls FOR SELECT TO authenticated
  USING (public.has_activity_access(activity_id, auth.uid()));

CREATE POLICY "Plan members can create polls"
  ON public.polls FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = created_by AND public.has_activity_access(activity_id, auth.uid()));

CREATE POLICY "Creator can close/edit own polls"
  ON public.polls FOR UPDATE TO authenticated
  USING (auth.uid() = created_by)
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Creator can delete own polls"
  ON public.polls FOR DELETE TO authenticated
  USING (auth.uid() = created_by);

-- ============ POLL VOTES ============
CREATE TABLE public.poll_votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id uuid NOT NULL REFERENCES public.polls(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  option_index int NOT NULL CHECK (option_index >= 0 AND option_index < 20),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (poll_id, user_id)
);
CREATE INDEX idx_poll_votes_poll ON public.poll_votes(poll_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.poll_votes TO authenticated;
GRANT ALL ON public.poll_votes TO service_role;
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Plan members can view poll votes"
  ON public.poll_votes FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_id AND public.has_activity_access(p.activity_id, auth.uid())
    )
  );

CREATE POLICY "Plan members can cast their own vote"
  ON public.poll_votes FOR INSERT TO authenticated
  WITH CHECK (
    auth.uid() = user_id AND EXISTS (
      SELECT 1 FROM public.polls p
      WHERE p.id = poll_id AND public.has_activity_access(p.activity_id, auth.uid())
    )
  );

CREATE POLICY "Users can change their own vote"
  ON public.poll_votes FOR UPDATE TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can retract their own vote"
  ON public.poll_votes FOR DELETE TO authenticated
  USING (auth.uid() = user_id);

-- ============ STORAGE: event-memories bucket ============
CREATE POLICY "Auth users can view event memory photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'event-memories');

CREATE POLICY "Auth users can upload event memories to own folder"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'event-memories'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete own event memory photos"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'event-memories'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
