const express = require('express');
const cors = require('cors');
const { initDB } = require('./config/database');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// ── Middleware ──────────────────────────────────────────────
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Request logging
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} │ ${req.method} ${req.path}`);
  next();
});

const path = require('path');
const fs = require('fs');

// ── Static Files (Covers, Pages, Avatars) ─────────────────────
const publicDir = path.join(__dirname, '../public');
const avatarsDir = path.join(publicDir, 'avatars');
if (!fs.existsSync(avatarsDir)) {
  fs.mkdirSync(avatarsDir, { recursive: true });
}

const staticOptions = {
  setHeaders: (res) => {
    res.set('Cache-Control', 'no-cache, must-revalidate');
  },
};
app.use('/covers', express.static(path.join(publicDir, 'covers'), staticOptions));
app.use('/pages', express.static(path.join(publicDir, 'pages'), staticOptions));
app.use('/avatars', express.static(avatarsDir, staticOptions));
app.use('/public', express.static(publicDir, staticOptions));

// ── Routes ─────────────────────────────────────────────────
app.use('/api/auth', require('./routes/auth'));
app.use('/api/comics', require('./routes/comics'));
app.use('/api/chapters', require('./routes/chapters'));
app.use('/api/bookmarks', require('./routes/bookmarks'));
app.use('/api/history', require('./routes/history'));
app.use('/api/admin', require('./routes/admin'));
app.use('/api/proxy', require('./routes/proxy'));

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    name: 'ComicStream API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ── Start Server ───────────────────────────────────────────
const { startAutoUpdateScheduler } = require('./services/autoUpdateService');

const start = async () => {
  // Initialize database tables
  await initDB();

  app.listen(PORT, () => {
    console.log(`
╔══════════════════════════════════════════╗
║   🚀 ComicStream API Server             ║
║   Running on http://localhost:${PORT}       ║
║   Health: http://localhost:${PORT}/api/health║
╚══════════════════════════════════════════╝
    `);

    // Start background auto-update scheduler (checks every 30 minutes)
    startAutoUpdateScheduler(30);
  });
};

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
