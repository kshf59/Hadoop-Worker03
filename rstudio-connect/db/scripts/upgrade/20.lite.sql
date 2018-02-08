CREATE TABLE apps_replacement(
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, 
   principal_id INTEGER NOT NULL,
   access_type TEXT,
   connection_timeout INTEGER NULL,
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
   mail_collab BOOLEAN DEFAULT FALSE,
   mail_viewers BOOLEAN DEFAULT FALSE,
   email BOOLEAN NOT NULL DEFAULT FALSE,
   content_category TEXT NOT NULL DEFAULT '');

INSERT INTO apps_replacement select id, principal_id, access_type, connection_timeout, init_timeout, idle_timeout, worker_type, url, name, bundle_id, app_dir, app_mode, title, needs_config, created_time, last_deployed_time, cpu_set, cpu_shares, memory, r_version, build_status, mail_collab, mail_viewers, email, case when content_category is null then '' else content_category end as content_category from apps;

DROP TABLE apps;

ALTER TABLE apps_replacement RENAME TO apps;
