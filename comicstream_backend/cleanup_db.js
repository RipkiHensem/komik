const { DatabaseSync } = require('node:sqlite');
const db = new DatabaseSync('comicstream.db');

// Count before
const bCount = db.prepare('SELECT COUNT(*) as c FROM bookmarks').get();
console.log('Bookmarks sebelum:', bCount.c);

// Hapus semua bookmark (karena semua itu sebenarnya adalah progress baca yang salah masuk)
db.exec('DELETE FROM bookmarks');
console.log('Semua bookmark dihapus (ini sebenarnya history baca yang salah masuk ke bookmarks)');

// Count comics before
const cBefore = db.prepare('SELECT COUNT(*) as c FROM comics').get();
console.log('Comics sebelum cleanup:', cBefore.c);

// Lihat dulu comic apa saja yang ada
const allComics = db.prepare('SELECT id, title, cover_url FROM comics').all();
allComics.forEach(c => {
  const isDummy = c.title === c.id;
  console.log(`  [${isDummy ? 'DUMMY' : 'OK'}] ${c.title.substring(0, 50)}`);
});

// Hapus comic dummy (title sama dengan id)
db.exec('DELETE FROM comics WHERE title = id');
console.log('Comic dummy dihapus');

// Buat tabel reading_history jika belum ada
try {
  db.exec(`
    CREATE TABLE IF NOT EXISTS reading_history (
      id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
      user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
      comic_id TEXT REFERENCES comics(id) ON DELETE CASCADE,
      last_chapter_id TEXT REFERENCES chapters(id),
      last_page INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, comic_id)
    )
  `);
  console.log('Tabel reading_history sudah siap');
} catch (e) {
  console.log('reading_history already exists:', e.message);
}

const cAfter = db.prepare('SELECT COUNT(*) as c FROM comics').get();
console.log('Comics setelah cleanup:', cAfter.c);
db.close();
console.log('Done!');
