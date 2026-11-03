import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists profile edits. UI and input rules stay outside this layer.
class ProfileRepository {
  final SupabaseClient client;
  const ProfileRepository(this.client);

  Future<void> save({
    String? username,
    String? avatarUrl,
    bool updateAvatar = false,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Belum login');
    final updates = <String, dynamic>{
      'id': user.id,
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (username != null && username.trim().isNotEmpty) {
      updates['username'] = username.trim();
    }
    if (updateAvatar || avatarUrl != null) updates['avatar_url'] = avatarUrl;
    await client.from('profiles').upsert(updates);
    if (username != null && username.trim().isNotEmpty) {
      try {
        await client.auth.updateUser(
          UserAttributes(data: {'username': username.trim()}),
        );
      } catch (_) {
        // The profiles table remains the source of truth for the username.
      }
    }
  }
}
