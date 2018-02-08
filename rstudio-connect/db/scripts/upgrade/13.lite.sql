
CREATE TEMPORARY TABLE apps_backup(
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
  memory TEXT NULL);

INSERT INTO apps_backup SELECT id, principal_id, access_type, connection_timeout, init_timeout, idle_timeout, worker_type, url, name, bundle_id, app_dir, app_mode, title, needs_config, created_time, last_deployed_time, cpu_set, cpu_shares, memory FROM apps;
DROP TABLE apps;
CREATE TABLE apps(
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
  memory TEXT NULL);

INSERT INTO apps SELECT id, principal_id, access_type, connection_timeout, init_timeout, idle_timeout, worker_type, url, name, bundle_id, app_dir, app_mode, title, needs_config, created_time, last_deployed_time, cpu_set, cpu_shares, memory FROM apps_backup;
DROP TABLE apps_backup;

DROP TABLE r_versions;
