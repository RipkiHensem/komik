# Yomu — laporan bug pascadeploy

Tanggal verifikasi: **9 November 2026**.

Laporan ini mencatat 11 masalah yang pernah dilaporkan pengguna setelah menjalankan APK Yomu. Issue dibuat retrospektif agar perbaikan yang terkumpul dapat diperiksa dosen; bukan 11 kegagalan baru yang diklaim ditemukan ulang pada build ini. Versi APK lama tidak tercatat. Setiap issue memuat reproduksi versi terdampak, penyebab, penanganan, tes regresi, dan batasannya.

## Daftar issue dan bukti regresi

| Issue | Masalah | Tes di `comicstream_app/` |
|---|---|---|
| [#4](https://github.com/RipkiHensem/komik/issues/4) | Bookmark tersimpan tidak dapat dihapus dengan menekan tombol lagi | [test/bookmark_delete_test.dart](comicstream_app/test/bookmark_delete_test.dart) |
| [#5](https://github.com/RipkiHensem/komik/issues/5) | Komik yang sama membuat dua riwayat setelah perpindahan sumber API | [test/history_identity_test.dart](comicstream_app/test/history_identity_test.dart)<br>[test/history_repository_test.dart](comicstream_app/test/history_repository_test.dart) |
| [#6](https://github.com/RipkiHensem/komik/issues/6) | Cover riwayat kembali loading saat digulir keluar lalu masuk layar | [test/session_thumbnail_test.dart](comicstream_app/test/session_thumbnail_test.dart) |
| [#7](https://github.com/RipkiHensem/komik/issues/7) | Editor komik crash ketika status dari sumber berisi teks genre | [test/admin_editor_test.dart](comicstream_app/test/admin_editor_test.dart) |
| [#8](https://github.com/RipkiHensem/komik/issues/8) | Genre hilang dan filter genre tidak mempertahankan tipe Manhwa | [test/genre_catalog_test.dart](comicstream_app/test/genre_catalog_test.dart)<br>[test/genre_filter_ui_test.dart](comicstream_app/test/genre_filter_ui_test.dart) |
| [#9](https://github.com/RipkiHensem/komik/issues/9) | Halaman Update Terbaru berhenti sebelum memenuhi 12 slot | [test/home_page_fill_test.dart](comicstream_app/test/home_page_fill_test.dart) |
| [#10](https://github.com/RipkiHensem/komik/issues/10) | Riwayat sempat menampilkan Baca terakhir sebelum nomor chapter | [test/history_and_cover_loading_test.dart](comicstream_app/test/history_and_cover_loading_test.dart) |
| [#11](https://github.com/RipkiHensem/komik/issues/11) | Gangguan sumber gambar ditampilkan keliru sebagai Chapter Kosong | [test/chapter_failure_test.dart](comicstream_app/test/chapter_failure_test.dart)<br>[test/comic_detail_loading_test.dart](comicstream_app/test/comic_detail_loading_test.dart) |
| [#12](https://github.com/RipkiHensem/komik/issues/12) | Mengedit metadata membuat waktu rilis komik terlihat Baru saja | [test/comic_caption_and_time_test.dart](comicstream_app/test/comic_caption_and_time_test.dart) |
| [#13](https://github.com/RipkiHensem/komik/issues/13) | Komik di tujuh slot Populer tidak tercentang pada editor admin | [test/popular_editor_test.dart](comicstream_app/test/popular_editor_test.dart)<br>[test/popular_repository_test.dart](comicstream_app/test/popular_repository_test.dart) |
| [#14](https://github.com/RipkiHensem/komik/issues/14) | Cover terpotong oleh transformasi thumbnail dan pemaksaan isi frame | [test/comic_detail_loading_test.dart](comicstream_app/test/comic_detail_loading_test.dart)<br>[test/history_and_cover_loading_test.dart](comicstream_app/test/history_and_cover_loading_test.dart) |

## Hasil verifikasi lokal

| Pemeriksaan | Hasil |
|---|---|
| `flutter test --no-pub` | 64 tes lulus, 0 gagal |
| `dart analyze lib test` | No issues found |
| `flutter build apk --debug --no-pub` | Berhasil menghasilkan `build/app/outputs/flutter-apk/app-debug.apk` |
| SQL statistik mingguan | PASS; guest yang sama tidak dihitung berulang, filter format, batas 7 hari, transisi guest ke akun, dan pembatasan akses identitas diuji dengan rollback |

Tes Dart menggunakan fixture/mock; tes widget memeriksa perilaku UI dalam test runner. Build APK membuktikan kompilasi dan packaging, **bukan** pengujian ulang pada HP. Belum dilakukan pengujian ulang APK batch ini di HP pengguna atau pengukuran FPS perangkat. Hasil GitHub Actions dan commit final dapat dilihat pada PR yang ditautkan dari setiap issue.

## Menjalankan ulang

Dari folder `comicstream_app`, gunakan Flutter 3.41.9, JDK 17 dan Android SDK sesuai README:

```sh
flutter pub get
dart analyze lib test
flutter test --no-pub
flutter build apk --debug --no-pub
```

Dari root repository:

```sh
python tools/check_public_repo.py
```

SQL `supabase_catalog_edit_setup.sql` dan `supabase_weekly_popular.sql` sudah diterapkan pada backend proyek ini. Untuk backend baru, terapkan setup dasar yang dirujuk README, lalu kedua berkas tersebut. Tes SQL ada di `comicstream_app/supabase/tests/catalog_metadata.sql` dan `weekly_popular.sql`; jalankan memakai akses administrasi pada database uji. Keduanya memakai transaksi dan rollback untuk data uji. Jangan meletakkan service-role key di aplikasi.

## Ringkasan perbaikan

### #4 — Bookmark tersimpan tidak dapat dihapus dengan menekan tombol lagi

Notifier mengikuti user ID, menunggu backend, mempertahankan item jika gagal, dan tombol detail melakukan toggle dengan status pending.

Batasan: Penghapusan tetap memerlukan koneksi backend; error ditampilkan dan dapat dicoba ulang.

### #5 — Komik yang sama membuat dua riwayat setelah perpindahan sumber API

Tambahkan pencocokan lintas sumber yang konservatif, gabungkan tampilan terbaru, dan pindahkan progress sebelum membersihkan duplikat lama.

Batasan: Judul yang benar-benar berbeda atau tidak memiliki metadata tidak digabung secara spekulatif; kegagalan tulis tidak menghapus progress lama.

### #6 — Cover riwayat kembali loading saat digulir keluar lalu masuk layar

Cache thumbnail terdekode per sesi/akun, reuse RawImage tanpa fade, dan bebaskan resource saat sesi berakhir.

Batasan: Cache hanya untuk thumbnail berukuran kecil, bukan seluruh gambar chapter; bukan jaminan FPS semua perangkat.

### #7 — Editor komik crash ketika status dari sumber berisi teks genre

Normalisasi nilai status; nilai tidak dikenal memakai Unknown sebelum membangun dropdown.

Batasan: Metadata sumber yang rusak tidak dianggap status valid.

### #8 — Genre hilang dan filter genre tidak mempertahankan tipe Manhwa

Map genre sumber, gabungkan parameter genre+format, pertahankan filter saat pagination, dan abaikan respons filter lama.

Batasan: Genre tersedia di detail/Search; sesuai revisi pengguna tidak ditampilkan di bawah chip format beranda.

### #9 — Halaman Update Terbaru berhenti sebelum memenuhi 12 slot

Isi batch hingga target 12 lintas halaman, deduplikasi ID, dan berhenti pada halaman kosong/berulang.

Batasan: Halaman terakhir boleh kurang dari 12 ketika sumber benar-benar habis.

### #10 — Riwayat sempat menampilkan Baca terakhir sebelum nomor chapter

Gunakan nomor chapter tersimpan/endpoint dan selesaikan ID opaque sebelum mempublikasikan hasil riwayat.

Batasan: Jika sumber tidak menyediakan nomor yang dapat diselesaikan, tampilkan Chapter tidak tersedia; jangan membuat nomor palsu.

### #11 — Gangguan sumber gambar ditampilkan keliru sebagai Chapter Kosong

Pertahankan error sumber jika backup tidak berhasil; bedakan empty yang sah dari error dan sediakan retry.

Batasan: Perbaikan ini tidak menjamin server pihak ketiga selalu tersedia; aplikasi tidak mengklaim chapter kosong saat koneksi gagal.

### #12 — Mengedit metadata membuat waktu rilis komik terlihat Baru saja

Pisahkan content_updated_at dari updated_at dan pertahankan tanggal sumber yang diketahui tanpa menebak tanggal yang hilang.

Batasan: Tanggal yang tidak diberikan sumber tetap tidak diketahui, bukan diganti waktu sekarang.

### #13 — Komik di tujuh slot Populer tidak tercentang pada editor admin

Editor membaca keanggotaan top tujuh global/tipe yang sama; pilihan eksplisit admin diprioritaskan, pengecualian disimpan, dan edit metadata tidak diam-diam membuat pin.

Batasan: Tambahan terkait: slot otomatis memakai pembaca unik tujuh hari; data baru mulai dicatat setelah pembaruan, guest dibedakan per instalasi.

### #14 — Cover terpotong oleh transformasi thumbnail dan pemaksaan isi frame

Gunakan cover bersama dengan BoxFit.contain, buang transformasi crop hanya pada host thumbnail yang dikenal, pilih poster detail dan fallback URL terbatas, serta pisahkan cache thumbnail lama.

Batasan: Jika file asli memang landscape atau sudah terpotong di sumber, area kosong mungkin tetap ada; solusi tidak mengarang artwork yang tidak tersedia.

## Pemeriksaan manual setelah memasang APK terbaru

1. Login, simpan komik lalu tekan Bookmark lagi; komik hilang setelah backend berhasil, dan kegagalan tidak menghapus tampilan secara palsu.
2. Buka riwayat lintas Komiku/Shinigami untuk judul sama; periksa satu kartu, nomor chapter, dan scroll keluar/masuk tanpa pemuatan ulang thumbnail sukses.
3. Buka editor admin untuk komik yang statusnya tidak valid; editor tetap terbuka. Periksa centang tujuh slot Populer serta pilihan manual/otomatis.
4. Tekan genre dari detail Manhwa; hasil tetap genre dan tipe yang dipilih. Gulir halaman Update Terbaru yang masih memiliki cukup data hingga 12 kartu.
5. Uji chapter kosong dan kegagalan jaringan secara terpisah; kegagalan harus memberi retry, bukan berpura-pura chapter kosong.
6. Edit judul tanpa mengubah tanggal rilis; waktu konten tidak berubah menjadi sekarang. Periksa cover potret dan lanskap: seluruh gambar dipertahankan, ruang kosong untuk rasio berbeda diperbolehkan.

Statistik mingguan mulai terkumpul dari versi yang merekam pembacaan setelah gambar chapter berhasil didekode. Data historis tidak direkayasa. Pilihan manual admin diprioritaskan; peringkat pembaca mengisi slot berikutnya dan saran sumber mengisi kekurangan. Guest dihitung per instalasi, bukan bukti orang unik secara mutlak.
