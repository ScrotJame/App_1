import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/daily_review/data/daily_review_status.dart';
import 'package:test_abc/page/daily_review/widgets/daily_review_badge.dart';

void main() {
  Future<void> pumpBadge(WidgetTester tester, DailyReviewStatus status,
      {VoidCallback? onTap}) {
    return tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: DailyReviewBadge(status: status, onTap: onTap ?? () {}),
        ),
      ),
    ));
  }

  testWidgets('no review yet: only the icon', (tester) async {
    await pumpBadge(tester, DailyReviewStatus.notCreated);

    expect(find.byIcon(Icons.fact_check_rounded), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('in progress: done / total', (tester) async {
    await pumpBadge(
      tester,
      const DailyReviewStatus(
          progress: DailyReviewProgress.inProgress, answered: 3, total: 20),
    );

    expect(find.text('3/20'), findsOneWidget);
  });

  testWidgets('completed: a check mark, no numbers', (tester) async {
    await pumpBadge(
      tester,
      const DailyReviewStatus(
          progress: DailyReviewProgress.completed, answered: 20, total: 20),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.textContaining('/'), findsNothing);
  });

  testWidgets('tapping calls onTap', (tester) async {
    var taps = 0;
    await pumpBadge(tester, DailyReviewStatus.notCreated, onTap: () => taps++);

    await tester.tap(find.byType(DailyReviewBadge));

    expect(taps, 1);
  });
}
