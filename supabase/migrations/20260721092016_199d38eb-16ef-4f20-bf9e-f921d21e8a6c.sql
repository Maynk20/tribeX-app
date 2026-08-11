
CREATE EXTENSION IF NOT EXISTS citext;

DROP TABLE IF EXISTS public.password_reset_otps;

CREATE TABLE public.auth_otps (
  id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  email CITEXT NOT NULL,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INT NOT NULL DEFAULT 0,
  used_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX auth_otps_email_created_idx ON public.auth_otps (email, created_at DESC);
CREATE INDEX auth_otps_expires_idx ON public.auth_otps (expires_at);

GRANT ALL ON public.auth_otps TO service_role;

ALTER TABLE public.auth_otps ENABLE ROW LEVEL SECURITY;
-- No policies: only service role (server functions) may access.
