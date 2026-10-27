# P8 — verifikasi, keamanan, dan paket demo Yomu

Dokumen ini mencatat pemeriksaan pada kode dan APK demo. Backend Supabase
adalah layanan yang sudah ada; pengujian unit menggunakan HTTP mock dan tidak
menulis data produksi.

## 01. Hasil uji keamanan dan perubahan

| Pemeriksaan | Hasil | Batas bukti / tindak lanjut |
| --- | --- | --- |
| Kunci privat di file Git | `python tools/check_public_repo.py` lulus pada 161 file yang dilacak: tidak ada keystore/`.env`/blok private key, dan JWT kunci aplikasi berperan `anon`. | Pemeriksaan statis file saat ini; tidak memeriksa riwayat commit lama atau secret di luar repo. |
| Izin koleksi | SQL mengaktifkan RLS; pemilik saja yang dapat mengubah koleksi, item, dan like miliknya. | Sudah diuji pada SQL test P6/P7 sebelumnya; tidak diuji ulang terhadap backend live pada P8. |
| Izin admin untuk caption | UI membatasi tombol edit ke admin; SQL `comic_synopsis_overrides` membatasi INSERT/UPDATE dengan allowlist `admin_users`. | Perlu menjalankan `supabase_comic_caption_setup.sql` pada proyek Supabase aktif dan menguji admin serta akun biasa. |
| Distribusi Android | Build release tidak lagi memakai debug signing. | Demo memakai APK debug. Rilis produksi membutuhkan keystore pribadi dan pengujian terpisah. |
| Login username lama | Review SQL menemukan RPC `SECURITY DEFINER` yang dapat mengembalikan email dari username kepada `anon`. | Login aplikasi sekarang email saja. Jalankan `supabase_security_p8.sql` pada backend agar RPC lama dihapus; temuan ini belum diuji terhadap backend live. |
| Proxy gambar | Klien dapat mengirim URL ke Edge Function `img-proxy`. | Kode Edge Function tidak ada di repo ini; pembatasan host/SSRF di server belum dapat diverifikasi. |
| Log kesalahan | Contoh log aman ada di bagian 03. | Sebagian kode debug lama masih mencetak exception mentah; jangan lampirkan log tersebut tanpa redaksi. |

Review ini adalah **audit statis terbatas**, bukan pentest yang membuktikan
eksploitasi. Strix tidak tersedia di lingkungan kerja ini dan tidak ada
staging atau akun pengujian terpisah untuk uji serangan aktif. Karena itu,
temuan RPC username dan proxy gambar adalah risiko yang perlu diverifikasi,
bukan klaim eksploit berhasil terhadap layanan produksi.

**Tindakan backend yang masih diperlukan:** jalankan
[`supabase_security_p8.sql`](supabase_security_p8.sql) untuk menghapus RPC lama,
dan [`supabase_comic_caption_setup.sql`](supabase_comic_caption_setup.sql)
untuk membuat tabel caption dengan RLS. Kode aplikasi tetap aman dari pemanggilan
RPC lama meski SQL belum dijalankan, tetapi endpoint lama masih dapat diakses
oleh klien lain sampai fungsi benar-benar dihapus di backend. Fitur simpan
caption belum dapat bekerja sebelum tabelnya dibuat.

Perubahan relevan di branch P8: pengaman username kosong di Koleksi Publik,
caption admin dengan validasi dan RLS terpisah, parsing tanggal update tanpa
mengarang timestamp, workflow verifikasi PR, dan penghapusan debug signing
dari build release. Login username dinonaktifkan atas persetujuan pemilik;
username tetap digunakan sebagai nama tampilan. Login email tetap berjalan.

## 02. Fresh clone, akses, build, dan deploy demo

Ikuti [README.md](README.md) mulai dari `git clone`, `flutter pub get`,
`flutter doctor`, `flutter analyze`, `flutter test`, dan `flutter build apk
--debug`. Backend yang aktif diperlukan untuk data komik, autentikasi, dan
penyimpanan caption. File SQL di repo adalah perubahan skema, bukan backup
data atau setup penuh Edge Function untuk proyek Supabase baru.

