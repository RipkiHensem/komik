import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/presentation/screens/admin/admin_comics_screen.dart';

void main() {
  testWidgets(
    'currently displayed comic is checked; metadata save does not pin automatically',
    (tester) async {
      Map<String, dynamic>? result;
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const ComicEditorDialog(
                      initialPopular: true,
                      comic: Comic(
                        id: 'source',
                        title: 'Source',
                        coverUrl: 'https://example.com/cover.jpg',
                      ),
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(
        CheckboxListTile,
        'Tampilkan di Populer',
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      expect(tester.widget<CheckboxListTile>(tile).value, isTrue);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result!.containsKey('popular_override'), isFalse);
      expect(result!['is_popular'], isFalse);
    },
  );
  testWidgets(
    'unchecking a currently displayed comic saves explicit exclusion',
    (tester) async {
      Map<String, dynamic>? result;
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const ComicEditorDialog(
                      initialPopular: true,
                      comic: Comic(
                        id: 'source',
                        title: 'Source',
                        coverUrl: 'https://example.com/cover.jpg',
                      ),
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final tile = find.widgetWithText(
        CheckboxListTile,
        'Tampilkan di Populer',
      );
      await tester.ensureVisible(tile);
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(result!['popular_override'], isFalse);
    },
  );
}
