CREATE TABLE queue (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  priority INTEGER NOT NULL,
  type INTEGER NOT NULL,
  item bytea NOT NULL,
  heartbeat TIMESTAMPTZ,
  hostname TEXT,
  created_time TIMESTAMPTZ DEFAULT NOW(),
  updated_time TIMESTAMPTZ DEFAULT NOW()
);

CREATE FUNCTION update_queue_time() RETURNS TRIGGER AS $$
BEGIN
  IF pg_trigger_depth() <> 1 THEN
    RETURN NEW;
  END IF;
  UPDATE queue SET updated_time=now() WHERE id=NEW.id;
    RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER update_queue
AFTER UPDATE ON queue
FOR EACH ROW EXECUTE PROCEDURE update_queue_time();
