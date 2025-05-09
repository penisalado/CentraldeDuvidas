/*
  # Create Quick Links Storage Bucket

  1. New Storage Bucket
    - Creates a new public bucket named 'quick-links' for storing quick link images
    - Enables public read access
    - Sets up RLS policies for authenticated users to manage files

  2. Security
    - Enables RLS on the bucket
    - Adds policy for public read access
    - Adds policy for authenticated users to manage files
*/

-- Create the storage bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('quick-links', 'quick-links', true);

-- Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access to files in the quick-links bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'quick-links');

-- Create policy to allow authenticated users to manage files in the quick-links bucket
CREATE POLICY "Authenticated users can upload files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'quick-links');

CREATE POLICY "Authenticated users can update files"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'quick-links');

CREATE POLICY "Authenticated users can delete files"
ON storage.objects FOR DELETE
TO authenticated
USING (bucket_id = 'quick-links');