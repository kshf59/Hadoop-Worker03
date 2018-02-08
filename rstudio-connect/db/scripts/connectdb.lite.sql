-- Create the RStudio Connect database

CREATE TABLE principals (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT);

CREATE TABLE users (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   principal_id INTEGER NOT NULL,
   provider_key TEXT,
   username TEXT,
   email TEXT,
   password TEXT,
   first_name TEXT,
   last_name TEXT,
   user_role TEXT,
   created_time DATETIME,
   updated_time DATETIME,
   active_time DATETIME,
   confirmed BOOLEAN NOT NULL DEFAULT FALSE,
   locked BOOLEAN NOT NULL DEFAULT FALSE);

CREATE TABLE temp_passwords (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  password TEXT NOT NULL DEFAULT '',
  expires DATETIME NOT NULL);

CREATE TABLE reset_password_tokens (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  password TEXT NOT NULL DEFAULT '',
  expires DATETIME NOT NULL);

CREATE TABLE groups (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   principal_id INTEGER NOT NULL,
   owner_id INTEGER NOT NULL,
   provider_key TEXT,
   name TEXT);

CREATE TABLE groups_users (
   user_id INTEGER NOT NULL,
   group_id INTEGER NOT NULL);

CREATE TABLE permissions (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   app_id INTEGER NOT NULL,
   principal_id INTEGER NOT NULL,
   app_role TEXT);

CREATE TABLE apps(
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   principal_id INTEGER NOT NULL,
   access_type TEXT,
   connection_timeout INTEGER NULL,
   read_timeout INTEGER NULL,
   init_timeout INTEGER NULL,
   idle_timeout INTEGER NULL,
   name TEXT,
   bundle_id INTEGER NULL,
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
   run_as TEXT NULL,
   run_as_current_user BOOLEAN DEFAULT 0);

CREATE TABLE variants (
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
   render_duration INTEGER NULL,
   visibility INTEGER DEFAULT 0,
   owner_id INTEGER DEFAULT 0,
   rendering_id INTEGER NULL);

CREATE TABLE tokens (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   user_id INTEGER NOT NULL,
   token TEXT,
   public_key TEXT,
   active BOOLEAN,
   created_time TIMESTAMP,
   used_time TIMESTAMP);

CREATE TABLE bundles (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   app_id INTEGER NOT NULL,
   created_time DATETIME,
   updated_time DATETIME,
   r_version TEXT NULL,
   build_status INT DEFAULT 0);

CREATE TABLE server_settings (
   name TEXT NOT NULL PRIMARY KEY,
   value TEXT NOT NULL);

CREATE TABLE audit_logs (
   id INTEGER NOT NULL PRIMARY KEY,
   time DATETIME,
   user_id INTEGER,
   user_key TEXT,
   user_desc TEXT,
   action TEXT,
   event_desc TEXT);

CREATE TABLE audit_objects (
   id INTEGER NOT NULL PRIMARY KEY,
   audit_id INTEGER,
   relationship TEXT,
   object_id INTEGER,
   object_type TEXT,
   object_key TEXT,
   object_desc TEXT,
   FOREIGN KEY(audit_id) REFERENCES audit_logs(id));

CREATE TABLE refresh_tokens (
   id INTEGER NOT NULL PRIMARY KEY,
   user_id INTEGER NOT NULL,
   token text,
   created_time DATETIME DEFAULT (datetime('now')),
   used_time DATETIME DEFAULT (datetime('now')));

CREATE TABLE schedule (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  app_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  schedule TEXT NOT NULL,
  next_run DATETIME NULL,
  start_time DATETIME NULL,
  activate BOOLEAN DEFAULT 0,
  email BOOLEAN DEFAULT 0);

CREATE TABLE subscription (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  app_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  principal_id INTEGER NOT NULL,
  include BOOLEAN NOT NULL);

CREATE TABLE vanities (
      id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
      app_id INTEGER NOT NULL,
      path_prefix TEXT NOT NULL,
      created_time DATETIME DEFAULT (datetime('now')));

CREATE UNIQUE INDEX unique_vanities_app_id ON vanities(app_id);

CREATE TABLE api_keys (
       id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
       user_id INTEGER NOT NULL,
       key TEXT NOT NULL,
       created_time DATETIME DEFAULT (datetime('now')),
       last_used_time DATETIME,
       name TEXT NOT NULL DEFAULT '');

CREATE UNIQUE INDEX unique_api_keys ON api_keys(key);

