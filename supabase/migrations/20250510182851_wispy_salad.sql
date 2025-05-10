/*
  # Fix tutorial images storage configuration
  
  1. Changes
    - Create dedicated bucket for tutorial images
    - Set up proper RLS policies
    - Configure public access and authenticated operations
*/

-- Create the tutorial-images bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-images', 'tutorial-images', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for this bucket
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "tutorial_images_public_select" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_images_auth_insert" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_images_auth_update" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_images_auth_delete" ON storage.objects;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Create fresh policies with proper names
CREATE POLICY "tutorial_images_public_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-images');

CREATE POLICY "tutorial_images_auth_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-images');

CREATE POLICY "tutorial_images_auth_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'tutorial-images')
WITH CHECK (bucket_id = 'tutorial-images');

CREATE POLICY "tutorial_images_auth_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'tutorial-images');

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_storage_objects_tutorial_images
ON storage.objects(bucket_id)
WHERE bucket_id = 'tutorial-images';