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
import '../models/history_identity.dart';
import '../models/comment.dart';
import '../services/api_service.dart';
import '../services/shinigami_api_service.dart';
import '../services/auth_service.dart';
import '../repositories/comic_caption_repository.dart';
import '../repositories/popular_repository.dart';

// ── Service Providers ───────────────────────────────────────

final mangaApiServiceProvider = Provider<MangaApiService>(
  (ref) => MangaApiService(),
);
final shinigamiApiServiceProvider = Provider<ShinigamiApiService>(
  (ref) => ShinigamiApiService(),
);
final useShinigamiSourceProvider = Provider<bool>(
  (ref) => ShinigamiApiService.active,
);
final supabaseComicServiceProvider = Provider<SupabaseComicService>(
  (ref) => SupabaseComicService(Supabase.instance.client),
);
final comicCaptionRepositoryProvider = Provider<ComicCaptionRepository>(
  (ref) => ComicCaptionRepository(Supabase.instance.client),
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

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _authService.login(email: email, password: password);
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

  Future<bool> uploadAvatarImage(
    Uint8List bytes, {
    required String extension,
  }) async {
    try {
      final updatedUser = await _authService.uploadAvatarImage(
        bytes,
        extension: extension,
      );
      state = state.copyWith(user: updatedUser, errorMessage: null);
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
    if (msg.contains('Masukkan alamat email yang valid')) {
      return 'Masukkan alamat email yang valid.';
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
  final managed = await db.getAdminManagedComics();
  final apiCatalog = <Comic>[];
  apiCatalog.addAll(
    await ref.watch(popularComicsByFormatProvider(null).future),
  );
  try {
    if (ref.read(useShinigamiSourceProvider)) {
      apiCatalog.addAll(await ref.read(shinigamiApiServiceProvider).list());
    } else {
      apiCatalog.addAll(
        await ref.read(mangaApiServiceProvider).getLatestManga(),
      );
    }
  } catch (_) {
    /* Managed and popular entries remain editable if source fails. */
  }
  final hiddenIds = await db.getHiddenComicIds();
  final managedIds = managed.map((comic) => comic.id).toSet();
  final all = [
    ...managed,
    ...apiCatalog.where((comic) => !managedIds.contains(comic.id)),
  ];
  return {
    for (final comic in all)
      if (!hiddenIds.contains(comic.id)) comic.id: comic,
  }.values.toList();
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

final popularRepositoryProvider = Provider<PopularRepository>((ref) {
  final shinigami = ref.watch(useShinigamiSourceProvider);
  return PopularRepository(
    Supabase.instance.client,
    fallback: (format) => shinigami
        ? ref.read(shinigamiApiServiceProvider).popular(format: format)
        : ref.read(mangaApiServiceProvider).getPopularManga(format: format),
    lookup: (id) => ref.read(comicFromDetailProvider(id).future),
  );
});
final readerIdentityProvider = Provider((ref) => ReaderIdentity());
final readPopularityTrackerProvider = Provider(
  (ref) => ReadPopularityTracker(
    Supabase.instance.client,
    guestId: ref.read(readerIdentityProvider).getId,
  ),
);
final popularComicsByFormatProvider =
    FutureProvider.family<List<Comic>, String?>(
      (ref, format) =>
          ref.watch(popularRepositoryProvider).load(format: format),
    );

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
  final bool _useShinigami;
  bool _isFetching = false;

  HomeComicsNotifier(
    this._liveApi,
    this._dbApi,
    this._format, {
    bool useShinigami = true,
  }) : _useShinigami = useShinigami,
       super(const HomeComicsState(isLoading: true)) {
    loadInitial();
  }

  Future<void> loadInitial() async {
    if (_isFetching) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final batch = await _fetchBatch(const [], 0, 12);
      state = state.copyWith(
        comics: batch.comics,
        currentPage: batch.page,
        isLoading: false,
        hasMore: batch.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isFetching = false;
    }
  }

  Future<void> loadMore({int? targetCount}) async {
    if (_isFetching ||
        state.isLoading ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }
    _isFetching = true;
    state = state.copyWith(isLoadingMore: true);

    try {
      final batch = await _fetchBatch(
        state.comics,
        state.currentPage,
        targetCount ?? ((state.comics.length ~/ 12) + 1) * 12,
      );
      state = state.copyWith(
        comics: batch.comics,
        currentPage: batch.page,
        isLoadingMore: false,
        hasMore: batch.hasMore,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false);
    } finally {
      _isFetching = false;
    }
  }

  Future<({List<Comic> comics, int page, bool hasMore})> _fetchBatch(
    List<Comic> existing,
    int page,
    int targetCount,
  ) async {
    final comics = [...existing];
    final ids = comics.map((comic) => comic.id).toSet();
    var hasMore = true;
    while (comics.length < targetCount && hasMore) {
      final next = await _fetchFromSources(++page);
      final additions = next.where((comic) => ids.add(comic.id)).toList();
      comics.addAll(additions);
      // A short filtered page is not proof that the source is exhausted.
      // Stop on an empty/repeated page so a broken source cannot loop forever.
      hasMore = additions.isNotEmpty;
    }
    return (comics: comics, page: page, hasMore: hasMore);
  }

  Future<List<Comic>> _fetchFromSources(int page) async {
    if (_useShinigami) {
      final shinigami = await ShinigamiApiService().list(
        page: page,
        format: _format,
      );
      return _dbApi.filterHiddenComics(shinigami);
    }
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
        useShinigami: ref.read(useShinigamiSourceProvider),
      );
    });

final latestComicsByFormatProvider =
    FutureProvider.family<List<Comic>, String?>((ref, format) async {
      final homeState = ref.watch(homeComicsProvider(format));
      return homeState.comics;
    });

final comicDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((
  ref,
  endpoint,
) async {
  if (ShinigamiApiService.active && endpoint.startsWith('shngm:')) {
    return ref.read(shinigamiApiServiceProvider).detail(endpoint);
  }
  if (ShinigamiApiService.active && endpoint.startsWith('shngm:')) {
    return ref.read(shinigamiApiServiceProvider).detail(endpoint);
  }
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
    // "Comic not found" adalah expected untuk komik dari API eksternal — jangan print
    final msg = e.toString();
    if (!msg.contains('Comic not found in Supabase')) {
      debugPrint('[Supabase] no managed detail for $endpoint: $e');
    }
  }

  try {
    final detail = await liveApi.getComicDetail(endpoint);
    if (detail['comic'] is Comic) {
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
    if (managedDetail == null) rethrow;
  }

  if (managedDetail != null) {
    return dbApi.filterHiddenChapters(managedDetail);
  }
  return dbApi.filterHiddenChapters(await dbApi.getComicDetail(endpoint));
});

/// Provider khusus untuk data Comic dari detail
final comicFromDetailProvider = FutureProvider.family<Comic, String>((
  ref,
  endpoint,
) async {
  final detail = await ref.watch(comicDetailProvider(endpoint).future);
  final comic = detail['comic'] as Comic;
  try {
    final caption = await ref
        .read(comicCaptionRepositoryProvider)
        .getCaption(endpoint);
    return caption == null ? comic : comic.withSynopsis(caption);
  } catch (error) {
    debugPrint('[Comic caption] Override unavailable for $endpoint: $error');
    return comic;
  }
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
  if (ShinigamiApiService.active && chapterEndpoint.startsWith('shngm:')) {
    return ref.read(shinigamiApiServiceProvider).pages(chapterEndpoint);
  }
  final liveApi = ref.read(mangaApiServiceProvider);
  final dbApi = ref.read(supabaseComicServiceProvider);
  Object? sourceError;
  try {
    final pages = await liveApi.getChapterPages(chapterEndpoint);
    if (pages.isNotEmpty) return pages;
  } catch (e) {
    sourceError = e;
    debugPrint('[Live API Fallback] chapterPages: $e');
  }
  try {
    final backup = await dbApi.getChapterPages(chapterEndpoint);
    if (backup.isNotEmpty || sourceError == null) return backup;
  } catch (_) {
    if (sourceError == null) rethrow;
  }
  throw sourceError;
});

// ── Bookmarks Provider (Supabase) ────────────────────────────

class BookmarksNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final SupabaseAuthService _authService;
  final bool _isAuthenticated;
  int _loadVersion = 0;

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
    final version = ++_loadVersion;
    state = const AsyncValue.loading();
    try {
      final bookmarks = await _authService.getMyBookmarks();
      if (mounted && version == _loadVersion) {
        state = AsyncValue.data(bookmarks);
      }
    } catch (e, st) {
      if (mounted && version == _loadVersion) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> addBookmark(
    String comicId, {
    String? title,
    String? coverUrl,
  }) async {
    if (!_isAuthenticated) throw Exception('Masuk untuk menyimpan bookmark');
    final bookmark = await _authService.saveBookmark(
      comicId: comicId,
      comicTitle: title,
      comicCoverUrl: coverUrl,
    );
    if (!mounted) return;
    _loadVersion++;
    state = AsyncValue.data([
      bookmark,
      ...?state.valueOrNull?.where((item) => item.comicId != comicId),
    ]);
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
    if (!_isAuthenticated) throw Exception('Masuk untuk menghapus bookmark');
    await _authService.deleteBookmarkByComicId(comicId);
    if (!mounted) return;
    _loadVersion++;
    state = AsyncValue.data([
      ...?state.valueOrNull?.where((item) => item.comicId != comicId),
    ]);
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
      // Recreate only when the account changes, not on profile/progress updates.
      final userId = ref.watch(authProvider.select((state) => state.user?.id));
      return BookmarksNotifier(
        ref.read(supabaseAuthServiceProvider),
        userId != null,
      );
    });

// ── History Provider (Supabase) ───────────────────────────────

class HistoryNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final SupabaseAuthService _authService;
  final bool _isAuthenticated;
  final Future<List<Chapter>> Function(String)? _loadChapters;

  HistoryNotifier(
    this._authService,
    this._isAuthenticated, {
    Future<List<Chapter>> Function(String)? loadChapters,
  }) : _loadChapters = loadChapters,
       super(const AsyncValue.loading()) {
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
      final history = await _resolvedHistory();
      if (mounted) state = AsyncValue.data(history);
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String historyId) async {
    if (!_isAuthenticated) return;
    try {
      await _authService.deleteHistory(historyId);
      await loadHistory();
    } catch (_) {}
  }

  Future<List<Bookmark>> _resolvedHistory() async {
    final history = HistoryIdentity.merge(await _authService.getMyHistory());
    return Future.wait(
      history.map((item) async {
        if (item.chapterLabel != null || _loadChapters == null) return item;
        try {
          final chapters = await _loadChapters(item.comicId);
          for (final chapter in chapters) {
            if (chapter.id == item.lastChapterId) {
              return item.withChapterNumber(chapter.chapterNumber);
            }
          }
        } catch (_) {
          // Preserve the history entry if its source is unavailable.
        }
        return item;
      }),
    );
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
      final history = await _resolvedHistory();
      if (mounted) state = AsyncValue.data(history);
    } catch (_) {}
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<Bookmark>>>((ref) {
      final userId = ref.watch(authProvider.select((state) => state.user?.id));
      return HistoryNotifier(
        ref.read(supabaseAuthServiceProvider),
        userId != null,
        loadChapters: (id) => ref.read(comicChaptersProvider(id).future),
      );
    });

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

const _unchangedSearchValue = Object();
final exploreFormatProvider = StateProvider<String?>((ref) => null);

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
    Object? selectedFormat = _unchangedSearchValue,
    Object? selectedStatus = _unchangedSearchValue,
    String? sortBy,
    int? page,
  }) => SearchState(
    query: query ?? this.query,
    selectedGenres: selectedGenres ?? this.selectedGenres,
    selectedFormat: identical(selectedFormat, _unchangedSearchValue)
        ? this.selectedFormat
        : selectedFormat as String?,
    selectedStatus: identical(selectedStatus, _unchangedSearchValue)
        ? this.selectedStatus
        : selectedStatus as String?,
    sortBy: sortBy ?? this.sortBy,
    page: page ?? this.page,
  );

  bool matches(Comic comic) =>
      (selectedFormat == null ||
          comic.format.toLowerCase() == selectedFormat!.toLowerCase()) &&
      selectedGenres.every(
        (genre) => comic.genres.any(
          (value) =>
              ShinigamiApiService.genreSlug(value) ==
              ShinigamiApiService.genreSlug(genre),
        ),
      ) &&
      (selectedStatus == null ||
          comic.status.toLowerCase() == selectedStatus!.toLowerCase());

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

