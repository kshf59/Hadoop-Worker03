CREATE TABLE cookies (
   id SERIAL PRIMARY KEY,
   cookie_key TEXT NOT NULL,
   user_id INTEGER NOT NULL,
   provider TEXT,
   xsrf_token TEXT,
   created_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
   used_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
   expires TIMESTAMPTZ NOT NULL);

CREATE UNIQUE INDEX cookies_by_key ON cookies (cookie_key);
CREATE INDEX cookies_by_expires ON cookies (expires);
