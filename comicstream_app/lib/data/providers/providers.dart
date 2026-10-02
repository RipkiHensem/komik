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
import '../models/comment.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ── Service Providers ───────────────────────────────────────

final mangaApiServiceProvider = Provider<MangaApiService>(
  (ref) => MangaApiService(),
);
final supabaseComicServiceProvider = Provider<SupabaseComicService>(
  (ref) => SupabaseComicService(Supabase.instance.client),
);
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>(
  (ref) => SupabaseAuthService(),
);

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

  AuthState copyWith({AuthStatus? status, User? user, String? errorMessage}) {
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
      final user = await _authService.login(
        username: username,
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
    if (msg.contains('Invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('invalid_grant')) {
      return 'Email atau password salah. Periksa kembali keduanya.';
    }
    if (msg.contains('Email not confirmed') ||
        msg.contains('email_not_confirmed')) {
      return 'Email belum diverifikasi. Silakan cek kotak masuk email atau matikan "Confirm email" di Supabase Dashboard.';
    }
    if (msg.contains('Password salah')) {
      return 'Password salah. Silakan periksa kembali password kamu.';
    }
    if (msg.contains('User already registered') ||
        msg.contains('already been registered') ||
        msg.contains('user_already_exists')) {
      return 'Email atau username ini sudah terdaftar. Silakan langsung masuk.';
    }
    if (msg.contains('over_email_send_rate_limit') ||
        msg.contains('rate limit exceeded')) {
      return 'Batas pengiriman email tercapai. Silakan coba beberapa menit lagi.';
    }
    if (msg.contains('Password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (msg.contains('connection') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host lookup')) {
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

final isAdminProvider = FutureProvider<bool>((ref) async {
  final email = ref.watch(authProvider.select((state) => state.user?.email));
  if (email == null || email.isEmpty) return false;
  return ref.read(supabaseAuthServiceProvider).isAdmin(email);
});

final adminComicsProvider = FutureProvider<List<Comic>>((ref) async {
  if (!await ref.watch(isAdminProvider.future)) {
    throw Exception('Akun ini tidak memiliki akses admin.');
  }
  final db = ref.read(supabaseComicServiceProvider);
  final api = ref.read(mangaApiServiceProvider);
  final managed = await db.getAdminManagedComics();
  final apiCatalog = <Comic>[];
  try {
    apiCatalog.addAll(await api.getLatestManga(page: 1));
    apiCatalog.addAll(await api.getPopularManga(page: 1));
  } catch (error) {
    debugPrint('[Admin] API catalog unavailable: $error');
  }
  final hiddenIds = await db.getHiddenComicIds();
  final managedIds = managed.map((comic) => comic.id).toSet();
  final all = [
    ...managed,
    ...apiCatalog.where((comic) => !managedIds.contains(comic.id)),
  ];
  return all.where((comic) => !hiddenIds.contains(comic.id)).toList();
});

// ── Comics Providers (Supabase) ─────────────────────────────

final latestComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final db = ref.read(supabaseComicServiceProvider);
  return db.filterHiddenComics(await db.getLatestManga(page: 1));
});

final popularComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final db = ref.read(supabaseComicServiceProvider);
  return db.filterHiddenComics(await db.getPopularManga(page: 1));
});

final recommendedComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final db = ref.read(supabaseComicServiceProvider);
  return db.filterHiddenComics(await db.getRecommended());
});

final manhwaProvider = FutureProvider<List<Comic>>((ref) async {
  final db = ref.read(supabaseComicServiceProvider);
  return db.filterHiddenComics(await db.getManhwa(page: 1));
});

final manhuaProvider = FutureProvider<List<Comic>>((ref) async {
  final db = ref.read(supabaseComicServiceProvider);
  return db.filterHiddenComics(await db.getManhua(page: 1));
});

