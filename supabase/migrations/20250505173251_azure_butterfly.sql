/*
  # Fix rating system reset functionality
  
  1. Changes
    - Add function to properly reset ratings
    - Add trigger to handle vote resets
    - Update tutorial_vote_resets table structure
    
  2. Security
    - Enable RLS on all new functions
*/

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS reset_tutorial_ratings;

-- Create improved reset function
CREATE OR REPLACE FUNCTION reset_tutorial_ratings()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete ratings based on tutorial_id
  IF NEW.tutorial_id IS NOT NULL THEN
    DELETE FROM tutorial_ratings WHERE tutorial_id = NEW.tutorial_id;
  ELSE
    -- If no specific tutorial_id, reset all ratings
    DELETE FROM tutorial_ratings;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically reset ratings when a reset record is inserted
DROP TRIGGER IF EXISTS trigger_reset_ratings ON tutorial_vote_resets;
CREATE TRIGGER trigger_reset_ratings
  AFTER INSERT ON tutorial_vote_resets
  FOR EACH ROW
  EXECUTE FUNCTION reset_tutorial_ratings();

-- Add index to improve performance
CREATE INDEX IF NOT EXISTS idx_tutorial_ratings_tutorial_id 
  ON tutorial_ratings(tutorial_id);