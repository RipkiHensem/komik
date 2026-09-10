const express = require('express');
const { pool } = require('../config/database');

const router = express.Router();

/**
 * Admin routes for managing comics.
 * In production, you'd add admin-only auth middleware here.
 *
 * POST /api/admin/comics — Add a new comic
 * Body: { title, alternative_title, synopsis, cover_url, genre[], status, author, artist, format, rating }
 *
 * POST /api/admin/comics/:comicId/chapters — Add chapters to a comic
 * Body: { chapter_number, title, pages: [{ page_number, image_url }] }
 */

// POST /api/admin/comics — add a new comic
router.post('/comics', async (req, res) => {
  try {
    const {
      title,
      alternative_title,
      synopsis,
      cover_url,
      genre = [],
      status = 'Ongoing',
      author,
      artist,
      format = 'Manhwa',
      rating = 0.0,
    } = req.body;

    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const genreJson = JSON.stringify(genre);

    const result = await pool.query(
      `INSERT INTO comics (title, alternative_title, synopsis, cover_url, genre, status, author, artist, format, rating)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
       RETURNING *`,
      [title, alternative_title || null, synopsis || '', cover_url || '', genreJson, status, author || '', artist || '', format, rating]
    );

    res.status(201).json({ data: result.rows[0] });
  } catch (err) {
    console.error('Add comic error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/admin/comics/:comicId/chapters — add a chapter with pages
router.post('/comics/:comicId/chapters', async (req, res) => {
  try {
    const { comicId } = req.params;
    const { chapter_number, title, pages = [] } = req.body;

    if (!chapter_number) {
      return res.status(400).json({ error: 'chapter_number is required' });
    }

    // Insert chapter
    const chapterResult = await pool.query(
      `INSERT INTO chapters (comic_id, chapter_number, title)
       VALUES (?, ?, ?)
       RETURNING *`,
      [comicId, chapter_number, title || `Chapter ${chapter_number}`]
    );

    const chapterId = chapterResult.rows[0].id;

    // Insert pages
    for (const page of pages) {
      await pool.query(
        `INSERT INTO pages (chapter_id, page_number, image_url)
         VALUES (?, ?, ?)`,
        [chapterId, page.page_number, page.image_url]
      );
    }

    // Update comic's updated_at with ISO string
    await pool.query(
      `UPDATE comics SET updated_at = ? WHERE id = ?`,
      [new Date().toISOString(), comicId]
    );

    res.status(201).json({
      data: {
        chapter: chapterResult.rows[0],
        pages_count: pages.length,
      },
    });
  } catch (err) {
    console.error('Add chapter error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/admin/sync — trigger background auto-update or sync specific comic
router.post('/sync', async (req, res) => {
  try {
    const { syncComicChapters, runBackgroundAutoUpdate } = require('../services/autoUpdateService');
    const { comicId } = req.body || {};
    if (comicId) {
      const result = await syncComicChapters(comicId, true);
      return res.json({ success: true, result });
    }
    // Run global background sync asynchronously
    runBackgroundAutoUpdate().catch((err) => console.error('[Admin Sync Error]', err.message));
    res.json({ success: true, message: 'Background sync started' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE /api/admin/comics/:id — delete a comic and all its data
router.delete('/comics/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await pool.query('DELETE FROM comics WHERE id = ?', [id]);
    res.json({ message: 'Comic deleted' });
  } catch (err) {
    console.error('Delete comic error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
