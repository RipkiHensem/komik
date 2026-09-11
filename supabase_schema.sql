-- ============================================================
-- COMICSTREAM — Supabase Schema & Initial Data
-- Jalankan script ini di: Supabase Dashboard > SQL Editor
-- Script ini aman dijalankan berulang kali (Idempotent)
-- ============================================================


-- ── 1. PROFILES ──────────────────────────────────────────────
-- Menyimpan data profil user (username, avatar)
-- Terhubung ke auth.users via id (UUID)

CREATE TABLE IF NOT EXISTS public.profiles (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username    TEXT,
  avatar_url  TEXT,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Trigger: otomatis buat row profiles saat user baru register
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, username)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'username'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ── 2. BOOKMARKS ─────────────────────────────────────────────
-- Menyimpan komik yang di-bookmark user

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comic_id         TEXT NOT NULL,          -- slug komik
  last_chapter_id  TEXT,                   -- slug chapter terakhir
  last_page        INTEGER NOT NULL DEFAULT 1,
  comic_title      TEXT,                   -- judul komik (cache lokal)
  comic_cover_url  TEXT,                   -- URL cover komik (cache lokal)
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, comic_id)
);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own bookmarks" ON public.bookmarks;
CREATE POLICY "Users can manage own bookmarks"
  ON public.bookmarks FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_bookmarks_user_id ON public.bookmarks(user_id);
CREATE INDEX IF NOT EXISTS idx_bookmarks_comic_id ON public.bookmarks(comic_id);


-- ── 3. HISTORY ───────────────────────────────────────────────
-- Menyimpan riwayat baca (progress) per komik per user

CREATE TABLE IF NOT EXISTS public.history (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comic_id         TEXT NOT NULL,          -- slug komik
  last_chapter_id  TEXT,                   -- slug chapter terakhir dibaca
  last_page        INTEGER NOT NULL DEFAULT 1,
  comic_title      TEXT,
  comic_cover_url  TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, comic_id)
);

ALTER TABLE public.history ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own history" ON public.history;
CREATE POLICY "Users can manage own history"
  ON public.history FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_history_user_id ON public.history(user_id);
CREATE INDEX IF NOT EXISTS idx_history_updated_at ON public.history(updated_at DESC);


-- ── 4. READ_CHAPTERS ─────────────────────────────────────────
-- Mencatat chapter mana saja yang sudah dibaca user

CREATE TABLE IF NOT EXISTS public.read_chapters (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  comic_id    TEXT NOT NULL,    -- slug komik
  chapter_id  TEXT NOT NULL,   -- slug chapter yang sudah dibaca
  read_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (user_id, comic_id, chapter_id)
);

ALTER TABLE public.read_chapters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own read chapters" ON public.read_chapters;
CREATE POLICY "Users can manage own read chapters"
  ON public.read_chapters FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE INDEX IF NOT EXISTS idx_read_chapters_user_comic
  ON public.read_chapters(user_id, comic_id);


-- ── 5. COMICS ────────────────────────────────────────────────
-- Menyimpan katalog komik (Manga, Manhwa, Manhua)

