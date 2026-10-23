# Yomu — Pertemuan 6 dan 7

## P6: Integrasi API dan vertical slice

Fitur inti yang dipilih: koleksi komik pribadi/publik.

Alur: layar koleksi → provider Riverpod → `CollectionRepository` →
`SupabaseCollectionRepository` → Supabase Data API → model `Collection` / `CollectionItem`.
Form membuat dan mengedit koleksi menggunakan repository yang sama melalui dependency injection.

| Kriteria | Implementasi |
| --- | --- |
| Model | `comicstream_app/lib/data/models/collection.dart`; identitas dan nama wajib valid |
| Repository | `comicstream_app/lib/data/repositories/collection_repository.dart` |
| Backend read | Daftar koleksi pribadi, publik, dan detail beserta isi |
| Backend write | Buat/edit/hapus koleksi, tambah/keluarkan komik, like/unlike |
| Loading | Spinner daftar dan form; tombol simpan dinonaktifkan saat request |
| Empty | Pesan belum ada koleksi/komik dan tombol tindakan |
| Error dan retry | Daftar memiliki tombol Coba lagi; form tetap terbuka saat gagal dan dapat disimpan ulang |
| Success | Data ditampilkan, daftar diperbarui, pesan sukses membuat/mengedit/menghapus |
| Validasi | Nama wajib diisi; form membatasi nama 80 karakter dan deskripsi 500 karakter |
| Akses | Edit/hapus hanya pemilik; publik dapat dibaca; satu like per akun per koleksi |

### Unit test

`comicstream_app/test/collection_repository_test.dart` berisi 8 pengujian:

1. Model valid.
2. Model invalid: identitas hilang atau nama kosong.
3. API berhasil: HTTP GET, filter publik, dan konversi ke model.
4. Data kosong menghasilkan daftar kosong.
5. HTTP 403 diteruskan sebagai error, bukan daftar kosong.
6. JSON rusak pada respons HTTP 200 diteruskan sebagai error parsing SDK.
7. Penyimpanan: POST mengirim nilai yang dibersihkan dan membaca model hasil simpan.
8. Retry: permintaan berikutnya berhasil setelah kegagalan pertama.

Tes memakai HTTP mock pada SupabaseClient asli: tidak memanggil backend produksi,
tidak membutuhkan akun, dan tidak mengganti repository dengan hasil tetap.

```powershell
cd comicstream_app
flutter pub get
flutter test
flutter analyze
flutter build apk --debug
```

## P7: MVP dan tiga advanced feature

| Fitur | Implementasi dan manfaat | Penanganan kondisi khusus |
| --- | --- | --- |
| Autentikasi | Supabase Auth: daftar, masuk, keluar, pemulihan password; akun menyimpan koleksi dan profil pengguna | Validasi form, loading, pesan gagal, alur konfirmasi email sesuai pengaturan backend |
| Kamera | Profil → ubah avatar → kamera/galeri; foto pribadi memudahkan mengenali akun | Izin ditolak, pembatalan, batas ukuran, upload gagal, pemulihan hasil picker Android |
| Notifikasi | Profil → Tes Notifikasi; pengingat lokal untuk melanjutkan membaca | Permintaan izin Android, izin ditolak, kegagalan, platform tidak didukung |

Notifikasi saat ini dikirim langsung dari menu demo pada Android. Belum berupa
push otomatis saat chapter terbit atau pengingat terjadwal. Foto profil disimpan
di bucket `avatars` dengan URL publik dan izin tulis milik pemilik akun.

Alur MVP: jelajahi/cari komik → detail → baca chapter → bookmark/riwayat;
masuk → kelola profil → koleksi → buat/edit/isi/hapus → jelajahi koleksi publik → suka.

## Langkah demonstrasi

1. Daftar atau masuk dengan akun demo; tunjukkan pesan validasi saat input kosong.
2. Cari komik, buka detail dan reader; lanjutkan bacaan melalui riwayat.
3. Buka Koleksi, buat koleksi baru, dan tambahkan komik.
4. Tekan pensil pada detail, ubah nama/deskripsi atau publik/privat, lalu simpan.
5. Buka Jelajahi Publik, beri suka lalu batalkan suka.
6. Keluar lalu masuk kembali untuk menunjukkan data dibaca dari backend.
7. Putuskan jaringan sebelum memuat ulang koleksi; tunjukkan error. Sambungkan
   kembali lalu tekan Coba lagi. Koleksi tanpa isi menunjukkan empty state.
8. Profil → ubah avatar → kamera. Coba pembatalan dan penolakan izin, kemudian
   ambil foto dan simpan. Profil → Tes Notifikasi untuk menunjukkan notifikasi Android.
9. Keluarkan komik dan hapus koleksi demo melalui konfirmasi.

## Backend dan batas verifikasi

Verifikasi checkpoint pada 23 Oktober 2026: `flutter test` lulus 8/8,
`dart analyze lib test` menghasilkan `No issues found`, dan
`flutter build apk --debug --no-pub` berhasil menghasilkan APK.

Proyek menggunakan backend Supabase yang sudah ada. SQL pada
`comicstream_app/supabase/migrations/` adalah perubahan terhadap skema sebelumnya,
bukan bootstrap lengkap database kosong. Tidak perlu menjalankan ulang migration
pada proyek yang sudah menerima perubahan.

`comicstream_app/supabase/tests/collection_edit_likes.sql` menguji izin pemilik,
larangan edit akun lain, duplikasi like, unlike, dan akses privat dalam transaksi
yang di-rollback. Pengujian ini telah lolos pada backend saat fitur ditambahkan.

Unit test otomatis memverifikasi model dan repository. Perilaku kamera, izin,
notifikasi OS, dan seluruh alur UI tetap perlu demonstrasi pada HP Android;
kelulusan unit test tidak membuktikan pengujian perangkat fisik tersebut.
