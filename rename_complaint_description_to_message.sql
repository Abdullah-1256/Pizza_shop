-- Rename 'description' column to 'message' in complaints table

-- Add the new 'message' column
ALTER TABLE complaints ADD COLUMN message TEXT;

-- Copy data from description to message
UPDATE complaints SET message = description WHERE description IS NOT NULL;

-- Drop the old 'description' column
ALTER TABLE complaints DROP COLUMN description;

-- Add comment for documentation
COMMENT ON COLUMN complaints.message IS 'The detailed message content of the complaint';