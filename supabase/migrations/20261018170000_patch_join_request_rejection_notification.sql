-- Migration: Fix join request status notification to handle both 'rejected' and 'declined'
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
  ELSIF NEW.status IN ('rejected', 'declined') THEN
    INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
    VALUES (NEW.user_id, 'request_declined', 'Request declined',
      'Host declined your request for ' || COALESCE(v_title, 'the plan') || '.',
      NEW.activity_id, NEW.id);
  END IF;
  RETURN NEW;
END; $$;