/// Provider untuk search langsung berdasarkan query — dipakai di sheet
/// tanpa mengubah global searchStateProvider
final searchComicsByQueryProvider = FutureProvider.family<List<Comic>, String>((
  ref,
  query,
) async {
  if (query.trim().length < 2) return [];
  final liveApi = ref.read(mangaApiServiceProvider);
  final dbApi = ref.read(supabaseComicServiceProvider);
  try {
    final result = await liveApi.search(query.trim());
    if (result.isNotEmpty) return result;
    return await dbApi.search(query.trim());
  } catch (_) {
    return await dbApi.search(query.trim());
  }
});

final searchComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final searchState = ref.watch(searchStateProvider);
  final api = ref.read(supabaseComicServiceProvider);
  final liveApi = ref.read(mangaApiServiceProvider);
  List<Comic> list;

  if (ShinigamiApiService.active) {
    list = searchState.query.trim().isNotEmpty
        ? await ref
              .read(shinigamiApiServiceProvider)
              .search(
                searchState.query.trim(),
                page: searchState.page,
                format: searchState.selectedFormat,
                genres: searchState.selectedGenres,
              )
        : await ref
              .read(shinigamiApiServiceProvider)
              .list(
                page: searchState.page,
                sort: searchState.sortBy == 'popular' ? 'popularity' : 'latest',
                format: searchState.selectedFormat,
                genres: searchState.selectedGenres,
              );
    return api.filterHiddenComics(list.where(searchState.matches).toList());
  }

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
  final ShinigamiApiService? _shinigami;
  SearchState _filter = const SearchState();
  int _generation = 0;

  BrowseNotifier(this._liveApi, this._dbApi, {ShinigamiApiService? shinigami})
    : _shinigami = shinigami,
      super(const BrowseState());

  Future<void> init({
    String? format,
    String sortBy = 'latest',
    Set<String> genres = const {},
    String? status,
    String query = '',
  }) async {
    _filter = SearchState(
      selectedFormat: format,
      sortBy: sortBy,
      selectedGenres: Set.unmodifiable(genres),
      selectedStatus: status,
      query: query,
    );
    final generation = ++_generation;
    state = const BrowseState();
    await _fetchPage(1, generation, _filter);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    await _fetchPage(state.currentPage + 1, _generation, _filter);
  }

  Future<ComicCatalogPage> _sourcePage(int page, SearchState filter) async {
    if (_shinigami != null) {
      return _shinigami.catalogPage(
        page: page,
        format: filter.selectedFormat,
        genres: filter.selectedGenres,
        query: filter.query,
        sort: filter.sortBy == 'popular' ? 'popularity' : 'latest',
      );
    }
    List<Comic> comics;
    try {
      if (filter.query.isNotEmpty) {
        comics = page == 1 ? await _liveApi.search(filter.query) : [];
      } else if (filter.selectedGenres.isNotEmpty) {
        comics = await _liveApi.getByGenre(
          ShinigamiApiService.genreSlug(filter.selectedGenres.first),
          page: page,
        );
      } else if (filter.sortBy == 'popular') {
        comics = await _liveApi.getPopularManga(
          page: page,
          format: filter.selectedFormat,
        );
      } else {
        comics = await _liveApi.getLatestManga(
          page: page,
          format: filter.selectedFormat,
        );
      }
    } catch (_) {
      if (filter.query.isNotEmpty) {
        comics = page == 1 ? await _dbApi.search(filter.query) : [];
      } else if (filter.selectedGenres.isNotEmpty) {
        comics = await _dbApi.getByGenre(
          filter.selectedGenres.first,
          page: page,
        );
      } else {
        comics = await _dbApi.getLatestManga(page: page);
      }
    }
    return ComicCatalogPage(
      comics,
      hasMore: filter.query.isEmpty && comics.length >= 8,
    );
  }

  Future<void> _fetchPage(int page, int generation, SearchState filter) async {
    state = state.copyWith(isLoading: true);
    final collected = <Comic>[];
    var lastPage = page - 1;
    var hasMore = true;
    try {
      // Bound extra requests when hidden items or combined filters leave a page sparse.
      for (var attempt = 0; attempt < 4; attempt++) {
        final result = await _sourcePage(lastPage + 1, filter);
        if (!mounted || generation != _generation) return;
        var items = result.comics;
        if (lastPage == 0) {
          items = await _dbApi.mergeAdminComics(
            items,
            format: filter.selectedFormat,
            genres: filter.selectedGenres.toList(),
            popularOnly: filter.sortBy == 'popular',
            searchQuery: filter.query.isEmpty ? null : filter.query,
          );
        }
        items = await _dbApi.filterHiddenComics(items);
        if (!mounted || generation != _generation) return;
        collected.addAll(items.where(filter.matches));
        lastPage++;
        hasMore = result.hasMore;
        if (!hasMore || collected.length >= 12) break;
      }
      final byId = {
        for (final comic in [...state.comics, ...collected]) comic.id: comic,
      };
      final comics = byId.values.toList();
      if (filter.sortBy == 'title') {
        comics.sort((a, b) => a.title.compareTo(b.title));
      }
      if (filter.sortBy == 'rating') {
        comics.sort((a, b) => b.rating.compareTo(a.rating));
      }
      state = BrowseState(
        comics: comics,
        currentPage: lastPage,
        hasMore: hasMore,
      );
    } catch (_) {
      if (mounted && generation == _generation) {
        state = state.copyWith(
          isLoading: false,
          error: 'Gagal memuat komik. Coba lagi.',
        );
      }
    }
  }
}

final browseComicsProvider = StateNotifierProvider<BrowseNotifier, BrowseState>(
  (ref) => BrowseNotifier(
    ref.read(mangaApiServiceProvider),
    ref.read(supabaseComicServiceProvider),
    shinigami: ref.watch(useShinigamiSourceProvider)
        ? ref.read(shinigamiApiServiceProvider)
        : null,
  ),
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
    bool isSpoiler = false,
  }) async {
    if (content.trim().isEmpty) return;
    try {
      await _client.from('comic_comments').insert({
        'comic_id': _comicId,
        'user_id': userId,
        'username': username,
        'avatar_url': avatarUrl,
        'content': content.trim(),
        'is_spoiler': isSpoiler,
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
        isSpoiler: isSpoiler,
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
    bool isSpoiler = false,
  }) async {
    if (content.trim().isEmpty) return;
    try {
      await _client.from('chapter_comments').insert({
        'chapter_id': _chapterId,
        'user_id': userId,
        'username': username,
        'avatar_url': avatarUrl,
        'content': content.trim(),
        'is_spoiler': isSpoiler,
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
        isSpoiler: isSpoiler,
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
