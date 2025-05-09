/*
  # Create storage buckets for tutorials and quick links

  1. New Storage Buckets
    - `tutorial-assets`: For storing tutorial-related files and images
    - `quick-links-assets`: For storing quick links images

  2. Security
    - Enable public access for both buckets
    - Allow authenticated users to upload files
*/

-- Create tutorial-assets bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('tutorial-assets', 'tutorial-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Create quick-links-assets bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('quick-links-assets', 'quick-links-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Set up security policies for tutorial-assets bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'tutorial-assets');

CREATE POLICY "Authenticated users can upload tutorial assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'tutorial-assets');

-- Set up security policies for quick-links-assets bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'quick-links-assets');

CREATE POLICY "Authenticated users can upload quick link images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'quick-links-assets');