CREATE TABLE IF NOT EXISTS public.comics (
  id                TEXT PRIMARY KEY,              -- slug / endpoint komik (mis: 'solo-leveling')
  title             TEXT NOT NULL,
  alternative_title TEXT,
  synopsis          TEXT DEFAULT '',
  cover_url         TEXT DEFAULT '',
  genres            TEXT[] DEFAULT '{}',
  status            TEXT DEFAULT 'Ongoing',        -- 'Ongoing' / 'Completed'
  author            TEXT DEFAULT 'Unknown',
  artist            TEXT,
  format            TEXT DEFAULT 'Manhwa',         -- 'Manhwa' / 'Manga' / 'Manhua'
  rating            NUMERIC(3, 1) DEFAULT 0.0,
  view_count        INTEGER DEFAULT 0,
  is_popular        BOOLEAN DEFAULT false,
  is_recommended    BOOLEAN DEFAULT false,
  chapter_count     INTEGER DEFAULT 0,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.comics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public comics are viewable by everyone" ON public.comics;
CREATE POLICY "Public comics are viewable by everyone"
  ON public.comics FOR SELECT
  USING (true);

CREATE INDEX IF NOT EXISTS idx_comics_format ON public.comics(format);
CREATE INDEX IF NOT EXISTS idx_comics_is_popular ON public.comics(is_popular);
CREATE INDEX IF NOT EXISTS idx_comics_is_recommended ON public.comics(is_recommended);
CREATE INDEX IF NOT EXISTS idx_comics_updated_at ON public.comics(updated_at DESC);


-- ── 6. CHAPTERS ──────────────────────────────────────────────
-- Menyimpan daftar chapter dari komik

CREATE TABLE IF NOT EXISTS public.chapters (
  id              TEXT PRIMARY KEY,                -- slug chapter (mis: 'solo-leveling-chapter-1')
  comic_id        TEXT NOT NULL REFERENCES public.comics(id) ON DELETE CASCADE,
  chapter_number  INTEGER NOT NULL,
  title           TEXT,
  released_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.chapters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public chapters are viewable by everyone" ON public.chapters;
CREATE POLICY "Public chapters are viewable by everyone"
  ON public.chapters FOR SELECT
  USING (true);

CREATE INDEX IF NOT EXISTS idx_chapters_comic_id ON public.chapters(comic_id);
CREATE INDEX IF NOT EXISTS idx_chapters_number ON public.chapters(comic_id, chapter_number DESC);


-- ── 7. CHAPTER_PAGES ─────────────────────────────────────────
-- Menyimpan daftar URL halaman/gambar dari setiap chapter

CREATE TABLE IF NOT EXISTS public.chapter_pages (
  id            TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  chapter_id    TEXT NOT NULL REFERENCES public.chapters(id) ON DELETE CASCADE,
  page_number   INTEGER NOT NULL,
  image_url     TEXT NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.chapter_pages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public chapter pages are viewable by everyone" ON public.chapter_pages;
CREATE POLICY "Public chapter pages are viewable by everyone"
  ON public.chapter_pages FOR SELECT
  USING (true);

CREATE INDEX IF NOT EXISTS idx_chapter_pages_chapter_id ON public.chapter_pages(chapter_id, page_number ASC);


-- ============================================================
-- ── 8. SEED DATA (DATA DUMMY KOMIK, CHAPTER & GAMBAR) ───────
-- Data komik berkualitas tinggi dengan gambar stabil (CORS OK)
-- ============================================================

INSERT INTO public.comics (id, title, alternative_title, synopsis, cover_url, genres, status, author, artist, format, rating, view_count, is_popular, is_recommended, chapter_count, updated_at)
VALUES
  (
    'solo-leveling',
    'Solo Leveling',
    'Na Honjaman Level Up',
    'Sepuluh tahun yang lalu, sebuah portal aneh bernama "Gate" menghubungkan dunia nyata dengan dunia monster. Sung Jin-Woo, seorang Hunter peringkat E yang paling lemah, terjebak dalam Double Dungeon maut dan mendapatkan quest rahasia untuk "Level Up" tanpa batas.',
    'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop&q=80',
    ARRAY['Action', 'Adventure', 'Fantasy'],
    'Completed',
    'Chugong',
    'DUBU (REDICE STUDIO)',
    'Manhwa',
    4.9,
    1580000,
    true,
    true,
    3,
    NOW()
  ),
  (
    'omniscient-readers-viewpoint',
    'Omniscient Reader''s Viewpoint',
    'Jeonjijeog Dogja Sijeom',
    'Kim Dokja adalah pekerja kantoran biasa yang satu-satunya hobinya adalah membaca web novel "Tiga Cara Bertahan Hidup di Dunia yang Hancur". Tepat setelah ia selesai membaca bab terakhir, dunia nyata tiba-tiba hancur dan berubah persis sesuai alur novel tersebut!',
    'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=600&auto=format&fit=crop&q=80',
    ARRAY['Action', 'Fantasy', 'Adventure'],
    'Ongoing',
    'sing N song',
    'Sleepy-C',
    'Manhwa',
    4.8,
    980000,
    true,
    true,
    2,
    NOW() - INTERVAL '2 hours'
  ),
  (
    'one-piece',
    'One Piece',
    'Wan Pīsu',
    'Raja Bajak Laut legendaris Gol D. Roger mengumumkan keberadaan harta karun terbesar di dunia "One Piece" tepat sebelum dieksekusi. Monkey D. Luffy yang memakan buah iblis Gomu Gomu no Mi memulai perjalanannya mengarungi Grand Line.',
    'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=600&auto=format&fit=crop&q=80',
    ARRAY['Action', 'Adventure', 'Comedy'],
    'Ongoing',
    'Eiichiro Oda',
    'Eiichiro Oda',
    'Manga',
    4.9,
    2750000,
    true,
    false,
    2,
    NOW() - INTERVAL '5 hours'
  ),
  (
    'tower-of-god',
    'Tower of God',
    'Sin-ui Tap',
    'Apa pun yang kamu inginkan di dunia ini: kekayaan, kejayaan, kekuasaan, atau rahasia alam semesta—semuanya ada di puncak Menara. Ikuti perjuangan Twenty-Fifth Bam mendaki menara misterius untuk menemukan temannya, Rachel.',
    'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop&q=80',
    ARRAY['Fantasy', 'Action', 'Mystery'],
    'Ongoing',
    'SIU',
    'SIU',
    'Manhwa',
    4.7,
    850000,
    false,
    true,
    2,
    NOW() - INTERVAL '1 day'
  ),
  (
    'magic-emperor',
    'Magic Emperor',
    'Demonic Emperor / Zhuo Yifan',
    'Zhuo Yifan adalah Kaisar Iblis perkasa yang dikhianati murid kepercayaannya saat mempelajari Kitab Sembilan Rahasia. Jiwanya bereinkarnasi ke dalam tubuh pelayan lemah bernama Zhuo Fan di klan bangsawan yang sedang di ambang kehancuran.',
    'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop&q=80',
    ARRAY['Martial Arts', 'Action', 'Fantasy'],
    'Ongoing',
    'Ye Xiao',
    'Wuer Manhua',
    'Manhua',
    4.6,
    720000,
    true,
    false,
    2,
    NOW() - INTERVAL '1 day 4 hours'
  ),
  (
    'jujutsu-kaisen',
    'Jujutsu Kaisen',
    'Sorcery Fight',
    'Yuji Itadori adalah siswa SMA berbakat atletik luar biasa yang bergabung dengan Klub Penelitian Ilmu Gaib. Saat kutukan menyerang sekolahnya, demi menyelamatkan teman-temannya ia menelan jari Ryomen Sukuna, Raja Kutukan paling mematikan.',
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop&q=80',
    ARRAY['Action', 'Supernatural', 'Fantasy'],
    'Completed',
    'Gege Akutami',
    'Gege Akutami',
    'Manga',
    4.8,
    1920000,
    true,
    true,
    2,
    NOW() - INTERVAL '2 days'
  )
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  alternative_title = EXCLUDED.alternative_title,
  synopsis = EXCLUDED.synopsis,
  cover_url = EXCLUDED.cover_url,
  genres = EXCLUDED.genres,
  status = EXCLUDED.status,
  author = EXCLUDED.author,
  artist = EXCLUDED.artist,
  format = EXCLUDED.format,
  rating = EXCLUDED.rating,
  view_count = EXCLUDED.view_count,
  is_popular = EXCLUDED.is_popular,
  is_recommended = EXCLUDED.is_recommended,
  chapter_count = EXCLUDED.chapter_count,
  updated_at = EXCLUDED.updated_at;


-- ── 9. SEED DATA CHAPTERS ────────────────────────────────────

INSERT INTO public.chapters (id, comic_id, chapter_number, title, released_at)
VALUES
  -- Solo Leveling
  ('solo-leveling-chapter-1', 'solo-leveling', 1, 'Chapter 1: The E-Rank Hunter', NOW() - INTERVAL '30 days'),
  ('solo-leveling-chapter-2', 'solo-leveling', 2, 'Chapter 2: The Double Dungeon', NOW() - INTERVAL '23 days'),
  ('solo-leveling-chapter-3', 'solo-leveling', 3, 'Chapter 3: The Courage of the Weak', NOW() - INTERVAL '16 days'),
  -- Omniscient Reader's Viewpoint
  ('orv-chapter-1', 'omniscient-readers-viewpoint', 1, 'Chapter 1: Skenario Dimulai', NOW() - INTERVAL '14 days'),
  ('orv-chapter-2', 'omniscient-readers-viewpoint', 2, 'Chapter 2: Jembatan Runtuh', NOW() - INTERVAL '7 days'),
  -- One Piece
  ('one-piece-chapter-1', 'one-piece', 1, 'Chapter 1: Romance Dawn - Fajar Petualangan', NOW() - INTERVAL '50 days'),
  ('one-piece-chapter-2', 'one-piece', 2, 'Chapter 2: Sang Manusia Topi Jerami', NOW() - INTERVAL '43 days'),
  -- Tower of God
  ('tower-of-god-chapter-1', 'tower-of-god', 1, 'Chapter 1: Lantai 1F - Lantai Headon', NOW() - INTERVAL '20 days'),
  ('tower-of-god-chapter-2', 'tower-of-god', 2, 'Chapter 2: Ujian Bola Hitam', NOW() - INTERVAL '13 days'),
  -- Magic Emperor
  ('magic-emperor-chapter-1', 'magic-emperor', 1, 'Chapter 1: Kembalinya Kaisar Iblis', NOW() - INTERVAL '18 days'),
  ('magic-emperor-chapter-2', 'magic-emperor', 2, 'Chapter 2: Pengawal Klan Luo', NOW() - INTERVAL '10 days'),
  -- Jujutsu Kaisen
  ('jujutsu-kaisen-chapter-1', 'jujutsu-kaisen', 1, 'Chapter 1: Ryomen Sukuna', NOW() - INTERVAL '25 days'),
  ('jujutsu-kaisen-chapter-2', 'jujutsu-kaisen', 2, 'Chapter 2: Eksekusi Rahasia', NOW() - INTERVAL '18 days')
ON CONFLICT (id) DO UPDATE SET
  comic_id = EXCLUDED.comic_id,
  chapter_number = EXCLUDED.chapter_number,
  title = EXCLUDED.title,
  released_at = EXCLUDED.released_at;


-- ── 10. SEED DATA CHAPTER_PAGES (GAMBAR HALAMAN KOMIK) ───────

INSERT INTO public.chapter_pages (id, chapter_id, page_number, image_url)
VALUES
  -- Solo Leveling - Chapter 1
  ('sl-1-1', 'solo-leveling-chapter-1', 1, 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=900&auto=format&fit=crop&q=80'),
  ('sl-1-2', 'solo-leveling-chapter-1', 2, 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=900&auto=format&fit=crop&q=80'),
  ('sl-1-3', 'solo-leveling-chapter-1', 3, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=900&auto=format&fit=crop&q=80'),
  ('sl-1-4', 'solo-leveling-chapter-1', 4, 'https://images.unsplash.com/photo-1563089145-599997674d42?w=900&auto=format&fit=crop&q=80'),

  -- Solo Leveling - Chapter 2
  ('sl-2-1', 'solo-leveling-chapter-2', 1, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=900&auto=format&fit=crop&q=80'),
  ('sl-2-2', 'solo-leveling-chapter-2', 2, 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=900&auto=format&fit=crop&q=80'),
  ('sl-2-3', 'solo-leveling-chapter-2', 3, 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=900&auto=format&fit=crop&q=80'),

  -- Solo Leveling - Chapter 3
  ('sl-3-1', 'solo-leveling-chapter-3', 1, 'https://images.unsplash.com/photo-1563089145-599997674d42?w=900&auto=format&fit=crop&q=80'),
  ('sl-3-2', 'solo-leveling-chapter-3', 2, 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=900&auto=format&fit=crop&q=80'),

  -- ORV - Chapter 1
  ('orv-1-1', 'orv-chapter-1', 1, 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=900&auto=format&fit=crop&q=80'),
  ('orv-1-2', 'orv-chapter-1', 2, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=900&auto=format&fit=crop&q=80'),
  ('orv-1-3', 'orv-chapter-1', 3, 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=900&auto=format&fit=crop&q=80'),

  -- One Piece - Chapter 1
  ('op-1-1', 'one-piece-chapter-1', 1, 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=900&auto=format&fit=crop&q=80'),
  ('op-1-2', 'one-piece-chapter-1', 2, 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=900&auto=format&fit=crop&q=80'),

  -- Tower of God - Chapter 1
  ('tog-1-1', 'tower-of-god-chapter-1', 1, 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=900&auto=format&fit=crop&q=80'),
  ('tog-1-2', 'tower-of-god-chapter-1', 2, 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=900&auto=format&fit=crop&q=80'),

  -- Magic Emperor - Chapter 1
  ('me-1-1', 'magic-emperor-chapter-1', 1, 'https://images.unsplash.com/photo-1563089145-599997674d42?w=900&auto=format&fit=crop&q=80'),
  ('me-1-2', 'magic-emperor-chapter-1', 2, 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=900&auto=format&fit=crop&q=80'),

  -- Jujutsu Kaisen - Chapter 1
  ('jjk-1-1', 'jujutsu-kaisen-chapter-1', 1, 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=900&auto=format&fit=crop&q=80'),
  ('jjk-1-2', 'jujutsu-kaisen-chapter-1', 2, 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=900&auto=format&fit=crop&q=80')
ON CONFLICT (id) DO UPDATE SET
  chapter_id = EXCLUDED.chapter_id,
  page_number = EXCLUDED.page_number,
  image_url = EXCLUDED.image_url;


-- ── SELESAI ──────────────────────────────────────────────────
-- Tabel yang dibuat & dikonfigurasi:
--   ✅ profiles      → data user (username, avatar_url)
--   ✅ bookmarks     → bookmark komik user
--   ✅ history       → riwayat baca & progress halaman
--   ✅ read_chapters → chapter yang sudah dibaca
--   ✅ comics        → data katalog komik (Solo Leveling, One Piece, dll)
--   ✅ chapters      → bab-bab komik
--   ✅ chapter_pages → halaman baca bergambar
-- ============================================================
