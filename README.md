# ComicStream 📚

**Aplikasi Baca Komik/Manhwa Mobile** — Flutter + Node.js + PostgreSQL

> Mata Kuliah: Pemrograman Mobile Era AI Agent  
> Skema: Project-Based Learning — 12 Pertemuan

## 📱 Preview

Aplikasi membaca komik mobile dengan dark theme terinspirasi shinigami.to, mendukung mode baca halaman (manga) dan scroll vertikal (manhwa/webtoon).

## 🏗 Tech Stack

| Layer | Teknologi |
|-------|-----------|
| Mobile App | Flutter (Dart) |
| State Management | Riverpod |
| Navigation | go_router |
| Network | Dio |
| Local Storage | Hive + Flutter Secure Storage |
| Backend API | Node.js + Express |
| Database | PostgreSQL |
| Auth | JWT (JSON Web Token) |

## 📂 Struktur Project

```
├── comicstream_app/           # Flutter Mobile App
│   ├── lib/
│   │   ├── core/              # Theme, constants
│   │   ├── data/              # Models, services, providers
│   │   ├── presentation/      # Screens & widgets
│   │   └── router/            # Go Router config
│   └── pubspec.yaml
│
├── comicstream_backend/       # Node.js REST API
│   ├── src/
│   │   ├── config/            # Database connection
│   │   ├── middleware/        # JWT auth
│   │   ├── routes/            # API endpoints
│   │   └── seeds/             # Dummy data
│   └── package.json
```

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK 3.x+
- Node.js 18+
- PostgreSQL 14+

### 1. Setup Database
```bash
# Buat database PostgreSQL
createdb comicstream
```

### 2. Setup Backend
```bash
cd comicstream_backend
npm install

# Edit .env sesuai konfigurasi PostgreSQL lokal
# Jalankan seed data
npm run seed

# Jalankan server
npm run dev
```

### 3. Setup Flutter App
```bash
cd comicstream_app
flutter pub get
flutter run
```

## 📡 API Endpoints

| Method | Endpoint | Fungsi |
|--------|----------|--------|
| POST | `/api/auth/register` | Registrasi |
| POST | `/api/auth/login` | Login → JWT |
| GET | `/api/auth/me` | Profil user |
| GET | `/api/comics` | Daftar komik (search, filter, sort) |
| GET | `/api/comics/:id` | Detail komik |
| GET | `/api/comics/:id/chapters` | Daftar chapter |
| GET | `/api/chapters/:id/pages` | Halaman reader |
| POST | `/api/bookmarks` | Simpan/update bookmark |
| GET | `/api/bookmarks/me` | Bookmark user |
| DELETE | `/api/bookmarks/:id` | Hapus bookmark |

## 🎨 Fitur

- ✅ Autentikasi JWT (register, login, logout)
- ✅ Home dengan hero carousel & grid komik
- ✅ Pencarian & filter (genre, format, status, sort)
- ✅ Detail komik dengan metadata & daftar chapter
- ✅ Reader dual mode (page-view & scroll vertikal)
- ✅ Bookmark & histori baca otomatis
- ✅ Dark theme premium
- ✅ Loading skeleton (shimmer)
- ✅ Error & empty state handling
- ✅ Pull-to-refresh

## 📝 License

Educational project — for academic purposes only.
