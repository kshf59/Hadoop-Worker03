DROP TRIGGER aft_tag_update;

ALTER TABLE tags RENAME TO tags_temp;

CREATE TABLE tags (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL DEFAULT '',
  parent_id INTEGER,
  created_time DATETIME NOT NULL DEFAULT (datetime('now')),
  updated_time DATETIME NOT NULL DEFAULT (datetime('now')),
  version INTEGER NOT NULL DEFAULT(0),
  deleted BOOLEAN NOT NULL DEFAULT(0),
  FOREIGN KEY(parent_id) REFERENCES tags(id)
);

INSERT INTO tags(name, parent_id, created_time, updated_time, deleted)
SELECT name, parent_id, created_time, updated_time, deleted
FROM tags_temp;

DROP TABLE tags_temp;

CREATE TRIGGER aft_tag_update AFTER UPDATE ON tags
BEGIN
UPDATE tags
SET
  updated_time = datetime('now'),
  version = OLD.version + 1
WHERE
  id = OLD.id;
END;