CREATE TABLE jobs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pid INTEGER,
    key VARCHAR(16) NOT NULL,
    app_id INTEGER NOT NULL,
    variant_id INTEGER,
    bundle_id INTEGER,
    tag VARCHAR(16) NOT NULL,
    start_time DATETIME NOT NULL DEFAULT (datetime('now')),
    end_time DATETIME NULL,
    exit_code INTEGER NULL,
    finalized BOOLEAN NOT NULL DEFAULT FALSE,
    hostname TEXT);

CREATE TABLE store_metadata (
   current_schema_version INTEGER,
   job_schema_version INTEGER DEFAULT(0));

CREATE TABLE tags (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL DEFAULT '',
  parent_id INTEGER,
  created_time DATETIME NOT NULL DEFAULT (datetime('now')),
  updated_time DATETIME NOT NULL DEFAULT (datetime('now')),
  version INTEGER NOT NULL DEFAULT(0),
  FOREIGN KEY(parent_id) REFERENCES tags(id)
);

CREATE TABLE tagmap (
  app_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  FOREIGN KEY(app_id) REFERENCES apps(id),
  FOREIGN KEY(tag_id) REFERENCES tags(id),
  PRIMARY KEY (app_id, tag_id)
);

CREATE TABLE queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  priority INTEGER NOT NULL,
  type INTEGER NOT NULL,
  item bytea NOT NULL,
  heartbeat DATETIME,
  hostname TEXT,
  created_time DATETIME NOT NULL DEFAULT (datetime('now')),
  updated_time DATETIME NOT NULL DEFAULT (datetime('now')),
  permit TEXT);

CREATE TABLE cookies (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   cookie_key TEXT NOT NULL,
   user_id INTEGER NOT NULL,
   provider TEXT,
   xsrf_token TEXT,
   created_time DATETIME NOT NULL,
   used_time DATETIME NOT NULL,
   expires DATETIME NOT NULL);

CREATE TABLE renderings (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    app_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    bundle_id INTEGER NULL,
    job_key key VARCHAR(16) NULL,
    render_time DATETIME NOT NULL,
    render_duration INTEGER NOT NULL);

CREATE TRIGGER aft_tag_update AFTER UPDATE ON tags
BEGIN
UPDATE tags
SET
  updated_time = datetime('now'),
  version = OLD.version + 1
WHERE
  id = OLD.id;
END;

CREATE TRIGGER queue_update AFTER UPDATE ON queue
BEGIN
  UPDATE queue
  SET
    updated_time = datetime('now')
  WHERE
    id = NEW.id;
END;

CREATE INDEX groups_by_principal_id ON groups (principal_id);

CREATE INDEX users_by_principal_id ON users (principal_id);
CREATE INDEX users_active_time ON users (active_time);

CREATE INDEX schedule_by_next_run ON schedule(next_run);

CREATE INDEX tagmap_by_tag_id ON tagmap (tag_id);

CREATE INDEX vanities_by_path_prefix on vanities (path_prefix);

CREATE INDEX permissions_by_app_id_principal_id ON permissions (app_id, principal_id);

CREATE INDEX apps_by_principal_id_app_mode ON apps (principal_id, app_mode);

CREATE INDEX apps_by_app_mode ON apps (app_mode);

CREATE INDEX variants_by_visibility_created_time ON variants(visibility,created_time);

CREATE INDEX variants_by_app_id ON variants (app_id);

CREATE INDEX jobs_by_app_id_etc ON jobs (app_id,finalized,start_time);

CREATE INDEX users_by_provider_key ON users(provider_key);

CREATE INDEX schedule_by_variant_id ON schedule (variant_id);

CREATE INDEX schedule_by_app_id_variant_id ON schedule (app_id,variant_id);

CREATE INDEX subscription_by_app_id_variant_id ON subscription (app_id,variant_id);

CREATE INDEX jobs_by_hostname_finalized ON jobs (finalized,hostname);

CREATE UNIQUE INDEX jobs_by_app_id_and_key ON jobs(app_id,key);

CREATE UNIQUE INDEX cookies_by_key ON cookies (cookie_key);

CREATE INDEX cookies_by_expires ON cookies (expires);

CREATE INDEX renderings_by_variant_id ON renderings (variant_id);

-- Rules for the store_metadata insert:
--     job_schema_version should be zero and is updated by the application.
INSERT INTO store_metadata
    (current_schema_version, job_schema_version)
    VALUES
    (240,0);
