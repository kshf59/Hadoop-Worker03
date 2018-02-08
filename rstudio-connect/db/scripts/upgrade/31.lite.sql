ALTER TABLE users ADD COLUMN confirmed BOOLEAN NOT NULL DEFAULT FALSE; 

-- Assume that all existing users have been confirmed
UPDATE users SET confirmed = 1;
