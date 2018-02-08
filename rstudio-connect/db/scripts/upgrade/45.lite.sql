CREATE TABLE api_keys (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   user_id INTEGER NOT NULL,
   key TEXT NOT NULL,
   created_time DATETIME DEFAULT (datetime('now')),
   last_used_time DATETIME);

CREATE UNIQUE INDEX unique_api_keys ON api_keys(key);
