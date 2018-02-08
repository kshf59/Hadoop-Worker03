-- This migration removes associations between apps and _category_ tags (roots
-- of the tag forest). We only want to permit associations between apps and
-- actual tags (non-roots).

DELETE FROM tagmap WHERE tag_id IN (SELECT id FROM tags WHERE parent_id IS NULL);
