-- Run once in the existing Supabase project's SQL Editor.
-- App login now uses email directly. Remove the old public lookup RPC so
-- anonymous callers cannot resolve usernames into email addresses.

drop function if exists public.get_email_by_username(text);

-- Verification (run separately if needed):
-- select to_regprocedure('public.get_email_by_username(text)') is null
--   as username_lookup_removed;
