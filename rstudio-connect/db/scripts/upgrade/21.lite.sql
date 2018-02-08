ALTER TABLE apps ADD COLUMN last_rendered_time DATETIME NULL;
ALTER TABLE apps ADD COLUMN last_rendered_duration INTEGER DEFAULT 0;
UPDATE apps SET last_rendered_time = last_deployed_time WHERE app_mode = 3;
