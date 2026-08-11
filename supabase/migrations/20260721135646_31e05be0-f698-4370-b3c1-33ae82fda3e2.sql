
-- 1. Add total_reviews to profiles
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_reviews integer NOT NULL DEFAULT 0;

-- 2. Ratings table
CREATE TABLE IF NOT EXISTS public.ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id uuid NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  reviewer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  reviewee_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating smallint NOT NULL CHECK (rating BETWEEN 1 AND 5),
  badges text[] NOT NULL DEFAULT '{}',
  comment text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT ratings_no_self CHECK (reviewer_id <> reviewee_id),
  CONSTRAINT ratings_unique_per_plan UNIQUE (plan_id, reviewer_id, reviewee_id)
);

CREATE INDEX IF NOT EXISTS ratings_reviewee_idx ON public.ratings (reviewee_id);
CREATE INDEX IF NOT EXISTS ratings_plan_idx ON public.ratings (plan_id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.ratings TO authenticated;
GRANT ALL ON public.ratings TO service_role;

ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- Reviewee can see ratings about them; reviewer can see & edit their own.
CREATE POLICY "Ratings: reviewer or reviewee can view"
  ON public.ratings FOR SELECT
  TO authenticated
  USING (auth.uid() = reviewer_id OR auth.uid() = reviewee_id);

-- Only accepted attendee or host of the plan can insert, and only for someone
-- else who is also part of the same plan (accepted attendee or host), and only
-- after the plan has started.
CREATE POLICY "Ratings: eligible attendees can insert"
  ON public.ratings FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = reviewer_id
    AND public.has_activity_access(plan_id, reviewer_id)
    AND public.has_activity_access(plan_id, reviewee_id)
    AND EXISTS (
      SELECT 1 FROM public.activities a
      WHERE a.id = plan_id AND a.date_time < now()
    )
  );

CREATE POLICY "Ratings: reviewer can update own"
  ON public.ratings FOR UPDATE
  TO authenticated
  USING (auth.uid() = reviewer_id)
  WITH CHECK (auth.uid() = reviewer_id);

CREATE POLICY "Ratings: reviewer can delete own"
  ON public.ratings FOR DELETE
  TO authenticated
  USING (auth.uid() = reviewer_id);

CREATE TRIGGER ratings_updated_at
  BEFORE UPDATE ON public.ratings
  FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

-- 3. Recalculate function
CREATE OR REPLACE FUNCTION public.recalculate_user_rating(target_user_id uuid)
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
   WHERE reviewee_id = target_user_id;

  UPDATE public.profiles
     SET rating = v_avg,
         total_reviews = v_count
   WHERE id = target_user_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.recalculate_user_rating(uuid) FROM PUBLIC, anon, authenticated;

-- 4. Trigger to recalc on insert/update/delete
CREATE OR REPLACE FUNCTION public.tg_ratings_recalc()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.recalculate_user_rating(OLD.reviewee_id);
    RETURN OLD;
  END IF;
  PERFORM public.recalculate_user_rating(NEW.reviewee_id);
  IF TG_OP = 'UPDATE' AND OLD.reviewee_id <> NEW.reviewee_id THEN
    PERFORM public.recalculate_user_rating(OLD.reviewee_id);
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER ratings_recalc_aiud
  AFTER INSERT OR UPDATE OR DELETE ON public.ratings
  FOR EACH ROW EXECUTE FUNCTION public.tg_ratings_recalc();
