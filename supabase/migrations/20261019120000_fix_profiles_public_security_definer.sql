-- Fix profiles_public view: remove security_invoker so authenticated users can read public profile fields.
-- This restores the security-definer view behavior originally established in migration 20260721115734,
-- preventing RLS on the base profiles table (auth.uid() = id) from blocking reads of safe public profile fields.
DROP VIEW IF EXISTS public.profiles_public;
CREATE VIEW public.profiles_public AS
SELECT id, full_name, username, avatar_url, rating, is_verified, reliability_score
FROM public.profiles;

REVOKE ALL ON public.profiles_public FROM PUBLIC, anon;
GRANT SELECT ON public.profiles_public TO authenticated;
