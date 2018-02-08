CREATE TABLE renderings (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    app_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    bundle_id INTEGER NULL,
    job_key key VARCHAR(16) NULL,
    render_time DATETIME NOT NULL,
    render_duration INTEGER NOT NULL);

CREATE INDEX renderings_by_variant_id ON renderings (variant_id);
