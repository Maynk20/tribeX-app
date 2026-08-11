-- Repair policies that previously called private helper functions directly.
-- The helpers remain non-executable by app roles; policies now inline the same checks.

DROP POLICY IF EXISTS "Applicant or host can view join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Applicant or host can update join requests" ON public.join_requests;
DROP POLICY IF EXISTS "Applicant or host can delete join requests" ON public.join_requests;

CREATE POLICY "Applicant or host can view join requests"
ON public.join_requests
FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
);

CREATE POLICY "Applicant or host can update join requests"
ON public.join_requests
FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
)
WITH CHECK (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
);

CREATE POLICY "Applicant or host can delete join requests"
ON public.join_requests
FOR DELETE
TO authenticated
USING (
  auth.uid() = user_id
  OR EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = join_requests.activity_id
      AND a.host_id = auth.uid()
  )
);

DROP POLICY IF EXISTS "Members can read messages" ON public.messages;
DROP POLICY IF EXISTS "Members can send messages" ON public.messages;

CREATE POLICY "Members can read messages"
ON public.messages
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = messages.activity_id
      AND a.host_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.join_requests jr
    WHERE jr.activity_id = messages.activity_id
      AND jr.user_id = auth.uid()
      AND jr.status = 'accepted'
  )
);

CREATE POLICY "Members can send messages"
ON public.messages
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = sender_id
  AND (
    EXISTS (
      SELECT 1
      FROM public.activities a
      WHERE a.id = messages.activity_id
        AND a.host_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.join_requests jr
      WHERE jr.activity_id = messages.activity_id
        AND jr.user_id = auth.uid()
        AND jr.status = 'accepted'
    )
  )
);

DROP POLICY IF EXISTS "Plan members can view memories" ON public.event_memories;
DROP POLICY IF EXISTS "Plan members can upload their own memories" ON public.event_memories;

CREATE POLICY "Plan members can view memories"
ON public.event_memories
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.activities a
    WHERE a.id = event_memories.activity_id AND a.host_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.join_requests jr
    WHERE jr.activity_id = event_memories.activity_id
      AND jr.user_id = auth.uid()
      AND jr.status = 'accepted'
  )
);

CREATE POLICY "Plan members can upload their own memories"
ON public.event_memories
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND (
    EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = event_memories.activity_id AND a.host_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.join_requests jr
      WHERE jr.activity_id = event_memories.activity_id
        AND jr.user_id = auth.uid()
        AND jr.status = 'accepted'
    )
  )
);

DROP POLICY IF EXISTS "Members can view expenses" ON public.expenses;
DROP POLICY IF EXISTS "Members can create expenses" ON public.expenses;
DROP POLICY IF EXISTS "Members can view expense shares" ON public.expense_shares;

CREATE POLICY "Members can view expenses"
ON public.expenses
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.activities a
    WHERE a.id = expenses.activity_id AND a.host_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.join_requests jr
    WHERE jr.activity_id = expenses.activity_id
      AND jr.user_id = auth.uid()
      AND jr.status = 'accepted'
  )
);

CREATE POLICY "Members can create expenses"
ON public.expenses
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = created_by
  AND (
    EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = expenses.activity_id AND a.host_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.join_requests jr
      WHERE jr.activity_id = expenses.activity_id
        AND jr.user_id = auth.uid()
        AND jr.status = 'accepted'
    )
  )
);

CREATE POLICY "Members can view expense shares"
ON public.expense_shares
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.expenses e
    JOIN public.activities a ON a.id = e.activity_id
    WHERE e.id = expense_shares.expense_id
      AND a.host_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.expenses e
    JOIN public.join_requests jr ON jr.activity_id = e.activity_id
    WHERE e.id = expense_shares.expense_id
      AND jr.user_id = auth.uid()
      AND jr.status = 'accepted'
  )
);

DROP POLICY IF EXISTS "Plan members can view polls" ON public.polls;
DROP POLICY IF EXISTS "Plan members can create polls" ON public.polls;
DROP POLICY IF EXISTS "Plan members can view poll votes" ON public.poll_votes;
DROP POLICY IF EXISTS "Plan members can cast their own vote" ON public.poll_votes;

CREATE POLICY "Plan members can view polls"
ON public.polls
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM public.activities a
    WHERE a.id = polls.activity_id AND a.host_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.join_requests jr
    WHERE jr.activity_id = polls.activity_id
      AND jr.user_id = auth.uid()
      AND jr.status = 'accepted'
  )
);

CREATE POLICY "Plan members can create polls"
ON public.polls
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = created_by
  AND (
    EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = polls.activity_id AND a.host_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.join_requests jr
      WHERE jr.activity_id = polls.activity_id
        AND jr.user_id = auth.uid()
        AND jr.status = 'accepted'
    )
  )
);

CREATE POLICY "Plan members can view poll votes"
ON public.poll_votes
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.polls p
    JOIN public.activities a ON a.id = p.activity_id
    WHERE p.id = poll_votes.poll_id
      AND a.host_id = auth.uid()
  )
  OR EXISTS (
    SELECT 1
    FROM public.polls p
    JOIN public.join_requests jr ON jr.activity_id = p.activity_id
    WHERE p.id = poll_votes.poll_id
      AND jr.user_id = auth.uid()
      AND jr.status = 'accepted'
  )
);

CREATE POLICY "Plan members can cast their own vote"
ON public.poll_votes
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND (
    EXISTS (
      SELECT 1
      FROM public.polls p
      JOIN public.activities a ON a.id = p.activity_id
      WHERE p.id = poll_votes.poll_id
        AND a.host_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1
      FROM public.polls p
      JOIN public.join_requests jr ON jr.activity_id = p.activity_id
      WHERE p.id = poll_votes.poll_id
        AND jr.user_id = auth.uid()
        AND jr.status = 'accepted'
    )
  )
);

DROP POLICY IF EXISTS "Ratings: eligible attendees can insert" ON public.ratings;

CREATE POLICY "Ratings: eligible attendees can insert"
ON public.ratings
FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = reviewer_id
  AND EXISTS (
    SELECT 1
    FROM public.activities a
    WHERE a.id = ratings.plan_id
      AND a.date_time < now()
  )
  AND (
    EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = ratings.plan_id AND a.host_id = reviewer_id
    )
    OR EXISTS (
      SELECT 1 FROM public.join_requests jr
      WHERE jr.activity_id = ratings.plan_id
        AND jr.user_id = reviewer_id
        AND jr.status = 'accepted'
    )
  )
  AND (
    EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = ratings.plan_id AND a.host_id = reviewee_id
    )
    OR EXISTS (
      SELECT 1 FROM public.join_requests jr
      WHERE jr.activity_id = ratings.plan_id
        AND jr.user_id = reviewee_id
        AND jr.status = 'accepted'
    )
  )
);

REVOKE EXECUTE ON FUNCTION public.is_activity_host(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.has_activity_access(uuid, uuid) FROM PUBLIC, anon, authenticated;