-- Soft-delete catalog items supplied by the external manga API.
-- Source records are preserved; these tables only hide them in ComicStream.

CREATE TABLE IF NOT EXISTS public.hidden_comics (
  comic_id text PRIMARY KEY,
  hidden_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.hidden_chapters (
  chapter_id text PRIMARY KEY,
  comic_id text NOT NULL,
  hidden_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.hidden_comics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.hidden_chapters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Hidden comics are readable by everyone" ON public.hidden_comics;
CREATE POLICY "Hidden comics are readable by everyone"
  ON public.hidden_comics FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Hidden chapters are readable by everyone" ON public.hidden_chapters;
CREATE POLICY "Hidden chapters are readable by everyone"
  ON public.hidden_chapters FOR SELECT TO anon, authenticated USING (true);

REVOKE ALL ON TABLE public.hidden_comics, public.hidden_chapters FROM PUBLIC, anon;
GRANT SELECT ON TABLE public.hidden_comics, public.hidden_chapters TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.hidden_comics, public.hidden_chapters TO authenticated;

DROP POLICY IF EXISTS "Admins can hide comics" ON public.hidden_comics;
CREATE POLICY "Admins can hide comics"
  ON public.hidden_comics FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

DROP POLICY IF EXISTS "Admins can restore comics" ON public.hidden_comics;
CREATE POLICY "Admins can restore comics"
  ON public.hidden_comics FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

DROP POLICY IF EXISTS "Admins can hide chapters" ON public.hidden_chapters;
CREATE POLICY "Admins can hide chapters"
  ON public.hidden_chapters FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));

DROP POLICY IF EXISTS "Admins can restore chapters" ON public.hidden_chapters;
CREATE POLICY "Admins can restore chapters"
  ON public.hidden_chapters FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.admin_users
    WHERE email = lower(coalesce((select auth.jwt() ->> 'email'), ''))
  ));
