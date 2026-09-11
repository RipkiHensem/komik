-- ============================================================
-- Jalankan script ini di: Supabase Dashboard > SQL Editor
-- Script ini menyempurnakan pencarian username & sinkronisasi akun
-- ============================================================

-- 1. Fungsi get_email_by_username yang fleksibel:
-- Mendukung username persis, awalan nama email (misal 'rhifqi' dari 'rhifqi.syahputra@gmail.com'),
-- atau email langsung.
CREATE OR REPLACE FUNCTION public.get_email_by_username(p_username TEXT)
RETURNS TEXT AS $$
  SELECT au.email
  FROM auth.users au
  WHERE 
    -- 1. Cek jika input adalah email lengkap
    au.email ILIKE p_username
    -- 2. Cek username di metadata saat register
    OR au.raw_user_meta_data->>'username' ILIKE p_username
    -- 3. Cek username di tabel profiles
    OR au.id IN (
      SELECT id FROM public.profiles
      WHERE username ILIKE p_username
    )
    -- 4. Cek awalan email (misal 'rhifqi.syahputra' dari 'rhifqi.syahputra@gmail.com')
    OR split_part(au.email, '@', 1) ILIKE p_username
    -- 5. Cek kata pertama awalan email sebelum tanda titik (misal 'rhifqi' dari 'rhifqi.syahputra@gmail.com')
    OR split_part(split_part(au.email, '@', 1), '.', 1) ILIKE p_username
    -- 6. Cek kata pertama awalan email sebelum underscore (misal 'rhifqi' dari 'rhifqi_syahputra@gmail.com')
    OR split_part(split_part(au.email, '@', 1), '_', 1) ILIKE p_username
    -- 7. Cek apakah awalan email diawali dengan username yang dimasukkan
    OR split_part(au.email, '@', 1) ILIKE (p_username || '%')
  LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

-- Berikan izin eksekusi ke role anon & authenticated
GRANT EXECUTE ON FUNCTION public.get_email_by_username(TEXT) TO anon, authenticated;

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
