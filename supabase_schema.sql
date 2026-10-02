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
-- Catalog content is loaded from the live Manga API.
-- No sample comics, chapters, or chapter pages are seeded by this schema.

-- ── SELESAI ──────────────────────────────────────────────────
-- Tabel yang dibuat & dikonfigurasi:
--   ✅ profiles      → data user (username, avatar_url)
--   ✅ bookmarks     → bookmark komik user
--   ✅ history       → riwayat baca & progress halaman
--   ✅ read_chapters → chapter yang sudah dibaca
--   ✅ comics        → katalog komik (diisi dari API, tanpa seed contoh)
--   ✅ chapters      → bab-bab komik
--   ✅ chapter_pages → halaman baca bergambar
-- ============================================================
