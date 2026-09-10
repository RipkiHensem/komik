const { pool } = require('../config/database');
const mangaApiService = require('./mangaApiService');

// Cache to prevent spamming Komiku for the same comic within a short window (15 minutes)
const syncCache = new Map();
const CACHE_TTL_MS = 15 * 60 * 1000;

/**
 * Check and sync a single comic for new chapters from Komiku.
 * Can be called on-demand when a user views a comic, or via background worker.
 *
 * @param {string} comicId - The SQLite comic id or slug
 * @param {boolean} force - Whether to bypass the 15-minute cache
 * @returns {Promise<{ updated: boolean, totalChapters: number, newCount: number }>}
 */
async function syncComicChapters(comicId, force = false) {
  const now = Date.now();
  const lastSync = syncCache.get(comicId) || 0;

  if (!force && now - lastSync < CACHE_TTL_MS) {
    return { updated: false, totalChapters: 0, newCount: 0 };
  }

  syncCache.set(comicId, now);

  try {
    // 1. Get comic info from local DB
    const comicRes = await pool.query('SELECT * FROM comics WHERE id = $1', [comicId]);
    const comic = comicRes.rows[0];
    const searchTarget = comic ? (comic.title || comicId) : comicId;
    const slugCandidate = searchTarget.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

    // 2. Fetch live detail from Komiku
    const liveDetail =
      (await mangaApiService.getMangaDetail(comicId)) ||
      (await mangaApiService.getMangaDetail(slugCandidate));

    if (!liveDetail || !liveDetail.chapters || liveDetail.chapters.length === 0) {
      return { updated: false, totalChapters: 0, newCount: 0 };
    }

    // 3. Compare with existing chapters in SQLite
    const existingChapters = await pool.query(
      'SELECT id, chapter_number FROM chapters WHERE comic_id = $1',
      [comicId]
    );

    const existingIds = new Set(existingChapters.rows.map((r) => r.id));
    const newChapters = liveDetail.chapters.filter((ch) => !existingIds.has(ch.id));

    // 4. Insert any newly released chapters
    if (newChapters.length > 0) {
      const nowIso = new Date().toISOString();
      for (const ch of newChapters) {
        await pool.query(
          `INSERT INTO chapters (id, comic_id, chapter_number, title, released_at)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT(id) DO UPDATE SET
             comic_id = excluded.comic_id,
             chapter_number = excluded.chapter_number,
             title = excluded.title,
             released_at = excluded.released_at`,
          [ch.id, comicId, ch.chapter_number, ch.title, ch.released_at || nowIso]
        );
      }

      // Only update comic's updated_at timestamp if this was an established comic with genuine new releases
      // (not initial chapter population where existingChapters was <= 5)
      if (existingChapters.rows.length > 5) {
        await pool.query(
          'UPDATE comics SET updated_at = $1, status = $2 WHERE id = $3',
          [nowIso, liveDetail.comic.status || 'Ongoing', comicId]
        );

        console.log(
          `[AutoUpdate] 🚀 Found ${newChapters.length} new chapter(s) for "${searchTarget}"! (Total: ${liveDetail.chapters.length})`
        );
      }

      return {
        updated: true,
        totalChapters: liveDetail.chapters.length,
        newCount: newChapters.length,
      };
    }

    return {
      updated: false,
      totalChapters: existingChapters.rows.length,
      newCount: 0,
    };
  } catch (err) {
    console.error(`[AutoUpdate] Error syncing comic ${comicId}:`, err.message);
    return { updated: false, totalChapters: 0, newCount: 0 };
  }
}

/**
 * Global background sync routine:
 * 1. Checks Komiku's live latest update feed for newly released chapters.
 * 2. Checks all bookmarked comics in user libraries.
 * 3. Checks top Ongoing popular series.
 */
async function runBackgroundAutoUpdate() {
  console.log(`[AutoUpdate] 🔄 Running periodic comic sync at ${new Date().toISOString()}...`);

  try {
    // 1. Fetch latest releases from Komiku page 1
    const latestLive = await mangaApiService.getLatestManga(1);
    console.log(`[AutoUpdate] Fetched ${latestLive.length} latest items from Komiku live feed.`);

    for (const item of latestLive.slice(0, 10)) {
      // Check if we have this comic in our database
      const dbCheck = await pool.query(
        'SELECT id FROM comics WHERE id = $1 OR title LIKE $2',
        [item.id, `%${item.title}%`]
      );

      if (dbCheck.rows.length > 0) {
        const matchedId = dbCheck.rows[0].id;
        await syncComicChapters(matchedId);
      }
    }

    // 2. Sync ALL comics in local DB (not just bookmarked ones)
    const allComics = await pool.query(
      "SELECT id, title FROM comics ORDER BY updated_at DESC"
    );

    if (allComics.rows.length > 0) {
      console.log(`[AutoUpdate] Syncing ${allComics.rows.length} comics in local DB...`);
      for (const row of allComics.rows) {
        await syncComicChapters(row.id);
      }
    }

    // 3. Also check comics that users have read (reading_history)
    const historyComics = await pool.query(
      'SELECT DISTINCT comic_id FROM reading_history'
    );
    for (const row of historyComics.rows) {
      await syncComicChapters(row.comic_id);
    }

    console.log('[AutoUpdate] ✅ Periodic sync completed.');
  } catch (err) {
    console.error('[AutoUpdate] Error in background auto-update:', err.message);
  }
}

/**
 * Start the background cron / interval timer
 *
 * @param {number} intervalMinutes - How often to check for new chapters (default: 30 minutes)
 */
function startAutoUpdateScheduler(intervalMinutes = 30) {
  const intervalMs = intervalMinutes * 60 * 1000;
  console.log(`[AutoUpdate] ⏰ Scheduler registered: checking every ${intervalMinutes} minutes.`);

  // Run initial sync 15 seconds after server startup
  setTimeout(() => {
    runBackgroundAutoUpdate();
  }, 15000);

  // Recurring interval
  setInterval(() => {
    runBackgroundAutoUpdate();
  }, intervalMs);
}

module.exports = {
  syncComicChapters,
  runBackgroundAutoUpdate,
  startAutoUpdateScheduler,
};
