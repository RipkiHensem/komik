import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:comicstream_app/data/models/comic_page.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/services/api_service.dart';

class FailedSource extends MangaApiService {
  @override
  Future<List<ComicPage>> getChapterPages(String endpoint) async =>
      throw StateError('source HTTP 403');
}
class EmptyPages extends SupabaseComicService {
  EmptyPages(super.client);
  @override
  Future<List<ComicPage>> getChapterPages(String endpoint) async => [];
}
void main() {
  test('source failure with empty backup remains an error, not empty chapter', () async {
    final client = SupabaseClient('https://example.supabase.co', 'test');
    final container = ProviderContainer(overrides: [
      mangaApiServiceProvider.overrideWithValue(FailedSource()),
      supabaseComicServiceProvider.overrideWithValue(EmptyPages(client)),
    ]);
    addTearDown(container.dispose);
    addTearDown(client.dispose);
    await expectLater(container.read(chapterPagesProvider('chapter-1').future),
      throwsA(isA<StateError>()));
  });
}
