INSERT INTO vanities
  (app_id, path_prefix, created_time)
SELECT
  apps.id AS app_id,
  ("/" || users.username || "/" || apps.name || "/") AS path_prefix,
  (datetime('now', 'localtime')) AS created_time
FROM apps JOIN users ON apps.principal_id=users.principal_id 
WHERE apps.id not in (SELECT app_id from vanities);
