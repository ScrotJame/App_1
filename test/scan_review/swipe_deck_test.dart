import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/page/scan_review/widgets/swipe_deck.dart';

void main() {
  late List<String> events;

  setUp(() => events = []);

  Future<void> pumpDeck(WidgetTester tester, {bool canKeep = true}) {
    return tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          width: 400,
          height: 500,
          child: SwipeDeck(
            canKeep: canKeep,
            keepLabel: 'KEEP',
            discardLabel: 'DROP',
            onKeep: () => events.add('keep'),
            onDiscard: () => events.add('discard'),
            onKeepBlocked: () => events.add('blocked'),
            child: const ColoredBox(
              color: Colors.blue,
              child: Center(child: Text('card')),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> drag(WidgetTester tester, double dx) async {
    await tester.drag(find.text('card'), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('gạt phải quá ngưỡng thì giữ', (tester) async {
    await pumpDeck(tester);
    await drag(tester, 250);
    expect(events, ['keep']);
  });

  testWidgets('gạt trái quá ngưỡng thì bỏ', (tester) async {
    await pumpDeck(tester);
    await drag(tester, -250);
    expect(events, ['discard']);
  });

  testWidgets('gạt ngắn thì thẻ bật về, không quyết định', (tester) async {
    await pumpDeck(tester);
    final start = tester.getCenter(find.text('card'));
    await drag(tester, 60);
    expect(events, isEmpty);
    expect(tester.getCenter(find.text('card')), start);
  });

  testWidgets('vuốt nhanh quãng ngắn vẫn tính', (tester) async {
    await pumpDeck(tester);
    await tester.fling(find.text('card'), const Offset(80, 0), 1500);
    await tester.pumpAndSettle();
    expect(events, ['keep']);
  });

  testWidgets('không được giữ thì báo và bật về', (tester) async {
    await pumpDeck(tester, canKeep: false);
    final start = tester.getCenter(find.text('card'));
    await drag(tester, 250);
    expect(events, ['blocked']);
    expect(tester.getCenter(find.text('card')), start);
  });
}
