# Yomu
## Mulai dari fresh clone (P8)

Yomu adalah aplikasi Flutter untuk membaca komik. Backend yang dipakai aplikasi
adalah proyek Supabase yang sudah berjalan; fresh clone mengambil kode aplikasi,
bukan salinan data pengguna atau Edge Function dari server.

**Prasyarat:** Git, Flutter yang memenuhi Dart `^3.11.5` (verifikasi dengan
`flutter --version`), Android SDK, dan perangkat Android atau emulator.
Jalankan `flutter doctor` dan pastikan **Android toolchain** siap. Visual Studio
tidak diperlukan untuk build Android.

```powershell
git clone https://github.com/RipkiHensem/komik.git
cd komik/comicstream_app
flutter pub get
flutter devices
flutter analyze
flutter test
flutter build apk --debug
```

APK demo berada di `comicstream_app/build/app/outputs/flutter-apk/app-debug.apk`.
Untuk langsung menjalankan pada HP yang terhubung dan mengizinkan USB debugging:

```powershell
flutter run -d <device-id>
```

Untuk memasang APK yang sudah dibangun tanpa sesi Flutter, gunakan
`adb install -r build/app/outputs/flutter-apk/app-debug.apk`, lalu buka **Yomu**
di HP. Aplikasi tetap dapat dibuka setelah kabel USB dilepas; data daring
memerlukan internet dan proyek Supabase yang aktif.

**Konfigurasi backend:** URL proyek dan *publishable/anon key* Supabase ada di
`comicstream_app/lib/core/constants/app_constants.dart`. Kunci ini bersifat
publik; jangan menaruh `service_role`, token pribadi, atau sandi SMTP di repo.
Skema pada file SQL adalah catatan perubahan untuk proyek Supabase yang sudah
ada, bukan bootstrap lengkap untuk membuat backend baru. Fitur edit caption
admin memerlukan [SQL caption](supabase_comic_caption_setup.sql) dijalankan
sekali di Supabase SQL Editor. Akun admin ditentukan di tabel `admin_users`
dan aturan RLS, bukan oleh email yang ditulis di aplikasi. Login sekarang
memakai **email dan password**. Untuk menutup fungsi pencarian email dari
username yang lama, jalankan [SQL keamanan P8](supabase_security_p8.sql)
sekali pada proyek Supabase yang sama.

## APK Release dan log saat aplikasi berjalan (P11)

Untuk demo di HP, siapkan APK **Release** dengan skrip PowerShell ini dari root
repo:

```powershell
cd comicstream_app
.\tool\build_release_demo.ps1
```

Skrip membangun mode Release, menandatangani APK dengan debug keystore lokal,
lalu memverifikasi tanda tangannya. Hasilnya ada di
`comicstream_app/build/app/outputs/flutter-apk/yomu-release-demo.apk`.
Kirim APK itu ke HP dan buka untuk memasang. APK ini bukan build Debug, tetapi
tanda tangannya memang khusus demo/instalasi lokal; siapkan keystore rilis
sendiri sebelum distribusi publik atau Play Store. Jangan kirim file
`debug.keystore` ke GitHub atau orang lain.

Log runtime aman memakai prefix `[YOMU]`; log mencatat tahap API, status,
durasi, dan jenis error tanpa mencatat isi komentar, kredensial, token, atau
body request. Untuk mengambil log dari HP yang tersambung USB (atau ADB
wireless), jalankan di PowerShell:

```powershell
adb logcat -c
adb logcat | Select-String '\[YOMU\]' | Tee-Object -FilePath .\yomu-runtime.log
```

Lakukan langkah yang bermasalah di aplikasi, lalu tekan `Ctrl+C`. File
`yomu-runtime.log` berisi baris Yomu yang tersaring; tinjau sebelum dibagikan.
Dokumentasi 11 bug/issue yang sudah dibuat di GitHub, status perbaikannya, dan
langkah reproduksi ada di [POST_DEPLOY_BUGS.md](POST_DEPLOY_BUGS.md), dengan
tautan ke issue #4 sampai #14.

Pada pull request, workflow `P8 Flutter verification` menjalankan analisis,
unit test, dan build APK debug; unduh paket CI dari artifact `yomu-debug-apk`.

Lihat [bukti P8, hasil review keamanan, dan log aman](P8_VERIFICATION.md).
Langkah demonstrasi P6/P7 ada di [P6_P7_MVP.md](P6_P7_MVP.md).

---

## Arsip dokumentasi tahap awal

Checkpoint P6/P7: integrasi API melalui repository, unit test, dan MVP dengan
autentikasi, kamera avatar, serta notifikasi lokal Android.
Lihat [pemetaan kriteria dan panduan demonstrasi P6/P7](P6_P7_MVP.md).

