import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/collection.dart';

/// Sumber data koleksi. UI menerima model tanpa mengetahui query backend.
abstract class CollectionRepository {
  Future<List<Collection>> getMyCollections(String userId);
  Future<List<Collection>> getPublicCollections();
  Future<Collection?> getById(String id);
  Future<void> updateCollection(
    String id, {
    required String name,
    required String description,
    required bool isPublic,
  });
  Future<({int count, bool liked})> getLikes(String id);
  Future<void> setLiked(String id, bool liked);
  Future<Collection> create({
    required String userId,
    required String name,
    String? description,
    bool isPublic = true,
  });
  Future<void> delete(String id);
  Future<void> addComic(
    String collectionId, {
    required String comicId,
    String? comicTitle,
    String? comicCoverUrl,
  });
  Future<void> removeComic(String collectionId, String comicId);
}

class SupabaseCollectionRepository implements CollectionRepository {
  SupabaseCollectionRepository(this._client);

  final SupabaseClient _client;
  static const _selection = '*, collection_items(*)';

  @override
  Future<void> updateCollection(
    String id, {
    required String name,
    required String description,
    required bool isPublic,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Silakan masuk terlebih dahulu');
    if (name.trim().isEmpty) throw ArgumentError('Nama koleksi wajib diisi');
    await _client
        .from('collections')
        .update({
          'name': name.trim(),
          'description': description.trim(),
          'is_public': isPublic,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .eq('user_id', userId)
        .select('id')
        .single();
  }

  @override
  Future<({int count, bool liked})> getLikes(String id) async {
    final count = await _client
        .from('collection_likes')
        .count(CountOption.exact)
        .eq('collection_id', id);
    final userId = _client.auth.currentUser?.id;
    final row = userId == null
        ? null
        : await _client
              .from('collection_likes')
              .select('user_id')
              .eq('collection_id', id)
              .eq('user_id', userId)
              .maybeSingle();
    return (count: count, liked: row != null);
  }

  @override
  Future<void> setLiked(String id, bool liked) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Silakan masuk untuk menyukai koleksi');
    }
    if (liked) {
      await _client
          .from('collection_likes')
          .upsert(
            {'collection_id': id, 'user_id': userId},
            onConflict: 'collection_id,user_id',
            ignoreDuplicates: true,
          );
    } else {
      await _client
          .from('collection_likes')
          .delete()
          .eq('collection_id', id)
          .eq('user_id', userId);
    }
  }

  @override
  Future<List<Collection>> getMyCollections(String userId) async {
    if (userId.isEmpty) return [];
    final rows = await _client
        .from('collections')
        .select(_selection)
        .eq('user_id', userId)
        .order('updated_at', ascending: false);
    return rows.map(Collection.fromJson).toList();
  }

  @override
  Future<List<Collection>> getPublicCollections() async {
    final rows = await _client
        .from('collections')
        .select(_selection)
        .eq('is_public', true)
        .order('updated_at', ascending: false)
        .limit(50);
    return rows.map(Collection.fromJson).toList();
  }

  @override
  Future<Collection?> getById(String id) async {
    final row = await _client
        .from('collections')
        .select(_selection)
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : Collection.fromJson(row);
  }

  @override
  Future<Collection> create({
    required String userId,
    required String name,
    String? description,
    bool isPublic = true,
  }) async {
    final row = await _client
        .from('collections')
        .insert({
          'user_id': userId,
          'name': name.trim(),
          'description': description?.trim(),
          'is_public': isPublic,
        })
        .select()
        .single();
    return Collection.fromJson(row);
  }

  @override
  Future<void> delete(String id) async {
    await _client.from('collections').delete().eq('id', id);
  }

  @override
  Future<void> addComic(
    String collectionId, {
    required String comicId,
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    await _client.from('collection_items').upsert({
      'collection_id': collectionId,
      'comic_id': comicId,
      'comic_title': comicTitle,
      'comic_cover_url': comicCoverUrl,
    }, onConflict: 'collection_id,comic_id');
  }

  @override
  Future<void> removeComic(String collectionId, String comicId) async {
    await _client
        .from('collection_items')
        .delete()
        .eq('collection_id', collectionId)
        .eq('comic_id', comicId);
  }
}
