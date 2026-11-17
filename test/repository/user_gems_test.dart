import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/repository/user_repository.dart';

import 'backup_test_support.dart';

void main() {
  late AppDatabase db;
  late UserRepository repo;

  Future<UsersEntrieData> readUser() => db.select(db.usersEntrie).getSingle();

  setUp(() async {
    db = await openDbWithUser('device', gems: 40, experience: 30);
    addTearDown(db.close);
    repo = UserRepository(db);
  });

  group('UserRepository.addGems', () {
    test('adds to the current balance', () async {
      expect(await repo.addGems(15), isTrue);

      expect((await readUser()).gems, 55);
    });

    test('rewards granted at the same time are all kept', () async {
      await Future.wait([for (var i = 1; i <= 20; i++) repo.addGems(i)]);

      expect((await readUser()).gems, 40 + 210);
    });

    test('ignores zero and negative amounts', () async {
      expect(await repo.addGems(0), isFalse);
      expect(await repo.addGems(-25), isFalse);

      expect((await readUser()).gems, 40);
    });

    test('leaves the other profile fields alone', () async {
      final before = await readUser();

      await repo.addGems(5);

      final after = await readUser();
      expect(after.experience, before.experience);
      expect(after.level, before.level);
      expect(after.currentStreak, before.currentStreak);
      expect(after.username, before.username);
    });

    test('does nothing without a local user', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await repo.addGems(10), isFalse);

      expect((await readUser()).gems, 40);
    });
  });

  group('XpCubit', () {
    late XpCubit cubit;

    setUp(() {
      cubit = XpCubit(repo);
      addTearDown(cubit.close);
    });

    test('gems from several sources at once are all added', () async {
      await Future.wait([
        cubit.addGems(5),
        cubit.addGems(10),
        cubit.addGems(15),
      ]);

      expect((await readUser()).gems, 70);
    });

    test('gems and XP granted together do not overwrite each other',
        () async {
      await Future.wait([
        cubit.addGems(5),
        cubit.addXp(10),
        cubit.addGems(7),
      ]);

      final user = await readUser();
      expect(user.gems, 52);
      expect(user.experience, 40);
    });
  });
}
