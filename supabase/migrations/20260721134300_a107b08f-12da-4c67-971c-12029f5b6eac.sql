ALTER TABLE public.activities
  ADD COLUMN IF NOT EXISTS is_online boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS meeting_link text,
  ADD COLUMN IF NOT EXISTS amenities text[] NOT NULL DEFAULT ARRAY[]::text[],
  ADD COLUMN IF NOT EXISTS topic_tags text[] NOT NULL DEFAULT ARRAY[]::text[];

-- Meeting link is only returned to the host or an accepted attendee.
CREATE OR REPLACE FUNCTION public.get_meeting_link(_activity_id uuid)
RETURNS text
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT meeting_link
  FROM public.activities
  WHERE id = _activity_id
    AND public.has_activity_access(_activity_id, auth.uid());
$$;

REVOKE ALL ON FUNCTION public.get_meeting_link(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_meeting_link(uuid) TO authenticated;