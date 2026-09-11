import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_models;
import '../models/bookmark.dart';

/// Service untuk autentikasi dan data user menggunakan Supabase
class SupabaseAuthService {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Auth ──────────────────────────────────────────────────

  /// Register user baru dengan email & password
  Future<app_models.User> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.user == null) {
      throw Exception('Registrasi gagal. Coba lagi.');
    }

    // Update username di tabel profiles (jika trigger belum otomatis mengisinya)
    try {
      await _client.from('profiles').upsert({
        'id': response.user!.id,
        'username': username,
      });
    } catch (_) {
      // Trigger database handle_new_user() sudah otomatis mengisi profiles
    }

    // Pastikan session langsung aktif agar user otomatis masuk (auto-login)
    if (_client.auth.currentSession == null) {
      try {
        await _client.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } catch (_) {}
    }

    // Ambil data profil (opsional, fallback ke username dari input jika belum siap)
    Map<String, dynamic>? profile;
    try {
      profile = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();
    } catch (_) {}

    return app_models.User.fromSupabase(
      id: response.user!.id,
      email: email,
      username: (profile?['username'] as String?) ?? username,
      avatarUrl: profile?['avatar_url'] as String?,
      createdAt: response.user!.createdAt,
    );
  }

  /// Login dengan username ATAU email & password
  /// - Jika user mengetik email (mengandung @), langsung sign in dengan email.
  /// - Jika user mengetik username, cari email via RPC get_email_by_username.
  Future<app_models.User> login({
    required String username,
    required String password,
  }) async {
    final input = username.trim();
    String? email;

    // 1. Jika input mengandung '@', user memasukkan email langsung
    if (input.contains('@')) {
      email = input;
    } else {
      // 2. Cari email berdasarkan username via RPC function di Supabase
      try {
        final result = await _client.rpc(
          'get_email_by_username',
          params: {'p_username': input},
        );
        if (result != null && result is String && result.trim().isNotEmpty) {
          email = result.trim();
        }
      } catch (_) {}
    }

    // 3. Jika belum ditemukan dan input mengandung '@', tetap coba sebagai email
    if (email == null || email.isEmpty) {
      if (input.contains('@')) {
        email = input;
      } else {
        throw Exception('Username atau email tidak ditemukan. Pastikan akun sudah terdaftar atau periksa kembali ejaannya.');
      }
    }

    // 4. Sign in dengan email dan password ke Supabase Auth
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Password salah. Silakan coba lagi.');
    }

    // 5. Ambil data profil dari tabel profiles
    Map<String, dynamic>? profile;
    try {
      profile = await _client
          .from('profiles')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();
    } catch (_) {}

    final rawUsername = (profile?['username'] as String?)?.trim();
    final metaUsername = (response.user!.userMetadata?['username'] as String?)?.trim();
    final resolvedUsername = (rawUsername != null && rawUsername.isNotEmpty)
        ? rawUsername
        : (metaUsername != null && metaUsername.isNotEmpty)
            ? metaUsername
            : email.split('@').first;

    // Jika username di profiles atau metadata belum tersimpan, otomatis simpan
    if (rawUsername == null || rawUsername.isEmpty) {
      try {
        await _client.from('profiles').upsert({
          'id': response.user!.id,
          'username': resolvedUsername,
          'updated_at': DateTime.now().toIso8601String(),
        });
        await _client.auth.updateUser(
          UserAttributes(data: {'username': resolvedUsername}),
        );
      } catch (_) {}
    }

    return app_models.User.fromSupabase(
      id: response.user!.id,
      email: email,
      username: resolvedUsername,
      avatarUrl: profile?['avatar_url'] as String?,
      createdAt: response.user!.createdAt,
    );
  }


  /// Logout
  Future<void> logout() async {
    await _client.auth.signOut();
  }

  /// Cek sesi yang sedang aktif
  app_models.User? getCurrentUser() {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return null;
    return app_models.User.fromSupabase(
      id: supaUser.id,
      email: supaUser.email ?? '',
      username: supaUser.userMetadata?['username'] as String?,
      createdAt: supaUser.createdAt,
    );
  }

  /// Ambil profil user yang lengkap (termasuk avatar dari tabel profiles)
  Future<app_models.User?> fetchFullProfile() async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return null;

    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', supaUser.id)
        .maybeSingle();

    return app_models.User.fromSupabase(
      id: supaUser.id,
      email: supaUser.email ?? '',
      username: profile?['username'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      createdAt: supaUser.createdAt,
    );
  }

  /// Update profil (username dan/atau avatar URL) di tabel profiles & auth metadata
  Future<app_models.User?> updateProfile({String? username, String? avatarUrl}) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) throw Exception('Belum login');

    final updates = <String, dynamic>{
      'id': supaUser.id,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null && username.trim().isNotEmpty) {
      updates['username'] = username.trim();
    }
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client.from('profiles').upsert(updates);

    if (username != null && username.trim().isNotEmpty) {
      try {
        await _client.auth.updateUser(
          UserAttributes(data: {'username': username.trim()}),
        );
      } catch (_) {}
    }

    return fetchFullProfile();
  }

  /// Update avatar URL di tabel profiles
  Future<app_models.User> updateAvatar(String? avatarUrl) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) throw Exception('Belum login');

    await _client.from('profiles').upsert({
      'id': supaUser.id,
      'avatar_url': avatarUrl,
    });

    return app_models.User.fromSupabase(
      id: supaUser.id,
      email: supaUser.email ?? '',
      avatarUrl: avatarUrl,
      createdAt: supaUser.createdAt,
    );
  }

  // ── Bookmarks (Supabase) ──────────────────────────────────

  /// Ambil semua bookmark milik user yang sedang login
  Future<List<Bookmark>> getMyBookmarks() async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return [];

    final data = await _client
        .from('bookmarks')
        .select()
        .eq('user_id', supaUser.id)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Tambah atau update bookmark
  Future<Bookmark> saveBookmark({
    required String comicId,
    String? lastChapterId,
    int? lastPage,
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) throw Exception('Belum login');

    final data = {
      'user_id': supaUser.id,
      'comic_id': comicId,
      'last_chapter_id': lastChapterId,
      'last_page': lastPage ?? 1,
      'comic_title': comicTitle,
      'comic_cover_url': comicCoverUrl,
    };

    final response = await _client
        .from('bookmarks')
        .upsert(data, onConflict: 'user_id,comic_id')
        .select()
        .single();

    return Bookmark.fromJson(response);
  }

  /// Hapus bookmark berdasarkan comic_id
  Future<void> deleteBookmarkByComicId(String comicId) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return;

    await _client
        .from('bookmarks')
        .delete()
        .eq('user_id', supaUser.id)
        .eq('comic_id', comicId);
  }

  /// Cek apakah sebuah komik sudah dibookmark
  Future<bool> isBookmarked(String comicId) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return false;

    final data = await _client
        .from('bookmarks')
        .select('id')
        .eq('user_id', supaUser.id)
        .eq('comic_id', comicId)
        .maybeSingle();

    return data != null;
  }

  // ── History (Supabase) ────────────────────────────────────

  /// Ambil semua riwayat baca milik user
  Future<List<Bookmark>> getMyHistory() async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return [];

    final data = await _client
        .from('history')
        .select()
        .eq('user_id', supaUser.id)
        .order('updated_at', ascending: false);

    return (data as List)
        .map((json) => Bookmark.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Simpan riwayat baca (upsert)
  Future<void> saveHistory({
    required String comicId,
    String? lastChapterId,
    int? lastPage,
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return;

    await _client.from('history').upsert({
      'user_id': supaUser.id,
      'comic_id': comicId,
      'last_chapter_id': lastChapterId,
      'last_page': lastPage ?? 1,
      'comic_title': comicTitle,
      'comic_cover_url': comicCoverUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,comic_id');
  }

  /// Hapus satu entri riwayat
  Future<void> deleteHistory(String historyId) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return;
    await _client
        .from('history')
        .delete()
        .eq('id', historyId)
        .eq('user_id', supaUser.id);
  }

  /// Hapus semua riwayat baca
  Future<void> clearHistory() async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return;
    await _client.from('history').delete().eq('user_id', supaUser.id);
  }

  // ── Read Chapters (Supabase) ──────────────────────────────

  /// Ambil daftar chapter yang sudah dibaca untuk satu komik
  Future<List<String>> getReadChapters(String comicId) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return [];

    final data = await _client
        .from('read_chapters')
        .select('chapter_id')
        .eq('user_id', supaUser.id)
        .eq('comic_id', comicId);

    return (data as List)
        .map((row) => row['chapter_id'].toString())
        .toList();
  }

  /// Tandai satu chapter sebagai sudah dibaca
  Future<void> markChapterRead(String comicId, String chapterId) async {
    final supaUser = _client.auth.currentUser;
    if (supaUser == null) return;

    await _client.from('read_chapters').upsert({
      'user_id': supaUser.id,
      'comic_id': comicId,
      'chapter_id': chapterId,
    }, onConflict: 'user_id,comic_id,chapter_id');
  }
}
