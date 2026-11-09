import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/components/privacy_policy_dialog.dart';

void main() {
  testWidgets('shows the privacy policy and closes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPrivacyPolicyDialog(context),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Chính sách riêng tư'), findsOneWidget);
    expect(find.textContaining('lưu trên thiết bị'), findsOneWidget);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();

    expect(find.text('Chính sách riêng tư'), findsNothing);
  });
}
