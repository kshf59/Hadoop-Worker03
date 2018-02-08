CREATE TABLE cookies (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   cookie_key TEXT NOT NULL,
   user_id INTEGER NOT NULL,
   provider TEXT,
   xsrf_token TEXT,
   created_time DATETIME NOT NULL DEFAULT (datetime('now')),
   used_time DATETIME NOT NULL DEFAULT (datetime('now')),
   expires DATETIME NOT NULL);

CREATE UNIQUE INDEX cookies_by_key ON cookies (cookie_key);
CREATE INDEX cookies_by_expires ON cookies (expires);
