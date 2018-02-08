-- Remove the password_expire column from users.

CREATE TABLE users_replacement (
   id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
   principal_id INTEGER NOT NULL,
   provider_key TEXT,
   username TEXT,
   email TEXT,
   password TEXT,
   first_name TEXT,
   last_name TEXT,
   user_role TEXT,
   created_time DATETIME,
   updated_time DATETIME,
   active_time DATETIME,
   confirmed BOOLEAN NOT NULL DEFAULT FALSE,
   locked BOOLEAN NOT NULL DEFAULT FALSE);

INSERT INTO users_replacement
SELECT
   id,
   principal_id,
   provider_key,
   username,
   email,
   password,
   first_name,
   last_name,
   user_role,
   created_time,
   updated_time,
   active_time,
   confirmed,
   locked
FROM users;

DROP TABLE users;
ALTER TABLE users_replacement RENAME TO users;
