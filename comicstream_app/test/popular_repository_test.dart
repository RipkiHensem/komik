import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/data/repositories/popular_repository.dart';

Comic comic(String id, {String format = 'Manhwa'}) =>
    Comic(id: id, title: id, coverUrl: '', format: format);
SupabaseClient client(Future<http.Response> Function(http.Request) handler) =>
    SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(handler),
    );

void main() {
  test(
    'seven slots: manual pins first, weekly ranking next, suggestions last',
    () {
      final selected = selectPopularComics(
        pinned: [comic('pin')],
        ranked: [
          comic('most-read'),
          comic('pin'),
          comic('hidden'),
          comic('next'),
        ],
        suggestions: List.generate(10, (i) => comic('suggestion-$i')),
        excluded: {'hidden'},
      );
      expect(selected.length, 7);
      expect(selected.take(3).map((c) => c.id), ['pin', 'most-read', 'next']);
      expect(selected.map((c) => c.id).toSet().length, 7);
    },
  );
  test('manual exclusions and format apply to every source', () {
    final selected = selectPopularComics(
      pinned: [comic('excluded')],
      ranked: [comic('manga', format: 'Manga')],
      suggestions: [comic('wanted'), comic('excluded')],
      excluded: {'excluded'},
      format: 'Manhwa',
    );
    expect(selected.single.id, 'wanted');
  });
  test(
    'repository consumes server weekly ranking and explicit admin exclusion',
    () async {
      final db = client((r) async {
        Object data = [];
        if (r.url.path.endsWith('weekly_popular_comics')) {
          expect(jsonDecode(r.body)['p_format'], 'Manhwa');
          data = [
            {'comic_id': 'read-first', 'weekly_readers': 30},
            {'comic_id': 'removed', 'weekly_readers': 20},
          ];
        } else if (r.url.path.endsWith('/comics')) {
          data = [
            {
              'id': 'manual',
              'title': 'Manual',
              'format': 'Manhwa',
              'is_popular': true,
            },
            {'id': 'removed', 'title': 'Removed', 'popular_override': false},
          ];
        }
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json'},
          request: r,
        );
      });
      final repo = PopularRepository(
        db,
        fallback: (_) async => [comic('suggestion')],
        lookup: (id) async => comic(id),
      );
      expect((await repo.load(format: 'Manhwa')).map((c) => c.id), [
        'manual',
        'read-first',
        'suggestion',
      ]);
    },
  );
  test(
    'same reader sends one concurrent record and no repeated count within an hour',
    () async {
      var calls = 0;
      final gate = Completer<void>();
      final db = client((r) async {
        calls++;
        await gate.future;
        return http.Response('', 204, request: r);
      });
      var now = DateTime.utc(2026, 11, 9);
      final tracker = ReadPopularityTracker(
        db,
        guestId: () async => '11111111-1111-4111-8111-111111111111',
        now: () => now,
      );
      final first = tracker.record(comic('one'));
      final second = tracker.record(comic('one'));
      gate.complete();
      await Future.wait([first, second]);
      await tracker.record(comic('one'));
      expect(calls, 1);
      now = now.add(const Duration(hours: 2));
      await tracker.record(comic('one'));
      expect(calls, 2);
    },
  );
  test('failed analytics do not throw or suppress the next retry', () async {
    var calls = 0;
    final db = client((r) async {
      calls++;
      return calls == 1
          ? http.Response('{"message":"unavailable"}', 400, request: r)
          : http.Response('', 204, request: r);
    });
    final tracker = ReadPopularityTracker(
      db,
      guestId: () async => '11111111-1111-4111-8111-111111111111',
    );
    expect(await tracker.record(comic('one')), isFalse);
    expect(await tracker.record(comic('one')), isTrue);
    expect(calls, 2);
  });
}
