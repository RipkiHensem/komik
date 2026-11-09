import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/data/models/comic.dart';
import 'package:comicstream_app/presentation/screens/admin/admin_comics_screen.dart';

void main() {
  testWidgets('editor tolerates genre text accidentally returned as status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ComicEditorDialog(
            comic: Comic(
              id: 'bocchi',
              title: 'Bocchi',
              coverUrl: 'https://example.com/cover.jpg',
              status:
                  'Comedy\nOne Shot\nRomance\nSchool life\nSlice of Life tess.',
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Edit komik'), findsOneWidget);
  });
}
