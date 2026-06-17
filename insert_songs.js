// insert_songs.js
// Run: node insert_songs.js

const SUPABASE_URL = 'https://gdxtbjmglsmuqhncevsk.supabase.co';
const SERVICE_ROLE_KEY = 'YAHAN_SERVICE_ROLE_KEY_DAALO'; // <-- Dashboard > Settings > API > service_role
const BUCKET = 'songs-audio';
const FOLDER = 'old song';

async function listFiles() {
  const res = await fetch(`${SUPABASE_URL}/storage/v1/object/list/${BUCKET}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ prefix: `${FOLDER}/`, limit: 1000 }),
  });
  const data = await res.json();
  return data.filter(f => f.name && !f.id?.includes('placeholder'));
}

function parseFileName(filename) {
  // Remove extension
  const name = filename.replace(/\.(mp3|m4a|wav|flac)$/i, '').trim();
  
  // Try "Artist - Title" format
  if (name.includes(' - ')) {
    const parts = name.split(' - ');
    return { title: parts.slice(1).join(' - ').trim(), artist: parts[0].trim() };
  }
  
  // Just use filename as title
  return { title: name, artist: 'Unknown Artist' };
}

async function insertSongs(songs) {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/songs`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
      'apikey': SERVICE_ROLE_KEY,
      'Content-Type': 'application/json',
      'Prefer': 'return=minimal',
    },
    body: JSON.stringify(songs),
  });
  return res.status;
}

async function main() {
  console.log('📂 Bucket se files read kar raha hun...');
  const files = await listFiles();
  
  if (!files.length) {
    console.log('❌ Koi files nahi mili. Service role key check karo.');
    return;
  }

  console.log(`✅ ${files.length} songs mile!`);

  const songs = files.map(f => {
    const { title, artist } = parseFileName(f.name);
    const audioUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${FOLDER}/${encodeURIComponent(f.name)}`;
    return { title, artist, album: 'Old Songs', audio_url: audioUrl };
  });

  console.log('📝 Songs table mein insert kar raha hun...');
  
  // Insert in batches of 50
  for (let i = 0; i < songs.length; i += 50) {
    const batch = songs.slice(i, i + 50);
    const status = await insertSongs(batch);
    console.log(`  Batch ${Math.floor(i/50)+1}: status ${status}`);
  }

  console.log('🎵 Done! Saare songs insert ho gaye.');
  songs.forEach(s => console.log(`  - ${s.title} | ${s.artist}`));
}

main().catch(console.error);
