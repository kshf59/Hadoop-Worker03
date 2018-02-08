CREATE TABLE subscription_replacement (
  id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  app_id INTEGER NOT NULL,
  variant_id INTEGER NOT NULL,
  principal_id INTEGER NOT NULL,
  include BOOLEAN NOT NULL);

-- This migration discards all existing subscription ids since we're exploding
-- the subscription entry across all variants.
INSERT INTO subscription_replacement
    (app_id, variant_id, principal_id, include)
SELECT
    subscription.app, variants.id, subscription.principal, subscription.include
FROM subscription, variants
WHERE variants.app_id = subscription.app;

DROP TABLE subscription;

ALTER TABLE subscription_replacement RENAME TO subscription;
