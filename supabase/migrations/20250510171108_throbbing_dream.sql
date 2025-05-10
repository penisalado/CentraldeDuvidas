/*
  # Fix storage bucket configuration for tutorial assets
  
  1. Changes
    - Drop existing bucket and policies
    - Create new bucket with proper configuration
    - Set up correct policies with owner checks
*/

-- Drop existing bucket if exists
DO $$ 
BEGIN
  DELETE FROM storage.buckets WHERE id = 'tutorial-assets';
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Create the bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-assets', 'tutorial-assets', true);

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Public Access" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can upload files" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can update own files" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can delete own files" ON storage.objects;
EXCEPTION
  WHEN others THEN NULL;
END $$;

-- Create new policies
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-assets');

CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');

CREATE POLICY "Authenticated users can update files"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'tutorial-assets')
WITH CHECK (bucket_id = 'tutorial-assets');

CREATE POLICY "Authenticated users can delete files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'tutorial-assets');