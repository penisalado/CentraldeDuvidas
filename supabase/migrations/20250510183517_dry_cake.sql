-- Create the tutorial-videos bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-videos', 'tutorial-videos', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for this bucket
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "tutorial_videos_public_select" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_videos_auth_insert" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_videos_auth_update" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_videos_auth_delete" ON storage.objects;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Create fresh policies
CREATE POLICY "tutorial_videos_public_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-videos');

CREATE POLICY "tutorial_videos_auth_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-videos');

CREATE POLICY "tutorial_videos_auth_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'tutorial-videos')
WITH CHECK (bucket_id = 'tutorial-videos');

CREATE POLICY "tutorial_videos_auth_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'tutorial-videos');

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_storage_objects_tutorial_videos
ON storage.objects(bucket_id)
WHERE bucket_id = 'tutorial-videos';