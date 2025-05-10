/*
  # Fix Tutorial Assets Storage Bucket Configuration

  1. Changes
    - Ensures tutorial-assets bucket exists and is properly configured
    - Drops and recreates all policies to avoid conflicts
    - Sets up comprehensive access policies

  2. Security
    - Public read access to all files in the bucket
    - Authenticated users can upload, update, and delete files
    - Proper RLS configuration
*/

-- Ensure the bucket exists and is public
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-assets', 'tutorial-assets', true)
ON CONFLICT (id) DO UPDATE
SET public = true;

-- Enable RLS on storage.objects
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies for tutorial-assets to avoid conflicts
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