CREATE TABLE renderings (
    id SERIAL PRIMARY KEY,
    app_id INTEGER NOT NULL,
    variant_id INTEGER NOT NULL,
    bundle_id INTEGER NULL,
    job_key VARCHAR(16) NULL,
    render_time TIMESTAMPTZ NOT NULL,
    render_duration BIGINT NOT NULL);

CREATE INDEX renderings_by_variant_id ON renderings (variant_id);
