const express = require('express');
const { pool } = require('../config/database');
const mangaApiService = require('../services/mangaApiService');
const autoUpdateService = require('../services/autoUpdateService');

const router = express.Router();

/**
 * Format DB comic row to ensure genre is an array
 */
function formatDbComic(row) {
  let genre = row.genre;
  if (typeof genre === 'string') {
    try {
      genre = JSON.parse(genre);
    } catch (_) {
      genre = genre.split(',').map((g) => g.trim());
    }
  }
  let updatedAt = row.latest_update_at || row.updated_at;
  if (typeof updatedAt === 'string') {
    updatedAt = updatedAt.replace(' ', 'T');
    if (!updatedAt.endsWith('Z') && !updatedAt.includes('+')) {
      updatedAt += 'Z';
    }
  }
  return {
    ...row,
    genre: Array.isArray(genre) ? genre : [genre || 'Action'],
    updated_at: updatedAt,
    latest_update_at: updatedAt,
  };
}

/**
 * Helper to upsert an external comic into the SQLite database
 * so foreign key relations (bookmarks, chapters) work seamlessly.
 */
async function upsertComicToDb(comic) {
  try {
    const genreStr = JSON.stringify(comic.genre || []);
    await pool.query(
      `INSERT INTO comics (id, title, alternative_title, synopsis, cover_url, genre, status, author, artist, format, rating, view_count, bookmark_count, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
       ON CONFLICT(id) DO UPDATE SET
         title = excluded.title,
         synopsis = excluded.synopsis,
         cover_url = excluded.cover_url,
         genre = excluded.genre,
         status = excluded.status,
         format = excluded.format,
         updated_at = COALESCE(comics.updated_at, excluded.updated_at)`,
      [
        comic.id,
        comic.title,
        comic.alternative_title || null,
        comic.synopsis || '',
        comic.cover_url || '',
        genreStr,
        comic.status || 'Ongoing',
        comic.author || 'Komiku Author',
        comic.artist || null,
        comic.format || 'Manga',
        comic.rating || 9.0,
        comic.view_count || 100000,
        comic.bookmark_count || 5000,
        comic.updated_at || new Date().toISOString(),
      ]
    );
  } catch (err) {
    console.error('upsertComicToDb error:', err.message);
  }
}

/**
 * Helper to upsert external chapters into the SQLite database
 */
async function upsertChaptersToDb(chapters) {
  for (const ch of chapters) {
    try {
      // Ensure parent comic row exists in comics table
      await pool.query(
        `INSERT INTO comics (id, title, synopsis, cover_url, genre)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO NOTHING`,
        [ch.comic_id, ch.comic_id, '', '', '[]']
      );

      await pool.query(
        `INSERT INTO chapters (id, comic_id, chapter_number, title, released_at)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT(id) DO UPDATE SET
           chapter_number = excluded.chapter_number,
           title = excluded.title,
           released_at = excluded.released_at`,
        [
          ch.id,
          ch.comic_id,
          ch.chapter_number,
          ch.title || `Chapter ${ch.chapter_number}`,
          ch.released_at || new Date().toISOString(),
        ]
      );
    } catch (_) {
      // Ignore conflict
    }
  }
}

