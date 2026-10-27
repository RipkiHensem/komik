-- ============================================================
-- Jalankan script ini di: Supabase Dashboard > SQL Editor
-- Script ini menyempurnakan pencarian username & sinkronisasi akun
-- ============================================================

-- 1. P8: pencarian email dari username tidak dipakai lagi pada login.
-- Fungsi lama berpotensi mengungkap email melalui pemanggilan anonim.
DROP FUNCTION IF EXISTS public.get_email_by_username(TEXT);

-- 2. Sinkronisasi username di tabel profiles untuk akun yang username-nya masih kosong
UPDATE public.profiles p
SET username = COALESCE(
  NULLIF(p.username, ''),
  NULLIF(u.raw_user_meta_data->>'username', ''),
  split_part(split_part(u.email, '@', 1), '.', 1)
)
FROM auth.users u
WHERE p.id = u.id AND (p.username IS NULL OR p.username = '');

-- 3. Sinkronisasi metadata auth.users agar username otomatis terisi
UPDATE auth.users
SET raw_user_meta_data = jsonb_set(
  COALESCE(raw_user_meta_data, '{}'::jsonb),
  '{username}',
  to_jsonb(split_part(split_part(email, '@', 1), '.', 1))
)
WHERE raw_user_meta_data->>'username' IS NULL;
