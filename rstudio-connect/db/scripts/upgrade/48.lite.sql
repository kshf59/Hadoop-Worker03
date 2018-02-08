-- Add the apps.run_as_current_user column, which tracks if an app is allowed
-- to launch as the currently logged in user instead of the configured
-- apps.run_as user (or global default).
ALTER TABLE apps ADD COLUMN run_as_current_user BOOLEAN DEFAULT 0;
