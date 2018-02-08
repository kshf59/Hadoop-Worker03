--  Apps
CREATE TABLE apps_replacement(
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
   principal_id INTEGER NOT NULL,
   access_type TEXT,
   connection_timeout INTEGER NULL,
   read_timeout INTEGER NULL,
   init_timeout INTEGER NULL,
   idle_timeout INTEGER NULL,
   name TEXT,
   bundle_id INTEGER NULL,
   app_dir TEXT NULL,
   app_mode INTEGER NOT NULL,
   title TEXT,
   needs_config BOOLEAN DEFAULT FALSE,
   created_time DATETIME DEFAULT (datetime('now')), 
   last_deployed_time DATETIME DEFAULT (datetime('now')),
   r_version TEXT NULL,
   build_status INT DEFAULT 0,
   content_category TEXT NOT NULL DEFAULT '',
   has_parameters BOOLEAN DEFAULT 0,
   max_processes INTEGER NULL,
   min_processes INTEGER NULL,
   max_conns_per_process INTEGER NULL,
   load_factor REAL NULL,
   run_as TEXT NULL);

INSERT INTO apps_replacement
SELECT
    id,
    principal_id,
    access_type,
    connection_timeout,
    read_timeout,
    init_timeout,
    idle_timeout,
    name,
    bundle_id,
    app_dir,
    app_mode,
    title,
    needs_config,
    created_time,
    last_deployed_time,
    r_version,
    build_status,
    content_category,
    has_parameters,
    max_processes,
    min_processes,
    max_conns_per_process,
    load_factor,
    run_as 
FROM apps;

DROP TABLE apps;
ALTER TABLE apps_replacement RENAME TO apps;

-- Variants

CREATE TABLE variants_replacement (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   app_id INTEGER NOT NULL,
   bundle_id INTEGER NULL,
   key TEXT NOT NULL,
   is_default BOOLEAN DEFAULT 0,
   name TEXT,
   email_collaborators BOOLEAN DEFAULT 0,
   email_viewers BOOLEAN DEFAULT 0,
   created_time DATETIME DEFAULT (datetime('now')), 
   render_time DATETIME NULL,
   render_duration INTEGER DEFAULT 0);

INSERT INTO variants_replacement
SELECT
   id,
   app_id,
   bundle_id,
   key,
   is_default,
   name,
   email_collaborators,
   email_viewers,
   DATETIME(created_time, "UTC"),
   DATETIME(render_time, "UTC"),
   render_duration
FROM variants;

DROP TABLE variants;
ALTER TABLE variants_replacement RENAME TO variants;

CREATE TABLE refresh_tokens_replacement (
   id INTEGER NOT NULL PRIMARY KEY,
   user_id INTEGER NOT NULL,
   token text,
   created_time DATETIME DEFAULT (datetime('now')), 
   used_time DATETIME DEFAULT (datetime('now')));

INSERT INTO refresh_tokens_replacement 
SELECT
  id,
  user_id,
  token,
  DATETIME(created_time, "UTC"),
  DATETIME(used_time, "UTC")
FROM refresh_tokens;

DROP TABLE refresh_tokens;
ALTER TABLE refresh_tokens_replacement RENAME TO refresh_tokens;


CREATE TABLE vanities_replacement (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      app_id INTEGER NOT NULL,
      path_prefix TEXT NOT NULL,
      created_time DATETIME DEFAULT (datetime('now')));

INSERT INTO vanities_replacement
SELECT
  id,
  app_id,
  path_prefix,
  DATETIME(created_time, "UTC")
FROM vanities;

DROP TABLE vanities;
ALTER TABLE vanities_replacement RENAME TO vanities;

CREATE UNIQUE INDEX unique_vanities_app_id ON vanities(app_id);
