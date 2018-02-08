-- https://github.com/rstudio/connect/issues/7006
-- there is no need to attempt to delete duplicate keys because they cannot
-- happen on sqlite due to being a single instance
DROP INDEX jobs_by_app_id_and_key;

CREATE UNIQUE INDEX jobs_by_app_id_and_key ON jobs(app_id,key);

