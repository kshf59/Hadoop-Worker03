ALTER TABLE apps ADD COLUMN email BOOLEAN NOT NULL DEFAULT FALSE;
UPDATE apps SET email = 0;
