-- https://github.com/rstudio/connect/issues/7006
-- A cluster of nodes may process the same job spool file at approx the same
-- time with can cause us to create two entries in the database. This function
-- finds entries that have duplicate entries and deletes all but one (giving
-- priority to keep finalized jobs)

DELETE FROM jobs A WHERE EXISTS ( 
    SELECT 'y' FROM jobs B WHERE 
        B.id < A.id AND 
        B.app_id = A.app_id AND 
        B.key = A.key);

DROP INDEX jobs_by_app_id_and_key;

-- Create unique index on app_id and key to stop more duplicates from being
-- created in the future
CREATE UNIQUE INDEX jobs_by_app_id_and_key ON jobs(app_id,key);

