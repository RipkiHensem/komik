const { DatabaseSync } = require('node:sqlite');
require('dotenv').config();

const db = new DatabaseSync('comicstream.db');
db.exec('PRAGMA foreign_keys = ON;');

const pool = {
  query: async (sql, params = []) => {
    let sqliteSql = sql;
    let sqliteParams = params;
    const matches = sql.match(/\$(\d+)/g);
    if (matches && matches.length > 0) {
      sqliteParams = matches.map((m) => {
        const idx = parseInt(m.substring(1), 10) - 1;
        return params[idx];
      });
      sqliteSql = sql.replace(/\$\d+/g, '?');
    }
    const stmt = db.prepare(sqliteSql);
    try {
      if (sqliteSql.trim().toUpperCase().startsWith('SELECT') || sqliteSql.trim().toUpperCase().includes('RETURNING')) {
        const rows = stmt.all(...sqliteParams);
        return { rows };
      } else {
        const info = stmt.run(...sqliteParams);
        return { rows: [], rowCount: info.changes };
      }
    } catch (err) {
      console.error('SQL Error:', err.message, sqliteSql, sqliteParams);
      throw err;
    }
  },
  connect: async () => ({
    query: pool.query,
    release: () => {}
  }),
  end: async () => { db.close(); }
};

const initDB = async () => {
  try {
    db.exec(`
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        avatar_url TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );
    `);

    try {
      db.exec('ALTER TABLE users ADD COLUMN avatar_url TEXT;');
    } catch (_) {}

    db.exec(`

      CREATE TABLE IF NOT EXISTS comics (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        title TEXT NOT NULL,
        alternative_title TEXT,
        synopsis TEXT,
        cover_url TEXT,
        genre TEXT DEFAULT '[]',
        status TEXT DEFAULT 'Ongoing',
        author TEXT,
        artist TEXT,
        format TEXT DEFAULT 'Manhwa',
        rating REAL DEFAULT 0.0,
        view_count INTEGER DEFAULT 0,
        bookmark_count INTEGER DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS chapters (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        comic_id TEXT REFERENCES comics(id) ON DELETE CASCADE,
        chapter_number INTEGER NOT NULL,
        title TEXT,
        released_at DATETIME DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS pages (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        chapter_id TEXT REFERENCES chapters(id) ON DELETE CASCADE,
        page_number INTEGER NOT NULL,
        image_url TEXT NOT NULL
      );

      CREATE TABLE IF NOT EXISTS bookmarks (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        comic_id TEXT REFERENCES comics(id) ON DELETE CASCADE,
        last_chapter_id TEXT REFERENCES chapters(id),
        last_page INTEGER DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, comic_id)
      );

      CREATE TABLE IF NOT EXISTS reading_history (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        comic_id TEXT REFERENCES comics(id) ON DELETE CASCADE,
        last_chapter_id TEXT REFERENCES chapters(id),
        last_page INTEGER DEFAULT 1,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, comic_id)
      );

      CREATE TABLE IF NOT EXISTS read_chapters (
        id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
        user_id TEXT REFERENCES users(id) ON DELETE CASCADE,
        comic_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        read_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, comic_id, chapter_id)
      );
    `);
    console.log('✅ Database tables initialized (SQLite built-in)');
  } catch (err) {
    console.error('❌ Error initializing database:', err.message);
  }
};

module.exports = { pool, initDB };
