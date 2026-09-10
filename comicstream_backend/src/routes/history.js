const express = require('express');
const { pool } = require('../config/database');
const authMiddleware = require('../middleware/auth');
const mangaApiService = require('../services/mangaApiService');

const router = express.Router();

// All history routes require authentication
router.use(authMiddleware);

// GET /api/history/me — get user's reading history
router.get('/me', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT h.*,
        COALESCE(c.title, h.comic_id) as comic_title,
        COALESCE(c.cover_url, '') as comic_cover_url,
        ch.chapter_number as last_chapter_number
       FROM reading_history h
       LEFT JOIN comics c ON c.id = h.comic_id
       LEFT JOIN chapters ch ON ch.id = h.last_chapter_id
       WHERE h.user_id = $1
       ORDER BY h.updated_at DESC
       LIMIT 100`,
      [req.user.id]
    );

    res.json({ data: result.rows });
  } catch (err) {
    console.error('Get history error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/history/read-chapters/:comicId — get list of read chapter IDs for a comic
router.get('/read-chapters/:comicId', async (req, res) => {
  try {
    const { comicId } = req.params;
    const result = await pool.query(
      `SELECT chapter_id FROM read_chapters
       WHERE user_id = $1 AND comic_id = $2
       ORDER BY read_at DESC`,
      [req.user.id, comicId]
    );
    res.json({ data: result.rows.map((r) => r.chapter_id) });
  } catch (err) {
    console.error('Get read chapters error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/history/read-chapters — mark a specific chapter as read
router.post('/read-chapters', async (req, res) => {
  try {
    const { comic_id, chapter_id } = req.body;
    if (!comic_id || !chapter_id) {
      return res.status(400).json({ error: 'comic_id and chapter_id are required' });
    }
    await pool.query(
      `INSERT INTO read_chapters (user_id, comic_id, chapter_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, comic_id, chapter_id)
       DO UPDATE SET read_at = CURRENT_TIMESTAMP`,
      [req.user.id, comic_id, chapter_id]
    );
    res.json({ success: true, message: 'Chapter marked as read' });
  } catch (err) {
    console.error('Mark read chapter error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/history — save or update reading progress (auto-called when reading)
router.post('/', async (req, res) => {
  try {
    const { comic_id, last_chapter_id, last_page } = req.body;

    if (!comic_id) {
      return res.status(400).json({ error: 'comic_id is required' });
    }

    // Ensure comic exists in local DB so foreign key constraint is satisfied
    const comicCheck = await pool.query('SELECT id FROM comics WHERE id = $1', [comic_id]);
    if (comicCheck.rows.length === 0) {
      try {
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
                [ch.id, comic_id, ch.chapter_number, ch.title]
              );
            }
          }
        } else {
          await pool.query(
            `INSERT INTO comics (id, title, cover_url)
             VALUES ($1, $2, $3)
             ON CONFLICT (id) DO NOTHING`,
            [comic_id, comic_id, '']
          );
        }
      } catch (err) {
        console.warn('Could not auto-insert comic detail for history, inserting placeholder:', err.message);
        await pool.query(
          `INSERT INTO comics (id, title, cover_url)
           VALUES ($1, $2, $3)
           ON CONFLICT (id) DO NOTHING`,
          [comic_id, comic_id, '']
        );
      }
    }

    // If last_chapter_id is provided, ensure it exists in chapters table
    if (last_chapter_id) {
      const chCheck = await pool.query('SELECT id FROM chapters WHERE id = $1', [last_chapter_id]);
      if (chCheck.rows.length === 0) {
        const chNumMatch = last_chapter_id.match(/chapter-(\d+(\.\d+)?)/i) || last_chapter_id.match(/ch-(\d+(\.\d+)?)/i);
        const chNum = chNumMatch ? parseFloat(chNumMatch[1]) : 1;
        await pool.query(
          `INSERT INTO chapters (id, comic_id, chapter_number, title)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (id) DO NOTHING`,
          [last_chapter_id, comic_id, chNum, last_chapter_id]
        );
      }

      // Record in read_chapters
      await pool.query(
        `INSERT INTO read_chapters (user_id, comic_id, chapter_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, comic_id, chapter_id)
         DO UPDATE SET read_at = CURRENT_TIMESTAMP`,
        [req.user.id, comic_id, last_chapter_id]
      );
    }

    // Upsert reading history
    const result = await pool.query(
      `INSERT INTO reading_history (user_id, comic_id, last_chapter_id, last_page)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (user_id, comic_id)
       DO UPDATE SET
         last_chapter_id = COALESCE($3, reading_history.last_chapter_id),
         last_page = COALESCE($4, reading_history.last_page),
         updated_at = CURRENT_TIMESTAMP
       RETURNING *`,
      [req.user.id, comic_id, last_chapter_id || null, last_page || 1]
    );

    res.status(201).json({ data: result.rows[0] });
  } catch (err) {
    console.error('Save history error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/history/:id — remove a single history entry
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query(
      'DELETE FROM reading_history WHERE id = $1 AND user_id = $2',
      [id, req.user.id]
    );
    res.json({ message: 'History entry removed' });
  } catch (err) {
    console.error('Delete history error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// DELETE /api/history/all — clear all history
router.delete('/', async (req, res) => {
  try {
    await pool.query(
      'DELETE FROM reading_history WHERE user_id = $1',
      [req.user.id]
    );
    res.json({ message: 'All history cleared' });
  } catch (err) {
    console.error('Clear history error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
