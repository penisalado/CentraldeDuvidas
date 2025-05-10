/*
  # Fix Storage Bucket Configuration

  1. Changes
    - Ensure tutorial-assets bucket exists and is public
    - Set up proper RLS policies with correct naming
    - Configure proper access controls

  2. Security
    - Enable RLS on storage.objects
    - Public read access to tutorial-assets bucket
    - Authenticated users can upload, update, and delete files
*/

-- Ensure the bucket exists and is public
DO $$ 
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('tutorial-assets', 'tutorial-assets', true)
  ON CONFLICT (id) DO UPDATE
  SET public = true;
END $$;

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Remove any existing policies to avoid conflicts
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "tutorial_assets_public_select" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_assets_auth_insert" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_assets_auth_update" ON storage.objects;
  DROP POLICY IF EXISTS "tutorial_assets_auth_delete" ON storage.objects;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Create fresh policies
CREATE POLICY "tutorial_assets_public_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-assets');

CREATE POLICY "tutorial_assets_auth_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');

CREATE POLICY "tutorial_assets_auth_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'tutorial-assets')
WITH CHECK (bucket_id = 'tutorial-assets');

CREATE POLICY "tutorial_assets_auth_delete"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'tutorial-assets');