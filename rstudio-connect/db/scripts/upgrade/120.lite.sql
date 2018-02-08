-- https://github.com/rstudio/connect/issues/6957
CREATE INDEX jobs_by_hostname_finalized ON jobs (finalized,hostname);
