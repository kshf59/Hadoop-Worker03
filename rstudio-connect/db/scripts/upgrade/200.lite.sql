
-- Set build status to BuildStatusComplete (==2) for bundles associated with
-- static content (AppMode==4)
UPDATE bundles set build_status = 2 where app_id in (
    select id from apps where app_mode = 4
);
