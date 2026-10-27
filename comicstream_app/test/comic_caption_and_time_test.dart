import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/models/chapter.dart';
import 'package:comicstream_app/data/models/comic.dart';

void main() {
  test('comic detail keeps a real update timestamp', () {
    final comic = Comic.fromDetailJson({
      'manga_endpoint': 'comic-1',
      'title': 'Komik',
      'updated_on': '2026-10-20T10:00:00Z',
    });

    expect(comic.updatedAt, DateTime.utc(2026, 10, 20, 10));
    expect(comic.withSynopsis('Caption admin').synopsis, 'Caption admin');
    expect(comic.withSynopsis('Caption admin').updatedAt, comic.updatedAt);
  });

  test('chapter parses alternate update date fields', () {
    final chapter = Chapter.fromJson({
      'endpoint': 'chapter-1',
      'chapter_number': 1,
      'chapter_date': '2026-10-19T08:30:00Z',
    });

    expect(chapter.releasedAt, DateTime.utc(2026, 10, 19, 8, 30));
  });

  test('chapter does not invent an update time when source omits it', () {
    final chapter = Chapter.fromJson({
      'endpoint': 'chapter-1',
      'chapter_number': 1,
    });

    expect(chapter.relativeTimeAt(), isNull);
  });
}
