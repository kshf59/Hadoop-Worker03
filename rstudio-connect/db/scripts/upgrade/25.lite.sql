ALTER TABLE schedule ADD COLUMN email BOOLEAN DEFAULT 0;

UPDATE schedule SET email = 1 where app_id in (select id from apps a where a.email = 1);

-- removing the email column from apps is in the next migration (26).
