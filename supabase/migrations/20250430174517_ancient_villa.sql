-- Create quick-links-assets bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('quick-links-assets', 'quick-links-assets', true)
ON CONFLICT (id) DO NOTHING;

-- Set up security policies for quick-links-assets bucket
CREATE POLICY "Public Access"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'quick-links-assets');

CREATE POLICY "Authenticated users can upload quick link images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'quick-links-assets');

CREATE POLICY "Authenticated users can update quick link images"
ON storage.objects FOR UPDATE
TO authenticated
WITH CHECK (bucket_id = 'quick-links-assets');

CREATE POLICY "Authenticated users can delete quick link images"
ON storage.objects FOR DELETE
TO authenticated
WITH CHECK (bucket_id = 'quick-links-assets');