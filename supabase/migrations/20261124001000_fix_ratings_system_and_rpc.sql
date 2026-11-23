-- Migration: 20261124001000_fix_ratings_system_and_rpc.sql
-- Purpose:
-- 1. Create atomic, security-definer RPC `submit_squad_rating` for reciprocal host & member ratings.
-- 2. Repair RLS policies on `public.ratings` for seamless INSERT and UPDATE (upsert).
-- 3. Ensure profile rating recalculation handles reciprocal ratings accurately.

-- 1. Ensure ratings table constraints
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'ratings_no_self'
  ) THEN
    ALTER TABLE public.ratings ADD CONSTRAINT ratings_no_self CHECK (reviewer_id <> reviewee_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'ratings_unique_per_plan'
  ) THEN
    ALTER TABLE public.ratings ADD CONSTRAINT ratings_unique_per_plan UNIQUE (plan_id, reviewer_id, reviewee_id);
  END IF;
END $$;

-- 2. Recalculate user rating helper (parameter _user_id preserved)
CREATE OR REPLACE FUNCTION public.recalculate_user_rating(_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_avg numeric(3,2);
  v_count integer;
BEGIN
  SELECT COALESCE(ROUND(AVG(rating)::numeric, 1), 5.0),
         COUNT(*)
    INTO v_avg, v_count
    FROM public.ratings
   WHERE reviewee_id = _user_id;

  UPDATE public.profiles
     SET rating = v_avg,
         total_reviews = v_count
   WHERE id = _user_id;
END;
$$;
GRANT EXECUTE ON FUNCTION public.recalculate_user_rating(uuid) TO authenticated, service_role;

-- 3. Atomic reciprocal rating submission RPC
DROP FUNCTION IF EXISTS public.submit_squad_rating(uuid, uuid, integer, text[], text);
CREATE OR REPLACE FUNCTION public.submit_squad_rating(
  _plan_id uuid,
  _reviewee_id uuid,
  _rating integer,
  _badges text[] DEFAULT '{}',
  _comment text DEFAULT NULL
)
RETURNS public.ratings
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reviewer_id uuid;
  v_activity public.activities;
  v_rating_row public.ratings;
BEGIN
  v_reviewer_id := auth.uid();
  IF v_reviewer_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  -- 1. Self-rating is forbidden
  IF v_reviewer_id = _reviewee_id THEN
    RAISE EXCEPTION 'You cannot rate yourself';
  END IF;

  -- 2. Validate rating range (1-5)
  IF _rating < 1 OR _rating > 5 THEN
    RAISE EXCEPTION 'Rating must be between 1 and 5 stars';
  END IF;

  -- 3. Verify plan exists
  SELECT * INTO v_activity
  FROM public.activities
  WHERE id = _plan_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  -- 4. Verify plan is completed or started
  -- (Allow up to 10 min clock skew buffer)
  IF v_activity.date_time > now() + INTERVAL '10 minutes' THEN
    RAISE EXCEPTION 'Rating becomes available once the plan has started';
  END IF;

  -- 5. Verify reviewer is an eligible participant (host or accepted attendee)
  IF NOT (
    v_activity.host_id = v_reviewer_id OR
    EXISTS (
      SELECT 1 FROM public.join_requests
      WHERE activity_id = _plan_id AND user_id = v_reviewer_id AND status = 'accepted'
    )
  ) THEN
    RAISE EXCEPTION 'Only confirmed participants can rate squad members';
  END IF;

  -- 6. Verify reviewee is an eligible participant (host or accepted attendee)
  IF NOT (
    v_activity.host_id = _reviewee_id OR
    EXISTS (
      SELECT 1 FROM public.join_requests
      WHERE activity_id = _plan_id AND user_id = _reviewee_id AND status = 'accepted'
    )
  ) THEN
    RAISE EXCEPTION 'Target user is not a confirmed participant in this plan';
  END IF;

  -- 7. Upsert rating record atomically
  INSERT INTO public.ratings (
    plan_id,
    reviewer_id,
    reviewee_id,
    rating,
    badges,
    comment,
    updated_at
  )
  VALUES (
    _plan_id,
    v_reviewer_id,
    _reviewee_id,
    _rating::smallint,
    COALESCE(_badges, '{}'),
    NULLIF(TRIM(_comment), ''),
    now()
  )
  ON CONFLICT (plan_id, reviewer_id, reviewee_id)
  DO UPDATE SET
    rating = EXCLUDED.rating,
    badges = EXCLUDED.badges,
    comment = EXCLUDED.comment,
    updated_at = now()
  RETURNING * INTO v_rating_row;

  -- 8. Recalculate target user's profile rating and reviews
  PERFORM public.recalculate_user_rating(_reviewee_id);

  RETURN v_rating_row;
END;
$$;
GRANT EXECUTE ON FUNCTION public.submit_squad_rating(uuid, uuid, integer, text[], text) TO authenticated, service_role;

-- 4. Repair RLS policies on public.ratings
DROP POLICY IF EXISTS "Ratings: reviewer or reviewee can view" ON public.ratings;
DROP POLICY IF EXISTS "Ratings: participants can view plan ratings" ON public.ratings;
CREATE POLICY "Ratings: participants can view plan ratings"
  ON public.ratings FOR SELECT
  TO authenticated
  USING (
    auth.uid() = reviewer_id
    OR auth.uid() = reviewee_id
    OR public.has_activity_access(plan_id, auth.uid())
  );

DROP POLICY IF EXISTS "Ratings: eligible attendees can insert" ON public.ratings;
CREATE POLICY "Ratings: eligible attendees can insert"
  ON public.ratings FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = reviewer_id
    AND reviewer_id <> reviewee_id
    AND rating BETWEEN 1 AND 5
    AND public.has_activity_access(plan_id, reviewer_id)
    AND public.has_activity_access(plan_id, reviewee_id)
  );

DROP POLICY IF EXISTS "Ratings: reviewer can update own" ON public.ratings;
CREATE POLICY "Ratings: reviewer can update own"
  ON public.ratings FOR UPDATE
  TO authenticated
  USING (auth.uid() = reviewer_id)
  WITH CHECK (
    auth.uid() = reviewer_id
    AND reviewer_id <> reviewee_id
    AND rating BETWEEN 1 AND 5
    AND public.has_activity_access(plan_id, reviewer_id)
    AND public.has_activity_access(plan_id, reviewee_id)
  );

DROP POLICY IF EXISTS "Ratings: reviewer can delete own" ON public.ratings;
CREATE POLICY "Ratings: reviewer can delete own"
  ON public.ratings FOR DELETE
  TO authenticated
  USING (auth.uid() = reviewer_id);
