import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/models/bookmark.dart';
import 'package:comicstream_app/data/models/chapter.dart';
import 'package:comicstream_app/data/services/auth_service.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/presentation/widgets/comic_card.dart';
import 'package:comicstream_app/presentation/widgets/comic_cover.dart';

class SavedHistory extends SupabaseAuthService {
  final Bookmark item;
  SavedHistory(this.item);
  @override
  Future<List<Bookmark>> getMyHistory() async => [item];
}

void main() {
  Bookmark history(String id, {int? number}) => Bookmark(
    id: 'history',
    userId: 'reader',
    comicId: 'comic',
    lastChapterId: id,
    lastChapterNumber: number,
    createdAt: DateTime(2026),
  );
  test('history displays chapter from saved endpoint without network', () {
    expect(history('eleceed-chapter-54/').progressText, 'Chapter 54');
    expect(history('comic-chapter-0').progressText, 'Chapter 0');
    expect(history('comic-chapter-52.5/').progressText, 'Chapter 52.5');
    expect(history('comic-chapter-52', number: 53).progressText, 'Chapter 53');
  });
  test('opaque chapter IDs never become invented chapter numbers', () {
    expect(history('4ac2-1234').progressText, 'Chapter tidak tersedia');
  });
  test(
    'legacy history publishes its resolved chapter, not a temporary label',
    () async {
      final chapters = Completer<List<Chapter>>();
      final notifier = HistoryNotifier(
        SavedHistory(history('opaque-id')),
        true,
        loadChapters: (_) => chapters.future,
      );
      final ready = notifier.stream.firstWhere((value) => value.hasValue);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isLoading, isTrue);
      chapters.complete([
        const Chapter(
          id: 'opaque-id',
          comicId: 'comic',
          chapterNumber: 14,
          releasedAt: null,
        ),
      ]);
      expect((await ready).requireValue.single.progressText, 'Chapter 14');
      notifier.dispose();
    },
  );
  testWidgets('list cover does not wait for the detail request', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          comicDetailProvider('comic').overrideWith((ref) => pending.future),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160,
              child: ComicCard(
                comic: Comic(
                  id: 'comic',
                  title: 'Title',
                  coverUrl: 'https://example.invalid/cover.jpg',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(ComicCover), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
