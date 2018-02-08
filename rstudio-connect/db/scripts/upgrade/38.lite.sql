CREATE TABLE vanities (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  app_id INTEGER NOT NULL,
  path_prefix TEXT NOT NULL,
  created_time DATETIME DEFAULT (datetime('now', 'localtime')));
