-- https://github.com/rstudio/connect/issues/5652

-- select by app_id in ListAllJobsByAppId
-- select by app_id and variant_id in ListAllJobsByVariantId
-- select by app_id and key in GetJobByKeyAndAppId
CREATE INDEX jobs_by_app_id_and_key ON jobs (app_id, key);
