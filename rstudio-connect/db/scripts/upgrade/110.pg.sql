CREATE TABLE reset_password_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  password TEXT NOT NULL DEFAULT '',
  expires TIMESTAMPTZ NOT NULL);
