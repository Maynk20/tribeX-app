-- Migration: 20261018183000_squad_message_notifications_trigger.sql
-- Purpose: Automatically create rows in public.notifications for all other squad members (host + accepted attendees)
-- whenever a message is posted to public.messages, ensuring instant realtime and system notifications.

CREATE OR REPLACE FUNCTION public.tg_notify_squad_on_new_message()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
  v_sender_name TEXT;
  v_recipient_id UUID;
  v_body TEXT;
BEGIN
  -- 1. Retrieve the plan title
  SELECT title INTO v_title FROM public.activities WHERE id = NEW.activity_id;
  
  -- 2. Retrieve sender display name from profiles
  SELECT COALESCE(full_name, username, 'Squad Member') INTO v_sender_name 
  FROM public.profiles WHERE id = NEW.sender_id;

  v_body := COALESCE(v_sender_name, 'Squad Member') || ': ' || 
    CASE 
      WHEN NEW.text IS NOT NULL AND LENGTH(TRIM(NEW.text)) > 0 THEN LEFT(TRIM(NEW.text), 120)
      ELSE 'Sent a message'
    END;

  -- 3. Notify all other confirmed squad members:
  --    a) The host (if not the sender)
  --    b) All accepted join requests (if not the sender)
  FOR v_recipient_id IN
    SELECT host_id AS user_id FROM public.activities 
    WHERE id = NEW.activity_id AND host_id <> NEW.sender_id
    UNION
    SELECT user_id FROM public.join_requests 
    WHERE activity_id = NEW.activity_id AND status = 'accepted' AND user_id <> NEW.sender_id
  LOOP
    INSERT INTO public.notifications (
      user_id,
      type,
      title,
      body,
      activity_id,
      related_user_id
    ) VALUES (
      v_recipient_id,
      'chat_message',
      COALESCE(v_title, 'Squad Chat'),
      v_body,
      NEW.activity_id,
      NEW.sender_id
    );
  END LOOP;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_squad_on_new_message ON public.messages;
CREATE TRIGGER trg_notify_squad_on_new_message
AFTER INSERT ON public.messages
FOR EACH ROW EXECUTE FUNCTION public.tg_notify_squad_on_new_message();
