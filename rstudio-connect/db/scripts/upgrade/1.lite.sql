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
   password_expire DATETIME,
   created_time DATETIME,
   updated_time DATETIME);

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

CREATE TABLE apps (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
   principal_id INTEGER NOT NULL,
   access_type TEXT,
   connection_timeout INTEGER NULL,
   init_timeout INTEGER NULL,
   idle_timeout INTEGER NULL,
   worker_type INTEGER NULL,
   url TEXT NULL,
   name TEXT,
   bundle_id INTEGER,
   app_dir STRING NULL,
   r_version_id INTEGER NULL,
   app_mode INTEGER NOT NULL);

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
   url TEXT,
   created_time DATETIME,
   updated_time DATETIME);

CREATE TABLE r_versions (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  major INTEGER NOT NULL,
  minor INTEGER NOT NULL,
  patch INTEGER NOT NULL,
  docker_path TEXT,
  local_path TEXT);

INSERT INTO r_versions (major, minor, patch, docker_path)
  VALUES (3, 1, 0, "/opt/R/3.1.0/bin/R"), (3, 1, 1, "/opt/R/3.1.1/bin/R");

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

CREATE TABLE store_metadata (
   current_schema_version INTEGER);

INSERT INTO store_metadata VALUES (1);

