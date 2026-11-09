import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmptyCatalog extends SupabaseComicService {
  EmptyCatalog(super.client);
  int lookups = 0;

  @override
  Future<Map<String, dynamic>> getComicDetail(String endpoint) async {
    lookups++;
    throw Exception('Comic not found in Supabase');
  }

  @override
  Future<Map<String, dynamic>> filterHiddenChapters(
    Map<String, dynamic> detail,
  ) async => detail;
}

void main() {
  test('cover prefers current detail poster over stale list thumbnail', () {
    const poster = 'https://thumbnail.komiku.to/new/youngest.jpg?w=500';
    const thumbnail =
        'https://thumbnail.komiku.org/new/youngest.jpg?resize=450,235&quality=60';
    expect(Comic.coverCandidates(posterUrl: poster, thumbnailUrl: thumbnail), [
      'https://thumbnail.komiku.to/new/youngest.jpg',
      'https://thumbnail.komiku.org/new/youngest.jpg',
    ]);
  });

  test('cover fallback is finite, unique and ignores missing URLs', () {
    expect(Comic.coverCandidates(posterUrl: '', thumbnailUrl: ''), isEmpty);
    expect(
      Comic.coverCandidates(
        posterUrl: 'https://example.com/a.jpg',
        thumbnailUrl: 'https://example.com/a.jpg',
      ),
      ['https://example.com/a.jpg'],
    );
  });

  test(
    'all fallback covers avoid server-side crops including standalone crop',
    () {
      final urls = Comic.coverCandidates(
        thumbnailUrl:
            'https://thumbnail.komiku.org/eleceed.jpg?crop=1&fit=cover&h=235&w=450',
      );
      expect(urls, isNotEmpty);
      for (final url in urls) {
        final params = Uri.parse(url).queryParameters;
        expect(params.keys, isNot(contains('resize')));
        expect(params.keys, isNot(contains('crop')));
        expect(params.keys, isNot(contains('fit')));
        expect(params.keys, isNot(contains('h')));
      }
      expect(urls, contains('https://thumbnail.komiku.to/eleceed.jpg'));
    },
  );

  ProviderContainer setup(MangaApiService api, EmptyCatalog db) {
    final container = ProviderContainer(
      overrides: [
        mangaApiServiceProvider.overrideWithValue(api),
        supabaseComicServiceProvider.overrideWithValue(db),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  EmptyCatalog catalog() {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(client.dispose);
    return EmptyCatalog(client);
  }

  test('valid comic with no chapters still opens its detail', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          handler.resolve(
            Response(
              requestOptions: request,
              statusCode: 200,
              data: {
                'manga_endpoint': 'gods-cuisine',
                'title': 'God’s Cuisine',
                'chapter': [],
              },
            ),
          );
        },
      ),
    );
    final db = catalog();
    final container = setup(MangaApiService(client: dio), db);
    final result = await container.read(
      comicDetailProvider('gods-cuisine').future,
    );
    expect((result['comic'] as Comic).title, 'God’s Cuisine');
    expect(result['chapters'], isEmpty);
    expect(db.lookups, 1);
  });

  test(
    'upstream 404 is kept as unavailable instead of database error',
    () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            handler.reject(
              DioException(
                requestOptions: request,
                type: DioExceptionType.badResponse,
                response: Response(
                  requestOptions: request,
                  statusCode: 500,
                  data: {'message': 'Failed to fetch source - HTTP 404'},
                ),
              ),
            );
          },
        ),
      );
      final container = setup(MangaApiService(client: dio), catalog());
      await expectLater(
        container.read(comicDetailProvider('eleceed').future),
        throwsA(isA<ComicUnavailableException>()),
      );
    },
  );

  test(
    'retry invalidating detail fetches again after a network failure',
    () async {
      var calls = 0;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            calls++;
            if (calls == 1) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  type: DioExceptionType.connectionTimeout,
                ),
              );
            } else {
              handler.resolve(
                Response(
                  requestOptions: request,
                  statusCode: 200,
                  data: {
                    'title': 'Recovered comic',
                    'manga_endpoint': 'retry',
                    'chapter': [],
                  },
                ),
              );
            }
          },
        ),
      );
      final container = setup(MangaApiService(client: dio), catalog());
      await expectLater(
        container.read(comicDetailProvider('retry').future),
        throwsA(isA<DioException>()),
      );
      container.invalidate(comicDetailProvider('retry'));
      final result = await container.read(comicDetailProvider('retry').future);
      expect((result['comic'] as Comic).title, 'Recovered comic');
      expect(calls, 2);
    },
  );

  test('cover uses original file instead of cached thumbnail transforms', () {
    final result = Uri.parse(
      Comic.originalCoverUrl(
        'https://thumbnail.komiku.org/uploads/eleceed.jpg?resize=450,235&quality=60',
      ),
    );
    expect(result.path, '/uploads/eleceed.jpg');
    expect(result.hasQuery, isFalse);
  });

  test('cover preserves unrelated signed image URLs', () {
    for (final url in [
      'https://example.com/cover.jpg?resize=400,600&token=signature',
    ]) {
      expect(Comic.originalCoverUrl(url), url);
    }
  });
}
