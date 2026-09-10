import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';
import '../models/comic.dart';
import '../models/chapter.dart';
import '../models/comic_page.dart';
import '../models/bookmark.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ── Service Providers ───────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Auth State ──────────────────────────────────────────────

enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.token,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final AuthService _authService;

  AuthNotifier(this._apiService, this._authService) : super(const AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await _authService.getToken();
    final user = await _authService.getUser();
    if (token != null && user != null) {
      _apiService.setAuthToken(token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final response = await _apiService.login(email: email, password: password);
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _authService.saveToken(token);
      await _authService.saveUser(user);
      _apiService.setAuthToken(token);

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
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
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
      );
      final token = response['token'] as String;
      final userData = response['user'] as Map<String, dynamic>;
      final user = User.fromJson(userData);

      await _authService.saveToken(token);
      await _authService.saveUser(user);
      _apiService.setAuthToken(token);

      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        token: token,
      );
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
    await _authService.clearAll();
    _apiService.setAuthToken(null);
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<bool> updateAvatar(String? avatarUrl) async {
    try {
      final updatedUser = await _apiService.updateAvatar(avatarUrl);
      await _authService.saveUser(updatedUser);
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
      return false;
    }
  }

  Future<bool> uploadAvatarBase64(String imageBase64) async {
    try {
      final updatedUser = await _apiService.uploadAvatarBase64(imageBase64);
      await _authService.saveUser(updatedUser);
      state = state.copyWith(user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: _parseError(e));
      return false;
    }
  }

  String _parseError(dynamic e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('DioException')) {
        if (msg.contains('401')) return 'Email atau password salah';
        if (msg.contains('409')) return 'Email sudah terdaftar';
        if (msg.contains('connection')) return 'Tidak dapat terhubung ke server';
      }
      return msg.replaceAll('Exception: ', '');
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiServiceProvider),
    ref.watch(authServiceProvider),
  );
});

// ── Comics Providers ────────────────────────────────────────

final comicsProvider = FutureProvider.family<List<Comic>, Map<String, String?>>((ref, params) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComics(
    search: params['search'],
    genre: params['genre'],
    format: params['format'],
    status: params['status'],
    sortBy: params['sortBy'],
  );
});

final popularComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComics(sortBy: 'popular', limit: 7);
});

final latestComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComics(sortBy: 'latest', limit: 20);
});

final popularComicsByFormatProvider = FutureProvider.family<List<Comic>, String?>((ref, format) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComics(
    sortBy: 'popular',
    format: format,
    limit: 7,
  );
});

final latestComicsByFormatProvider = FutureProvider.family<List<Comic>, String?>((ref, format) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComics(
    sortBy: 'latest',
    format: format,
    limit: 20,
  );
});

final comicDetailProvider = FutureProvider.family<Comic, String>((ref, comicId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComicDetail(comicId);
});

final comicChaptersProvider = FutureProvider.family<List<Chapter>, String>((ref, comicId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComicChapters(comicId);
});

// ── Chapter Pages Provider ──────────────────────────────────

final chapterPagesProvider = FutureProvider.family<List<ComicPage>, String>((ref, chapterId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getChapterPages(chapterId);
});

// ── Bookmarks Provider ──────────────────────────────────────

class BookmarksNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final ApiService _apiService;
  final bool _isAuthenticated;

  BookmarksNotifier(this._apiService, this._isAuthenticated)
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
      final bookmarks = await _apiService.getMyBookmarks();
      state = AsyncValue.data(bookmarks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBookmark(String comicId) async {
    if (!_isAuthenticated) return;
    try {
      await _apiService.saveBookmark(comicId: comicId);
      await loadBookmarks();
    } catch (_) {
      // Optionally handle error
    }
  }

  Future<void> updateProgress(String comicId, String chapterId, int page) async {
    if (!_isAuthenticated) return;
    try {
      // Progress is saved to HISTORY (not bookmarks — user must explicitly bookmark)
      await _apiService.saveHistory(
        comicId: comicId,
        lastChapterId: chapterId,
        lastPage: page,
      );
    } catch (_) {
      // Silently fail for progress updates
    }
  }

  Future<void> removeBookmark(String bookmarkId) async {
    if (!_isAuthenticated) return;
    try {
      await _apiService.deleteBookmark(bookmarkId);
      await loadBookmarks();
    } catch (_) {
      // Optionally handle error
    }
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
  return BookmarksNotifier(ref.watch(apiServiceProvider), isAuth);
});

