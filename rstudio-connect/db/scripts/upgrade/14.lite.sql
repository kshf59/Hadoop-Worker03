
-- Add RVersion and BuildStatus columns to DB

ALTER TABLE apps ADD COLUMN r_version TEXT NULL;
ALTER TABLE apps ADD COLUMN build_status INT DEFAULT 0;

