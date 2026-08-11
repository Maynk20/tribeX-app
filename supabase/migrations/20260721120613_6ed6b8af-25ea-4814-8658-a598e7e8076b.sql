ALTER TABLE public.activities
  ADD COLUMN IF NOT EXISTS is_urgent boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS urgent_until timestamptz;

CREATE INDEX IF NOT EXISTS idx_activities_urgent ON public.activities (is_urgent, urgent_until) WHERE is_urgent = true;