
ALTER TABLE public.activities
  ADD COLUMN IF NOT EXISTS women_only BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS verified_only BOOLEAN NOT NULL DEFAULT false;

-- Replace the open SELECT policy with a Safety Shield-aware one.
-- Non-matching users cannot see restricted plans at all.
DROP POLICY IF EXISTS "Activities are viewable by everyone" ON public.activities;

CREATE POLICY "Activities visible respecting safety filters"
  ON public.activities
  FOR SELECT
  USING (
    -- Host can always see their own plan
    auth.uid() = host_id
    -- Anyone can see fully open plans
    OR (women_only = false AND verified_only = false)
    -- Verified-only plans: viewer must be signed in AND verified
    OR (
      auth.uid() IS NOT NULL
      AND (verified_only = false OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.is_verified = true
      ))
      -- Women-only plans: viewer must be female (case-insensitive)
      AND (women_only = false OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid()
          AND lower(coalesce(p.gender, '')) IN ('female', 'woman', 'f', 'w')
      ))
    )
  );
