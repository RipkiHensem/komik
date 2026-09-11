import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/comic.dart';
import '../models/chapter.dart';
import '../models/comic_page.dart';
import '../../core/constants/app_constants.dart';

/// Service untuk mengambil data komik dari mangamint API (febryardiansyah/manga-api)
/// Base URL: https://mangamint.kaedenoki.net/api
///
/// Endpoints yang digunakan:
/// GET /manga/page/{page}        → daftar manga terbaru
/// GET /manga/popular/{page}     → daftar manga populer
/// GET /manhwa/{page}            → daftar manhwa
/// GET /manhua/{page}            → daftar manhua
/// GET /recommended              → manga yang direkomendasikan
/// GET /manga/detail/{endpoint}  → detail manga + daftar chapter
/// GET /chapter/{endpoint}       → halaman-halaman chapter
/// GET /search/{query}           → pencarian manga
/// GET /genres                   → daftar genre
class MangaApiService {
  late final Dio _dio;

  MangaApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.mangaApiBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Accept': 'application/json',
          'apikey': AppConstants.supabaseAnonKey,
          'Authorization': 'Bearer ${AppConstants.supabaseAnonKey}',
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('MANGA API → ${options.method} ${options.path}');
            return handler.next(options);
          },
          onError: (error, handler) {
            debugPrint('MANGA API ✖ ${error.response?.statusCode} ${error.message}');
            return handler.next(error);
          },
        ),
      );
    }
  }

  // ── Comics List ───────────────────────────────────────────

  /// Ambil daftar manga terbaru
  Future<List<Comic>> getLatestManga({int page = 1}) async {
    final response = await _dio.get(page == 1 ? '/manga' : '/manga/page/$page');
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  /// Ambil daftar manga populer
  Future<List<Comic>> getPopularManga({int page = 1}) async {
    final response = await _dio.get(page == 1 ? '/manga/popular' : '/manga/popular/$page');
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  /// Ambil daftar manhwa (komik Korea)
  Future<List<Comic>> getManhwa({int page = 1}) async {
    final response = await _dio.get(page == 1 ? '/manhwa' : '/manhwa/page/$page');
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  /// Ambil daftar manhua (komik China)
  Future<List<Comic>> getManhua({int page = 1}) async {
    final response = await _dio.get(page == 1 ? '/manhua' : '/manhua/page/$page');
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  /// Ambil daftar manga yang direkomendasikan
  Future<List<Comic>> getRecommended() async {
    final response = await _dio.get('/recommended');
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  // ── Detail & Chapters ─────────────────────────────────────

  /// Ambil detail komik beserta daftar chapter-nya
  /// [endpoint] adalah slug/endpoint komik, mis: "solo-leveling"
  Future<Map<String, dynamic>> getComicDetail(String endpoint) async {
    final response = await _dio.get('/manga/detail/$endpoint');
    final data = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};

    // Parse comic dari Edge Function (format langsung, bukan nested)
    final comic = Comic.fromDetailJson(data);

    // Chapters dari Edge Function ada di field 'chapter'
    final chapterRaw = data['chapter'] as List? ?? data['chapter_list'] as List? ?? data['chapters'] as List? ?? [];
    final chapters = chapterRaw.asMap().entries.map((entry) {
      final idx = entry.key;
      final json = Map<String, dynamic>.from(entry.value as Map);
      // Edge Function format: { chapter_title, chapter_endpoint }
      final chapterEndpoint = json['chapter_endpoint']?.toString() ?? json['endpoint']?.toString() ?? json['id']?.toString() ?? '';
      final chapterTitle = json['chapter_title']?.toString() ?? json['title']?.toString() ?? 'Chapter ${chapterRaw.length - idx}';
      return Chapter(
        id: chapterEndpoint,
        comicId: endpoint,
        chapterNumber: _parseChapterNumber(json, idx, chapterRaw.length),
        title: chapterTitle,
        pageCount: 0,
        releasedAt: _parseDate(json['released_at'] ?? json['date']),
      );
    }).toList();

    return {'comic': comic, 'chapters': chapters};
  }

  // ── Chapter Pages ─────────────────────────────────────────

  /// Ambil halaman-halaman sebuah chapter
  /// [endpoint] adalah slug/endpoint chapter, mis: "solo-leveling-chapter-1"
  Future<List<ComicPage>> getChapterPages(String endpoint) async {
    final response = await _dio.get('/chapter/$endpoint');
    final data = response.data is Map ? response.data as Map<String, dynamic> : {};

    // Edge Function mengembalikan chapter_image: [{chapter_image_link, image_number}]
    final rawPages = data['chapter_image'] as List? ?? data['chapter_pages'] as List? ?? data['pages'] as List? ?? [];
    return rawPages.asMap().entries.map((entry) {
      final idx = entry.key;
      final json = entry.value;
      if (json is String) {
        return ComicPage(
          id: '${endpoint}_$idx',
          chapterId: endpoint,
          pageNumber: idx + 1,
          imageUrl: json,
        );
      }
      final map = json as Map<String, dynamic>;
      // Edge Function format: chapter_image_link
      final imageUrl = map['chapter_image_link']?.toString() ??
          map['image']?.toString() ??
          map['image_url']?.toString() ?? '';
      return ComicPage(
        id: map['id']?.toString() ?? '${endpoint}_$idx',
        chapterId: endpoint,
        pageNumber: (map['image_number'] as int?) ?? idx + 1,
        imageUrl: imageUrl,
      );
    }).toList();
  }

  // ── Search ────────────────────────────────────────────────

  /// Cari komik berdasarkan keyword
  Future<List<Comic>> search(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await _dio.get('/search', queryParameters: {'q': query.trim()});
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  // ── Genres ────────────────────────────────────────────────

  /// Ambil daftar semua genre
  Future<List<String>> getGenres() async {
    final response = await _dio.get('/genres');
    final data = _extractList(response.data, 'genre_list');
    return data.map((g) => (g['genre_name'] ?? g.toString()) as String).toList();
  }

  /// Ambil komik berdasarkan genre
  Future<List<Comic>> getByGenre(String genreEndpoint, {int page = 1}) async {
    final response = await _dio.get('/genres/$genreEndpoint/$page');
    final data = _extractList(response.data, 'manga_list');
    return data.map((json) => Comic.fromListJson(json)).toList();
  }

  // ── Helpers ───────────────────────────────────────────────

  List<Map<String, dynamic>> _extractList(dynamic responseData, String key) {
    if (responseData is Map) {
      final list = responseData[key];
      if (list is List) {
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    }
    if (responseData is List) {
      return responseData.map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }

  int _parseChapterNumber(Map<String, dynamic> json, int idx, int total) {
    // API biasanya mengurutkan chapter terbaru di atas
    // chapter_number dari JSON
    final raw = json['chapter_number'] ?? json['number'];
    if (raw != null) {
      final n = int.tryParse(raw.toString().replaceAll(RegExp(r'[^\d]'), ''));
      if (n != null) return n;
    }
    // fallback: dari title
    final title = json['title']?.toString() ?? '';
    final match = RegExp(r'(?:chapter|ch)[.\s-]*(\d+)', caseSensitive: false).firstMatch(title);
    if (match != null) return int.tryParse(match.group(1)!) ?? (total - idx);
    return total - idx;
  }

  DateTime _parseDate(dynamic v) {
    if (v == null) return DateTime.now();
    try {
      return DateTime.parse(v.toString());
    } catch (_) {
      return DateTime.now();
    }
  }
}

/// Service untuk mengambil data komik dari Supabase (setelah dipindahkan)
class SupabaseComicService {
  final SupabaseClient _supabase;

  SupabaseComicService(this._supabase);

  // ── Comics List ───────────────────────────────────────────

  /// Ambil daftar manga terbaru
  Future<List<Comic>> getLatestManga({int page = 1}) async {
    try {
      final response = await _supabase
          .from('comics')
          .select()
          .order('updated_at', ascending: false)
          .range((page - 1) * 20, page * 20 - 1);

      debugPrint('[Supabase] getLatestManga: ${response.length} komik');
      return (response as List).map((json) => Comic.fromSupabase(json)).toList();
    } catch (e, st) {
      debugPrint('[Supabase ERROR] getLatestManga: $e\n$st');
      return [];
    }
  }

  /// Ambil daftar manga populer
  Future<List<Comic>> getPopularManga({int page = 1}) async {
    try {
      final response = await _supabase
          .from('comics')
          .select()
          .eq('is_popular', true)
          .order('view_count', ascending: false)
          .range((page - 1) * 20, page * 20 - 1);

      debugPrint('[Supabase] getPopularManga: ${response.length} komik');
      return (response as List).map((json) => Comic.fromSupabase(json)).toList();
    } catch (e, st) {
      debugPrint('[Supabase ERROR] getPopularManga: $e\n$st');
      return [];
    }
  }

  /// Ambil daftar manhwa (komik Korea)
  Future<List<Comic>> getManhwa({int page = 1}) async {
    try {
      final response = await _supabase
          .from('comics')
          .select()
          .eq('format', 'Manhwa')
          .order('updated_at', ascending: false)
          .range((page - 1) * 20, page * 20 - 1);

      debugPrint('[Supabase] getManhwa: ${response.length} komik');
      return (response as List).map((json) => Comic.fromSupabase(json)).toList();
    } catch (e, st) {
      debugPrint('[Supabase ERROR] getManhwa: $e\n$st');
      return [];
    }
  }

  /// Ambil daftar manga (komik Jepang)
  Future<List<Comic>> getManga({int page = 1}) async {
    try {
      final response = await _supabase
          .from('comics')
          .select()
          .eq('format', 'Manga')
          .order('updated_at', ascending: false)
          .range((page - 1) * 20, page * 20 - 1);

      debugPrint('[Supabase] getManga: ${response.length} komik');
      return (response as List).map((json) => Comic.fromSupabase(json)).toList();
    } catch (e, st) {
      debugPrint('[Supabase ERROR] getManga: $e\n$st');
      return [];
    }
  }

  /// Ambil daftar manhua (komik China)
  Future<List<Comic>> getManhua({int page = 1}) async {
    try {
      final response = await _supabase
          .from('comics')
          .select()
          .eq('format', 'Manhua')
          .order('updated_at', ascending: false)
          .range((page - 1) * 20, page * 20 - 1);

      debugPrint('[Supabase] getManhua: ${response.length} komik');
      return (response as List).map((json) => Comic.fromSupabase(json)).toList();
    } catch (e, st) {
      debugPrint('[Supabase ERROR] getManhua: $e\n$st');
      return [];
    }
  }


  /// Ambil daftar manga yang direkomendasikan
  Future<List<Comic>> getRecommended() async {
    try {
      final response = await _supabase
          .from('comics')
          .select()
          .eq('is_recommended', true)
          .order('updated_at', ascending: false)
          .limit(10);

      debugPrint('[Supabase] getRecommended: ${response.length} komik');
      return (response as List).map((json) => Comic.fromSupabase(json)).toList();
    } catch (e, st) {
      debugPrint('[Supabase ERROR] getRecommended: $e\n$st');
      return [];
    }
  }

  // ── Detail & Chapters ─────────────────────────────────────

  /// Ambil detail komik beserta daftar chapter-nya
  Future<Map<String, dynamic>> getComicDetail(String endpoint) async {
    final comicResponse = await _supabase
        .from('comics')
        .select()
        .eq('id', endpoint)
        .single();
    
    final comic = Comic.fromSupabase(comicResponse);

    final chaptersResponse = await _supabase
        .from('chapters')
        .select()
        .eq('comic_id', endpoint)
        .order('chapter_number', ascending: false);
        
    final chapters = (chaptersResponse as List)
        .map((json) => Chapter.fromSupabase(json))
        .toList();

    return {'comic': comic, 'chapters': chapters};
  }

  // ── Chapter Pages ─────────────────────────────────────────

  /// Ambil halaman-halaman sebuah chapter
  Future<List<ComicPage>> getChapterPages(String endpoint) async {
    final response = await _supabase
        .from('chapter_pages')
        .select()
        .eq('chapter_id', endpoint)
        .order('page_number', ascending: true);
        
    return (response as List)
        .map((json) => ComicPage.fromSupabase(json))
        .toList();
  }

  // ── Search ────────────────────────────────────────────────

  /// Cari komik berdasarkan keyword
  Future<List<Comic>> search(String query) async {
    if (query.trim().isEmpty) return [];
    
    final response = await _supabase
        .from('comics')
        .select()
        .ilike('title', '%${query.trim()}%')
        .order('updated_at', ascending: false)
        .limit(20);
        
    return (response as List).map((json) => Comic.fromSupabase(json)).toList();
  }

  // ── Genres ────────────────────────────────────────────────

  /// Ambil daftar semua genre
  Future<List<String>> getGenres() async {
    // Sebagai mock, kita kembalikan beberapa genre populer
    return ['Action', 'Adventure', 'Fantasy', 'Comedy', 'Sci-Fi', 'Martial Arts'];
  }

  /// Ambil komik berdasarkan genre
  Future<List<Comic>> getByGenre(String genreEndpoint, {int page = 1}) async {
    // Karena kita menyimpan genres sebagai array di Supabase, kita bisa filter:
    final response = await _supabase
        .from('comics')
        .select()
        .contains('genres', [genreEndpoint])
        .order('updated_at', ascending: false)
        .range((page - 1) * 20, page * 20 - 1);
        
    return (response as List).map((json) => Comic.fromSupabase(json)).toList();
  }
}