// GET /api/comics — list comics with search, filter, sort, pagination
router.get('/', async (req, res) => {
  try {
    const {
      search,
      genre,
      format,
      status,
      sortBy = 'latest',
      page = 1,
      limit = 20,
    } = req.query;

    const pageNum = parseInt(page) || 1;
    const limitNum = parseInt(limit) || 20;

    // 1. Fetch matching local comics from database
    let dbQuery = `
      SELECT c.*,
        (SELECT COUNT(*) FROM chapters ch WHERE ch.comic_id = c.id) as chapter_count
      FROM comics c
      WHERE 1=1
    `;
    const dbParams = [];
    let paramIndex = 1;

    if (search && search.trim()) {
      const s = search.trim();
      dbQuery += ` AND (c.title LIKE $${paramIndex} OR c.alternative_title LIKE $${paramIndex + 1} OR c.synopsis LIKE $${paramIndex + 2} OR c.format LIKE $${paramIndex + 3} OR c.genre LIKE $${paramIndex + 4})`;
      dbParams.push(`%${s}%`, `%${s}%`, `%${s}%`, `%${s}%`, `%${s}%`);
      paramIndex += 5;
    }

    if (genre) {
      const genres = genre.split(',').map((g) => g.trim().toLowerCase());
      for (const g of genres) {
        dbQuery += ` AND LOWER(c.genre) LIKE $${paramIndex}`;
        dbParams.push(`%${g}%`);
        paramIndex++;
      }
    }

    if (format) {
      dbQuery += ` AND c.format = $${paramIndex}`;
      dbParams.push(format);
      paramIndex++;
    }

    if (status) {
      dbQuery += ` AND c.status = $${paramIndex}`;
      dbParams.push(status);
      paramIndex++;
    }

    // Build the SELECT with latest_update_at for latest sort
    if (sortBy === 'latest' || !['popular','rating','title'].includes(sortBy)) {
      // Replace the base SELECT to include latest update / chapter date
      dbQuery = dbQuery.replace(
        '(SELECT COUNT(*) FROM chapters ch WHERE ch.comic_id = c.id) as chapter_count',
        `(SELECT COUNT(*) FROM chapters ch WHERE ch.comic_id = c.id) as chapter_count,
         MAX(
           COALESCE(REPLACE((SELECT MAX(ch2.released_at) FROM chapters ch2 WHERE ch2.comic_id = c.id), ' ', 'T'), '1970-01-01T00:00:00.000Z'),
           COALESCE(REPLACE(c.updated_at, ' ', 'T'), '1970-01-01T00:00:00.000Z')
         ) as latest_update_at`
      );
    }

    switch (sortBy) {
      case 'popular':
        dbQuery += ' ORDER BY c.view_count DESC';
        break;
      case 'rating':
        dbQuery += ' ORDER BY c.rating DESC';
        break;
      case 'title':
        dbQuery += ' ORDER BY c.title ASC';
        break;
      case 'latest':
      default:
        // Sort by the most recently updated chapter date / comic update
        dbQuery += ' ORDER BY latest_update_at DESC';
        break;
    }


    const dbResult = await pool.query(dbQuery, dbParams);
    const localComics = dbResult.rows.map(formatDbComic);

    // 2. Fetch live comics from Manga API (Komiku) based on context
    let apiComics = [];

    try {
      if (search && search.trim()) {
        apiComics = await mangaApiService.searchManga(search.trim());
      } else if (sortBy === 'popular') {
        apiComics = await mangaApiService.getPopularManga(pageNum, format);
      } else if (sortBy === 'rating') {
        apiComics = await mangaApiService.getHotManga(pageNum, format);
      } else if (sortBy === 'latest' || !sortBy) {
        // Live latest updates feed, respecting selected comic format (manga, manhwa, manhua)
        const p1 = await mangaApiService.getLatestManga(pageNum, format);
        if (limitNum > 10 && pageNum === 1) {
          const p2 = await mangaApiService.getLatestManga(2, format);
          apiComics = [...p1, ...p2];
        } else {
          apiComics = p1;
        }
      } else if (format && format.toLowerCase() === 'manhwa') {
        apiComics = await mangaApiService.getManhwa(pageNum);
      } else if (format && format.toLowerCase() === 'manhua') {
        apiComics = await mangaApiService.getManhua(pageNum);
      } else if (format && format.toLowerCase() === 'manga') {
        apiComics = await mangaApiService.getManga(pageNum);
      } else {
        apiComics = await mangaApiService.getLatestManga(pageNum, format);
      }
    } catch (apiErr) {
      console.error('Manga API fetch error, falling back to DB:', apiErr.message);
    }

    // If format filter is active, filter external apiComics by that format
    if (format && apiComics.length > 0) {
      const fLower = format.toLowerCase().trim();
      apiComics = apiComics.filter((c) => c.format && c.format.toLowerCase() === fLower);
    }

    // If genre filter is active, filter external apiComics by that genre
    if (genre && apiComics.length > 0) {
      const gList = genre.toLowerCase().split(',').map((g) => g.trim());
      apiComics = apiComics.filter((c) => {
        const cGenres = (c.genre || []).map((cg) => cg.toLowerCase());
        return gList.some((g) => cGenres.some((cg) => cg.includes(g)));
      });
    }

    // 3. Merge:
    // For 'latest': local comics (sorted by most recent update) come FIRST!
    // This ensures any newly updated comic in the app is at the very top of "Update Terbaru".
    // For 'popular': local comics come first (sorted by view_count DESC).
    const seenIds = new Set();
    const seenTitles = new Set();
    const merged = [];

    if (sortBy === 'popular' && pageNum === 1) {
      // Popular: local comics first (high view_count), then API
      for (const c of localComics) {
        if (!seenIds.has(c.id) && !seenTitles.has(c.title.toLowerCase())) {
          seenIds.add(c.id);
          seenTitles.add(c.title.toLowerCase());
          merged.push(c);
        }
      }
      for (const c of apiComics) {
        if (!seenIds.has(c.id) && !seenTitles.has(c.title.toLowerCase())) {
          seenIds.add(c.id);
          seenTitles.add(c.title.toLowerCase());
          merged.push(c);
        }
      }
    } else if (sortBy === 'latest') {
      // Latest: "Update Terbaru" strictly follows the real-time chapter release feed.
      // Reading, viewing, or opening a comic must NEVER push it into "Update Terbaru".
      const localById = new Map();
      const localByTitle = new Map();
      for (const c of localComics) {
        localById.set(c.id, c);
        localByTitle.set(c.title.toLowerCase().trim(), c);
      }

      if (apiComics.length > 0) {
        // Keep the exact chronological release order from the live comic update feed
        for (const apiC of apiComics) {
          const normTitle = apiC.title.toLowerCase().trim();
          const localMatch = localById.get(apiC.id) || localByTitle.get(normTitle);
          if (localMatch) {
            seenIds.add(localMatch.id);
            seenTitles.add(normTitle);
            merged.push({
              ...localMatch,
              // Use the actual chapter release time from the live feed, NOT the user read timestamp
              updated_at: apiC.updated_at || apiC.latest_update_at,
              latest_update_at: apiC.latest_update_at || apiC.updated_at,
              chapter_count: Math.max(localMatch.chapter_count || 0, apiC.chapter_count || 0),
            });
          } else {
            seenIds.add(apiC.id);
            seenTitles.add(normTitle);
            merged.push(apiC);
          }
        }
      } else {
        // Fallback only if live API is unavailable
        for (const c of localComics) {
          if (!seenIds.has(c.id) && !seenTitles.has(c.title.toLowerCase())) {
            seenIds.add(c.id);
            seenTitles.add(c.title.toLowerCase());
            merged.push(c);
          }
        }
      }
    } else {
      // Default: local first, then API
      if (pageNum === 1) {
        for (const c of localComics) {
          if (!seenIds.has(c.id) && !seenTitles.has(c.title.toLowerCase())) {
            seenIds.add(c.id);
            seenTitles.add(c.title.toLowerCase());
            merged.push(c);
          }
        }
      }
      for (const c of apiComics) {
        if (!seenIds.has(c.id) && !seenTitles.has(c.title.toLowerCase())) {
          seenIds.add(c.id);
          seenTitles.add(c.title.toLowerCase());
          merged.push(c);
        }
      }
    }

    // Fallback: if empty
    if (merged.length === 0 && localComics.length > 0) {
      const offset = (pageNum - 1) * limitNum;
      merged.push(...localComics.slice(offset, offset + limitNum));
    }

    // Apply strict format filter on final results
    let finalComics = merged;
    if (format) {
      const fLower = format.toLowerCase().trim();
      finalComics = finalComics.filter((c) => c.format && c.format.toLowerCase() === fLower);
    }
    if (status) {
      const sLower = status.toLowerCase().trim();
      finalComics = finalComics.filter((c) => c.status && c.status.toLowerCase() === sLower);
    }

    // Apply limitNum if specified
    const result = limitNum ? finalComics.slice(0, limitNum) : finalComics;
    res.json({ data: result });
  } catch (err) {
    console.error('Get comics error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});


// GET /api/comics/:id — get comic detail
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Check local DB first
    const dbResult = await pool.query(
      `SELECT c.*,
        (SELECT COUNT(*) FROM chapters ch WHERE ch.comic_id = c.id) as chapter_count
       FROM comics c WHERE c.id = $1`,
      [id]
    );

    if (dbResult.rows.length > 0) {
      const comic = formatDbComic(dbResult.rows[0]);
      // If comic has <= 5 dummy chapters, attempt upgrade to real live catalog
      if (comic.chapter_count <= 5) {
        const titleSlug = comic.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
        const liveDetail = (await mangaApiService.getMangaDetail(id)) || (await mangaApiService.getMangaDetail(titleSlug));
        if (liveDetail && liveDetail.chapters && liveDetail.chapters.length > 5) {
          comic.chapter_count = liveDetail.chapters.length;
          const mappedChapters = liveDetail.chapters.map((ch) => ({ ...ch, comic_id: id }));
          upsertChaptersToDb(mappedChapters);
        }
      }
      // Trigger background sync for latest chapters (cached for 15 min to prevent spam)
      autoUpdateService.syncComicChapters(id).catch((err) => {
        console.error('[Detail Sync Error]', err.message);
      });

      await pool.query('UPDATE comics SET view_count = view_count + 1 WHERE id = $1', [id]);
      return res.json({ data: comic });
    }

    // If not in DB, try fetching live detail from Manga API
    const liveDetail = await mangaApiService.getMangaDetail(id);

    if (liveDetail && liveDetail.comic) {
      // Background upsert to SQLite DB so bookmarks and relations work
      upsertComicToDb(liveDetail.comic);
      if (liveDetail.chapters && liveDetail.chapters.length > 0) {
        upsertChaptersToDb(liveDetail.chapters);
      }
      return res.json({ data: liveDetail.comic });
    }

    return res.status(404).json({ error: 'Comic not found' });
  } catch (err) {
    console.error('Get comic detail error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/comics/:id/chapters — get chapters for a comic
router.get('/:id/chapters', async (req, res) => {
  try {
    const { id } = req.params;

    // Check local DB first
    const dbResult = await pool.query(
      `SELECT ch.*,
        (SELECT COUNT(*) FROM pages p WHERE p.chapter_id = ch.id) as page_count
       FROM chapters ch
       WHERE ch.comic_id = $1
       ORDER BY ch.chapter_number DESC`,
      [id]
    );

    // If local DB only has <= 5 dummy chapters OR if chapters have clustered/stale timestamps (span < 60s across chapters), refresh to full live catalog
    const timeSpanMs = dbResult.rows.length > 1
      ? Math.abs(
          new Date(dbResult.rows[0].released_at).getTime() -
          new Date(dbResult.rows[dbResult.rows.length - 1].released_at).getTime()
        )
      : 0;
    const hasStaleTimestamps = dbResult.rows.length > 5 && (isNaN(timeSpanMs) || timeSpanMs < 60 * 1000);

    if (dbResult.rows.length <= 5 || hasStaleTimestamps) {
      const comicRes = await pool.query('SELECT * FROM comics WHERE id = $1', [id]);
      const comic = comicRes.rows[0];
      const searchTarget = comic ? (comic.title || id) : id;
      const slugCandidate = searchTarget.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

      const liveDetail = (await mangaApiService.getMangaDetail(id)) || (await mangaApiService.getMangaDetail(slugCandidate));

      if (liveDetail && liveDetail.chapters && liveDetail.chapters.length > 0) {
        const mappedChapters = liveDetail.chapters.map((ch) => ({
          ...ch,
          comic_id: id,
        }));
        await upsertChaptersToDb(mappedChapters);
        return res.json({ data: mappedChapters });
      }

      if (dbResult.rows.length > 0) {
        return res.json({ data: dbResult.rows });
      }
    } else {
      // Background sync check for newly released chapters
      autoUpdateService.syncComicChapters(id).catch(() => {});
      return res.json({ data: dbResult.rows });
    }

    // If no chapters in DB, fetch from Manga API
    const liveDetail = await mangaApiService.getMangaDetail(id);

    if (liveDetail && liveDetail.chapters && liveDetail.chapters.length > 0) {
      if (liveDetail.comic) upsertComicToDb(liveDetail.comic);
      upsertChaptersToDb(liveDetail.chapters);
      return res.json({ data: liveDetail.chapters });
    }

    res.json({ data: [] });
  } catch (err) {
    console.error('Get chapters error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/comics/:id/sync — manually check for new chapters
router.post('/:id/sync', async (req, res) => {
  try {
    const { id } = req.params;
    const result = await autoUpdateService.syncComicChapters(id, true);

    const updatedChapters = await pool.query(
      `SELECT ch.*,
        (SELECT COUNT(*) FROM pages p WHERE p.chapter_id = ch.id) as page_count
       FROM chapters ch
       WHERE ch.comic_id = $1
       ORDER BY ch.chapter_number DESC`,
      [id]
    );

    res.json({
      success: true,
      updated: result.updated,
      new_count: result.newCount,
      total_chapters: updatedChapters.rows.length,
      data: updatedChapters.rows,
      message: result.updated
        ? `Berhasil memperbarui ${result.newCount} chapter baru!`
        : 'Semua chapter sudah dalam versi terbaru!',
    });
  } catch (err) {
    console.error('Sync comic error:', err);
    res.status(500).json({ error: 'Failed to sync comic' });
  }
});

module.exports = router;
