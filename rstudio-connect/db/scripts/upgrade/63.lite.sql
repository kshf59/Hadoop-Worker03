DROP INDEX permissions_by_app_id;

-- improves app-list permissions queries, which are often constrained by both
-- app and current-user (principal).
CREATE INDEX permissions_by_app_id_principal_id ON permissions (app_id, principal_id);
