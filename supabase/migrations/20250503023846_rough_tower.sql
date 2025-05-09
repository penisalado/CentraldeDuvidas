/*
  # Add tutorial rating system
  
  1. New Tables
    - tutorial_ratings: Stores user ratings for tutorials
      - id (uuid, primary key)
      - tutorial_id (uuid, references tutorials)
      - rating (integer, 1-5)
      - ip_address (text)
      - created_at (timestamp)
      
  2. Security
    - Enable RLS
    - Add policies for public access to create and read ratings
*/

CREATE TABLE IF NOT EXISTS tutorial_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id uuid REFERENCES tutorials(id) ON DELETE CASCADE,
  rating integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  ip_address text NOT NULL,
  created_at timestamptz DEFAULT now(),
  UNIQUE(tutorial_id, ip_address)
);

-- Enable RLS
ALTER TABLE tutorial_ratings ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow public to create ratings"
  ON tutorial_ratings
  FOR INSERT
  TO public
  WITH CHECK (true);

CREATE POLICY "Allow public to read ratings"
  ON tutorial_ratings
  FOR SELECT
  TO public
  USING (true);