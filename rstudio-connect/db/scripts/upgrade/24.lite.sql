ALTER TABLE schedule ADD COLUMN activate BOOLEAN DEFAULT 0;

-- Prior behavior had all schedules activating content post-rendering.
-- Preserve activation for any existing schedules.

UPDATE schedule SET activate = 1;
