UPDATE apps
  SET build_status = 2
  WHERE app_mode = 4 AND build_status IN ( 0, 1 ) AND bundle_id IS NOT NULL;

