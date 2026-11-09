import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:comicstream_app/data/models/bookmark.dart';
import 'package:comicstream_app/data/models/history_identity.dart';
import 'package:comicstream_app/data/repositories/history_repository.dart';

Map<String, dynamic> row(
  String id,
  String comicId,
  String? title, {
  String updated = '2026-11-05T10:00:00Z',
  String user = 'reader',
}) => {
  'id': id,
  'user_id': user,
  'comic_id': comicId,
  'comic_title': title,
  'comic_cover_url': 'https://example.test/$id.jpg',
  'last_chapter_id': '$comicId-chapter-12',
  'last_page': 9,
  'created_at': '2026-10-01T00:00:00Z',
  'updated_at': updated,
};

class FakeHistoryApi {
  final List<Map<String, dynamic>> rows;
  final methods = <String>[];
  bool failWrite = false;
  late final SupabaseClient client;
  late final HistoryRepository repository;
  FakeHistoryApi(this.rows) {
    client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        methods.add(request.method);
        final query = request.url.queryParameters;
        final body = request.body.isEmpty ? null : jsonDecode(request.body);
        if (request.method != 'POST') expect(query['user_id'], 'eq.reader');
        final owned = rows.where((row) => row['user_id'] == 'reader').toList();
        Object? data;
        if (request.method == 'GET') {
          data = owned;
        } else if (failWrite) {
          return http.Response(
            jsonEncode({'message': 'offline', 'code': '503'}),
            503,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        } else if (request.method == 'PATCH') {
          final target = owned.singleWhere(
            (row) => query['id'] == 'eq.${row['id']}',
          );
          target.addAll(body as Map<String, dynamic>);
          data = target;
        } else if (request.method == 'POST') {
          expect(body['user_id'], 'reader');
          final target = <String, dynamic>{'id': 'inserted', ...body};
          rows.add(target);
          data = target;
        } else if (request.method == 'DELETE') {
          final ids = query['id']!;
          rows.removeWhere(
            (row) =>
                row['user_id'] == 'reader' && ids.contains(row['id'] as String),
          );
          return http.Response('', 204, request: request);
        }
        return http.Response(
          jsonEncode(data),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    repository = HistoryRepository(client);
  }
}

void main() {
  FakeHistoryApi setup(List<Map<String, dynamic>> rows) {
    final api = FakeHistoryApi(rows);
    addTearDown(api.client.dispose);
    return api;
  }

  test(
    'switching source updates the original history row and route together',
    () async {
      final api = setup([row('old', 'eleceed', 'Komik Eleceed')]);
      await api.repository.save(
        'reader',
        comicId: 'shngm:uuid',
        title: 'Eleceed',
        chapterId: 'shngm:uuid:chapter13',
        page: 4,
        coverUrl: 'https://example.test/new.jpg',
      );
      expect(api.rows, hasLength(1));
      expect(api.rows.single['id'], 'old');
      expect(api.rows.single['comic_id'], 'shngm:uuid');
      expect(api.rows.single['last_chapter_id'], 'shngm:uuid:chapter13');
      expect(api.rows.single['last_page'], 4);
      expect(api.methods, ['GET', 'PATCH']);
    },
  );
  test(
    'existing duplicates display latest reading, not highest chapter or created date',
    () async {
      final api = setup([
        row('old', 'eleceed', 'Komik Eleceed', updated: '2026-11-01T00:00:00Z'),
        row('new', 'shngm:uuid', 'Eleceed'),
      ]);
      final result = await api.repository.read('reader');
      expect(result, hasLength(1));
      expect(result.single.id, 'new');
    },
  );
  test(
    'duplicate cleanup runs after confirmed save and never affects other users',
    () async {
      final api = setup([
        row('old', 'eleceed', 'Komik Eleceed'),
        row('new', 'shngm:uuid', 'Eleceed'),
        row('other', 'eleceed', 'Eleceed', user: 'other'),
      ]);
      await api.repository.save(
        'reader',
        comicId: 'shngm:uuid',
        title: 'Eleceed',
        chapterId: 'shngm:uuid:c',
      );
      expect(api.methods, ['GET', 'PATCH', 'DELETE']);
      expect(api.rows.map((row) => row['id']), ['new', 'other']);
    },
  );
  test('failed write leaves both old progress entries intact', () async {
    final api = setup([
      row('old', 'eleceed', 'Eleceed'),
      row('new', 'shngm:uuid', 'Eleceed'),
    ])..failWrite = true;
    await expectLater(
      api.repository.save('reader', comicId: 'shngm:uuid', title: 'Eleceed'),
      throwsA(isA<PostgrestException>()),
    );
    expect(api.rows, hasLength(2));
    expect(api.methods, isNot(contains('DELETE')));
  });
  test(
    'a metadata-free progress save preserves cached title and cover',
    () async {
      final api = setup([row('new', 'shngm:uuid', 'Eleceed')]);
      await api.repository.save(
        'reader',
        comicId: 'shngm:uuid',
        chapterId: 'shngm:uuid:c',
      );
      expect(api.rows.single['comic_title'], 'Eleceed');
      expect(
        api.rows.single['comic_cover_url'],
        'https://example.test/new.jpg',
      );
    },
  );
  test(
    'deleting a merged history item removes its hidden duplicate too',
    () async {
      final api = setup([
        row('old', 'eleceed', 'Eleceed'),
        row('new', 'shngm:uuid', 'Eleceed'),
      ]);
      await api.repository.delete('reader', 'new');
      expect(api.rows, isEmpty);
    },
  );
  test(
    'identity supports old slugs but keeps sequels, unknowns and accounts apart',
    () {
      Bookmark item(String id, String? title, {String user = 'reader'}) =>
          Bookmark.fromJson(row(id, id, title, user: user));
      expect(
        HistoryIdentity.sameComic(
          item('nano-machine', null),
          item('shngm:1', 'Nano Machine'),
        ),
        isTrue,
      );
      expect(
        HistoryIdentity.sameComic(
          item('eleceed', 'Eleceed'),
          item('shngm:1', 'Eleceed 2'),
        ),
        isFalse,
      );
      expect(
        HistoryIdentity.sameComic(
          item('shngm:1', 'Unknown'),
          item('opaque', 'Unknown'),
        ),
        isFalse,
      );
      expect(
        HistoryIdentity.sameComic(
          item('eleceed', 'Eleceed'),
          item('shngm:1', 'Eleceed', user: 'other'),
        ),
        isFalse,
      );
      expect(
        HistoryIdentity.sameComic(
          item('one', 'Same title'),
          item('two', 'Same title'),
        ),
        isFalse,
      );
    },
  );
}
