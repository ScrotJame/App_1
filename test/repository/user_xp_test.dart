import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/helper/level_helper.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/repository/user_repository.dart';

import 'backup_test_support.dart';

void main() {
  group('UserRepository.addXp', () {
    late AppDatabase db;
    late UserRepository repo;

    Future<UsersEntrieData> readUser() =>
        db.select(db.usersEntrie).getSingle();

    setUp(() async {
      db = await openDbWithUser('device', gems: 40, experience: 10);
      addTearDown(db.close);
      repo = UserRepository(db);
    });

    test('adds to the current experience', () async {
      final gain = await repo.addXp(15);

      expect(gain?.experience, 25);
      expect(gain?.leveledUp, isFalse);
      expect((await readUser()).experience, 25);
    });

    test('gains granted at the same time are all kept', () async {
      await Future.wait([for (var i = 1; i <= 20; i++) repo.addXp(i)]);

      final user = await readUser();
      expect(user.experience, 10 + 210);
      expect(user.level, LevelHelper.calculate(220).level);
    });

    test('raises the level when the experience crosses a threshold',
        () async {
      // Level 1 needs 30 XP.
      final gain = await repo.addXp(20);

      expect(gain?.leveledUp, isTrue);
      expect(gain?.level, 2);
      expect((await readUser()).level, 2);
    });

    test('ignores zero and negative amounts', () async {
      expect(await repo.addXp(0), isNull);
      expect(await repo.addXp(-25), isNull);

      expect((await readUser()).experience, 10);
    });

    test('leaves gems and streak alone', () async {
      final before = await readUser();

      await repo.addXp(5);

      final after = await readUser();
      expect(after.gems, before.gems);
      expect(after.currentStreak, before.currentStreak);
      expect(after.username, before.username);
    });

    test('does nothing without a local user', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await repo.addXp(10), isNull);

      expect((await readUser()).experience, 10);
    });
  });

  group('XpCubit.addXp', () {
    late AppDatabase db;
    late XpCubit cubit;

    setUp(() async {
      db = await openDbWithUser('device', experience: 0);
      addTearDown(db.close);
      cubit = XpCubit(UserRepository(db));
      addTearDown(cubit.close);
    });

    test('two gains started together are both kept', () async {
      await Future.wait([cubit.addXp(7), cubit.addXp(8)]);

      expect((await db.select(db.usersEntrie).getSingle()).experience, 15);
      expect(cubit.state.currentXp, 15);
    });

    test('flags the level up once and shows the new level', () async {
      await cubit.addXp(35);

      expect(cubit.state.justLeveledUp, isTrue);
      expect(cubit.state.level, 2);
      expect(cubit.state.currentXp, 5);

      cubit.acknowledgeLevelUp();
      await cubit.addXp(1);

      expect(cubit.state.justLeveledUp, isFalse);
      expect(cubit.state.currentXp, 6);
    });
  });

  group('first launch', () {
    late AppDatabase db;
    late UserRepository repo;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // No user and no local key yet, as on the very first start.
      SharedPreferences.setMockInitialValues({});
      db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      repo = UserRepository(db);
    });

    test('a watcher started before the user exists receives the new user',
        () async {
      final seen = <UsersEntrieData?>[];
      final sub = repo.watchCurrentUser().listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();
      expect(seen.whereType<UsersEntrieData>(), isEmpty);

      final created = await repo.createLocalUser('New learner');
      await pumpEventQueue();

      expect(seen.last?.keyOpen, created.keyOpen);
    });

    test('XpCubit follows the user created after it was loaded', () async {
      final cubit = XpCubit(repo);
      addTearDown(cubit.close);
      await cubit.loadXp();

      await repo.createLocalUser('New learner');
      // Written straight to the database, as a restore or another screen
      // would do it.
      await repo.addXp(35);
      await pumpEventQueue();

      expect(cubit.state.level, 2);
      expect(cubit.state.currentXp, 5);
    });
  });
}
