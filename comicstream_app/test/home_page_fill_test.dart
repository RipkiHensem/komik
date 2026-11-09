import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/services/api_service.dart';

class SmallPages extends MangaApiService {
  @override
  Future<List<Comic>> getLatestManga({int page = 1, String? format}) async =>
      page > 3
      ? []
      : List.generate(
          5,
          (i) => Comic(
            id: '$page-$i',
            title: '$page-$i',
            coverUrl: '',
            format: 'Manhwa',
          ),
        );
}

class VisibleCatalog extends SupabaseComicService {
  VisibleCatalog()
    : super(
        SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        ),
      );
  @override
  Future<List<Comic>> filterHiddenComics(List<Comic> comics) async => comics;
  @override
  Future<List<Comic>> mergeAdminComics(
    List<Comic> comics, {
    String? format,
    bool popularOnly = false,
    String? searchQuery,
    List<String> genres = const [],
  }) async => comics;
}

void main() {
  test('initial page fills twelve slots across short source pages', () async {
    final notifier = HomeComicsNotifier(
      SmallPages(),
      VisibleCatalog(),
      'Manhwa',
      useShinigami: false,
    );
    final ready = notifier.stream.firstWhere((state) => !state.isLoading);
    final state = await ready;
    expect(state.comics.length, greaterThanOrEqualTo(12));
    expect(state.currentPage, 3);
    notifier.dispose();
  });
}
