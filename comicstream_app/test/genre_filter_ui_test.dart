import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/services/api_service.dart';
import 'package:comicstream_app/data/services/shinigami_api_service.dart';
import 'package:comicstream_app/presentation/screens/search/search_screen.dart';
import 'package:comicstream_app/presentation/widgets/genre_chip.dart';
import 'home_page_fill_test.dart' show VisibleCatalog;

class EmptySource extends ShinigamiApiService {
  final filters = <SearchState>[];
  @override
  Future<ComicCatalogPage> catalogPage({
    int page = 1,
    String sort = 'latest',
    String? format,
    Set<String> genres = const {},
    String query = '',
  }) async {
    filters.add(SearchState(selectedFormat: format, selectedGenres: genres));
    return const ComicCatalogPage([], hasMore: false);
  }
}

void main() {
  testWidgets('genre buttons become active and preserve Manhwa at 360px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final source = EmptySource();
    final container = ProviderContainer(
      overrides: [
        searchStateProvider.overrideWith(
          (ref) => const SearchState(selectedFormat: 'Manhwa'),
        ),
        browseComicsProvider.overrideWith(
          (ref) => BrowseNotifier(
            MangaApiService(),
            VisibleCatalog(),
            shinigami: source,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final action = find.widgetWithText(GenreChip, 'Action');
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(tester.widget<GenreChip>(action).isSelected, isTrue);
    expect(source.filters.last.selectedGenres, {'Action'});
    expect(source.filters.last.selectedFormat, 'Manhwa');
    expect(container.read(exploreFormatProvider), 'Manhwa');
    expect(tester.takeException(), isNull);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(tester.widget<GenreChip>(action).isSelected, isFalse);
    expect(source.filters.last.selectedFormat, 'Manhwa');
    expect(source.filters.last.selectedGenres, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
