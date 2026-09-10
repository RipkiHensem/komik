import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/comic.dart';
import '../models/chapter.dart';
import '../models/comic_page.dart';
import '../models/bookmark.dart';
import '../models/user.dart';
import '../../core/constants/app_constants.dart';

/// HTTP API service for ComicStream backend
class ApiService {
  late final Dio _dio;
  String? _authToken;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_authToken != null) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          }
          debugPrint('API → ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint('API ← ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          debugPrint('API ✖ ${error.response?.statusCode} ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  void setAuthToken(String? token) {
    _authToken = token;
  }

  // ── Auth ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'username': username,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  // ── Comics ────────────────────────────────────────────────

  Future<List<Comic>> getComics({
    String? search,
    String? genre,
    String? format,
    String? status,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _dio.get('/comics', queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (genre != null && genre.isNotEmpty) 'genre': genre,
      if (format != null && format.isNotEmpty) 'format': format,
      if (status != null && status.isNotEmpty) 'status': status,
      'sortBy': ?sortBy,
      'page': page,
      'limit': limit,
    });
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => Comic.fromJson(json)).toList();
  }

  Future<Comic> getComicDetail(String comicId) async {
    final response = await _dio.get('/comics/$comicId');
    return Comic.fromJson(response.data['data'] ?? response.data);
  }

  Future<List<Chapter>> getComicChapters(String comicId) async {
    final response = await _dio.get('/comics/$comicId/chapters');
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => Chapter.fromJson(json)).toList();
  }

  // ── Chapters / Pages ──────────────────────────────────────

  Future<List<ComicPage>> getChapterPages(String chapterId) async {
    final response = await _dio.get('/chapters/$chapterId/pages');
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => ComicPage.fromJson(json)).toList();
  }

  // ── Bookmarks ─────────────────────────────────────────────

  Future<List<Bookmark>> getMyBookmarks() async {
    final response = await _dio.get('/bookmarks/me');
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => Bookmark.fromJson(json)).toList();
  }

  Future<Bookmark> saveBookmark({
    required String comicId,
    String? lastChapterId,
    int? lastPage,
  }) async {
    final response = await _dio.post('/bookmarks', data: {
      'comic_id': comicId,
      'last_chapter_id': ?lastChapterId,
      'last_page': ?lastPage,
    });
    return Bookmark.fromJson(response.data['data'] ?? response.data);
  }

  Future<void> deleteBookmark(String bookmarkId) async {
    await _dio.delete('/bookmarks/$bookmarkId');
  }

  // ── History ───────────────────────────────────────────────

  Future<List<Bookmark>> getMyHistory() async {
    final response = await _dio.get('/history/me');
    final List<dynamic> data = response.data['data'] ?? response.data;
    return data.map((json) => Bookmark.fromJson(json)).toList();
  }

  Future<void> saveHistory({
    required String comicId,
    String? lastChapterId,
    int? lastPage,
  }) async {
    try {
      await _dio.post('/history', data: {
        'comic_id': comicId,
        'last_chapter_id': ?lastChapterId,
        'last_page': ?lastPage,
      });
    } catch (_) {
      // History is best-effort, never throw
    }
  }

  Future<void> deleteHistory(String historyId) async {
    await _dio.delete('/history/$historyId');
  }

  Future<void> clearHistory() async {
    await _dio.delete('/history');
  }

  Future<List<String>> getReadChapters(String comicId) async {
    try {
      final response = await _dio.get('/history/read-chapters/$comicId');
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      return data.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> markChapterRead(String comicId, String chapterId) async {
    try {
      await _dio.post('/history/read-chapters', data: {
        'comic_id': comicId,
        'chapter_id': chapterId,
      });
    } catch (_) {
      // Best-effort
    }
  }

  // ── User ──────────────────────────────────────────────────

  Future<User> getProfile() async {
    final response = await _dio.get('/auth/me');
    return User.fromJson(response.data['data'] ?? response.data);
  }

  Future<User> updateAvatar(String? avatarUrl) async {
    final response = await _dio.put('/auth/avatar', data: {
      'avatar_url': avatarUrl,
    });
    return User.fromJson(response.data['data'] ?? response.data);
  }

  Future<User> uploadAvatarBase64(String imageBase64) async {
    final response = await _dio.post('/auth/avatar/upload', data: {
      'image_base64': imageBase64,
    });
    return User.fromJson(response.data['data'] ?? response.data);
  }
}
