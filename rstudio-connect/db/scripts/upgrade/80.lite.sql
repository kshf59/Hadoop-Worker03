CREATE TABLE variants_replacement (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    app_id INTEGER NOT NULL,
    bundle_id INTEGER NULL,
    key TEXT NOT NULL,
    is_default BOOLEAN DEFAULT 0,
    name TEXT,
    email_collaborators BOOLEAN DEFAULT 0,
    email_viewers BOOLEAN DEFAULT 0,
    created_time DATETIME DEFAULT (datetime('now')),
    render_time DATETIME NULL,
    render_duration INTEGER NULL,
    visibility INTEGER DEFAULT 0,
    owner_id INTEGER DEFAULT 0);

INSERT INTO variants_replacement
SELECT
   id,
   app_id,
   bundle_id,
   key,
   is_default,
   name,
   email_collaborators,
   email_viewers,
   DATETIME(created_time, "UTC"),
   DATETIME(render_time, "UTC"),
   render_duration,
   visibility,
   owner_id
FROM variants;

DROP TABLE variants;
ALTER TABLE variants_replacement RENAME TO variants;

CREATE INDEX variants_by_visibility_created_time ON variants(visibility,created_time);
CREATE INDEX variants_by_app_id ON variants (app_id);
