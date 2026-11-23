-- Fix invalid enum comparison in tg_notify_requester_on_status_change trigger
-- and safely expand join_status enum if needed.

DO $$
BEGIN
  ALTER TYPE public.join_status ADD VALUE IF NOT EXISTS 'declined';
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- Fix the status change notification trigger to use text casting and properly distinguish
-- between declining a pending request and removing an accepted attendee.
CREATE OR REPLACE FUNCTION public.tg_notify_requester_on_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title TEXT;
BEGIN
  IF NEW.status::text = OLD.status::text THEN
    RETURN NEW;
  END IF;

  SELECT title INTO v_title FROM public.activities WHERE id = NEW.activity_id;

  IF NEW.status::text = 'accepted' THEN
    INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
    VALUES (
      NEW.user_id,
      'request_accepted',
      'Request accepted',
      'Host accepted your request for ' || COALESCE(v_title, 'the plan') || '!',
      NEW.activity_id,
      NEW.id
    );
  ELSIF NEW.status::text IN ('rejected', 'declined') THEN
    IF OLD.status::text = 'accepted' THEN
      INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
      VALUES (
        NEW.user_id,
        'removed_from_plan',
        'Removed from plan',
        'The host removed you from "' || COALESCE(v_title, 'this plan') || '".',
        NEW.activity_id,
        NEW.id
      );
    ELSE
      INSERT INTO public.notifications (user_id, type, title, body, activity_id, join_request_id)
      VALUES (
        NEW.user_id,
        'request_declined',
        'Request declined',
        'Host declined your request for ' || COALESCE(v_title, 'the plan') || '.',
        NEW.activity_id,
        NEW.id
      );
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Ensure remove_join_request is clean and updates status to rejected
DROP FUNCTION IF EXISTS public.remove_join_request(uuid);
CREATE OR REPLACE FUNCTION public.remove_join_request(_req_id uuid)
RETURNS public.join_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_req public.join_requests;
  v_activity public.activities;
BEGIN
  SELECT * INTO v_req
  FROM public.join_requests
  WHERE id = _req_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Request not found';
  END IF;

  SELECT * INTO v_activity
  FROM public.activities
  WHERE id = v_req.activity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  IF v_activity.host_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only the host can remove attendees';
  END IF;

  IF v_req.status::text <> 'rejected' THEN
    UPDATE public.join_requests
       SET status = 'rejected'::public.join_status
     WHERE id = _req_id
     RETURNING * INTO v_req;
  END IF;

  RETURN v_req;
END;
$$;
GRANT EXECUTE ON FUNCTION public.remove_join_request(uuid) TO authenticated, service_role;

-- Ensure remove_user_from_activity is clean and updates status to rejected
DROP FUNCTION IF EXISTS public.remove_user_from_activity(uuid, uuid);
CREATE OR REPLACE FUNCTION public.remove_user_from_activity(_activity_id uuid, _user_id uuid)
RETURNS public.join_requests
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
DECLARE
  v_req public.join_requests;
  v_activity public.activities;
BEGIN
  SELECT * INTO v_activity
  FROM public.activities
  WHERE id = _activity_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Plan not found';
  END IF;

  IF v_activity.host_id <> auth.uid() THEN
    RAISE EXCEPTION 'Only the host can remove attendees';
  END IF;

  SELECT * INTO v_req
  FROM public.join_requests
  WHERE activity_id = _activity_id
    AND user_id = _user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'User is not a participant in this plan';
  END IF;

  IF v_req.status::text <> 'rejected' THEN
    UPDATE public.join_requests
       SET status = 'rejected'::public.join_status
     WHERE id = v_req.id
     RETURNING * INTO v_req;
  END IF;

  RETURN v_req;
END;
$$;
GRANT EXECUTE ON FUNCTION public.remove_user_from_activity(uuid, uuid) TO authenticated, service_role;
