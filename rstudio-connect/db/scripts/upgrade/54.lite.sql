CREATE INDEX groups_by_principal_id ON groups (principal_id);

CREATE INDEX users_by_principal_id ON users (principal_id);

CREATE INDEX permissions_by_app_id ON permissions (app_id);

CREATE INDEX variants_by_created_time ON variants(created_time);

CREATE INDEX schedule_by_next_run ON schedule(next_run);
