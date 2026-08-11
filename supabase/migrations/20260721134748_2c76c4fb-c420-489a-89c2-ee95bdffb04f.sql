REVOKE EXECUTE ON FUNCTION public.has_activity_access(uuid, uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.is_activity_host(uuid, uuid) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.has_activity_access(uuid, uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.is_activity_host(uuid, uuid) TO service_role;