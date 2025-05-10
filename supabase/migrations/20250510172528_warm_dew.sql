/*
  # Add error logging table
  
  1. New Table
    - error_logs: Stores application error logs
      - id (uuid, primary key)
      - error_message (text)
      - error_stack (text)
      - context (text)
      - metadata (jsonb)
      - created_at (timestamp)
      
  2. Security
    - Enable RLS
    - Add policies for authenticated users
*/

-- Create error_logs table
CREATE TABLE IF NOT EXISTS error_logs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  error_message text NOT NULL,
  error_stack text,
  context text,
  metadata jsonb,
  created_at timestamptz DEFAULT now()
);

-- Enable RLS
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Allow authenticated users to insert logs"
  ON error_logs
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow authenticated users to view logs"
  ON error_logs
  FOR SELECT
  TO authenticated
  USING (true);

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_error_logs_created_at 
  ON error_logs(created_at DESC);

-- Create index for context-based queries
CREATE INDEX IF NOT EXISTS idx_error_logs_context
  ON error_logs(context);