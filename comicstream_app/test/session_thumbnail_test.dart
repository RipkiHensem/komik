import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/presentation/widgets/saved_comic_cover.dart';

Future<ui.Image> tinyImage() async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(Colors.white, BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  picture.dispose();
  return image;
}

void main() {
  testWidgets('scrolling away and back reuses decoded history thumbnails', (
    tester,
  ) async {
    final image = (await tester.runAsync(tinyImage))!;
    final calls = <String, int>{};
    final cache = SessionThumbnailCache(
      loader: (url) async {
        calls[url] = (calls[url] ?? 0) + 1;
        return image.clone();
      },
    );
    final container = ProviderContainer(
      overrides: [sessionThumbnailCacheProvider.overrideWithValue(cache)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: ListView.builder(
            itemExtent: 120,
            itemCount: 30,
            itemBuilder: (_, i) => SavedComicCover(
              key: ValueKey(i),
              imageUrl: 'https://example.test/$i.jpg',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls['https://example.test/0.jpg'], 1);
    await tester.drag(find.byType(ListView), const Offset(0, -2200));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(0)), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 2400));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(0)), findsOneWidget);
    expect(calls['https://example.test/0.jpg'], 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    cache.dispose();
    image.dispose();
  });

  test(
    'session cache decodes once and retains cover beyond global cache eviction',
    () async {
      final image = await tinyImage();
      var loads = 0;
      final cache = SessionThumbnailCache(
        loader: (_) async {
          loads++;
          return image;
        },
      );
      final entry = cache.get(['https://example.test/cover.jpg']);
      await entry.ready;
      PaintingBinding.instance.imageCache.clear();
      final revisited = cache.get(['https://example.test/cover.jpg']);
      expect(revisited, same(entry));
      expect(revisited.image, same(image));
      expect(loads, 1);
      cache.dispose();
      expect(image.debugDisposed, isTrue);
    },
  );

  test(
    'failed thumbnails can retry and a successful fallback remains cached',
    () async {
      var fail = true;
      var loads = 0;
      final image = await tinyImage();
      final cache = SessionThumbnailCache(
        loader: (url) async {
          loads++;
          if (fail || url.endsWith('bad')) throw StateError('unavailable');
          return image;
        },
      );
      final first = cache.get(['bad', 'good']);
      await expectLater(first.ready, throwsStateError);
      fail = false;
      final retry = cache.get(['bad', 'good']);
      await retry.ready;
      expect(cache.get(['bad', 'good']), same(retry));
      expect(loads, 4);
      cache.dispose();
    },
  );

  testWidgets(
    'remounted history cover appears immediately without loading again',
    (tester) async {
      final image = (await tester.runAsync(tinyImage))!;
      var loads = 0;
      final cache = SessionThumbnailCache(
        loader: (_) async {
          loads++;
          return image;
        },
      );
      final entry = cache.get(['https://example.test/cover.jpg']);
      await tester.runAsync(() => entry.ready);
      final container = ProviderContainer(
        overrides: [sessionThumbnailCacheProvider.overrideWithValue(cache)],
      );
      addTearDown(container.dispose);
      addTearDown(cache.dispose);
      Widget screen(bool show) => UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: show
              ? const SizedBox(
                  width: 68,
                  height: 94,
                  child: SavedComicCover(
                    imageUrl: 'https://example.test/cover.jpg',
                  ),
                )
              : const SizedBox(),
        ),
      );
      await tester.pumpWidget(screen(true));
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(image));
      await tester.pumpWidget(screen(false));
      await tester.pumpWidget(screen(true));
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, same(image));
      expect(find.byType(FutureBuilder<void>), findsNothing);
      expect(loads, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
