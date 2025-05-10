/*
  # Create tutorial assets storage bucket

  1. Storage
    - Creates 'tutorial-assets' bucket for storing tutorial-related images and files
  
  2. Security
    - Enables public read access
    - Allows authenticated users to upload, update, and delete files
    - Sets up appropriate RLS policies for secure access
*/

-- Create the storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-assets', 'tutorial-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Policy for public read access
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-assets');

-- Policy for authenticated users to upload files
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');

-- Policy for authenticated users to update their own files
CREATE POLICY "Authenticated users can update own files"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'tutorial-assets' AND auth.uid() = owner)
WITH CHECK (bucket_id = 'tutorial-assets');

-- Policy for authenticated users to delete their own files
CREATE POLICY "Authenticated users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'tutorial-assets' AND auth.uid() = owner);