const express = require('express');
const { pool } = require('../config/database');
const mangaApiService = require('../services/mangaApiService');

const router = express.Router();

// GET /api/chapters/:id/pages — get pages for a chapter
router.get('/:id/pages', async (req, res) => {
  try {
    const { id } = req.params;

    // 1. Check local DB first
    const result = await pool.query(
      `SELECT * FROM pages
       WHERE chapter_id = $1
       ORDER BY page_number ASC`,
      [id]
    );

    if (result.rows.length > 0) {
      return res.json({ data: result.rows });
    }

    // 2. If not found in DB, fetch from Manga API (Komiku chapter slug)
    const rawPages = await mangaApiService.getChapterPages(id);

    if (rawPages.length > 0) {
      // Map all images through backend proxy to bypass hotlink & CORS restrictions
      const proxiedPages = rawPages.map((p) => ({
        id: p.id,
        chapter_id: p.chapter_id,
        page_number: p.page_number,
        image_url: `/api/proxy/image?url=${encodeURIComponent(p.image_url)}`,
      }));

      return res.json({ data: proxiedPages });
    }

    res.json({ data: [] });
  } catch (err) {
    console.error('Get pages error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

module.exports = router;
