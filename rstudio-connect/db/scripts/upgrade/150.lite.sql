CREATE TABLE apps_backup(
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

INSERT INTO apps_backup SELECT id, principal_id, access_type, connection_timeout, read_timeout, init_timeout, idle_timeout, name, bundle_id, app_mode, title, needs_config, created_time, last_deployed_time, r_version, build_status, content_category, has_parameters, max_processes, min_processes, max_conns_per_process, load_factor, run_as, run_as_current_user FROM apps;
DROP TABLE apps;
ALTER TABLE apps_backup RENAME TO apps;

CREATE INDEX apps_by_principal_id_app_mode ON apps (principal_id, app_mode);
CREATE INDEX apps_by_app_mode ON apps (app_mode);
