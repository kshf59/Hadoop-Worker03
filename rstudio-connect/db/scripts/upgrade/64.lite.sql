-- Improves queries when looking for "MY" content.
CREATE INDEX apps_by_principal_id_app_mode ON apps (principal_id, app_mode);

-- Improves queries when looking at content without ownership filter.
CREATE INDEX apps_by_app_mode ON apps (app_mode);
