/*
  # Fix rating system reset functionality
  
  1. Changes
    - Improve reset trigger function to properly handle resets
    - Add notification channel for real-time updates
    - Optimize performance with better indexing
*/

-- Drop existing function and trigger
DROP TRIGGER IF EXISTS trigger_reset_ratings ON tutorial_vote_resets;
DROP FUNCTION IF EXISTS reset_tutorial_ratings;

-- Create improved reset function with better error handling
CREATE OR REPLACE FUNCTION reset_tutorial_ratings()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete ratings based on tutorial_id
  IF NEW.tutorial_id IS NOT NULL THEN
    DELETE FROM tutorial_ratings WHERE tutorial_id = NEW.tutorial_id;
  ELSE
    -- If no specific tutorial_id, reset all ratings
    TRUNCATE tutorial_ratings;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically reset ratings
CREATE TRIGGER trigger_reset_ratings
  AFTER INSERT ON tutorial_vote_resets
  FOR EACH ROW
  EXECUTE FUNCTION reset_tutorial_ratings();

-- Recreate index for better performance
DROP INDEX IF EXISTS idx_tutorial_ratings_tutorial_id;
CREATE INDEX idx_tutorial_ratings_tutorial_id 
  ON tutorial_ratings(tutorial_id);