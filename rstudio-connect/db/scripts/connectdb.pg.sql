-- Create the RStudio Connect database

CREATE TABLE principals (
   id SERIAL PRIMARY KEY);

CREATE TABLE users (
   id SERIAL PRIMARY KEY,
   principal_id INTEGER NOT NULL,
   provider_key TEXT,
   username TEXT,
   email TEXT,
   password TEXT,
   first_name TEXT,
   last_name TEXT,
   user_role TEXT,
   created_time TIMESTAMPTZ,
   updated_time TIMESTAMPTZ,
   active_time TIMESTAMPTZ,
   confirmed BOOLEAN NOT NULL DEFAULT FALSE,
   locked BOOLEAN NOT NULL DEFAULT FALSE);

CREATE TABLE temp_passwords (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  password TEXT NOT NULL DEFAULT '',
  expires TIMESTAMPTZ NOT NULL);

CREATE TABLE reset_password_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  password TEXT NOT NULL DEFAULT '',
  expires TIMESTAMPTZ NOT NULL);

CREATE TABLE groups (
   id SERIAL PRIMARY KEY,
   principal_id INTEGER NOT NULL,
   owner_id INTEGER NOT NULL,
   provider_key TEXT,
   name TEXT);

CREATE TABLE groups_users (
   user_id INTEGER NOT NULL,
   group_id INTEGER NOT NULL);

CREATE TABLE permissions (
   id SERIAL PRIMARY KEY,
   app_id INTEGER NOT NULL,
   principal_id INTEGER NOT NULL,
   app_role TEXT);

CREATE TABLE apps(
   id SERIAL PRIMARY KEY,
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
   created_time TIMESTAMPTZ DEFAULT NOW(),
   last_deployed_time TIMESTAMPTZ DEFAULT NOW(),
   r_version TEXT NULL,
   build_status INT DEFAULT 0,
   content_category TEXT NOT NULL DEFAULT '',
   has_parameters BOOLEAN DEFAULT FALSE,
   max_processes INTEGER NULL,
   min_processes INTEGER NULL,
   max_conns_per_process INTEGER NULL,
   load_factor DECIMAL(10,5) NULL,
   run_as TEXT NULL,
   run_as_current_user BOOLEAN DEFAULT FALSE);

CREATE TABLE variants (
   id SERIAL PRIMARY KEY,
   app_id INTEGER NOT NULL,
   bundle_id INTEGER NULL,
   key TEXT NOT NULL,
   is_default BOOLEAN DEFAULT FALSE,
   name TEXT,
   email_collaborators BOOLEAN DEFAULT FALSE,
   email_viewers BOOLEAN DEFAULT FALSE,
   created_time TIMESTAMPTZ DEFAULT NOW(),
   render_time TIMESTAMPTZ NULL,
   render_duration BIGINT NULL,
   visibility INTEGER DEFAULT 0,
   owner_id INTEGER DEFAULT 0,
   rendering_id INTEGER NULL);

CREATE TABLE tokens (
   id SERIAL PRIMARY KEY,
   user_id INTEGER NOT NULL,
   token TEXT,
   public_key TEXT,
   active BOOLEAN,
   created_time TIMESTAMPTZ,
   used_time TIMESTAMPTZ);

CREATE TABLE bundles (
   id SERIAL PRIMARY KEY,
   app_id INTEGER NOT NULL,
   created_time TIMESTAMPTZ,
   updated_time TIMESTAMPTZ,
   r_version TEXT NULL,
   build_status INT DEFAULT 0);

CREATE TABLE server_settings (
   name TEXT NOT NULL PRIMARY KEY,
   value TEXT NOT NULL);

CREATE TABLE audit_logs (
   id SERIAL PRIMARY KEY,
   time TIMESTAMPTZ,
   user_id INTEGER,
   user_key TEXT,
   user_desc TEXT,
   action TEXT,
   event_desc TEXT);

CREATE TABLE audit_objects (
   id SERIAL PRIMARY KEY,
   audit_id INTEGER,
   relationship TEXT,
   object_id INTEGER,
   object_type TEXT,
   object_key TEXT,
   object_desc TEXT,
   FOREIGN KEY(audit_id) REFERENCES audit_logs(id));

