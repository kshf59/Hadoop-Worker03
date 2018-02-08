DROP TRIGGER aft_tag_update;

ALTER TABLE tags RENAME TO tags_temp;

CREATE TABLE tags (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  name VARCHAR(255) NOT NULL DEFAULT '',
  parent_id INTEGER,
  created_time DATETIME NOT NULL DEFAULT (datetime('now')),
  updated_time DATETIME NOT NULL DEFAULT (datetime('now')),
  version INTEGER NOT NULL DEFAULT(0),
  FOREIGN KEY(parent_id) REFERENCES tags(id)
);

--copy back table but only tags that haven't been deleted
INSERT INTO tags(id, name, parent_id, created_time, updated_time, version)
SELECT id, name, parent_id, created_time, updated_time, version
FROM tags_temp
WHERE deleted = 0;

----delete associations of deleted
DELETE FROM tagmap
WHERE tag_id IN (SELECT id FROM tags_temp WHERE deleted = 1);

--drop temp table
DROP TABLE tags_temp;

--recreate trigger
CREATE TRIGGER aft_tag_update AFTER UPDATE ON tags
BEGIN
UPDATE tags
SET
  updated_time = datetime('now'),
  version = OLD.version + 1
WHERE
  id = OLD.id;
END;
