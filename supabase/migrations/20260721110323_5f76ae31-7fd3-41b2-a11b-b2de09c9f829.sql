
CREATE POLICY "Anyone can view activity images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'activity-images');

CREATE POLICY "Authenticated users can upload activity images to their folder"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'activity-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can update their own activity images"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'activity-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "Users can delete their own activity images"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'activity-images'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
