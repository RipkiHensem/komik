class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────
  static const String appName = 'ComicStream';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Baca Komik Tanpa Batas';

  // ── Supabase ──────────────────────────────────────────────
  static const String supabaseUrl = 'https://fvyfaleismwukeqwnbku.supabase.co';
  // Ganti dengan anon key dari: Settings > API > Project API keys > anon public
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2eWZhbGVpc213dWtlcXduYmt1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwNDA1MjksImV4cCI6MjEwNDYxNjUyOX0.-pYyxXKBRAgKi4WTmQMd30n_Rgj8Lbn627znzgNJB9U';

  // ── Manga API (Supabase Edge Function) ───────────────────
  static const String mangaApiBaseUrl = 'https://fvyfaleismwukeqwnbku.supabase.co/functions/v1/manga-api';
  static const Duration apiTimeout = Duration(seconds: 30);

  // ── Storage Keys ──────────────────────────────────────────
  static const String themeKey = 'theme_mode';
  static const String readingModeKey = 'reading_mode';

  // ── Hive Boxes ────────────────────────────────────────────
  static const String comicsBox = 'comics_cache';
  static const String bookmarksBox = 'bookmarks_cache';
  static const String historyBox = 'reading_history';
  static const String readChaptersBox = 'read_chapters';

  // ── Pagination ────────────────────────────────────────────
  static const int pageSize = 20;

  // ── Genres ────────────────────────────────────────────────
  static const List<String> genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Horror',
    'Martial Arts',
    'Mystery',
    'Psychological',
    'Romance',
    'Sci-Fi',
    'Slice of Life',
    'Supernatural',
    'Thriller',
    'Tragedy',
  ];

  // ── Comic Formats ────────────────────────────────────────
  static const List<String> formats = ['Manhwa', 'Manga', 'Manhua'];

  // ── Comic Statuses ───────────────────────────────────────
  static const List<String> statuses = ['Ongoing', 'Completed', 'Hiatus'];

  // ── Reading Modes ────────────────────────────────────────
  static const String readingModePage = 'page';
  static const String readingModeScroll = 'scroll';
}
