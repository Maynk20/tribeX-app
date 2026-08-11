
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS has_completed_onboarding boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS interests text[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS profiles_interests_gin_idx ON public.profiles USING GIN (interests);

-- Trigger: when a new activity is created, notify users whose interests contain the category
-- and whose city matches the event location (case-insensitive substring match either way).
CREATE OR REPLACE FUNCTION public.tg_notify_matching_users_on_activity()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_host_name text;
BEGIN
  SELECT COALESCE(full_name, username, 'Someone') INTO v_host_name
  FROM public.profiles WHERE id = NEW.host_id;

  INSERT INTO public.notifications (user_id, type, title, body, activity_id, related_user_id)
  SELECT
    p.id,
    'event_match',
    'New ' || NEW.category || ' in your area!',
    COALESCE(v_host_name, 'Someone') || ' created "' || NEW.title || '" near ' || NEW.location || '. Check it out!',
    NEW.id,
    NEW.host_id
  FROM public.profiles p
  WHERE p.id <> NEW.host_id
    AND NEW.category = ANY (p.interests)
    AND p.city IS NOT NULL
    AND length(trim(p.city)) > 0
    AND (
      lower(NEW.location) LIKE '%' || lower(p.city) || '%'
      OR lower(p.city) LIKE '%' || lower(split_part(NEW.location, ',', 1)) || '%'
    );
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS activities_notify_matching_users ON public.activities;
CREATE TRIGGER activities_notify_matching_users
AFTER INSERT ON public.activities
FOR EACH ROW EXECUTE FUNCTION public.tg_notify_matching_users_on_activity();
