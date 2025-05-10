/*
  # Add image upload support
  
  1. New Table
    - tutorial_images: Stores uploaded images for tutorials
      - id (uuid, primary key)
      - tutorial_id (uuid, references tutorials)
      - url (text)
      - filename (text)
      - created_at (timestamp)
      
  2. Security
    - Enable RLS
    - Add policies for public read access
    - Add policies for authenticated users to manage images
*/

CREATE TABLE IF NOT EXISTS tutorial_images (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id uuid REFERENCES tutorials(id) ON DELETE CASCADE,
  url text NOT NULL,
  filename text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE tutorial_images ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow public to read images"
  ON tutorial_images
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Allow authenticated users to manage images"
  ON tutorial_images
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);