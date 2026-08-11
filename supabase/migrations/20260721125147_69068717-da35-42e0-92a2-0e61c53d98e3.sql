ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS has_completed_profile boolean NOT NULL DEFAULT false;

-- Backfill: existing users who have already picked interests, or clearly set their name, are treated as completed.
UPDATE public.profiles
   SET has_completed_profile = true
 WHERE has_completed_profile = false
   AND (
     has_completed_onboarding = true
     OR (full_name IS NOT NULL AND length(trim(full_name)) > 0
         AND username IS NOT NULL AND length(trim(username)) > 0
         AND city IS NOT NULL AND length(trim(city)) > 0)
   );