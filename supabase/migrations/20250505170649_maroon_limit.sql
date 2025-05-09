/*
  # Update tutorial ratings to use cookie_id instead of ip_address
  
  1. Changes
    - Add cookie_id column allowing nulls initially
    - Migrate existing data
    - Make cookie_id not null
    - Update constraints
*/

-- Add cookie_id column as nullable first
ALTER TABLE tutorial_ratings
ADD COLUMN cookie_id text;

-- Update existing rows with a generated cookie_id based on ip_address
UPDATE tutorial_ratings
SET cookie_id = encode(digest(ip_address, 'sha256'), 'hex')
WHERE cookie_id IS NULL;

-- Now make cookie_id not null
ALTER TABLE tutorial_ratings
ALTER COLUMN cookie_id SET NOT NULL;

-- Drop the old unique constraint
ALTER TABLE tutorial_ratings
DROP CONSTRAINT IF EXISTS tutorial_ratings_tutorial_id_ip_address_key;

-- Add new unique constraint
ALTER TABLE tutorial_ratings
ADD CONSTRAINT tutorial_ratings_tutorial_id_cookie_id_key UNIQUE (tutorial_id, cookie_id);

-- Finally drop the ip_address column
ALTER TABLE tutorial_ratings
DROP COLUMN IF EXISTS ip_address;