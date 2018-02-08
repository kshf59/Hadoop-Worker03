-- Delete orphaned subscriptions where the variant it's connected to doesn't exist

DELETE
    FROM subscription WHERE id IN (
    SELECT s2.id FROM subscription s2
    LEFT JOIN variants v ON v.id = s2.variant_id
    WHERE v.id IS NULL
    );
