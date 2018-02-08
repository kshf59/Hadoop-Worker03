/* Add visibility column and default to public (0) */
ALTER TABLE variants ADD COLUMN visibility INTEGER DEFAULT 0;
ALTER TABLE variants ADD COLUMN owner_id INTEGER DEFAULT 0;

/* migrate current variants to have an owner_id */
UPDATE variants SET owner_id = (SELECT users.id FROM apps JOIN users ON users.principal_id == apps.principal_id WHERE variants.app_id == apps.id);
