import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

class AppConstants {
  AppConstants._();

  // ── App Info ──────────────────────────────────────────────
  static const String appName = 'ComicStream';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Baca Komik Tanpa Batas';

  // ── API ───────────────────────────────────────────────────
  /// Adaptive backend host:
  /// - Android Emulator requires 10.0.2.2 to access host machine localhost
  /// - Web / Windows desktop use localhost
  static String get baseHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get baseUrl => '$baseHost/api';
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Resolves image URL to full URL, handling relative paths and platform host
  static String resolveImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';

    String resolved = imageUrl;

    // If relative path like /covers/... or /pages/...
    if (resolved.startsWith('/')) {
      resolved = '$baseHost$resolved';
    } else if (resolved.contains('localhost:3000') && baseHost != 'http://localhost:3000') {
      // If image URL has localhost but we are on Android emulator (10.0.2.2)
      resolved = resolved.replaceFirst('http://localhost:3000', baseHost);
    }

    // On Web, if external third-party URL, route through proxy to bypass CORS
    if (kIsWeb && !resolved.startsWith(baseHost)) {
      return '$baseHost/api/proxy/image?url=${Uri.encodeComponent(resolved)}';
    }

    return resolved;
  }

  /// Proxy image URL through our backend to bypass CORS on web
  static String proxyImageUrl(String imageUrl) => resolveImageUrl(imageUrl);

  // ── Storage Keys ──────────────────────────────────────────
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String readingModeKey = 'reading_mode';

  // ── Hive Boxes ────────────────────────────────────────────
  static const String comicsBox = 'comics_cache';
  static const String bookmarksBox = 'bookmarks_cache';
  static const String historyBox = 'reading_history';

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
