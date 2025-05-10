/*
  # Fix storage configuration for tutorial assets
  
  1. Changes
    - Ensure storage bucket exists and is properly configured
    - Set up correct RLS policies
    - Fix bucket permissions
*/

-- Create the bucket if it doesn't exist
DO $$ 
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('tutorial-assets', 'tutorial-assets', true)
  ON CONFLICT (id) DO UPDATE
  SET public = true;
END $$;

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Public Access" ON storage.objects;
  DROP POLICY IF EXISTS "Public Access tutorial-assets" ON storage.objects;
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