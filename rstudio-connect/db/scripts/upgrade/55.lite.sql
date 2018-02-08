CREATE TABLE jobs (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    pid INTEGER,
    key VARCHAR(16) NOT NULL,
    app_id INTEGER NOT NULL,
    variant_id INTEGER,
    bundle_id INTEGER,
    tag VARCHAR(16) NOT NULL,
    start_time DATETIME NOT NULL DEFAULT (datetime('now')),
    end_time DATETIME NULL,
    exit_code INTEGER NULL,
    finalized BOOLEAN NOT NULL DEFAULT FALSE);