final popularComicsByFormatProvider =
    FutureProvider.family<List<Comic>, String?>((ref, format) async {
      final liveApi = ref.read(mangaApiServiceProvider);
      final dbApi = ref.read(supabaseComicServiceProvider);

      try {
        List<Comic> list = await liveApi.getPopularManga(
          page: 1,
          format: format,
        );
        if (format != null) {
          final f = format.toLowerCase();
          list = list.where((c) => c.format.toLowerCase() == f).toList();
        }
        if (list.isNotEmpty) {
          return dbApi.mergeAdminComics(
            list,
            format: format,
            popularOnly: true,
          );
        }
      } catch (e) {
        debugPrint('[Live API Fallback] popularComics: $e');
      }

      // Fallback to Supabase Database
      List<Comic> fallback;
      if (format == 'Manhwa') {
        fallback = await dbApi.getManhwa(page: 1);
      } else if (format == 'Manhua') {
        fallback = await dbApi.getManhua(page: 1);
      } else if (format == 'Manga') {
        fallback = await dbApi.getManga(page: 1);
      } else {
        fallback = await dbApi.getPopularManga(page: 1);
      }
      return dbApi.filterHiddenComics(fallback);
    });

// ── Home Comics State with Pagination ────────────────────────

class HomeComicsState {
  final List<Comic> comics;
  final int currentPage;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const HomeComicsState({
    this.comics = const [],
    this.currentPage = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  HomeComicsState copyWith({
    List<Comic>? comics,
    int? currentPage,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) {
    return HomeComicsState(
      comics: comics ?? this.comics,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class HomeComicsNotifier extends StateNotifier<HomeComicsState> {
  final MangaApiService _liveApi;
  final SupabaseComicService _dbApi;
  final String? _format;
  bool _isFetching = false;

  HomeComicsNotifier(this._liveApi, this._dbApi, this._format)
    : super(const HomeComicsState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final page1 = await _fetchFromSources(1);
      List<Comic> combined = List.from(page1);

      // Fetch page 2 directly on init for rich initial view (20+ comics)
      if (page1.isNotEmpty) {
        try {
          final page2 = await _fetchFromSources(2);
          final existingIds = page1.map((c) => c.id).toSet();
          for (final c in page2) {
            if (!existingIds.contains(c.id)) {
              combined.add(c);
            }
          }
        } catch (_) {}
      }

      state = state.copyWith(
        comics: combined,
        currentPage: combined.length > page1.length ? 2 : 1,
        isLoading: false,
        hasMore: page1.length >= 8,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_isFetching ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final newComics = await _fetchFromSources(nextPage);
      if (newComics.isEmpty) {
        state = state.copyWith(isLoadingMore: false, hasMore: false);
      } else {
        final existingIds = state.comics.map((c) => c.id).toSet();
        final filteredNew = newComics
            .where((c) => !existingIds.contains(c.id))
            .toList();
        state = state.copyWith(
          comics: [...state.comics, ...filteredNew],
          currentPage: nextPage,
          isLoadingMore: false,
          hasMore: newComics.length >= 8,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    } finally {
      _isFetching = false;
    }
  }

  Future<List<Comic>> _fetchFromSources(int page) async {
    List<Comic> raw = [];
    bool fromLive = false;
    try {
      raw = await _liveApi.getLatestManga(page: page, format: _format);
      fromLive = true;
    } catch (e) {
      debugPrint('[HomeComics] Live API error: $e');
    }

    if (!fromLive || raw.isEmpty) {
      if (_format == 'Manhwa') {
        raw = await _dbApi.getManhwa(page: page);
      } else if (_format == 'Manhua') {
        raw = await _dbApi.getManhua(page: page);
      } else if (_format == 'Manga') {
        raw = await _dbApi.getManga(page: page);
      } else {
        raw = await _dbApi.getLatestManga(page: page);
      }
    } else {
      raw = await _dbApi.mergeAdminComics(raw, format: _format);
    }

    // Strict format guarantee
    final selectedFmt = _format;
    if (selectedFmt != null) {
      final f = selectedFmt.toLowerCase();
      raw = raw.where((c) => c.format.toLowerCase() == f).toList();
    }
    return _dbApi.filterHiddenComics(raw);
  }
}

final homeComicsProvider =
    StateNotifierProvider.family<HomeComicsNotifier, HomeComicsState, String?>((
      ref,
      format,
    ) {
      return HomeComicsNotifier(
        ref.read(mangaApiServiceProvider),
        ref.read(supabaseComicServiceProvider),
        format,
      );
    });

final latestComicsByFormatProvider =
    FutureProvider.family<List<Comic>, String?>((ref, format) async {
      final homeState = ref.watch(homeComicsProvider(format));
      return homeState.comics;
    });

final comicDetailProvider = FutureProvider.family<Map<String, dynamic>, String>(
  (ref, endpoint) async {
    final liveApi = ref.read(mangaApiServiceProvider);
    final dbApi = ref.read(supabaseComicServiceProvider);

    // Admin-managed rows override metadata and may provide their own chapters.
    Map<String, dynamic>? managedDetail;
    try {
      managedDetail = await dbApi.getComicDetail(endpoint);
      if ((managedDetail['chapters'] as List?)?.isNotEmpty == true) {
        return dbApi.filterHiddenChapters(managedDetail);
      }
    } catch (e) {
      debugPrint('[Supabase] no managed detail for $endpoint: $e');
    }

    try {
      final detail = await liveApi.getComicDetail(endpoint);
      if (detail.isNotEmpty &&
          (detail['chapters'] as List?)?.isNotEmpty == true) {
        if (managedDetail != null) {
          return dbApi.filterHiddenChapters({
            ...detail,
            'comic': managedDetail['comic'],
          });
        }
        return dbApi.filterHiddenChapters(detail);
      }
    } catch (e) {
      debugPrint('[Live API Fallback] comicDetail: $e');
    }

    if (managedDetail != null) {
      return dbApi.filterHiddenChapters(managedDetail);
    }
    return dbApi.filterHiddenChapters(await dbApi.getComicDetail(endpoint));
  },
);

/// Provider khusus untuk data Comic dari detail
final comicFromDetailProvider = FutureProvider.family<Comic, String>((
  ref,
  endpoint,
) async {
  final detail = await ref.watch(comicDetailProvider(endpoint).future);
  return detail['comic'] as Comic;
});

/// Provider khusus untuk chapters dari detail
final comicChaptersProvider = FutureProvider.family<List<Chapter>, String>((
  ref,
  endpoint,
) async {
  final detail = await ref.watch(comicDetailProvider(endpoint).future);
  return detail['chapters'] as List<Chapter>;
});

// ── Chapter Pages ─────────────────────────────────────────

final chapterPagesProvider = FutureProvider.family<List<ComicPage>, String>((
  ref,
  chapterEndpoint,
) async {
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

  Future<void> addBookmark(
    String comicId, {
    String? title,
    String? coverUrl,
  }) async {
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

  Future<void> updateProgress(
    String comicId,
    String chapterId,
    int page, {
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
        ) ??
        false;
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
      await _storage.write(key: _storageKey, value: jsonEncode(set.toList()));
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
    StateNotifierProvider.family<ReadChaptersNotifier, Set<String>, String>((
      ref,
      comicId,
    ) {
      return ReadChaptersNotifier(
        ref.watch(supabaseAuthServiceProvider),
        comicId,
      );
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

final searchStateProvider = StateProvider<SearchState>(
  (ref) => const SearchState(),
);

final searchComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final searchState = ref.watch(searchStateProvider);
  final api = ref.read(supabaseComicServiceProvider);
  final liveApi = ref.read(mangaApiServiceProvider);
  List<Comic> list;

  if (searchState.query.trim().isNotEmpty) {
    try {
      list = await liveApi.search(searchState.query.trim());
      if (list.isEmpty) {
        list = await api.search(searchState.query.trim());
      }
    } catch (e) {
      debugPrint('[Live API Fallback] search: $e');
      list = await api.search(searchState.query.trim());
    }
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

  list = await api.mergeAdminComics(
    list,
    format: searchState.selectedFormat,
    popularOnly: searchState.sortBy == 'popular',
    searchQuery: searchState.query.trim().isEmpty
        ? null
        : searchState.query.trim(),
    genres: searchState.selectedGenres.take(1).toList(),
  );

  // Filter format secara lokal jika query aktif
  if (searchState.selectedFormat != null &&
      searchState.query.trim().isNotEmpty) {
    list = list
        .where(
          (c) =>
              c.format.toLowerCase() ==
              searchState.selectedFormat!.toLowerCase(),
        )
        .toList();
  }

  // Filter status jika ada
  if (searchState.selectedStatus != null) {
    list = list
        .where(
          (c) => c.status.toLowerCase().contains(
            searchState.selectedStatus!.toLowerCase(),
          ),
        )
        .toList();
  }

  // Sort
  if (searchState.sortBy == 'title') {
    list.sort((a, b) => a.title.compareTo(b.title));
  } else if (searchState.sortBy == 'rating') {
    list.sort((a, b) => b.rating.compareTo(a.rating));
  }

  return list;
});

// ── Browse / Paginated Comics (Infinite Scroll) ──────────────

class BrowseState {
  final List<Comic> comics;
  final int currentPage;
  final bool isLoading;
  final bool hasMore;
  final String? error;

  const BrowseState({
    this.comics = const [],
    this.currentPage = 0,
    this.isLoading = false,
    this.hasMore = true,
    this.error,
  });

  BrowseState copyWith({
    List<Comic>? comics,
    int? currentPage,
    bool? isLoading,
    bool? hasMore,
    String? error,
  }) {
    return BrowseState(
      comics: comics ?? this.comics,
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class BrowseNotifier extends StateNotifier<BrowseState> {
  final MangaApiService _liveApi;
  final SupabaseComicService _dbApi;
  String? _format;
  String _sortBy = 'latest';
  bool _isFetching = false;

  BrowseNotifier(this._liveApi, this._dbApi) : super(const BrowseState());

  /// Reset dan mulai dari halaman 1 (dipanggil saat filter berubah)
  Future<void> init({String? format, String sortBy = 'latest'}) async {
    if (_isFetching) return;
    _format = format;
    _sortBy = sortBy;
    state = const BrowseState(isLoading: true, hasMore: true);
    await _fetchPage(1);
  }

  /// Muat halaman berikutnya (dipanggil saat scroll ke bawah)
  Future<void> loadMore() async {
    if (_isFetching || state.isLoading || !state.hasMore) return;
    await _fetchPage(state.currentPage + 1);
  }

  Future<void> _fetchPage(int page) async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      List<Comic> rawComics = [];
      bool fromLive = false;

      // 1. Coba live API (Edge Function → scrape komiku.org)
      try {
        if (_sortBy == 'popular') {
          rawComics = await _liveApi.getPopularManga(
            page: page,
            format: _format,
          );
        } else {
          rawComics = await _liveApi.getLatestManga(
            page: page,
            format: _format,
          );
        }
        fromLive = true;
        debugPrint(
          '[Browse] Live API page $page: ${rawComics.length} raw ($_format/$_sortBy)',
        );
      } catch (e) {
        debugPrint('[Browse] Live API error: $e — fallback ke Supabase');
      }

      // 2. Fallback ke Supabase DB
      if (!fromLive || rawComics.isEmpty) {
        if (_format == 'Manhwa') {
          rawComics = await _dbApi.getManhwa(page: page);
        } else if (_format == 'Manhua') {
          rawComics = await _dbApi.getManhua(page: page);
        } else if (_format == 'Manga') {
          rawComics = await _dbApi.getManga(page: page);
        } else if (_sortBy == 'popular') {
          rawComics = await _dbApi.getPopularManga(page: page);
        } else {
          rawComics = await _dbApi.getLatestManga(page: page);
        }
        debugPrint('[Browse] Supabase page $page: ${rawComics.length} raw');
      } else if (page == 1) {
        rawComics = await _dbApi.mergeAdminComics(
          rawComics,
          format: _format,
          popularOnly: _sortBy == 'popular',
        );
      }

      // ── Filter ketat berdasarkan format yang dipilih ───────
      // Ini memastikan tidak ada campur antar negara
      rawComics = await _dbApi.filterHiddenComics(rawComics);
      final List<Comic> newComics;
      final int rawCount = rawComics.length;
      if (_format != null) {
        final f = _format!.toLowerCase();
        newComics = rawComics
            .where((c) => c.format.toLowerCase() == f)
            .toList();
        debugPrint(
          '[Browse] Setelah filter "$_format": ${newComics.length}/$rawCount komik',
        );
      } else {
        newComics = rawComics;
      }

      final existing = page == 1 ? <Comic>[] : List<Comic>.from(state.comics);
      final all = [...existing, ...newComics];

      // hasMore: gunakan rawCount (sebelum filter) untuk menentukan apakah
      // masih ada halaman berikutnya di sumber data
      final bool hasMore = rawCount >= 8;

      state = state.copyWith(
        comics: all,
        currentPage: page,
        isLoading: false,
        hasMore: hasMore,
      );

      // Auto-fetch halaman berikutnya jika hasil filter terlalu sedikit
      // (misalnya halaman berisi 20 komik tapi setelah filter hanya dapat 2)
      if (hasMore && newComics.length < 5 && _format != null) {
        _isFetching = false;
        await _fetchPage(page + 1);
        return;
      }
    } catch (e, st) {
      debugPrint('[Browse] Error: $e\n$st');
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }
}

final browseComicsProvider = StateNotifierProvider<BrowseNotifier, BrowseState>(
  (ref) {
    return BrowseNotifier(
      ref.read(mangaApiServiceProvider),
      ref.read(supabaseComicServiceProvider),
    );
  },
);

// ── UI States ────────────────────────────────────────────────

final bookmarkTabProvider = StateProvider<int>((ref) => 0);
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// ── Comments Provider ─────────────────────────────────────────

class CommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final SupabaseClient _client;
  final String _comicId;

  CommentsNotifier(this._client, this._comicId)
    : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('comic_comments')
          .select()
          .eq('comic_id', _comicId)
          .order('created_at', ascending: false)
          .limit(100);
      final list = (response as List<dynamic>)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e) {
      // Table belum ada atau error lain → tampilkan kosong
      debugPrint('[Comments] load error: $e');
      state = const AsyncValue.data([]);
    }
  }

  Future<void> postComment({
    required String userId,
    required String username,
    String? avatarUrl,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    try {
      await _client.from('comic_comments').insert({
        'comic_id': _comicId,
        'user_id': userId,
        'username': username,
        'avatar_url': avatarUrl,
        'content': content.trim(),
      });
      await loadComments();
    } catch (e) {
      debugPrint('[Comments] post error: $e');
      // Optimistic local insert so user sees their comment immediately
      final optimistic = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        comicId: _comicId,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        content: content.trim(),
        createdAt: DateTime.now(),
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([optimistic, ...current]);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('comic_comments').delete().eq('id', commentId);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((c) => c.id != commentId).toList());
    } catch (e) {
      debugPrint('[Comments] delete error: $e');
    }
  }
}

final commentsProvider =
    StateNotifierProvider.family<
      CommentsNotifier,
      AsyncValue<List<Comment>>,
      String
    >((ref, comicId) {
      return CommentsNotifier(Supabase.instance.client, comicId);
    });

// ── Chapter Comments Provider ─────────────────────────────────────────

class ChapterCommentsNotifier extends StateNotifier<AsyncValue<List<Comment>>> {
  final SupabaseClient _client;
  final String _chapterId;

  ChapterCommentsNotifier(this._client, this._chapterId)
    : super(const AsyncValue.loading()) {
    loadComments();
  }

  Future<void> loadComments() async {
    state = const AsyncValue.loading();
    try {
      final response = await _client
          .from('chapter_comments')
          .select()
          .eq('chapter_id', _chapterId)
          .order('created_at', ascending: false)
          .limit(100);

      final list = (response as List<dynamic>)
          .map((e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e) {
      debugPrint('[ChapterComments] load error: $e');
      state = const AsyncValue.data([]);
    }
  }

  Future<void> postComment({
    required String userId,
    required String username,
    String? avatarUrl,
    required String content,
  }) async {
    if (content.trim().isEmpty) return;
    try {
      await _client.from('chapter_comments').insert({
        'chapter_id': _chapterId,
        'user_id': userId,
        'username': username,
        'avatar_url': avatarUrl,
        'content': content.trim(),
      });
      await loadComments();
    } catch (e) {
      debugPrint('[ChapterComments] post error: $e');
      // Optimistic local insert so user sees their comment immediately
      final optimistic = Comment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chapterId: _chapterId,
        userId: userId,
        username: username,
        avatarUrl: avatarUrl,
        content: content.trim(),
        createdAt: DateTime.now(),
      );
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data([optimistic, ...current]);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await _client.from('chapter_comments').delete().eq('id', commentId);
      final current = state.valueOrNull ?? [];
      state = AsyncValue.data(current.where((c) => c.id != commentId).toList());
    } catch (e) {
      debugPrint('[ChapterComments] delete error: $e');
    }
  }
}

final chapterCommentsProvider =
    StateNotifierProvider.family<
      ChapterCommentsNotifier,
      AsyncValue<List<Comment>>,
      String
    >((ref, chapterId) {
      return ChapterCommentsNotifier(Supabase.instance.client, chapterId);
    });
