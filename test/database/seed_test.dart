import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/database/app_db.dart';

/// What a fresh install starts with.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
  });

  test('the shop catalogue holds only real items', () async {
    final items = await db.select(db.itemsEntrie).get();

    expect(
      items.map((i) => i.name).toList()..sort(),
      ['Double Gems', 'Save Streal', 'Streak Freeze'],
    );
    expect(items.every((i) => i.price > 1), isTrue);
  });
}
