const express = require('express');
const { pool } = require('../config/database');
const authMiddleware = require('../middleware/auth');
const mangaApiService = require('../services/mangaApiService');

const router = express.Router();

// All bookmark routes require authentication
router.use(authMiddleware);

// GET /api/bookmarks/me — get user's bookmarks with comic info
router.get('/me', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT b.*,
        c.title as comic_title,
        c.cover_url as comic_cover_url,
        ch.chapter_number as last_chapter_number
       FROM bookmarks b
       JOIN comics c ON c.id = b.comic_id
       LEFT JOIN chapters ch ON ch.id = b.last_chapter_id
       WHERE b.user_id = $1
       ORDER BY b.updated_at DESC`,
      [req.user.id]
    );

    res.json({ data: result.rows });
  } catch (err) {
    console.error('Get bookmarks error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/bookmarks — create or update bookmark
router.post('/', async (req, res) => {
  try {
    const { comic_id, last_chapter_id, last_page } = req.body;

    if (!comic_id) {
      return res.status(400).json({ error: 'comic_id is required' });
    }

    // Ensure comic exists in local DB so foreign key constraint is satisfied
    const comicCheck = await pool.query('SELECT id FROM comics WHERE id = $1', [comic_id]);
    if (comicCheck.rows.length === 0) {
      const detail = await mangaApiService.getMangaDetail(comic_id);
      if (detail && detail.comic) {
        const c = detail.comic;
        await pool.query(
          `INSERT INTO comics (id, title, synopsis, cover_url, genre, status, format, rating, view_count, bookmark_count)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           ON CONFLICT (id) DO NOTHING`,
          [
            c.id,
            c.title,
            c.synopsis || '',
            c.cover_url || '',
            JSON.stringify(c.genre || []),
            c.status || 'Ongoing',
            c.format || 'Manga',
            c.rating || 9.0,
            c.view_count || 10000,
            c.bookmark_count || 100,
          ]
        );
        if (detail.chapters) {
          for (const ch of detail.chapters) {
            await pool.query(
              `INSERT INTO chapters (id, comic_id, chapter_number, title)
               VALUES ($1, $2, $3, $4)
               ON CONFLICT (id) DO NOTHING`,
              [ch.id, ch.comic_id, ch.chapter_number, ch.title]
            );
          }
        }
      } else {
        // Create fallback placeholder row
        await pool.query(
          `INSERT INTO comics (id, title, synopsis, cover_url, genre)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (id) DO NOTHING`,
          [comic_id, comic_id, '', '', '[]']
        );
      }
    }

    // If last_chapter_id is provided, ensure it exists in chapters table
    if (last_chapter_id) {
      const chCheck = await pool.query('SELECT id FROM chapters WHERE id = $1', [last_chapter_id]);
      if (chCheck.rows.length === 0) {
        await pool.query(
          `INSERT INTO chapters (id, comic_id, chapter_number, title)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (id) DO NOTHING`,
          [last_chapter_id, comic_id, 1, last_chapter_id]
        );
      }
    }

    // Upsert bookmark
    const result = await pool.query(
      `INSERT INTO bookmarks (user_id, comic_id, last_chapter_id, last_page)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, comic_id)
       DO UPDATE SET
         last_chapter_id = COALESCE($3, bookmarks.last_chapter_id),
         last_page = COALESCE($4, bookmarks.last_page),
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [req.user.id, comic_id, last_chapter_id || null, last_page || 1]
    );

    // Update comic bookmark count
    await pool.query(
      `UPDATE comics SET bookmark_count = (
        SELECT COUNT(*) FROM bookmarks WHERE comic_id = $1
      ) WHERE id = $1`,
      [comic_id]
    );

    res.status(201).json({ data: result.rows[0] });
  } catch (err) {
    console.error('Save bookmark error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/bookmarks/:id — remove bookmark
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const result = await pool.query(
      'DELETE FROM bookmarks WHERE id = $1 AND user_id = $2 RETURNING comic_id',
      [id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Bookmark not found' });
    }

    // Update comic bookmark count
    const comicId = result.rows[0].comic_id;
    await pool.query(
      `UPDATE comics SET bookmark_count = (
        SELECT COUNT(*) FROM bookmarks WHERE comic_id = $1
      ) WHERE id = $1`,
      [comicId]
    );

    res.json({ message: 'Bookmark removed' });
  } catch (err) {
    console.error('Delete bookmark error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
