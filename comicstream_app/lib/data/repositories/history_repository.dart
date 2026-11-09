import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/bookmark.dart';
import '../models/history_identity.dart';

/// All requests are scoped to the caller; database RLS remains authoritative.
class HistoryRepository {
  final SupabaseClient _client;
  HistoryRepository(this._client);
  Future<void> _pending = Future.value();

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<List<Bookmark>> _read(String userId) async {
    final items = <Bookmark>[];
    const batch = 500;
    for (var offset = 0; ; offset += batch) {
      final rows = await _client
          .from('history')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false)
          .order('id')
          .range(offset, offset + batch - 1);
      items.addAll(rows.map(Bookmark.fromJson));
      if (rows.length < batch) break;
    }
    return items;
  }

  Future<List<Bookmark>> read(String userId) async =>
      HistoryIdentity.merge(await _read(userId));

  Future<void> save(
    String userId, {
    required String comicId,
    String? chapterId,
    int page = 1,
    String? title,
    String? coverUrl,
  }) => _serial(() async {
    final rows = await _read(userId);
    final sameSource = rows.where((row) => row.comicId == comicId).firstOrNull;
    final target = Bookmark(
      id: '',
      userId: userId,
      comicId: comicId,
      comicTitle: title?.trim().isNotEmpty == true
          ? title
          : sameSource?.comicTitle,
      createdAt: DateTime.now(),
    );
    final matches = rows
        .where((row) => HistoryIdentity.sameComic(row, target))
        .toList();
    final existing = sameSource ?? matches.firstOrNull;
    final data = {
      'user_id': userId,
      'comic_id': comicId,
      'last_chapter_id': chapterId,
      'last_page': page,
      'comic_title': target.comicTitle ?? existing?.comicTitle,
      'comic_cover_url': coverUrl?.trim().isNotEmpty == true
          ? coverUrl
          : existing?.comicCoverUrl,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    // Update the existing history row when switching source. Never attach an old
    // source chapter ID to a new source comic: both come from this reading event.
    final Map<String, dynamic> saved;
    if (existing == null) {
      saved = await _client
          .from('history')
          .upsert(data, onConflict: 'user_id,comic_id')
          .select()
          .single();
    } else {
      saved = await _client
          .from('history')
          .update(data)
          .eq('user_id', userId)
          .eq('id', existing.id)
          .select()
          .single();
    }
    final duplicates = matches
        .where((row) => row.id != saved['id'])
        .map((row) => row.id)
        .toList();
    // Only clean up duplicates after the updated progress is confirmed saved.
    if (duplicates.isNotEmpty) {
      await _client
          .from('history')
          .delete()
          .eq('user_id', userId)
          .inFilter('id', duplicates);
    }
  });

  Future<void> delete(String userId, String historyId) => _serial(() async {
    final rows = await _read(userId);
    final selected = rows.where((row) => row.id == historyId).firstOrNull;
    if (selected == null) return;
    final ids = rows
        .where((row) => HistoryIdentity.sameComic(row, selected))
        .map((row) => row.id)
        .toList();
    await _client
        .from('history')
        .delete()
        .eq('user_id', userId)
        .inFilter('id', ids);
  });

  Future<void> clear(String userId) => _serial(() async {
    await _client.from('history').delete().eq('user_id', userId);
  });
}
