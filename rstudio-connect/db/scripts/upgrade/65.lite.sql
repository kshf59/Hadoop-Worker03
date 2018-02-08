-- #5730: Improve scanning for expired ad-hoc variants
DROP INDEX variants_by_created_time;
CREATE INDEX variants_by_visibility_created_time ON variants(visibility,created_time);

-- #5731: Improve variant enumeration
CREATE INDEX variants_by_app_id ON variants (app_id);

-- #5732: Improve discovery of apps with too many jobs and reapable jobs for a
-- given app.
CREATE INDEX jobs_by_app_id_etc ON jobs (app_id,finalized,start_time);

-- #5733: Improve user lookup when using the provider key (common).
CREATE INDEX users_by_provider_key ON users(provider_key);

-- #5734: Improve schedule enumeration.
CREATE INDEX schedule_by_variant_id ON schedule (variant_id);
CREATE INDEX schedule_by_app_id_variant_id ON schedule (app_id,variant_id);

-- #5735: Improve subscription enumeration.
CREATE INDEX subscription_by_app_id_variant_id ON subscription (app_id,variant_id);
