import 'dart:async';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/data/services/api_service.dart';
import 'home_page_fill_test.dart' show VisibleCatalog;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/services/shinigami_api_service.dart';

Map<String, dynamic> manga(String id, String format, List<String> genres) => {
  'manga_id': id,
  'title': 'Comic $id',
  'cover_image_url': '',
  'taxonomy': {
    'Format': [
      {'name': format},
    ],
    'Genre': genres.map((g) => {'name': g}).toList(),
  },
};

class CatalogSource extends ShinigamiApiService {
  final calls = <SearchState>[];
  final requestedPages = <int>[];
  bool fail = false;
  Completer<ComicCatalogPage>? firstRequest;
  @override
  Future<ComicCatalogPage> catalogPage({
    int page = 1,
    String sort = 'latest',
    String? format,
    Set<String> genres = const {},
    String query = '',
  }) async {
    calls.add(
      SearchState(selectedFormat: format, selectedGenres: genres, query: query),
    );
    requestedPages.add(page);
    if (fail) throw Exception('offline');
    if (calls.length == 1 && firstRequest != null) return firstRequest!.future;
    return ComicCatalogPage([
      for (var i = 0; i < 12; i++)
        Comic(
          id: '$page-$i',
          title: 'Comic $i',
          coverUrl: '',
          format: format ?? 'Manhwa',
          genres: genres.toList(),
        ),
      Comic(
        id: 'wrong-format',
        title: 'Other format',
        coverUrl: '',
        format: 'Manga',
        genres: genres.toList(),
      ),
      Comic(
        id: 'wrong-genre',
        title: 'Other genre',
        coverUrl: '',
        format: format ?? 'Manhwa',
        genres: ['Horror'],
      ),
    ], hasMore: page < 2);
  }
}

void main() {
  test('source genre taxonomy is available in comic list and detail', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final item = manga('one', 'Manhwa', ['Action', 'Fantasy']);
          handler.resolve(
            Response(
              requestOptions: options,
              data: {
                'data': options.path.contains('manga/detail')
                    ? item
                    : options.path.contains('chapter')
                    ? []
                    : [item],
              },
            ),
          );
        },
      ),
    );
    final api = ShinigamiApiService(dio: dio);
    expect((await api.list()).single.genres, ['Action', 'Fantasy']);
    expect((await api.detail('shngm:one'))['comic'].genres, [
      'Action',
      'Fantasy',
    ]);
  });

  test(
    'API sends genre and format together on every page with pagination metadata',
    () async {
      final dio = Dio();
      final requests = <Map<String, dynamic>>[];
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (o, h) {
            requests.add(Map.of(o.queryParameters));
            h.resolve(
              Response(
                requestOptions: o,
                data: {
                  'data': [],
                  'meta': {'total_page': 2},
                },
              ),
            );
          },
        ),
      );
      final api = ShinigamiApiService(dio: dio);
      expect(
        (await api.catalogPage(
          format: 'Manhwa',
          genres: {'School Life'},
          query: 'test',
        )).hasMore,
        isTrue,
      );
      expect(
        (await api.catalogPage(
          page: 2,
          format: 'Manhwa',
          genres: {'School Life'},
        )).hasMore,
        isFalse,
      );
      expect(requests.first['genre'], 'school-life');
      expect(requests.first['q'], 'test');
      expect(requests.last['format'], 'manhwa');
      expect(requests.last['genre'], 'school-life');
      expect(requests.last['page'], 2);
    },
  );

  test('format can be cleared without clearing the selected genre', () {
    const filter = SearchState(
      selectedFormat: 'Manhwa',
      selectedGenres: {'Romance'},
    );
    expect(filter.copyWith(selectedFormat: null).selectedFormat, isNull);
    expect(filter.copyWith(selectedFormat: null).selectedGenres, {'Romance'});
    expect(filter.copyWith(query: 'test').selectedFormat, 'Manhwa');
  });

  test(
    'browse retains genre and type on page two and rejects other types/genres',
    () async {
      final api = CatalogSource();
      final notifier = BrowseNotifier(
        MangaApiService(),
        VisibleCatalog(),
        shinigami: api,
      );
      addTearDown(notifier.dispose);
      await notifier.init(format: 'Manhwa', genres: {'Romance'});
      expect(notifier.state.comics.length, 12);
      await notifier.loadMore();
      expect(notifier.state.comics.length, 24);
      expect(api.requestedPages, [1, 2]);
      expect(
        api.calls.every(
          (s) =>
              s.selectedFormat == 'Manhwa' &&
              s.selectedGenres.contains('Romance'),
        ),
        isTrue,
      );
      expect(notifier.state.hasMore, isFalse);
    },
  );

  test('changing genre while loading cannot restore stale results', () async {
    final api = CatalogSource()..firstRequest = Completer<ComicCatalogPage>();
    final notifier = BrowseNotifier(
      MangaApiService(),
      VisibleCatalog(),
      shinigami: api,
    );
    addTearDown(notifier.dispose);
    final old = notifier.init(format: 'Manhwa', genres: {'Action'});
    await notifier.init(format: 'Manhwa', genres: {'Romance'});
    api.firstRequest!.complete(const ComicCatalogPage([], hasMore: false));
    await old;
    expect(notifier.state.comics.length, 12);
    expect(
      notifier.state.comics.every((c) => c.genres.contains('Romance')),
      isTrue,
    );
  });

  test('request error can retry with the same genre and type', () async {
    final api = CatalogSource()..fail = true;
    final notifier = BrowseNotifier(
      MangaApiService(),
      VisibleCatalog(),
      shinigami: api,
    );
    addTearDown(notifier.dispose);
    await notifier.init(format: 'Manhwa', genres: {'Romance'});
    expect(notifier.state.error, isNotNull);
    api.fail = false;
    await notifier.loadMore();
    expect(notifier.state.error, isNull);
    expect(notifier.state.comics.length, 12);
  });
}
