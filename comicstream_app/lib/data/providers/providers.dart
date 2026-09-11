import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/comic.dart';
import '../models/chapter.dart';
import '../models/comic_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/bookmark.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ── Service Providers ───────────────────────────────────────

final mangaApiServiceProvider = Provider<MangaApiService>((ref) => MangaApiService());
final supabaseComicServiceProvider = Provider<SupabaseComicService>((ref) => SupabaseComicService(Supabase.instance.client));
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) => SupabaseAuthService());

// ── Auth State ──────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final user = _authService.getCurrentUser();
    if (user != null) {
      // Ambil profil lengkap (termasuk avatar & username dari profiles table)
      final fullUser = await _authService.fetchFullProfile();
      state = AuthState(
        status: AuthStatus.authenticated,
        user: fullUser ?? user,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.login(username: username, password: password);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.register(
        username: username,
        email: email,
        password: password,
      );
      state = AuthState(status: AuthStatus.authenticated, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: _parseError(e),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> updateProfile({String? username, String? avatarUrl}) async {
    try {
      final updatedUser = await _authService.updateProfile(
        username: username,
        avatarUrl: avatarUrl,
      );
      if (updatedUser != null) {
        state = state.copyWith(user: updatedUser);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
      return false;
    }
  }

  Future<bool> updateAvatar(String? avatarUrl) async {
    try {
      final updatedUser = await _authService.updateAvatar(avatarUrl);
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
      return false;
    }
  }

  // uploadAvatarBase64 dihapus karena Supabase Storage lebih cocok
  // untuk tahap ini cukup simpan URL avatar saja

  String _parseError(dynamic e) {
    final msg = e.toString();
    if (msg.contains('Username') || msg.contains('tidak ditemukan')) {
      return 'Username atau email tidak ditemukan. Pastikan akun sudah terdaftar atau cek kembali ejaan username.';
    }
    if (msg.contains('Password salah') ||
        msg.contains('Invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('invalid_grant')) {
      return 'Password salah. Silakan periksa kembali password kamu.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Email belum diverifikasi. Silakan cek kotak masuk email atau matikan "Confirm email" di Supabase Dashboard.';
    }
    if (msg.contains('User already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user_already_exists')) {
      return 'Email atau username ini sudah terdaftar. Silakan langsung masuk.';
    }
    if (msg.contains('over_email_send_rate_limit') || msg.contains('rate limit exceeded')) {
      return 'Batas pengiriman email tercapai. Silakan coba beberapa menit lagi.';
    }
    if (msg.contains('Password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (msg.contains('connection') || msg.contains('SocketException') || msg.contains('Failed host lookup')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    }
    return msg
        .replaceAll('Exception: ', '')
        .replaceAll('AuthApiException: ', '')
        .replaceAll('AuthException: ', '');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(supabaseAuthServiceProvider));
});

// ── Comics Providers (Supabase) ─────────────────────────────

final latestComicsProvider = FutureProvider<List<Comic>>((ref) async {
  return ref.read(supabaseComicServiceProvider).getLatestManga(page: 1);
});

final popularComicsProvider = FutureProvider<List<Comic>>((ref) async {
  return ref.read(supabaseComicServiceProvider).getPopularManga(page: 1);
});

final recommendedComicsProvider = FutureProvider<List<Comic>>((ref) async {
  return ref.read(supabaseComicServiceProvider).getRecommended();
});

final manhwaProvider = FutureProvider<List<Comic>>((ref) async {
  return ref.read(supabaseComicServiceProvider).getManhwa(page: 1);
});

final manhuaProvider = FutureProvider<List<Comic>>((ref) async {
  return ref.read(supabaseComicServiceProvider).getManhua(page: 1);
});

final popularComicsByFormatProvider =
    FutureProvider.family<List<Comic>, String?>((ref, format) async {
  final liveApi = ref.read(mangaApiServiceProvider);
  final dbApi = ref.read(supabaseComicServiceProvider);

  try {
    List<Comic> list;
    if (format == 'Manhwa') {
      list = await liveApi.getManhwa(page: 1);
    } else if (format == 'Manhua') {
      list = await liveApi.getManhua(page: 1);
    } else {
      list = await liveApi.getPopularManga(page: 1);
    }
    if (list.isNotEmpty) return list;
  } catch (e) {
    debugPrint('[Live API Fallback] popularComics: $e');
  }

  // Fallback to Supabase Database
  if (format == 'Manhwa') {
    return dbApi.getManhwa(page: 1);
  } else if (format == 'Manhua') {
    return dbApi.getManhua(page: 1);
  } else if (format == 'Manga') {
    return dbApi.getManga(page: 1);
  } else {
    return dbApi.getPopularManga(page: 1);
  }
});

final latestComicsByFormatProvider =
    FutureProvider.family<List<Comic>, String?>((ref, format) async {
  final liveApi = ref.read(mangaApiServiceProvider);
  final dbApi = ref.read(supabaseComicServiceProvider);

  try {
    List<Comic> list;
    if (format == 'Manhwa') {
      list = await liveApi.getManhwa(page: 1);
    } else if (format == 'Manhua') {
      list = await liveApi.getManhua(page: 1);
    } else {
      list = await liveApi.getLatestManga(page: 1);
    }
    if (list.isNotEmpty) return list;
  } catch (e) {
    debugPrint('[Live API Fallback] latestComics: $e');
  }

  // Fallback to Supabase Database
  if (format == 'Manhwa') {
    return dbApi.getManhwa(page: 1);
  } else if (format == 'Manhua') {
    return dbApi.getManhua(page: 1);
  } else if (format == 'Manga') {
    return dbApi.getManga(page: 1);
  } else {
    return dbApi.getLatestManga(page: 1);
  }
});

final comicDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, endpoint) async {
  final liveApi = ref.read(mangaApiServiceProvider);
  final dbApi = ref.read(supabaseComicServiceProvider);

  try {
    final detail = await liveApi.getComicDetail(endpoint);
    if (detail.isNotEmpty && (detail['chapters'] as List?)?.isNotEmpty == true) {
      return detail;
    }
  } catch (e) {
    debugPrint('[Live API Fallback] comicDetail: $e');
  }

  return dbApi.getComicDetail(endpoint);
});

/// Provider khusus untuk data Comic dari detail
final comicFromDetailProvider = FutureProvider.family<Comic, String>((ref, endpoint) async {
  final detail = await ref.watch(comicDetailProvider(endpoint).future);
  return detail['comic'] as Comic;
});

/// Provider khusus untuk chapters dari detail
final comicChaptersProvider = FutureProvider.family<List<Chapter>, String>((ref, endpoint) async {
  final detail = await ref.watch(comicDetailProvider(endpoint).future);
  return detail['chapters'] as List<Chapter>;
});

// ── Chapter Pages ─────────────────────────────────────────

final chapterPagesProvider = FutureProvider.family<List<ComicPage>, String>((ref, chapterEndpoint) async {
  final liveApi = ref.read(mangaApiServiceProvider);
  final dbApi = ref.read(supabaseComicServiceProvider);

  try {
    final pages = await liveApi.getChapterPages(chapterEndpoint);
    if (pages.isNotEmpty) return pages;
  } catch (e) {
    debugPrint('[Live API Fallback] chapterPages: $e');
  }

  return dbApi.getChapterPages(chapterEndpoint);
});

// ── Bookmarks Provider (Supabase) ────────────────────────────

class BookmarksNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final SupabaseAuthService _authService;
  final bool _isAuthenticated;

  BookmarksNotifier(this._authService, this._isAuthenticated)
      : super(const AsyncValue.loading()) {
    if (_isAuthenticated) {
      loadBookmarks();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadBookmarks() async {
    if (!_isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final bookmarks = await _authService.getMyBookmarks();
      state = AsyncValue.data(bookmarks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBookmark(String comicId, {String? title, String? coverUrl}) async {
    if (!_isAuthenticated) return;
    try {
      await _authService.saveBookmark(
        comicId: comicId,
        comicTitle: title,
        comicCoverUrl: coverUrl,
      );
      await loadBookmarks();
    } catch (_) {}
  }

  Future<void> updateProgress(String comicId, String chapterId, int page, {
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    if (!_isAuthenticated) return;
    try {
      await _authService.saveHistory(
        comicId: comicId,
        lastChapterId: chapterId,
        lastPage: page,
        comicTitle: comicTitle,
        comicCoverUrl: comicCoverUrl,
      );
    } catch (_) {}
  }

  Future<void> removeBookmarkByComicId(String comicId) async {
    if (!_isAuthenticated) return;
    try {
      await _authService.deleteBookmarkByComicId(comicId);
      await loadBookmarks();
    } catch (_) {}
  }

  bool isBookmarked(String comicId) {
    return state.whenOrNull(
      data: (bookmarks) => bookmarks.any((b) => b.comicId == comicId),
    ) ?? false;
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<List<Bookmark>>>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth = authState.status == AuthStatus.authenticated;
  return BookmarksNotifier(ref.watch(supabaseAuthServiceProvider), isAuth);
});

// ── History Provider (Supabase) ───────────────────────────────

class HistoryNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final SupabaseAuthService _authService;
  final bool _isAuthenticated;

  HistoryNotifier(this._authService, this._isAuthenticated)
      : super(const AsyncValue.loading()) {
    if (_isAuthenticated) {
      loadHistory();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadHistory() async {
    if (!_isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final history = await _authService.getMyHistory();
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String historyId) async {
    if (!_isAuthenticated) return;
    try {
      await _authService.deleteHistory(historyId);
      await loadHistory();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    if (!_isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      await _authService.clearHistory();
      state = const AsyncValue.data([]);
    } catch (_) {}
  }

  Future<void> recordProgress({
    required String comicId,
    String? chapterId,
    int page = 1,
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    if (!_isAuthenticated) return;
    try {
      await _authService.saveHistory(
        comicId: comicId,
        lastChapterId: chapterId,
        lastPage: page,
        comicTitle: comicTitle,
        comicCoverUrl: comicCoverUrl,
      );
      final history = await _authService.getMyHistory();
      state = AsyncValue.data(history);
    } catch (_) {}
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<Bookmark>>>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth = authState.status == AuthStatus.authenticated;
  return HistoryNotifier(ref.watch(supabaseAuthServiceProvider), isAuth);
});

// ── Read Chapters Provider ────────────────────────────────────

class ReadChaptersNotifier extends StateNotifier<Set<String>> {
  final SupabaseAuthService _authService;
  final String _comicId;
  static const _storage = FlutterSecureStorage();

  ReadChaptersNotifier(this._authService, this._comicId) : super({}) {
    _load();
  }

  String get _storageKey => 'read_chapters_$_comicId';

  Future<void> _load() async {
    final localSet = <String>{};
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        localSet.addAll(list.map((e) => e.toString()));
      }
    } catch (_) {}

    if (localSet.isNotEmpty) {
      state = Set.from(localSet);
    }

    // Sync dengan Supabase
    try {
      final remoteList = await _authService.getReadChapters(_comicId);
      if (remoteList.isNotEmpty) {
        localSet.addAll(remoteList);
        state = Set.from(localSet);
        await _saveLocal(localSet);
      }
    } catch (_) {}
  }

  Future<void> _saveLocal(Set<String> set) async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(set.toList()),
      );
    } catch (_) {}
  }

  Future<void> markAsRead(String chapterId) async {
    if (state.contains(chapterId)) return;
    final updated = Set<String>.from(state)..add(chapterId);
    state = updated;
    await _saveLocal(updated);
    try {
      await _authService.markChapterRead(_comicId, chapterId);
    } catch (_) {}
  }

  bool isRead(String chapterId) => state.contains(chapterId);
}

final readChaptersProvider =
    StateNotifierProvider.family<ReadChaptersNotifier, Set<String>, String>(
        (ref, comicId) {
  return ReadChaptersNotifier(ref.watch(supabaseAuthServiceProvider), comicId);
});

// ── Search State ─────────────────────────────────────────────

class SearchState {
  final String query;
  final Set<String> selectedGenres;
  final String? selectedFormat;
  final String? selectedStatus;
  final String sortBy;
  final int page;

  const SearchState({
    this.query = '',
    this.selectedGenres = const {},
    this.selectedFormat,
    this.selectedStatus,
    this.sortBy = 'latest',
    this.page = 1,
  });

  SearchState copyWith({
    String? query,
    Set<String>? selectedGenres,
    String? selectedFormat,
    String? selectedStatus,
    String? sortBy,
    int? page,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      selectedGenres.isNotEmpty ||
      selectedFormat != null ||
      selectedStatus != null ||
      sortBy != 'latest';
}

final searchStateProvider = StateProvider<SearchState>((ref) => const SearchState());

final searchComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final searchState = ref.watch(searchStateProvider);
  final api = ref.read(supabaseComicServiceProvider);
  List<Comic> list;

  if (searchState.query.trim().isNotEmpty) {
    list = await api.search(searchState.query.trim());
  } else if (searchState.selectedGenres.isNotEmpty) {
    final genre = searchState.selectedGenres.first;
    list = await api.getByGenre(genre, page: searchState.page);
  } else if (searchState.selectedFormat == 'Manhwa') {
    list = await api.getManhwa(page: searchState.page);
  } else if (searchState.selectedFormat == 'Manhua') {
    list = await api.getManhua(page: searchState.page);
  } else if (searchState.selectedFormat == 'Manga') {
    list = await api.getManga(page: searchState.page);
  } else if (searchState.sortBy == 'popular') {
    list = await api.getPopularManga(page: searchState.page);
  } else {
    list = await api.getLatestManga(page: searchState.page);
  }

  // Filter format secara lokal jika query aktif
  if (searchState.selectedFormat != null && searchState.query.trim().isNotEmpty) {
    list = list.where((c) => c.format.toLowerCase() == searchState.selectedFormat!.toLowerCase()).toList();
  }

  // Filter status jika ada
  if (searchState.selectedStatus != null) {
    list = list.where((c) => c.status.toLowerCase().contains(searchState.selectedStatus!.toLowerCase())).toList();
  }

  // Sort
  if (searchState.sortBy == 'title') {
    list.sort((a, b) => a.title.compareTo(b.title));
  } else if (searchState.sortBy == 'rating') {
    list.sort((a, b) => b.rating.compareTo(a.rating));
  }

  return list;
});

// ── UI States ────────────────────────────────────────────────

final bookmarkTabProvider = StateProvider<int>((ref) => 0);
final isDarkModeProvider = StateProvider<bool>((ref) => true);
