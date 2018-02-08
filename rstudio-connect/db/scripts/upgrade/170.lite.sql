CREATE TABLE queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  priority INTEGER NOT NULL,
  type INTEGER NOT NULL,
  item bytea NOT NULL,
  heartbeat DATETIME,
  hostname TEXT,
  created_time DATETIME NOT NULL DEFAULT (datetime('now')),
  updated_time DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TRIGGER queue_update AFTER UPDATE ON queue
BEGIN
  UPDATE queue
  SET
    updated_time = datetime('now')
  WHERE
    id = NEW.id;
END;
