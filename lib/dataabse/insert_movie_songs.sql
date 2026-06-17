INSERT INTO songs (title, artist, album, audio_url, category)
SELECT 
  trim(regexp_replace(split_part(name, '/', 2), '\.(mp3|m4a|wav|aac|ogg|flac)$', '', 'i')),
  'Unknown',
  split_part(name, '/', 1),
  'https://gdxtbjmglsmuqhncevsk.supabase.co/storage/v1/object/public/songs-audio/' || name,
  'movie'
FROM storage.objects
WHERE bucket_id = 'songs-audio'
  AND name NOT LIKE '%.emptyFolderPlaceholder%'
  AND name LIKE '%/%'
  AND split_part(name, '/', 1) NOT IN ('old song')
ON CONFLICT DO NOTHING;
