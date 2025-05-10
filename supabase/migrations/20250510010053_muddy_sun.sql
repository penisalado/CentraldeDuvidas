/*
  # Storage bucket and policies setup

  1. Changes
    - Create tutorial-assets storage bucket
    - Enable RLS on storage.objects
    - Set up policies for public access and authenticated operations
  
  2. Security
    - Public read access to tutorial-assets bucket
    - Authenticated users can upload, update, and delete files
*/

DO $$ 
BEGIN
  -- Create the tutorial-assets bucket if it doesn't exist
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('tutorial-assets', 'tutorial-assets', true)
  ON CONFLICT (id) DO NOTHING;

  -- Enable RLS on storage.objects if not already enabled
  ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
END $$;

-- Drop existing policies to avoid conflicts
DO $$ 
BEGIN
  DROP POLICY IF EXISTS "Public Access tutorial-assets" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can upload tutorial assets" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can update tutorial assets" ON storage.objects;
  DROP POLICY IF EXISTS "Authenticated users can delete tutorial assets" ON storage.objects;
END $$;

-- Create policies in separate transactions
DO $$ 
BEGIN
  -- Public read access
  CREATE POLICY "Public Access tutorial-assets"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'tutorial-assets');
END $$;

DO $$ 
BEGIN
  -- Authenticated users upload
  CREATE POLICY "Authenticated users can upload tutorial assets"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'tutorial-assets');
END $$;

DO $$ 
BEGIN
  -- Authenticated users update
  CREATE POLICY "Authenticated users can update tutorial assets"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'tutorial-assets')
  WITH CHECK (bucket_id = 'tutorial-assets');
END $$;

DO $$ 
BEGIN
  -- Authenticated users delete
  CREATE POLICY "Authenticated users can delete tutorial assets"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'tutorial-assets');
END $$;