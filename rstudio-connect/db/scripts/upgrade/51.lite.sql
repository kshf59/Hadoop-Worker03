CREATE TABLE tags (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL DEFAULT '',
  parent_id INTEGER,
  created_time DATETIME NOT NULL DEFAULT (datetime('now')),
  last_update_time DATETIME NOT NULL DEFAULT (datetime('now')),
  deleted BOOLEAN NOT NULL DEFAULT(0),
  FOREIGN KEY(parent_id) REFERENCES tags(id)
);

CREATE TABLE tagmap (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  content_id INTEGER,
  tag_id INTEGER,
  FOREIGN KEY(content_id) REFERENCES apps(id),
  FOREIGN KEY(tag_id) REFERENCES tags(id)
);

CREATE TRIGGER aft_tag_update AFTER UPDATE ON tags
BEGIN
UPDATE tags
SET
  last_update_time = datetime('now')
WHERE
  id = OLD.id;
END;
