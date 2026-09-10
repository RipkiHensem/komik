const express = require('express');

const router = express.Router();

/**
 * Image proxy — solves CORS issues for Flutter Web
 * GET /api/proxy/image?url=<encoded_url>
 *
 * Fetches the image server-side and serves it to the client
 * with proper CORS headers, bypassing browser restrictions.
 */
router.get('/image', async (req, res) => {
  const { url } = req.query;

  if (!url) {
    return res.status(400).json({ error: 'url parameter is required' });
  }

  try {
    let referer = 'https://komiku.org/';
    try {
      const parsed = new URL(url);
      referer = `${parsed.protocol}//${parsed.host}/`;
    } catch (_) {}

    const response = await fetch(url, {
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Referer': referer,
        'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
      },
    });

    if (!response.ok) {
      return res.status(response.status).json({
        error: `Failed to fetch image: ${response.statusText}`,
      });
    }

    const contentType = response.headers.get('content-type') || 'image/jpeg';
    const buffer = Buffer.from(await response.arrayBuffer());

    res.set({
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=86400',
      'Access-Control-Allow-Origin': '*',
    });

    res.send(buffer);
  } catch (err) {
    console.error('Proxy error:', err.message);
    res.status(500).json({ error: 'Failed to proxy image' });
  }
});

module.exports = router;
