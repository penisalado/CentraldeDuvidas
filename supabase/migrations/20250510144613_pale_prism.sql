/*
  # Fix image upload storage configuration
  
  1. Changes
    - Create tutorial-assets bucket if not exists
    - Set proper RLS policies
    - Ensure public access for uploaded files
*/

-- Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-assets', 'tutorial-assets', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Public Access tutorial-assets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload tutorial assets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can update tutorial assets" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete tutorial assets" ON storage.objects;

-- Create fresh policies with proper names and configurations
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