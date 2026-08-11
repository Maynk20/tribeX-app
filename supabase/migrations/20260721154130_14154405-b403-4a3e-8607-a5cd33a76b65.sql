
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS latitude double precision,
  ADD COLUMN IF NOT EXISTS longitude double precision,
  ADD COLUMN IF NOT EXISTS notify_radius_km integer NOT NULL DEFAULT 10;

ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_notify_radius_km_range
  CHECK (notify_radius_km BETWEEN 1 AND 100) NOT VALID;

CREATE OR REPLACE FUNCTION public.tg_notify_matching_users_on_activity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_host_name text;
BEGIN
  SELECT COALESCE(full_name, username, 'Someone') INTO v_host_name
  FROM public.profiles WHERE id = NEW.host_id;

  INSERT INTO public.notifications (user_id, type, title, body, activity_id, related_user_id)
  SELECT
    p.id,
    'event_match',
    'New ' || NEW.category || ' near you!',
    COALESCE(v_host_name, 'Someone') || ' created "' || NEW.title || '"'
      || CASE
           WHEN NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL
                AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
             THEN ' — about ' || ROUND(
                    (public.haversine_m(NEW.latitude, NEW.longitude, p.latitude, p.longitude) / 1000.0)::numeric,
                    1
                  )::text || ' km away'
           ELSE ' near ' || NEW.location
         END
      || '. Check it out!',
    NEW.id,
    NEW.host_id
  FROM public.profiles p
  WHERE p.id <> NEW.host_id
    AND NEW.category = ANY (p.interests)
    AND (
      -- Preferred path: both sides have coords → distance filter.
      (
        NEW.latitude IS NOT NULL AND NEW.longitude IS NOT NULL
        AND p.latitude IS NOT NULL AND p.longitude IS NOT NULL
        AND public.haversine_m(NEW.latitude, NEW.longitude, p.latitude, p.longitude)
              <= COALESCE(p.notify_radius_km, 10) * 1000
      )
      -- Fallback: no coords stored yet → keep city-name match so we don't stop notifying legacy users.
      OR (
        (p.latitude IS NULL OR p.longitude IS NULL OR NEW.latitude IS NULL OR NEW.longitude IS NULL)
        AND p.city IS NOT NULL
        AND length(trim(p.city)) > 0
        AND (
          lower(NEW.location) LIKE '%' || lower(p.city) || '%'
          OR lower(p.city) LIKE '%' || lower(split_part(NEW.location, ',', 1)) || '%'
        )
      )
    );
  RETURN NEW;
END; $function$;
