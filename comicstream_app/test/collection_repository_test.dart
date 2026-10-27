import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:comicstream_app/data/models/collection.dart';
import 'package:comicstream_app/data/repositories/collection_repository.dart';

Map<String, dynamic> fixture() => {
  'id': 'collection-1',
  'user_id': 'user-1',
  'name': 'Favorit',
  'is_public': true,
  'created_at': '2026-10-18T00:00:00Z',
  'updated_at': '2026-10-18T00:00:00Z',
  'collection_items': [],
};

void main() {
  SupabaseCollectionRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        final response = await handler(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          request: request,
          headers: response.headers,
        );
      }),
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    return SupabaseCollectionRepository(client);
  }

  test('model valid: parses fields and empty collection items', () {
    final model = Collection.fromJson(fixture());
    expect(model.name, 'Favorit');
    expect(model.isPublic, isTrue);
    expect(model.createdAt, DateTime.utc(2026, 10, 18));
    expect(model.itemCount, 0);
  });

  test('model uses a safe username for empty public profiles', () {
    expect(
      Collection.fromJson({...fixture(), 'username': ''}).username,
      'User',
    );
    expect(
      Collection.fromJson({...fixture(), 'username': '   '}).username,
      'User',
    );
  });

  test('model invalid: missing id and blank name are rejected', () {
    expect(
      () => Collection.fromJson(fixture()..remove('id')),
      throwsFormatException,
    );
    expect(
      () => Collection.fromJson({...fixture(), 'name': '  '}),
      throwsFormatException,
    );
  });

  test('API success: GET includes public filter and returns model', () async {
    final repo = repository((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/rest/v1/collections');
      expect(request.url.queryParameters['is_public'], 'eq.true');
      return http.Response(
        jsonEncode([fixture()]),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final result = await repo.getPublicCollections();
    expect(result.single.id, 'collection-1');
  });

  test(
    'empty data: successful empty API response returns empty list',
    () async {
      final repo = repository((_) async => http.Response('[]', 200));
      expect(await repo.getPublicCollections(), isEmpty);
    },
  );

  test(
    'HTTP failure: 403 propagates instead of becoming empty success',
    () async {
      final repo = repository(
        (_) async => http.Response(
          jsonEncode({'message': 'Access denied', 'code': '42501'}),
          403,
        ),
      );
      await expectLater(
        repo.getPublicCollections(),
        throwsA(isA<PostgrestException>()),
      );
    },
  );

  test(
    'malformed JSON: invalid success body propagates a parsing failure',
    () async {
      final repo = repository(
        (_) async => http.Response(
          '{invalid-json',
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      await expectLater(
        repo.getPublicCollections(),
        throwsA(
          isA<PostgrestException>()
              .having((error) => error.code, 'HTTP status', '200')
              .having(
                (error) => error.message,
                'invalid response',
                '{invalid-json',
              ),
        ),
      );
    },
  );

  test(
    'backend write: create posts trimmed values and returns saved model',
    () async {
      final repo = repository((request) async {
        expect(request.method, 'POST');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['name'], 'Favorit');
        expect(body['user_id'], 'user-1');
        expect(body['is_public'], isFalse);
        return http.Response(
          jsonEncode({...fixture(), 'is_public': false}),
          201,
        );
      });
      final saved = await repo.create(
        userId: 'user-1',
        name: '  Favorit  ',
        isPublic: false,
      );
      expect(saved.isPublic, isFalse);
    },
  );

  test('retry: a second request succeeds after a failed request', () async {
    var calls = 0;
    final repo = repository(
      (_) async => ++calls == 1
          ? http.Response('{"message":"Denied","code":"42501"}', 403)
          : http.Response(jsonEncode([fixture()]), 200),
    );
    await expectLater(
      repo.getPublicCollections(),
      throwsA(isA<PostgrestException>()),
    );
    expect((await repo.getPublicCollections()).single.name, 'Favorit');
    expect(calls, 2);
  });
}
