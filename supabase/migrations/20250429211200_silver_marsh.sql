/*
  # Add Quick Links feature
  
  1. New Tables
    - quick_links: Stores quick access links with images and descriptions
      - id (uuid, primary key)
      - title (text)
      - description (text)
      - image_url (text)
      - redirect_url (text)
      - order_position (integer)
      - created_at (timestamp)
      - updated_at (timestamp)
      
  2. Security
    - Enable RLS on quick_links table
    - Add policies for public read access
    - Add policies for authenticated users to manage links
*/

CREATE TABLE IF NOT EXISTS quick_links (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  image_url text,
  redirect_url text NOT NULL,
  order_position integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE quick_links ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow public read access to quick links"
  ON quick_links
  FOR SELECT
  TO public
  USING (true);

CREATE POLICY "Allow authenticated users to manage quick links"
  ON quick_links
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Create update trigger for updated_at
CREATE TRIGGER update_quick_links_updated_at
  BEFORE UPDATE ON quick_links
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();