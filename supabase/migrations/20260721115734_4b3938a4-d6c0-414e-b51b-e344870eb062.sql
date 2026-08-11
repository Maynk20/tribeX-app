-- Drop the broad policy we added; base table becomes strictly owner-only.
DROP POLICY IF EXISTS "Authenticated can read public profile fields" ON public.profiles;

-- Recreate the view as SECURITY DEFINER (default) so it bypasses base-table RLS
-- and exposes only the safe columns to any signed-in caller.
DROP VIEW IF EXISTS public.profiles_public;
CREATE VIEW public.profiles_public AS
SELECT id, full_name, username, avatar_url, rating, is_verified
FROM public.profiles;

REVOKE ALL ON public.profiles_public FROM PUBLIC, anon;
GRANT SELECT ON public.profiles_public TO authenticated;