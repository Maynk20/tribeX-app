
ALTER TABLE public.notifications ADD COLUMN IF NOT EXISTS read_at timestamptz;

UPDATE public.notifications SET read_at = created_at WHERE is_read = true AND read_at IS NULL;

CREATE OR REPLACE FUNCTION public.tg_notifications_set_read_at()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.is_read = true AND (OLD.is_read IS DISTINCT FROM true) AND NEW.read_at IS NULL THEN
    NEW.read_at := now();
  ELSIF NEW.is_read = false THEN
    NEW.read_at := NULL;
  END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_notifications_set_read_at ON public.notifications;
CREATE TRIGGER trg_notifications_set_read_at
BEFORE UPDATE ON public.notifications
FOR EACH ROW EXECUTE FUNCTION public.tg_notifications_set_read_at();

CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON public.notifications (read_at) WHERE read_at IS NOT NULL;

CREATE OR REPLACE FUNCTION public.purge_old_read_notifications()
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_count integer;
BEGIN
  WITH del AS (
    DELETE FROM public.notifications
    WHERE is_read = true AND read_at IS NOT NULL AND read_at < now() - interval '24 hours'
    RETURNING 1
  )
  SELECT count(*) INTO v_count FROM del;
  RETURN v_count;
END; $$;

REVOKE ALL ON FUNCTION public.purge_old_read_notifications() FROM PUBLIC, anon, authenticated;
