import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comic.dart';

typedef PopularFallback = Future<List<Comic>> Function(String? format);
typedef ComicLookup = Future<Comic> Function(String id);

/// Manual pins precede rolling weekly ranks; exclusions also apply to suggestions.
List<Comic> selectPopularComics({
  required List<Comic> pinned,
  required List<Comic> ranked,
  required List<Comic> suggestions,
  required Set<String> excluded,
  String? format,
  int limit = 7,
}) {
  final seen = <String>{};
  return [...pinned, ...ranked, ...suggestions]
      .where(
        (comic) =>
            !excluded.contains(comic.id) &&
            (format == null ||
                comic.format.toLowerCase() == format.toLowerCase()) &&
            seen.add(comic.id),
      )
      .take(limit)
      .toList();
}

class PopularRepository {
  final SupabaseClient client;
  final PopularFallback fallback;
  final ComicLookup lookup;
  PopularRepository(
    this.client, {
    required this.fallback,
    required this.lookup,
  });

  Future<List<Comic>> load({String? format}) async {
    final rows = await client.rpc(
      'weekly_popular_comics',
      params: {'p_format': format},
    );
    final overrides = await client
        .from('comics')
        .select()
        .or('popular_override.not.is.null,is_popular.eq.true')
        .order('updated_at', ascending: false);
    final hidden = await client.from('hidden_comics').select('comic_id');
    final excluded = <String>{
      for (final row in hidden) row['comic_id'] as String,
      for (final row in overrides)
        if (row['popular_override'] == false) row['id'] as String,
    };
    final pinned = overrides
        .where(
          (row) =>
              row['popular_override'] == true ||
              (row['popular_override'] == null && row['is_popular'] == true),
        )
        .map(Comic.fromSupabase)
        .toList();
    final ranked = <Comic>[];
    final ids = (rows as List)
        .map((row) => row['comic_id'] as String)
        .where((id) => !excluded.contains(id))
        .toList();
    // Resolve only enough ranked posters for seven slots, with bounded concurrency.
    for (
      var offset = 0;
      offset < ids.length && ranked.length < 7;
      offset += 7
    ) {
      final batch = await Future.wait(
        ids.skip(offset).take(7).map((id) async {
          try {
            return await lookup(id);
          } catch (_) {
            return null;
          }
        }),
      );
      ranked.addAll(
        batch.whereType<Comic>().where(
          (comic) =>
              format == null ||
              comic.format.toLowerCase() == format.toLowerCase(),
        ),
      );
    }
    var selected = selectPopularComics(
      pinned: pinned,
      ranked: ranked,
      suggestions: const [],
      excluded: excluded,
      format: format,
    );
    if (selected.length < 7) {
      try {
        selected = selectPopularComics(
          pinned: pinned,
          ranked: ranked,
          suggestions: await fallback(format),
          excluded: excluded,
          format: format,
        );
      } catch (_) {
        if (selected.isEmpty) rethrow;
      }
    }
    return selected;
  }
}

/// Stable random installation ID, not email/device hardware information.
class ReaderIdentity {
  final FlutterSecureStorage storage;
  Future<String>? _id;
  ReaderIdentity({this.storage = const FlutterSecureStorage()});
  Future<String> getId() => _id ??= _load().catchError((Object error) {
    _id = null;
    throw error;
  });
  Future<String> _load() async {
    final saved = await storage.read(key: 'weekly_reader_id_v1');
    if (saved != null) return saved;
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id =
        '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await storage.write(key: 'weekly_reader_id_v1', value: id);
    return id;
  }
}

class ReadPopularityTracker {
  final SupabaseClient client;
  final Future<String> Function() guestId;
  final DateTime Function() now;
  final Map<String, DateTime> _sent = {};
  final Map<String, Future<bool>> _pending = {};
  ReadPopularityTracker(
    this.client, {
    required this.guestId,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<bool> record(Comic comic) {
    final key = jsonEncode([client.auth.currentUser?.id, comic.id]);
    final last = _sent[key];
    if (last != null && now().difference(last) < const Duration(hours: 1)) {
      return Future.value(false);
    }
    return _pending[key] ??= _send(comic, key).whenComplete(() {
      _pending.remove(key);
    });
  }

  Future<bool> _send(Comic comic, String key) async {
    try {
      await client.rpc(
        'record_comic_read',
        params: {
          'p_comic_id': comic.id,
          'p_format': comic.format,
          'p_guest_id': await guestId(),
        },
      );
      _sent[key] = now();
      return true;
    } catch (_) {
      // Analytics must never interrupt the reader; allow a later page to retry.
      return false;
    }
  }
}
