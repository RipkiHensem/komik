-- Remove only placeholder comic rows that match the original seed IDs and Unsplash covers.
-- Chapter and chapter-page rows are removed by the schema's ON DELETE CASCADE constraints.
-- The returned IDs show exactly which comic rows were deleted.
DELETE FROM public.comics AS comics
WHERE comics.id IN (
  'solo-leveling',
  'omniscient-readers-viewpoint',
  'one-piece',
  'tower-of-god',
  'magic-emperor',
  'jujutsu-kaisen'
)
AND comics.cover_url LIKE 'https://images.unsplash.com/%'
RETURNING comics.id;
