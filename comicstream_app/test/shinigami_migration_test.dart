import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/services/shinigami_api_service.dart';

void main() {
  test('uses current public API and root image base for chapter 195', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          h.resolve(
            Response(
              requestOptions: r,
              data: {
                'retcode': 0,
                'data': {
                  'base_url': 'https://cdn.shinigami.gg',
                  'chapter': {
                    'path': '/chapter/195/',
                    'data': ['1.jpg', '2.gif'],
                  },
                },
              },
            ),
          );
        },
      ),
    );
    final pages = await ShinigamiApiService(
      dio: dio,
    ).pages('shngm:reality:195');
    expect(pages.length, 2);
    expect(pages.first.imageUrl, 'https://cdn.shinigami.gg/chapter/195/1.jpg');
  });

  test('chapter list follows cursor through the final page', () async {
    final dio = Dio();
    final cursors = <dynamic>[];
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          if (r.path.contains('/manga/detail/')) {
            h.resolve(
              Response(
                requestOptions: r,
                data: {
                  'data': {'manga_id': 'r', 'title': 'Reality Quest'},
                },
              ),
            );
            return;
          }
          cursors.add(r.queryParameters['cursor']);
          final last = r.queryParameters['cursor'] == 'next';
          h.resolve(
            Response(
              requestOptions: r,
              data: {
                'retcode': 0,
                'meta': {
                  'has_next': !last,
                  'next_cursor': last ? null : 'next',
                },
                'data': [
                  {
                    'chapter_id': last ? '193' : '195',
                    'chapter_number': last ? 193 : 195,
                  },
                ],
              },
            ),
          );
        },
      ),
    );
    final detail = await ShinigamiApiService(dio: dio).detail('shngm:r');
    expect((detail['chapters'] as List).length, 2);
    expect(cursors, [null, 'next']);
  });

  test('catalog uses offset and authoritative has_next', () async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (r, h) {
          expect(r.queryParameters['offset'], 30);
          expect(r.queryParameters['limit'], 30);
          h.resolve(
            Response(
              requestOptions: r,
              data: {
                'data': [],
                'meta': {'has_next': true},
              },
            ),
          );
        },
      ),
    );
    expect(
      (await ShinigamiApiService(dio: dio).catalogPage(page: 2)).hasMore,
      true,
    );
  });
}
