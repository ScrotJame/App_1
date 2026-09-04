import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/training_feed/widgets/snappy_feed_scroll_physics.dart';

void main() {
  testWidgets('Test SnappyFeedScrollPhysics forward and backward light swipes', (tester) async {
    final controller = PageController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageView.builder(
            controller: controller,
            scrollDirection: Axis.vertical,
            pageSnapping: false,
            physics: const SnappyFeedScrollPhysics(
              snapThreshold: 0.12, // 12% of screen height is enough to advance
              parent: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            ),
            itemCount: 10,
            itemBuilder: (context, index) {
              return Container(
                color: index.isEven ? Colors.red : Colors.blue,
                child: Center(child: Text('Page $index')),
              );
            },
          ),
        ),
      ),
    );

    // Test 1: Light drag UP of 100px (16.6% of 600px screen) -> advances to Page 1
    await tester.drag(find.byType(PageView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(controller.page, 1.0);

    // Test 2: Quick flick UP with 60px -> advances to Page 2
    await tester.fling(find.byType(PageView), const Offset(0, -60), 300);
    await tester.pumpAndSettle();
    expect(controller.page, 2.0);

    // Test 3: Light drag DOWN of 100px from Page 2 -> returns to Page 1
    await tester.drag(find.byType(PageView), const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(controller.page, 1.0);

    // Test 4: Quick flick DOWN from Page 1 -> returns to Page 0
    await tester.fling(find.byType(PageView), const Offset(0, 60), 300);
    await tester.pumpAndSettle();
    expect(controller.page, 0.0);
  });
}