**Aplikasi Baca Komik / Manhwa Mobile Modern** — Flutter + Supabase

> **Mata Kuliah:** Pemrograman Mobile  
> **Skema:** Project-Based Learning — 12 Pertemuan  
> **Tahap Saat Ini:** Tahap 1 • Define the mobile product (Minggu 01 - 03)  
> **Dokumentasi Lengkap:** Lihat [LAPORAN_TAHAP_1.md](LAPORAN_TAHAP_1.md)

---

##  Progress Capaian Proyek (Tahap 1)

| Minggu | Fokus | Output Wajib | Status |
|---|---|---|---|
| **01** | **Kickoff & ide** | Problem statement, target user, nilai aplikasi, batas fitur. | ✅ Selesai |
| **02** | **User flow** | Daftar screen, alur utama, navigasi, dan skenario penggunaan. | ✅ Selesai |
| **03** | **UI & foundation** | **Prototype, struktur proyek, routing, reusable component/widget, Git.** | ✅ Selesai (Siap Review) |

*Detail pembahasan setiap minggu dapat dilihat di dokumen [LAPORAN_TAHAP_1.md](LAPORAN_TAHAP_1.md).*

---

## Ringkasan Fitur Prototype (Minggu 03)

-  **Dark OLED Luxury Theme**: UI estetik bernuansa gelap dengan aksen ungu neon (`#8B5CF6`).
-  **Routing Deklaratif (GoRouter)**: Navigasi terstruktur menggunakan `ShellRoute` (persistent bottom navigation).
-  **Dual Reading Engine**: Mode baca vertikal (Webtoon) dan mode halaman (Manga).
-  **Autentikasi Fleksibel**: Registrasi otomatis login, serta mendukung login via **Username** maupun **Email**.
-  **Profil & Kustomisasi**: Penggantian avatar dan fitur ubah username secara instan.
-  **Modular & Reusable Widgets**: Komponen modular seperti `ComicCard`, `ProxiedImage`, `HoverWidget`, `GenreChip`, dll.

---

## Tech Stack

| Komponen | Teknologi |
|---|---|
| **Frontend Mobile** | Flutter (Dart 3.x) |
| **State Management** | Flutter Riverpod |
| **Navigation & Routing** | GoRouter |
| **Backend as a Service** | Supabase (PostgreSQL, Auth, Edge Functions) |
| **Local / Cache Storage**| Hive & Shared Preferences |
| **Version Control** | Git & GitHub |

---

##  Struktur Proyek (Clean Architecture)

```
comicstream_app/lib/
├── core/                         # Konfigurasi Tema, Warna, dan Konstanta
│   ├── constants/                # AppConstants, Keys
│   ├── theme/                    # AppColors, AppTheme
│   └── utils/                    # Helper & Image Picker
│
├── data/                         # Data, Model, dan State Management
│   ├── models/                   # Comic, Chapter, Bookmark, User
│   ├── providers/                # Riverpod Providers
│   └── services/                 # SupabaseComicService & SupabaseAuthService
│
├── presentation/                 # Tampilan Antarmuka (UI)
│   ├── screens/                  # 8 Screen Aplikasi
│   │   ├── auth/                 # Login & Register Screen
│   │   ├── bookmark/             # Bookmark & History Screen
│   │   ├── detail/               # Comic Detail Screen
│   │   ├── home/                 # Home Screen (Hero carousel, grid)
│   │   ├── main/                 # MainShell (Bottom Navigation Bar)
│   │   ├── profile/              # Profile Screen & Avatar Dialog
│   │   ├── reader/               # Reader Screen (Dual Mode Engine)
│   │   ├── search/               # Search & Filter Screen
│   │   └── splash/               # Splash Screen
│   └── widgets/                  # Reusable Components (ComicCard, HoverWidget, dll)
│
└── router/                       # Navigasi Aplikasi
    └── router.dart               # GoRouter Configuration
```

---

## Cara Menjalankan Prototype (Offline Review UI)

Pastikan Flutter SDK sudah terpasang di komputer Anda.

### 1. Masuk ke direktori aplikasi
```bash
cd comicstream_app
```

### 2. Pasang Dependencies
```bash
flutter pub get
```

### 3. Jalankan Aplikasi
- **Di Google Chrome (Web - Cepat):**
  ```bash
  flutter run -d chrome --web-port=8080
  ```
- **Di Windows Desktop:**
  ```bash
  flutter run -d windows
  ```
- **Di Android (Emulator / Device):**
  ```bash
  flutter run -d android
  ```
