ALTER TABLE bundles ADD COLUMN r_version TEXT NULL;
ALTER TABLE bundles ADD COLUMN build_status INT DEFAULT 0;

UPDATE bundles SET r_version=(SELECT r_version FROM apps WHERE apps.bundle_id=bundles.id)
WHERE EXISTS (SELECT r_version FROM apps WHERE apps.bundle_id=bundles.id);

UPDATE bundles SET build_status=(SELECT build_status FROM apps WHERE apps.bundle_id=bundles.id)
WHERE EXISTS (SELECT build_status FROM apps WHERE apps.bundle_id=bundles.id);
