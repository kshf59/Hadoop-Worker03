
CREATE TABLE refresh_tokens (
   id INTEGER NOT NULL PRIMARY KEY,
   user_id INTEGER NOT NULL,
   token text,
   created_time DATETIME DEFAULT(datetime('now', 'localtime')), 
   used_time DATETIME DEFAULT(datetime('now', 'localtime')));
