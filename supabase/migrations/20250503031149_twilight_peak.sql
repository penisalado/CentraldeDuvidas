/*
  # Add vote reset tracking
  
  1. New Table
    - tutorial_vote_resets: Track when votes are reset and by whom
      - id (uuid, primary key)
      - tutorial_id (uuid, nullable - null means all tutorials were reset)
      - admin_id (uuid)
      - reset_at (timestamptz)
      
  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

CREATE TABLE IF NOT EXISTS tutorial_vote_resets (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tutorial_id uuid REFERENCES tutorials(id) ON DELETE CASCADE,
  admin_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  reset_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE tutorial_vote_resets ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to manage vote resets"
  ON tutorial_vote_resets
  FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);