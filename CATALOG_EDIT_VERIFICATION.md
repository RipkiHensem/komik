# Admin catalog edits and public collection authors

Verified on 2026-10-30.

- Detail screen exposes the existing comic editor only to admins, including title, genres, cover URL, synopsis and content update time.
- Chapter metadata overrides preserve source IDs and reading URLs. Number, title and release time can be edited without copying or replacing chapter image data.
- `comics.content_updated_at` is nullable and separate from `updated_at` (metadata modification). Missing release dates remain unknown.
- Collection repository resolves current usernames and avatars through a narrow public-author RPC, restricted to owners of public collections; private profiles and emails are not returned.
- Applied `supabase_catalog_edit_setup.sql` to the project. Ran `comicstream_app/supabase/tests/catalog_metadata.sql`: non-admin denied, admin insert/update succeeded, all test writes rolled back. REST confirmed zero remaining probe rows.
- Public-author REST result contains a nonempty username and avatar for the existing public author.
- 22 Flutter tests passed. Dart analysis clean before final test additions.

Limitations: no physical-phone UI verification. Original landscape cover files still require replacement portrait artwork through the admin cover URL field; changing image fit cannot reconstruct missing artwork. Source release times are displayed only when available or supplied by the admin.
