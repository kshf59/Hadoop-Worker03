CREATE TABLE apps_5 (
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
   app_mode INTEGER NOT NULL, 
   title TEXT,
   needs_config BOOLEAN DEFAULT FALSE,
   created_time DATETIME DEFAULT (datetime('now', 'localtime')), 
   last_deployed_time DATETIME DEFAULT (datetime('now', 'localtime')));

INSERT INTO apps_5 (id, principal_id, access_type, connection_timeout, init_timeout, idle_timeout, worker_type, url, name, bundle_id, app_dir, r_version_id, app_mode, title, needs_config) SELECT * FROM apps;
DROP TABLE apps;
ALTER TABLE apps_5 RENAME TO apps;
