
-- Avatar bucket policies: authenticated users manage files in their own folder (userId/*)
DROP POLICY IF EXISTS "Avatar read own" ON storage.objects;
DROP POLICY IF EXISTS "Avatar insert own" ON storage.objects;
DROP POLICY IF EXISTS "Avatar update own" ON storage.objects;
DROP POLICY IF EXISTS "Avatar delete own" ON storage.objects;

CREATE POLICY "Avatar read own"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Avatar insert own"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Avatar update own"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1])
WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Avatar delete own"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);
