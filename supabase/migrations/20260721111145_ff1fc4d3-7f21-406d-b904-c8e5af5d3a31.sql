
-- Notifications table
CREATE TABLE public.notifications (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT,
  activity_id UUID REFERENCES public.activities(id) ON DELETE CASCADE,
  related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  join_request_id UUID REFERENCES public.join_requests(id) ON DELETE CASCADE,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.notifications TO authenticated;
GRANT ALL ON public.notifications TO service_role;

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users delete own notifications" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id);
-- Inserts happen exclusively via SECURITY DEFINER triggers; no INSERT policy needed.

CREATE INDEX notifications_user_created_idx ON public.notifications (user_id, created_at DESC);

-- Trigger: notify host on new join request
CREATE OR REPLACE FUNCTION public.tg_notify_host_on_join_request()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_host UUID;
  v_title TEXT;
  v_name TEXT;
BEGIN
  SELECT host_id, title INTO v_host, v_title FROM public.activities WHERE id = NEW.activity_id;
  SELECT COALESCE(full_name, username, 'Someone') INTO v_name FROM public.profiles WHERE id = NEW.user_id;
  IF v_host IS NOT NULL AND v_host <> NEW.user_id THEN
    INSERT INTO public.notifications (user_id, type, title, body, activity_id, related_user_id, join_request_id)
    VALUES (
      v_host,
      'join_request',
      'New join request',
      COALESCE(v_name, 'Someone') || ' requested to join your plan ''' || COALESCE(v_title, '') || '''.',
      NEW.activity_id,
      NEW.user_id,
      NEW.id
    );
  END IF;
  RETURN NEW;
END; $$;

CREATE TRIGGER trg_notify_host_on_join_request
AFTER INSERT ON public.join_requests
FOR EACH ROW EXECUTE FUNCTION public.tg_notify_host_on_join_request();

-- Trigger: notify requester when host responds
CREATE OR REPLACE FUNCTION public.tg_notify_requester_on_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
BEGIN
  IF NEW.status = OLD.status THEN
    RETURN NEW;
  END IF;
  SELECT title INTO v_title FROM public.activities WHERE id = NEW.activity_id;
  IF NEW.status = 'accepted' THEN
    INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
    VALUES (NEW.user_id, 'request_accepted', 'Request accepted',
      'Host accepted your request for ' || COALESCE(v_title, 'the plan') || '!',
      NEW.activity_id, NEW.id);
  ELSIF NEW.status = 'declined' THEN
    INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
    VALUES (NEW.user_id, 'request_declined', 'Request declined',
      'Host declined your request for ' || COALESCE(v_title, 'the plan') || '.',
      NEW.activity_id, NEW.id);
  END IF;
  RETURN NEW;
END; $$;

CREATE TRIGGER trg_notify_requester_on_status_change
AFTER UPDATE OF status ON public.join_requests
FOR EACH ROW EXECUTE FUNCTION public.tg_notify_requester_on_status_change();

-- Realtime for notifications and join_requests
ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE public.join_requests;
