-- https://github.com/rstudio/connect/issues/5650
CREATE INDEX vanities_by_path_prefix on vanities (path_prefix);