// ── History Provider ─────────────────────────────────────────

class HistoryNotifier extends StateNotifier<AsyncValue<List<Bookmark>>> {
  final ApiService _apiService;
  final bool _isAuthenticated;

  HistoryNotifier(this._apiService, this._isAuthenticated)
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
      final history = await _apiService.getMyHistory();
      state = AsyncValue.data(history);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteEntry(String historyId) async {
    if (!_isAuthenticated) return;
    try {
      await _apiService.deleteHistory(historyId);
      await loadHistory();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    if (!_isAuthenticated) {
      state = const AsyncValue.data([]);
      return;
    }
    try {
      await _apiService.clearHistory();
      state = const AsyncValue.data([]);
    } catch (_) {}
  }

  /// Immediately records reading progress and refreshes history state
  Future<void> recordProgress({
    required String comicId,
    String? chapterId,
    int page = 1,
  }) async {
    if (!_isAuthenticated) return;
    try {
      await _apiService.saveHistory(
        comicId: comicId,
        lastChapterId: chapterId,
        lastPage: page,
      );
      final history = await _apiService.getMyHistory();
      state = AsyncValue.data(history);
    } catch (_) {}
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, AsyncValue<List<Bookmark>>>((ref) {
  final authState = ref.watch(authProvider);
  final isAuth = authState.status == AuthStatus.authenticated;
  return HistoryNotifier(ref.watch(apiServiceProvider), isAuth);
});

// ── Read Chapters Provider (per comic) ───────────────────────

class ReadChaptersNotifier extends StateNotifier<Set<String>> {
  final ApiService _apiService;
  final String _comicId;
  static const _storage = FlutterSecureStorage();

  ReadChaptersNotifier(this._apiService, this._comicId) : super({}) {
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

    // Sync with backend
    try {
      final remoteList = await _apiService.getReadChapters(_comicId);
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
      await _apiService.markChapterRead(_comicId, chapterId);
    } catch (_) {}
  }

  bool isRead(String chapterId) => state.contains(chapterId);
}

final readChaptersProvider =
    StateNotifierProvider.family<ReadChaptersNotifier, Set<String>, String>(
        (ref, comicId) {
  return ReadChaptersNotifier(ref.watch(apiServiceProvider), comicId);
});

// ── Search State ────────────────────────────────────────────

class SearchState {
  final String query;
  final Set<String> selectedGenres;
  final String? selectedFormat;
  final String? selectedStatus;
  final String sortBy;

  const SearchState({
    this.query = '',
    this.selectedGenres = const {},
    this.selectedFormat,
    this.selectedStatus,
    this.sortBy = 'latest',
  });

  SearchState copyWith({
    String? query,
    Set<String>? selectedGenres,
    String? selectedFormat,
    String? selectedStatus,
    String? sortBy,
  }) {
    return SearchState(
      query: query ?? this.query,
      selectedGenres: selectedGenres ?? this.selectedGenres,
      selectedFormat: selectedFormat ?? this.selectedFormat,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  bool get hasActiveFilters =>
      query.isNotEmpty ||
      selectedGenres.isNotEmpty ||
      selectedFormat != null ||
      selectedStatus != null ||
      sortBy != 'latest';

  Map<String, String?> toParams() {
    return {
      'search': query.isEmpty ? null : query,
      'genre': selectedGenres.isEmpty ? null : selectedGenres.join(','),
      'format': selectedFormat,
      'status': selectedStatus,
      'sortBy': sortBy,
    };
  }
}

final searchStateProvider = StateProvider<SearchState>((ref) => const SearchState());

final searchComicsProvider = FutureProvider<List<Comic>>((ref) async {
  final searchState = ref.watch(searchStateProvider);
  final apiService = ref.read(apiServiceProvider);
  return apiService.getComics(
    search: searchState.query.isEmpty ? null : searchState.query,
    genre: searchState.selectedGenres.isEmpty ? null : searchState.selectedGenres.join(','),
    format: searchState.selectedFormat,
    status: searchState.selectedStatus,
    sortBy: searchState.sortBy,
  );
});

// ── UI States: Bookmark Tab & Theme Mode ────────────────────

final bookmarkTabProvider = StateProvider<int>((ref) => 0);

final isDarkModeProvider = StateProvider<bool>((ref) => true);
