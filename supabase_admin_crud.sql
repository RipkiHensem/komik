-- ComicStream admin CRUD access
-- Run only after reviewing the scope below. This grants write access to public.comics
-- through RLS to the allowlisted email; the Flutter app cannot modify this allowlist.

CREATE TABLE IF NOT EXISTS public.admin_users (
  email text PRIMARY KEY,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT admin_users_email_normalized CHECK (email = lower(email))
);

ALTER TABLE public.admin_users ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.admin_users FROM PUBLIC, anon, authenticated;
GRANT SELECT ON TABLE public.admin_users TO authenticated;

DROP POLICY IF EXISTS "Admins can read their own access" ON public.admin_users;
CREATE POLICY "Admins can read their own access"
  ON public.admin_users FOR SELECT
  TO authenticated
  USING (email = lower(coalesce((select auth.jwt() ->> 'email'), '')));

-- Public catalog reads remain available. Only allowlisted authenticated users can write.
REVOKE INSERT, UPDATE, DELETE ON TABLE public.comics FROM PUBLIC, anon;
GRANT SELECT ON TABLE public.comics TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.comics TO authenticated;

DROP POLICY IF EXISTS "Admins can manage comics" ON public.comics;
CREATE POLICY "Admins can manage comics"
  ON public.comics FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
    )
  );

-- API chapters use the hidden_chapters table for soft deletion.
REVOKE DELETE ON TABLE public.chapters FROM PUBLIC, anon, authenticated;
DROP POLICY IF EXISTS "Admins can delete chapters" ON public.chapters;

-- Add the requested account only if it already exists and its email is confirmed.
-- The account is currently unconfirmed, so this inserts no admin row until confirmed.
INSERT INTO public.admin_users (email)
SELECT lower(users.email)
FROM auth.users AS users
WHERE lower(users.email) = lower('syahputrarhifqi@gmail.com')
  AND users.email_confirmed_at IS NOT NULL
ON CONFLICT (email) DO NOTHING;
