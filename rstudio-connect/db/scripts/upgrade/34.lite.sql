-- Remove the url col from apps

CREATE TABLE apps_replacement(
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   principal_id INTEGER NOT NULL,
   access_type TEXT,
   connection_timeout INTEGER NULL,
   read_timeout INTEGER NULL,
   init_timeout INTEGER NULL,
   idle_timeout INTEGER NULL,
   worker_type TEXT NULL,
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
   has_parameters BOOLEAN DEFAULT 0,
   max_processes INTEGER NULL,
   min_processes INTEGER NULL,
   max_conns_per_process INTEGER NULL,
   load_factor REAL NULL);

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
    has_parameters,
    max_processes,
    min_processes,
    max_conns_per_process,
    load_factor
FROM apps;

DROP TABLE apps;
ALTER TABLE apps_replacement RENAME TO apps;
