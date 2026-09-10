const express = require('express');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../config/database');
const authMiddleware = require('../middleware/auth');
require('dotenv').config();

const router = express.Router();

// POST /api/auth/register
router.post('/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: 'Semua field wajib diisi' });
    }

    if (password.length < 6) {
      return res.status(400).json({ error: 'Password minimal 6 karakter' });
    }

    // Check existing user
    const existing = await pool.query(
      'SELECT id FROM users WHERE email = $1 OR username = $2',
      [email, username]
    );
    if (existing.rows.length > 0) {
      return res.status(409).json({ error: 'Email atau username sudah terdaftar' });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    // Insert user
    const result = await pool.query(
      `INSERT INTO users (username, email, password_hash)
       VALUES ($1, $2, $3)
       RETURNING id, username, email, avatar_url, created_at`,
      [username, email, passwordHash]
    );

    const user = result.rows[0];

    // Generate JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({ token, user });
  } catch (err) {
    console.error('Register error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email dan password wajib diisi' });
    }

    // Find user by email or username
    const result = await pool.query(
      'SELECT * FROM users WHERE email = $1 OR username = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }

    const user = result.rows[0];

    // Verify password
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Email atau password salah' });
    }

    // Generate JWT
    const token = jwt.sign(
      { id: user.id, username: user.username, email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url || null,
        created_at: user.created_at,
      },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/auth/me — get current user profile
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      'SELECT id, username, email, avatar_url, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ data: result.rows[0] });
  } catch (err) {
    console.error('Profile error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/auth/avatar — update avatar URL (preset or external link)
router.put('/avatar', authMiddleware, async (req, res) => {
  try {
    const { avatar_url } = req.body;
    await pool.query('UPDATE users SET avatar_url = $1 WHERE id = $2', [avatar_url || null, req.user.id]);
    const result = await pool.query(
      'SELECT id, username, email, avatar_url, created_at FROM users WHERE id = $1',
      [req.user.id]
    );
    res.json({ data: result.rows[0] });
  } catch (err) {
    console.error('Update avatar error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/auth/avatar/upload — upload custom avatar image (base64)
router.post('/avatar/upload', authMiddleware, async (req, res) => {
  try {
    const { image_base64 } = req.body;
    if (!image_base64) {
      return res.status(400).json({ error: 'image_base64 is required' });
    }

    const matches = image_base64.match(/^data:image\/([A-Za-z-+\/]+);base64,(.+)$/);
    const ext = matches ? matches[1].replace('jpeg', 'jpg') : 'png';
    const rawBase64 = matches ? matches[2] : image_base64;
    const buffer = Buffer.from(rawBase64, 'base64');

    const avatarsDir = path.join(__dirname, '../../public/avatars');
    if (!fs.existsSync(avatarsDir)) {
      fs.mkdirSync(avatarsDir, { recursive: true });
    }

    const filename = `avatar_${req.user.id}_${Date.now()}.${ext}`;
    fs.writeFileSync(path.join(avatarsDir, filename), buffer);

    const avatarUrl = `/avatars/${filename}`;
    await pool.query('UPDATE users SET avatar_url = $1 WHERE id = $2', [avatarUrl, req.user.id]);

    const result = await pool.query(
      'SELECT id, username, email, avatar_url, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    res.json({ data: result.rows[0] });
  } catch (err) {
    console.error('Upload avatar error:', err);
    res.status(500).json({ error: 'Gagal mengunggah foto profil' });
  }
});

module.exports = router;
