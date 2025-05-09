/*
  # Add function to properly reset tutorial ratings
  
  1. Changes
    - Add function to delete ratings for specific tutorial or all tutorials
    - Update tutorial_vote_resets table trigger
*/

-- Function to reset ratings
CREATE OR REPLACE FUNCTION reset_tutorial_ratings(tutorial_id_param uuid DEFAULT NULL)
RETURNS void AS $$
BEGIN
  IF tutorial_id_param IS NULL THEN
    -- Reset all ratings
    DELETE FROM tutorial_ratings;
  ELSE
    -- Reset ratings for specific tutorial
    DELETE FROM tutorial_ratings WHERE tutorial_id = tutorial_id_param;
  END IF;
END;
$$ LANGUAGE plpgsql;