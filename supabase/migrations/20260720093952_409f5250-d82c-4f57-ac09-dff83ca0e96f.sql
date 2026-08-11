
-- ENUMS
CREATE TYPE public.join_status AS ENUM ('pending', 'accepted', 'rejected');

-- PROFILES
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  bio TEXT,
  rating NUMERIC(3,2) NOT NULL DEFAULT 5.00,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
GRANT SELECT ON public.profiles TO anon;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT ALL ON public.profiles TO service_role;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- ACTIVITIES
CREATE TABLE public.activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  date_time TIMESTAMPTZ NOT NULL,
  location TEXT NOT NULL,
  total_slots INTEGER NOT NULL CHECK (total_slots > 0),
  cost_per_head NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (cost_per_head >= 0),
  slots_left INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX activities_date_time_idx ON public.activities(date_time);
CREATE INDEX activities_host_id_idx ON public.activities(host_id);
GRANT SELECT ON public.activities TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.activities TO authenticated;
GRANT ALL ON public.activities TO service_role;
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Activities are viewable by everyone" ON public.activities FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert activities" ON public.activities FOR INSERT TO authenticated WITH CHECK (auth.uid() = host_id);
CREATE POLICY "Hosts can update their activities" ON public.activities FOR UPDATE TO authenticated USING (auth.uid() = host_id) WITH CHECK (auth.uid() = host_id);
CREATE POLICY "Hosts can delete their activities" ON public.activities FOR DELETE TO authenticated USING (auth.uid() = host_id);

-- JOIN REQUESTS
CREATE TABLE public.join_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status public.join_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (activity_id, user_id)
);
CREATE INDEX join_requests_activity_idx ON public.join_requests(activity_id);
CREATE INDEX join_requests_user_idx ON public.join_requests(user_id);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.join_requests TO authenticated;
GRANT ALL ON public.join_requests TO service_role;
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;

-- Security definer: is caller the host of the given activity?
CREATE OR REPLACE FUNCTION public.is_activity_host(_activity_id UUID, _user_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT EXISTS (SELECT 1 FROM public.activities WHERE id = _activity_id AND host_id = _user_id);
$$;

-- Security definer: does caller have an accepted join_request for the activity? (host counts as accepted)
CREATE OR REPLACE FUNCTION public.has_activity_access(_activity_id UUID, _user_id UUID)
RETURNS BOOLEAN LANGUAGE SQL STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT public.is_activity_host(_activity_id, _user_id)
      OR EXISTS (
        SELECT 1 FROM public.join_requests
        WHERE activity_id = _activity_id AND user_id = _user_id AND status = 'accepted'
      );
$$;

CREATE POLICY "Applicant or host can view join requests" ON public.join_requests
  FOR SELECT TO authenticated
  USING (auth.uid() = user_id OR public.is_activity_host(activity_id, auth.uid()));
CREATE POLICY "Users can request to join" ON public.join_requests
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Applicant or host can update join requests" ON public.join_requests
  FOR UPDATE TO authenticated
  USING (auth.uid() = user_id OR public.is_activity_host(activity_id, auth.uid()))
  WITH CHECK (auth.uid() = user_id OR public.is_activity_host(activity_id, auth.uid()));
CREATE POLICY "Applicant or host can delete join requests" ON public.join_requests
  FOR DELETE TO authenticated
  USING (auth.uid() = user_id OR public.is_activity_host(activity_id, auth.uid()));

-- MESSAGES
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  activity_id UUID NOT NULL REFERENCES public.activities(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  text TEXT NOT NULL CHECK (length(trim(text)) > 0),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX messages_activity_idx ON public.messages(activity_id, created_at DESC);
GRANT SELECT, INSERT, DELETE ON public.messages TO authenticated;
GRANT ALL ON public.messages TO service_role;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Members can read messages" ON public.messages
  FOR SELECT TO authenticated
  USING (public.has_activity_access(activity_id, auth.uid()));
CREATE POLICY "Members can send messages" ON public.messages
  FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = sender_id AND public.has_activity_access(activity_id, auth.uid()));
CREATE POLICY "Senders can delete their messages" ON public.messages
  FOR DELETE TO authenticated
  USING (auth.uid() = sender_id);

-- TRIGGERS
-- Auto-create profile on new auth user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, username)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1)),
    NEW.raw_user_meta_data->>'avatar_url',
    split_part(NEW.email, '@', 1)
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- updated_at
CREATE OR REPLACE FUNCTION public.tg_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN NEW.updated_at = now(); RETURN NEW; END; $$;
CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();
CREATE TRIGGER activities_updated_at BEFORE UPDATE ON public.activities FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();
CREATE TRIGGER join_requests_updated_at BEFORE UPDATE ON public.join_requests FOR EACH ROW EXECUTE FUNCTION public.tg_set_updated_at();

-- Initialize slots_left from total_slots on insert
CREATE OR REPLACE FUNCTION public.tg_init_slots_left()
RETURNS TRIGGER LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF NEW.slots_left IS NULL OR NEW.slots_left = 0 THEN NEW.slots_left := NEW.total_slots; END IF;
  RETURN NEW;
END; $$;
ALTER TABLE public.activities ALTER COLUMN slots_left SET DEFAULT 0;
CREATE TRIGGER activities_init_slots BEFORE INSERT ON public.activities FOR EACH ROW EXECUTE FUNCTION public.tg_init_slots_left();

-- Decrement slots_left when a join_request is accepted
CREATE OR REPLACE FUNCTION public.tg_sync_slots_on_join_change()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF TG_OP = 'UPDATE' AND OLD.status <> 'accepted' AND NEW.status = 'accepted' THEN
    UPDATE public.activities SET slots_left = GREATEST(slots_left - 1, 0) WHERE id = NEW.activity_id;
  ELSIF TG_OP = 'UPDATE' AND OLD.status = 'accepted' AND NEW.status <> 'accepted' THEN
    UPDATE public.activities SET slots_left = LEAST(slots_left + 1, total_slots) WHERE id = NEW.activity_id;
  ELSIF TG_OP = 'DELETE' AND OLD.status = 'accepted' THEN
    UPDATE public.activities SET slots_left = LEAST(slots_left + 1, total_slots) WHERE id = OLD.activity_id;
  END IF;
  RETURN COALESCE(NEW, OLD);
END; $$;
CREATE TRIGGER join_requests_sync_slots
  AFTER UPDATE OR DELETE ON public.join_requests
  FOR EACH ROW EXECUTE FUNCTION public.tg_sync_slots_on_join_change();
