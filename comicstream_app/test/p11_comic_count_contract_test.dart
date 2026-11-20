import 'package:comicstream_app/data/models/comic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P11 chapter-count API contract', () {
    // Exercise a useful range of values across both list/detail API payloads,
    // including the numeric and string forms returned by real API versions.
    for (var count = 0; count <= 132; count++) {
      test('parses chapter count $count from supported payload shape', () {
        final dynamic apiValue = count.isEven ? count : '$count';
        final payload = count % 3 == 0
            ? {'chapter_count': apiValue}
            : count % 3 == 1
            ? {'total_chapter': apiValue}
            : {'chapter_count': apiValue, 'total_chapter': count + 1};

        final comic = count.isEven
            ? Comic.fromListJson({'endpoint': 'comic-$count', ...payload})
            : Comic.fromDetailJson({'manga_endpoint': 'comic-$count', ...payload});

        expect(comic.chapterCount, count, reason: 'API value: $apiValue');
      });
    }

    test('malformed chapter counts safely fall back to zero', () {
      expect(Comic.fromListJson({'chapter_count': null}).chapterCount, 0);
      expect(Comic.fromListJson({'chapter_count': 'unknown'}).chapterCount, 0);
      expect(Comic.fromDetailJson({'total_chapter': null}).chapterCount, 0);
    });
  });
}