CREATE TABLE refresh_tokens (
   id SERIAL PRIMARY KEY,
   user_id INTEGER NOT NULL,
   token text,
   created_time TIMESTAMPTZ DEFAULT NOW(),
   used_time TIMESTAMPTZ DEFAULT NOW());

CREATE TABLE schedule (
  id SERIAL PRIMARY KEY,
  app_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  type TEXT NOT NULL,
  schedule TEXT NOT NULL,
  next_run TIMESTAMPTZ NULL,
  start_time TIMESTAMPTZ NULL,
  activate BOOLEAN DEFAULT FALSE,
  email BOOLEAN DEFAULT FALSE);

CREATE TABLE subscription (
  id SERIAL PRIMARY KEY,
  app_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  principal_id INTEGER NOT NULL,
  include BOOLEAN NOT NULL);

CREATE TABLE vanities (
      id SERIAL PRIMARY KEY,
      app_id INTEGER NOT NULL,
      path_prefix TEXT NOT NULL,
      created_time TIMESTAMPTZ DEFAULT NOW());

CREATE UNIQUE INDEX unique_vanities_app_id ON vanities(app_id);

CREATE TABLE api_keys (
       id SERIAL PRIMARY KEY,
       user_id INTEGER NOT NULL,
       key TEXT NOT NULL,
       created_time TIMESTAMPTZ DEFAULT NOW(),
       last_used_time TIMESTAMPTZ,
       name TEXT NOT NULL DEFAULT '');

CREATE UNIQUE INDEX unique_api_keys ON api_keys(key);

CREATE TABLE jobs (
    id SERIAL PRIMARY KEY,
    pid INTEGER,
    key VARCHAR(16) NOT NULL,
    app_id INTEGER NOT NULL,
    variant_id INTEGER,
    bundle_id INTEGER,
    tag VARCHAR(16) NOT NULL,
    start_time TIMESTAMPTZ DEFAULT NOW(),
    end_time TIMESTAMPTZ NULL,
    exit_code INTEGER NULL,
    finalized BOOLEAN NOT NULL DEFAULT FALSE,
    hostname TEXT);

CREATE TABLE store_metadata (
   current_schema_version INTEGER,
   job_schema_version INTEGER DEFAULT(0));

CREATE TABLE tags (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL DEFAULT '',
  parent_id INTEGER,
  created_time TIMESTAMPTZ DEFAULT NOW(),
  updated_time TIMESTAMPTZ DEFAULT NOW(),
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
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  priority INTEGER NOT NULL,
  type INTEGER NOT NULL,
  item bytea NOT NULL,
  heartbeat TIMESTAMPTZ,
  hostname TEXT,
  created_time TIMESTAMPTZ DEFAULT NOW(),
  updated_time TIMESTAMPTZ DEFAULT NOW(),
  permit TEXT
);

CREATE TABLE cookies (
   id SERIAL PRIMARY KEY,
   cookie_key TEXT NOT NULL,
   user_id INTEGER NOT NULL,
   provider TEXT,
   xsrf_token TEXT,
   created_time TIMESTAMPTZ NOT NULL,
   used_time TIMESTAMPTZ NOT NULL,
   expires TIMESTAMPTZ NOT NULL
);

CREATE TABLE renderings (
    id SERIAL PRIMARY KEY,
    app_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    bundle_id INTEGER NULL,
    job_key VARCHAR(16) NULL,
    render_time TIMESTAMPTZ NOT NULL,
    render_duration BIGINT NOT NULL);

CREATE FUNCTION update_tag_version() RETURNS TRIGGER AS $$
BEGIN
    IF pg_trigger_depth() <> 1 THEN
        RETURN NEW;
    END IF;
    UPDATE tags SET updated_time=now(), version = version + 1 WHERE id=NEW.id;
    RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER update_tag
AFTER UPDATE ON tags
FOR EACH ROW EXECUTE PROCEDURE update_tag_version();

CREATE FUNCTION update_queue_time() RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() <> 1 THEN
    RETURN NEW;
  END IF;
  UPDATE queue SET updated_time=now() WHERE id=NEW.id;
    RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER update_queue
AFTER UPDATE ON queue
FOR EACH ROW EXECUTE PROCEDURE update_queue_time();

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
