import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:comicstream_app/presentation/screens/detail/comic_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/presentation/screens/bookmark/bookmark_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/models/bookmark.dart';
import 'package:comicstream_app/data/models/user.dart';
import 'package:comicstream_app/data/providers/providers.dart';
import 'package:comicstream_app/data/services/auth_service.dart';

class BookmarkStore extends SupabaseAuthService {
  List<Bookmark> items = [
    Bookmark(
      id: 'saved',
      userId: 'reader',
      comicId: 'shngm:comic',
      createdAt: DateTime(2026),
    ),
  ];
  bool failDelete = false;
  int deletes = 0;
  Completer<void>? deleteGate;
  @override
  User? getCurrentUser() => null;
  @override
  Future<List<Bookmark>> getMyBookmarks() async => List.of(items);
  @override
  Future<Bookmark> saveBookmark({
    required String comicId,
    String? lastChapterId,
    int? lastPage,
    String? comicTitle,
    String? comicCoverUrl,
  }) async {
    final item = Bookmark(
      id: 'saved',
      userId: 'reader',
      comicId: comicId,
      createdAt: DateTime(2026),
      comicTitle: comicTitle,
      comicCoverUrl: comicCoverUrl,
    );
    items = [item];
    return item;
  }

  @override
  Future<void> deleteBookmarkByComicId(String comicId) async {
    deletes++;
    await deleteGate?.future;
    if (failDelete) throw Exception('offline');
    items.removeWhere((item) => item.comicId == comicId);
  }
}

class TestAuth extends AuthNotifier {
  TestAuth(super.service);
  void signedIn(String id) => state = AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: id,
      username: id,
      email: '$id@example.test',
      createdAt: DateTime(2026),
    ),
  );
  void signedOut() =>
      state = const AuthState(status: AuthStatus.unauthenticated);
}

class EmptyComments extends CommentsNotifier {
  EmptyComments(super.client, super.comicId);
  @override
  Future<void> loadComments() async {
    state = const AsyncValue.data([]);
  }
}

void main() {
  testWidgets('press saved bookmark to remove it, press again to save', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    GoogleFonts.config.allowRuntimeFetching = false;
    final store = BookmarkStore();
    final auth = TestAuth(store)..signedIn('reader');
    final client = supa.SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const supa.AuthClientOptions(autoRefreshToken: false),
    );
    addTearDown(() {
      client.dispose();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          supabaseAuthServiceProvider.overrideWithValue(store),
          historyProvider.overrideWith((ref) => HistoryNotifier(store, false)),
          isAdminProvider.overrideWith((ref) async => false),
          comicChaptersProvider('shngm:comic').overrideWith((ref) async => []),
          commentsProvider(
            'shngm:comic',
          ).overrideWith((ref) => EmptyComments(client, 'shngm:comic')),
          comicFromDetailProvider('shngm:comic').overrideWith(
            (ref) async => const Comic(
              id: 'shngm:comic',
              title: 'Saved comic',
              coverUrl: '',
            ),
          ),
        ],
        child: const MaterialApp(
          home: ComicDetailScreen(comicId: 'shngm:comic'),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.text('Tersimpan'), findsOneWidget);
    store.failDelete = true;
    await tester.tap(find.text('Tersimpan'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.text('Tersimpan'), findsOneWidget);
    expect(find.text('Dihapus dari bookmark'), findsNothing);
    store.failDelete = false;
    await tester.tap(find.text('Tersimpan'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.text('Bookmark'), findsOneWidget);
    expect(store.items, isEmpty);
    await tester.tap(find.text('Bookmark'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.text('Tersimpan'), findsOneWidget);
    expect(store.items.single.comicTitle, 'Saved comic');
    expect(tester.takeException(), isNull);
  });

  Future<void> showBookmarks(WidgetTester tester, BookmarkStore store) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    GoogleFonts.config.allowRuntimeFetching = false;
    final auth = TestAuth(store)..signedIn('reader');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith((ref) => auth),
          supabaseAuthServiceProvider.overrideWithValue(store),
          historyProvider.overrideWith((ref) => HistoryNotifier(store, false)),
          comicFromDetailProvider('shngm:comic').overrideWith(
            (ref) async => const Comic(
              id: 'shngm:comic',
              title: 'Saved comic',
              coverUrl: '',
            ),
          ),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(0.8)),
            child: child!,
          ),
          home: const BookmarkScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
  }

  testWidgets('trash waits for persistence then removes the card', (
    tester,
  ) async {
    final store = BookmarkStore()..deleteGate = Completer<void>();
    await showBookmarks(tester, store);
    await tester.tap(find.byTooltip('Hapus'));
    await tester.pump();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Dismissible && widget.key == const ValueKey('saved'),
      ),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    store.deleteGate!.complete();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.text('Belum Ada Bookmark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed swipe preserves card, reports error and permits retry', (
    tester,
  ) async {
    final store = BookmarkStore()..failDelete = true;
    await showBookmarks(tester, store);
    await tester.drag(
      find.byWidgetPredicate(
        (widget) =>
            widget is Dismissible && widget.key == const ValueKey('saved'),
      ),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Dismissible && widget.key == const ValueKey('saved'),
      ),
      findsWidgets,
    );
    expect(
      find.text('Gagal menghapus. Periksa koneksi lalu coba lagi.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    store.failDelete = false;
    await tester.drag(find.byType(Dismissible).first, const Offset(-600, 0));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 3),
    );
    expect(find.text('Belum Ada Bookmark'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'bookmark provider follows login and logout, not profile refresh',
    () async {
      final store = BookmarkStore();
      final auth = TestAuth(store);
      final container = ProviderContainer(
        overrides: [
          supabaseAuthServiceProvider.overrideWithValue(store),
          authProvider.overrideWith((ref) => auth),
        ],
      );
      addTearDown(container.dispose);
      expect(container.read(bookmarksProvider).requireValue, isEmpty);
      auth.signedIn('reader');
      final notifier = container.read(bookmarksProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(bookmarksProvider).requireValue, hasLength(1));
      auth.signedIn('reader');
      expect(container.read(bookmarksProvider.notifier), same(notifier));
      await notifier.removeBookmarkByComicId('shngm:comic');
      expect(store.deletes, 1);
      expect(container.read(bookmarksProvider).requireValue, isEmpty);
      auth.signedOut();
      expect(container.read(bookmarksProvider).requireValue, isEmpty);
    },
  );

  test(
    'failed deletion is reported and preserves the saved bookmark',
    () async {
      final store = BookmarkStore()..failDelete = true;
      final notifier = BookmarksNotifier(store, true);
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      await expectLater(
        notifier.removeBookmarkByComicId('shngm:comic'),
        throwsException,
      );
      expect(notifier.state.requireValue, hasLength(1));
    },
  );

  test(
    'successful deletion updates list without replacing it with a loader',
    () async {
      final store = BookmarkStore();
      final notifier = BookmarksNotifier(store, true);
      addTearDown(notifier.dispose);
      await Future<void>.delayed(Duration.zero);
      final states = <AsyncValue<List<Bookmark>>>[];
      final subscription = notifier.stream.listen(states.add);
      addTearDown(subscription.cancel);
      await notifier.removeBookmarkByComicId('shngm:comic');
      expect(notifier.state.requireValue, isEmpty);
      expect(states.any((state) => state.isLoading), isFalse);
      await notifier.loadBookmarks();
      expect(notifier.state.requireValue, isEmpty);
    },
  );
}
