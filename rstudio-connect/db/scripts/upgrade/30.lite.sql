CREATE TABLE variants_replacement (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   app_id INTEGER NOT NULL,
   bundle_id INTEGER NULL,
   key TEXT NOT NULL,
   is_default BOOLEAN DEFAULT 0,
   name TEXT,
   email_collaborators BOOLEAN DEFAULT 0,
   email_viewers BOOLEAN DEFAULT 0,
   created_time DATETIME DEFAULT (datetime('now', 'localtime')), 
   render_time DATETIME NULL,
   render_duration INTEGER DEFAULT 0);

INSERT INTO variants_replacement
SELECT
    id,
    app_id,
    bundle_id,
    substr('00000000' || id, -8, 8),
    is_default,
    name,
    email_collaborators,
    email_viewers,
    created_time,
    render_time,
    render_duration
FROM variants;

DROP TABLE variants;

ALTER TABLE variants_replacement RENAME TO variants;