APK debug yang berhasil dibangun dapat dipasang melalui `adb install -r` atau
disalin ke HP. Workflow pull request juga mengunggah `yomu-debug-apk` sebagai
paket demo. Keduanya hanya untuk demonstrasi; belum ada deploy Play Store.

## 03. Contoh log aman, penyebab, dan perbaikan

Contoh yang aman untuk dibagikan ke dosen atau issue GitHub:

```text
2026-10-27T09:42:00+07:00 level=ERROR area=collection action=load
code=HTTP_403 request_id=[redacted] user_id=[redacted]
message="Akses ditolak saat membaca koleksi"
```

Jangan mencatat password, token `Authorization`, URL reset password, alamat
email lengkap, atau seluruh respons backend. Gunakan ID permintaan yang
disingkat/disamarkan dan kode error yang stabil.

| Gejala / kode | Penyebab yang mungkin | Tindakan |
| --- | --- | --- |
| `HTTP_401` saat login | Sesi/token kedaluwarsa atau email belum dikonfirmasi | Masuk ulang; cek status konfirmasi email di Supabase Auth. Jangan catat password. |
| `HTTP_403` / RLS | Akun bukan pemilik koleksi atau belum ada di allowlist admin | Pastikan masuk dengan akun yang tepat; periksa kebijakan RLS dan `admin_users` tanpa membagikan token. |
| `PGRST205` / tabel caption tidak ada | SQL caption belum diterapkan atau Data API belum mengekspos tabel | Jalankan `supabase_comic_caption_setup.sql`, periksa grant SELECT/INSERT/UPDATE, lalu ulangi. |
| Waktu chapter tidak tampil | API sumber tidak menyediakan tanggal valid | Tampilkan tanpa label waktu; jangan mengganti dengan “Baru saja”. |
| Gambar gagal dimuat | URL sumber mati, koneksi putus, atau proxy gagal | Coba jaringan lain, ulangi; cek status proxy dan host gambar yang diizinkan. |
| `INSTALL_FAILED_USER_RESTRICTED` | HP menolak instalasi via USB | Izinkan instalasi USB dan konfirmasi dialog pada HP, lalu ulangi `adb install`. |

## 04. Bukti fresh clone, PR, run, build, dan test

| Tahap | Status verifikasi |
| --- | --- |
| Fresh clone dari GitHub | Lulus pada 27 Oktober 2026: `git clone --branch codex/p8-verification --single-branch ...`, lalu `flutter pub get` berhasil. |
| Pemeriksaan keamanan statis | Lulus: `python tools/check_public_repo.py` pada 161 file Git. |
| Analisis kode | Lulus: `dart analyze lib test` → `No issues found!`. |
| Semua unit test | Lulus: `flutter test --no-pub` → `12/12 All tests passed!`. |
| Build APK debug | Lulus: `flutter build apk --debug --no-pub` → `app-debug.apk` (154,5 MB pada fresh clone). |
| Run lokal | Lulus terbatas: `flutter run -d web-server --web-port=8088 --no-pub` melalui launcher resmi; HTTP `/` mengembalikan 200 dan `flutter_bootstrap.js`. Ini smoke test server, belum membuktikan seluruh UI/fitur. |
| Run/install pada Android | Belum ada perangkat Android terhubung pada sesi verifikasi awal; perintah instalasi ada di README. |
| Pull request dan CI | [PR #1](https://github.com/RipkiHensem/komik/pull/1); workflow menjalankan pemeriksaan dan membuat APK debug. |
| Deploy produksi | Tidak dilakukan; paket demo adalah APK debug. |

Tidak ada klaim bahwa fitur yang bergantung pada Supabase, kamera, notifikasi,
atau instalasi perangkat telah lolos uji fisik hanya dari unit test dan build.
Saat mencoba menjalankan web-server melalui `flutter_tools.snapshot` langsung,
launcher internal Flutter mengalami error package config; perintah resmi
`flutter run` berhasil. Gunakan perintah README, bukan snapshot internal.
