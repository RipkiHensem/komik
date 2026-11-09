import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comicstream_app/presentation/widgets/proxied_image.dart';

void main() {
  testWidgets('cold reader builds only nearby pages while images load', (
    tester,
  ) async {
    var built = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 720,
              child: ListView.builder(
                cacheExtent: 900,
                itemCount: 80,
                itemBuilder: (_, i) {
                  built++;
                  return ProxiedImage(
                    imageUrl: 'https://example.invalid/cold-page-$i.jpg',
                    width: 360,
                    fit: BoxFit.fitWidth,
                    gaplessPlayback: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      built,
      lessThanOrEqualTo(8),
      reason: 'Tiny placeholders trigger mass image loading',
    );
    await tester.pumpWidget(const SizedBox());
  });
}
