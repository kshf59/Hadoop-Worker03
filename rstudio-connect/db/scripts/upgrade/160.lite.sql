CREATE TABLE bundles_backup (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    app_id INTEGER NOT NULL,
    created_time DATETIME,
    updated_time DATETIME,
    r_version TEXT NULL,
    build_status INT DEFAULT 0);
 
 INSERT INTO bundles_backup SELECT id, app_id, created_time, updated_time, r_version, build_status FROM bundles;
 DROP TABLE bundles;
 ALTER TABLE bundles_backup RENAME TO bundles;
