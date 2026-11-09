# Riwayat lintas sumber dan cache cover

**Goal:** Satukan riwayat komik yang sama setelah pergantian sumber dan pertahankan thumbnail selama sesi aplikasi.
**Architecture:** Identitas judul konservatif, repository history yang membatasi akses per pengguna dan menyimpan progres sebelum membersihkan duplikat. Cache thumbnail terpisah dari gambar reader; tidak mengubah ukuran cache global.
**Tech stack:** Flutter, Riverpod, Supabase Dart, CachedNetworkImage.

- [x] Tes reproduksi duplikasi Komiku/Shinigami, progres terbaru, judul berbeda, kegagalan simpan.
- [x] Tambah helper identitas dan repository; integrasikan service/provider serta pencocokan lanjut baca.
- [x] Cache thumbnail kecil selama sesi; hindari fetch detail jika metadata tersimpan lengkap.
- [x] Tes scroll/remount tidak mendekode ulang, kegagalan dapat dicoba ulang, pelepasan cache.
- [x] Jalankan semua tes, analyzer dan review diff. Jangan stage perubahan lama atau push tanpa permintaan baru.

Validation: flutter test --no-pub: 50 passed. dart analyze lib test: no issues. API persistence tested through mocked HTTP; no live account data was edited during verification. Existing duplicates merge on read; persisted duplicates are consolidated after the next successful progress save. Title translations/aliases without an exact normalized match remain separate.
