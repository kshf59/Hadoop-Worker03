-- Create the variants table
CREATE TABLE variants (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   app_id INTEGER NOT NULL,
   bundle_id INTEGER NULL,
   is_default BOOLEAN DEFAULT 0,
   name TEXT,
   email_collaborators BOOLEAN DEFAULT 0,
   email_viewers BOOLEAN DEFAULT 0,
   created_time DATETIME DEFAULT (datetime('now', 'localtime')), 
   render_time DATETIME NULL,
   render_duration INTEGER DEFAULT 0);

-- Copy data out of apps into variants
INSERT INTO variants
    (app_id, bundle_id, is_default, name, email_collaborators, email_viewers, created_time, render_time, render_duration)
SELECT
    id, bundle_id, 1, 'default', mail_collab, mail_viewers, created_time, last_rendered_time, last_rendered_duration
FROM apps WHERE app_mode = 3;

-- Add variant columns to schedule
ALTER TABLE schedule ADD COLUMN variant_id INTEGER NULL; -- initially NULL because we have existing data

-- Give the schedule its variant.
UPDATE schedule SET variant_id = (select id from variants where variants.app_id = schedule.app_id);

-- Now that we have populated its data, recreate the schedule table with a NOT
-- NULL constraint on `variant_id`.
CREATE TABLE schedule_replacement (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  app_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  type TEXT NOT NULL, 
  schedule TEXT NOT NULL, 
  next_run DATETIME NULL,
  start_time DATETIME NULL,
  activate BOOLEAN DEFAULT 0,
  email BOOLEAN DEFAULT 0);

INSERT INTO schedule_replacement
SELECT
  id,
  app_id,
  variant_id,
  type,
  schedule,
  next_run,
  start_time,
  activate,
  email
FROM schedule;

DROP TABLE schedule;

ALTER TABLE schedule_replacement RENAME TO schedule;

-- Recreate apps without moved fields
CREATE TABLE apps_replacement(
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
   principal_id INTEGER NOT NULL,
   access_type TEXT,
   connection_timeout INTEGER NULL,
   read_timeout INTEGER NULL,
   init_timeout INTEGER NULL,
   idle_timeout INTEGER NULL,
   worker_type TEXT NULL,
   url TEXT NULL,
   name TEXT,
   bundle_id INTEGER NULL,
   app_dir TEXT NULL,
   app_mode INTEGER NOT NULL,
   title TEXT,
   needs_config BOOLEAN DEFAULT FALSE,
   created_time DATETIME DEFAULT (datetime('now', 'localtime')), 
   last_deployed_time DATETIME DEFAULT (datetime('now', 'localtime')),
   cpu_set TEXT NULL,
   cpu_shares INTEGER NOT NULL DEFAULT 0,
   memory TEXT NULL,
   r_version TEXT NULL,
   build_status INT DEFAULT 0,
   content_category TEXT NOT NULL DEFAULT '',
   has_parameters BOOLEAN DEFAULT 0);

INSERT INTO apps_replacement
SELECT 
   id,
   principal_id,
   access_type,
   connection_timeout,
   read_timeout,
   init_timeout,
   idle_timeout,
   worker_type,
   url,
   name,
   bundle_id,
   app_dir,
   app_mode,
   title,
   needs_config,
   created_time,
   last_deployed_time,
   cpu_set,
   cpu_shares,
   memory,
   r_version,
   build_status,
   content_category,
   has_parameters
FROM apps;

DROP TABLE apps;

ALTER TABLE apps_replacement RENAME TO apps;
