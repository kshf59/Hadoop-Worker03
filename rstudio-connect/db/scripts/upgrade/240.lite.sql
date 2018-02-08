CREATE TABLE cookies_backup (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   cookie_key TEXT NOT NULL,
   user_id INTEGER NOT NULL,
   provider TEXT,
   xsrf_token TEXT,
   created_time DATETIME NOT NULL,
   used_time DATETIME NOT NULL,
   expires DATETIME NOT NULL);

DROP INDEX cookies_by_key;
DROP INDEX cookies_by_expires;

INSERT INTO cookies_backup SELECT id, cookie_key, user_id, provider, xsrf_token,
created_time, used_time, expires FROM cookies;
DROP TABLE cookies;
ALTER TABLE cookies_backup RENAME TO cookies;

CREATE UNIQUE INDEX cookies_by_key ON cookies (cookie_key);
CREATE INDEX cookies_by_expires ON cookies (expires);
