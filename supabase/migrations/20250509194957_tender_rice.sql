/*
  # Fix Tutorial Assets Storage Bucket

  1. Storage Bucket Configuration
    - Ensures 'tutorial-assets' bucket exists and is public
    - Sets up proper RLS policies for access control

  2. Security
    - Enables RLS
    - Configures public read access
    - Allows authenticated users to manage files
*/

-- Create the tutorial-assets bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-assets', 'tutorial-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Enable RLS on storage.objects if not already enabled
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies for the bucket to avoid conflicts
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload tutorial assets" ON storage.objects;

-- Create policy for public read access
CREATE POLICY "Public Access tutorial-assets"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-assets');

-- Create policy for authenticated users to upload files
CREATE POLICY "Authenticated users can upload tutorial assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');

-- Create policy for authenticated users to update files
CREATE POLICY "Authenticated users can update tutorial assets"
ON storage.objects FOR UPDATE
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');

-- Create policy for authenticated users to delete files
CREATE POLICY "Authenticated users can delete tutorial assets"
ON storage.objects FOR DELETE
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');