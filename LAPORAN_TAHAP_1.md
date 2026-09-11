# 📚 LAPORAN TAHAP 1 — DEFINE THE MOBILE PRODUCT
## Proyek: ComicStream — Aplikasi Baca Komik Mobile Modern
**Mata Kuliah:** Pemrograman Mobile  
**Repositori GitHub:** [https://github.com/RipkiHensem/komik](https://github.com/RipkiHensem/komik)  
**Pengembang:** Rhifqi Syahputra  

---

## 📌 DAFTAR ISI
1. [Minggu 01: Kickoff & Ide](#-minggu-01-kickoff--ide)
   - 1.1 Problem Statement
   - 1.2 Target User
   - 1.3 Nilai Aplikasi (Value Proposition)
   - 1.4 Batasan Fitur (Scope 12 Pertemuan)
2. [Minggu 02: User Flow](#-minggu-02-user-flow)
   - 2.1 Daftar Screen
   - 2.2 Alur Utama & Diagram Navigasi
   - 2.3 Skenario Penggunaan
3. [Minggu 03: UI & Foundation (Checkpoint: Offline Review UI)](#-minggu-03-ui--foundation)
   - 3.1 Prototype & Fitur Siap Review
   - 3.2 Struktur Proyek (Clean Architecture)
   - 3.3 Sistem Routing (GoRouter)
   - 3.4 Reusable Component / Widget
   - 3.5 Panduan Menjalankan Aplikasi (Offline Review UI)

---

## 🎯 MINGGU 01: KICKOFF & IDE

### 1.1 Problem Statement
Banyak pembaca komik digital (manga, manhwa, dan manhua) di Indonesia menghadapi kendala berikut:
1. **Antarmuka yang Usang & Penuh Iklan**: Sebagian besar situs atau aplikasi komik web dipenuhi iklan popup/banner yang mengganggu kenyamanan membaca.
2. **Pengalaman Membaca yang Kaku**: Format manga (halaman per halaman) dan manhwa (scroll vertikal panjang) membutuhkan mode baca yang berbeda, namun jarang ada aplikasi yang mendukung kedua mode secara fleksibel.
3. **Sinkronisasi Riwayat Baca yang Buruk**: Pembaca sering lupa chapter terakhir yang dibaca saat berpindah perangkat atau saat membuka aplikasi kembali.

### 1.2 Target User
- **Demografi**: Usia 15 – 35 tahun (pelajar, mahasiswa, pekerja muda).
- **Karakteristik**: Penggemar komik Jepang (Manga), Korea (Manhwa/Webtoon), dan China (Manhua).
- **Kebutuhan**: Aplikasi membaca yang cepat, ringan, estetik (Dark Mode premium), mudah mencari komik, dan otomatis mencatat progres membaca.

### 1.3 Nilai Aplikasi (Value Proposition)
- 🖤 **Desain Estetik Dark OLED**: Antarmuka modern bernuansa gelap dengan aksen ungu neon, nyaman di mata untuk sesi baca yang lama.
- 🔄 **Dual Mode Reader**: Mode Scroll Vertikal (khusus Webtoon/Manhwa) dan Mode Halaman Horisontal (khusus Manga) dengan zoom interaktif.
- ⚡ **Realtime Cloud Sync**: Bookmark dan riwayat baca tersimpan aman di cloud (Supabase) dan dapat diakses dari mana saja.
- 🔒 **Autentikasi Fleksibel**: Registrasi otomatis masuk (auto-login), serta login fleksibel menggunakan **Username** maupun **Email**.

### 1.4 Batasan Fitur (Scope 12 Pertemuan)
| Fase | Pertemuan | Fokus Pengerjaan | Status |
|---|---|---|---|
| **Tahap 1** | Minggu 1 - 3 | Ideation, User Flow, UI Prototype, Routing, Reusable Widgets | **SELESAI (Minggu 3)** |
| **Tahap 2** | Minggu 4 - 6 | State Management (Riverpod), Integrasi Data Cloud (Supabase/REST) | Berjalan |
| **Tahap 3** | Minggu 7 - 9 | Fitur Interaktif Lanjutan (Offline Caching, Search Engine, Chapter Reader) | Mendatang |
| **Tahap 4** | Minggu 10 - 12 | Polish, Testing, Build APK/Release, Final Presentation | Mendatang |

---

## 🗺️ MINGGU 02: USER FLOW

### 2.1 Daftar Screen
Aplikasi ComicStream memiliki 8 screen utama:

| No | Nama Screen | File Path | Deskripsi |
|---|---|---|---|
| 1 | **Splash Screen** | `lib/presentation/screens/splash/splash_screen.dart` | Tampilan pembuka animasi logo |
| 2 | **Home Screen** | `lib/presentation/screens/home/home_screen.dart` | Hero banner carousel, komik populer, update terbaru |
| 3 | **Search & Filter Screen** | `lib/presentation/screens/search/search_screen.dart` | Pencarian instan dan filter genre/format |
| 4 | **Comic Detail Screen** | `lib/presentation/screens/detail/comic_detail_screen.dart` | Sinopsis komik, rating, genre, dan daftar chapter |
| 5 | **Reader Screen** | `lib/presentation/screens/reader/reader_screen.dart` | Pembaca chapter dengan dual mode (webtoon & manga) |
| 6 | **Bookmark Screen** | `lib/presentation/screens/bookmark/bookmark_screen.dart` | Koleksi komik favorit & tab riwayat baca terakhir |
| 7 | **Profile Screen** | `lib/presentation/screens/profile/profile_screen.dart` | Info user, ganti foto profil, ganti username, logout |
| 8 | **Login & Register Screen**| `lib/presentation/screens/auth/` | Masuk dan daftar akun baru |

### 2.2 Alur Utama & Diagram Navigasi
```
[Splash Screen] 
       │
       ▼
  [Home Screen] ◄──────────────┐
   ├──► [Search Screen]        │
   │        │                  │
   ├──► [Bookmarks & History]  │ (Bottom Nav)
   │        │                  │
   ├──► [Profile Screen]       │
   │    └──► [Login/Register]  │
   │                           │
   ▼                           │
[Comic Detail Screen] ─────────┘
   │
   ▼
[Chapter Reader Screen] (Dual Mode Reader)
```

### 2.3 Skenario Penggunaan Utama
1. **Skenario 1 — Eksplorasi & Membaca Komik**:
   - Pengguna membuka Home, melihat rekomendasi komik populer.
   - Memilih komik untuk membuka Detail Screen.
   - Memilih Chapter untuk masuk ke Reader Screen (langsung membaca tanpa hambatan).
2. **Skenario 2 — Pencarian & Filter**:
   - Pengguna membuka tab Cari, mengetik judul atau memilih chip genre (Action, Fantasy, Romance).
   - Menemukan komik yang sesuai dan membukanya.
3. **Skenario 3 — Personalisasi & Bookmark**:
   - Pengguna login/daftar akun (bisa via Username atau Email).
   - Menekan tombol Bookmark pada komik favorit.
   - Komik tersimpan di tab Koleksi dan progres bab otomatis tercatat di tab Riwayat.

---

## 🎨 MINGGU 03: UI & FOUNDATION

### 3.1 Prototype & Fitur Siap Review
Aplikasi ComicStream telah dibangun secara utuh sebagai **Interactive UI Prototype** berbasis Flutter yang siap direview langsung (Web Chrome, Windows, maupun Android):
- [x] **Dark OLED Luxury Theme**: Warna konsisten menggunakan HSL tailored palette (`#0B0E14` background, `#141923` card, `#8B5CF6` primary violet).
- [x] **Bottom Navigation Bar**: ShellRoute persistent navigation memudahkan navigasi antar 4 menu utama tanpa re-render berlebih.
- [x] **Dual Reading Engine**: Mode baca vertikal untuk Manhwa dan mode halaman untuk Manga dengan kontrol navigasi tap.
- [x] **Authentication Flow**: Halaman Login (mendukung username & email) dan Register dengan validasi form serta ambient glow.
- [x] **User Management**: Fitur dialog interaktif untuk **Ubah Username** dan **Ganti Avatar**.

### 3.2 Struktur Proyek (Clean Architecture)
Struktur kode aplikasi mengikuti kaidah arsitektur modular yang rapi:

```
comicstream_app/lib/
├── core/                         # Pondasi & Konfigurasi Global
│   ├── constants/                # AppConstants, API URLs, Keys
│   ├── theme/                    # AppColors, AppTheme (Dark OLED styling)
│   └── utils/                    # Helper tools & Image Pickers
│
├── data/                         # Layer Data & State
│   ├── models/                   # Comic, Chapter, ComicPage, Bookmark, User
│   ├── providers/                # Riverpod StateNotifier & FutureProviders
│   └── services/                 # SupabaseComicService & SupabaseAuthService
│
├── presentation/                 # Layer Antarmuka (UI)
│   ├── screens/                  # 8 Screen Utama (Home, Search, Detail, dll)
│   │   ├── auth/                 # LoginScreen, RegisterScreen
│   │   ├── bookmark/             # BookmarkScreen & History
│   │   ├── detail/               # ComicDetailScreen
│   │   ├── home/                 # HomeScreen
│   │   ├── main/                 # MainShell (Bottom Navigation)
│   │   ├── profile/              # ProfileScreen & ChangeAvatarDialog
│   │   ├── reader/               # ReaderScreen (Dual-mode reader engine)
│   │   ├── search/               # SearchScreen
│   │   └── splash/               # SplashScreen
│   └── widgets/                  # Reusable Components (Komponen Berulang)
│
└── router/                       # Navigasi & Deklarasi Route
    └── router.dart               # Konfigurasi GoRouter + ShellRoute
```

### 3.3 Sistem Routing (GoRouter)
Routing didefinisikan secara deklaratif di `lib/router/router.dart`:

| Route Path | Screen Target | Tipe Navigasi | Keterangan |
|---|---|---|---|
| `/` & `/splash` | Redirect `/home` | Redirect | Otomatis masuk ke halaman utama |
| `/home` | `HomeScreen` | ShellRoute (Tab 0) | Halaman beranda utama |
| `/search` | `SearchScreen` | ShellRoute (Tab 1) | Halaman pencarian komik |
| `/bookmarks` | `BookmarkScreen` | ShellRoute (Tab 2) | Koleksi & riwayat baca |
| `/profile` | `ProfileScreen` | ShellRoute (Tab 3) | Profil & pengaturan akun |
| `/comic/:id` | `ComicDetailScreen` | Full Screen Route | Detail komik berdasarkan ID |
| `/comic/:comicId/chapter/:chapterId` | `ReaderScreen` | Full Screen Route | Pembaca bab komik |
| `/login` | `LoginScreen` | Full Screen Route | Autentikasi masuk |
| `/register` | `RegisterScreen` | Full Screen Route | Pendaftaran akun baru |

### 3.4 Reusable Component / Widget
Untuk memenuhi indikator *Reusable Component*, komponen visual dipisahkan ke dalam folder `lib/presentation/widgets/`:

1. **`ComicCard`** (`comic_card.dart`):
   - Komponen kartu komik dengan efek hover scale 1.05x, badge rating emas, badge format (Manga/Manhwa), dan bayangan dinamis.
2. **`ProxiedImage`** (`proxied_image.dart`):
   - Widget pembungkus gambar jaringan dengan shimmer placeholder otomatis, error fallback, dan dukungan CORS image proxy.
3. **`HoverWidget`** (`hover_builder.dart`):
   - Komponen interaktif yang memberikan micro-animation (scale up dan glow neon) saat kursor mouse melintas (hover) pada desktop/web.
4. **`GenreChip`** (`genre_chip.dart`):
   - Kapsul tag genre yang dapat diklik untuk melakukan filter cepat kategori komik.
5. **`ChapterTile`** (`chapter_tile.dart`):
   - Item daftar chapter dengan indikator tanggal rilis, status sudah dibaca, dan nomor chapter.
6. **`ShimmerLoading`** (`shimmer_loading.dart`):
   - Efek animasi skeleton loading berkilau saat data sedang diunduh dari jaringan.
7. **`ErrorView`** (`error_view.dart`):
   - Tampilan ramah pengguna ketika terjadi galat koneksi lengkap dengan tombol coba lagi.

---

## 💻 PANDUAN MENJALANKAN APLIKASI (OFFLINE REVIEW UI)

### Cara 1: Menjalankan di Chrome / Web (Rekomendasi Tercepat)
```bash
# Masuk ke direktori aplikasi
cd comicstream_app

# Ambil dependencies
flutter pub get

# Jalankan di Google Chrome
flutter run -d chrome --web-port=8080
```

### Cara 2: Menjalankan di Windows Desktop
```bash
flutter run -d windows
```

### Cara 3: Menjalankan di Android Emulator / Device
```bash
flutter run -d android
```

---
*Laporan ini disusun untuk memenuhi pemenuhan luaran **Tahap 1 (Minggu 01 - 03)** Mata Kuliah Pemrograman Mobile.*
