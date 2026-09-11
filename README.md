# ComicStream 

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
