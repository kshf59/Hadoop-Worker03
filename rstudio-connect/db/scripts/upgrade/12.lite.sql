-- DROP column r_versions.docker_path

CREATE TEMPORARY TABLE rversion_backup(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  major INTEGER NOT NULL,
  minor INTEGER NOT NULL,
  patch INTEGER NOT NULL,
  local_path TEXT);

INSERT INTO rversion_backup SELECT id, major, minor, patch, local_path FROM r_versions;
DROP TABLE r_versions;
CREATE TABLE r_versions(
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  major INTEGER NOT NULL,
  minor INTEGER NOT NULL,
  patch INTEGER NOT NULL,
  local_path TEXT);

INSERT INTO r_versions SELECT id, major, minor, patch, local_path FROM rversion_backup;
DROP TABLE rversion_backup;
