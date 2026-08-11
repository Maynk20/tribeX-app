
DROP POLICY IF EXISTS "Auth users can view event memory photos" ON storage.objects;

CREATE POLICY "Plan members can view event memory photos"
ON storage.objects FOR SELECT
TO authenticated
USING (
  bucket_id = 'event-memories'
  AND EXISTS (
    SELECT 1 FROM public.event_memories em
    WHERE em.image_url LIKE '%' || storage.objects.name || '%'
      AND (
        public.is_activity_host(em.activity_id, auth.uid())
        OR EXISTS (
          SELECT 1 FROM public.join_requests jr
          WHERE jr.activity_id = em.activity_id
            AND jr.user_id = auth.uid()
            AND jr.status = 'accepted'
        )
      )
  )
);
