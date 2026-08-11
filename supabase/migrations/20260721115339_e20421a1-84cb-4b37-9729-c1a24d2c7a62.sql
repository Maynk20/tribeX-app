CREATE INDEX IF NOT EXISTS idx_activities_date_time ON public.activities(date_time);
CREATE INDEX IF NOT EXISTS idx_activities_host_date ON public.activities(host_id, date_time);
CREATE INDEX IF NOT EXISTS idx_join_requests_act_status ON public.join_requests(activity_id, status);
CREATE INDEX IF NOT EXISTS idx_messages_act_created ON public.messages(activity_id, created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON public.notifications(user_id) WHERE is_read = false;

ALTER TABLE public.activities ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
CREATE INDEX IF NOT EXISTS idx_activities_deleted_at ON public.activities(deleted_at) WHERE deleted_at IS NULL;