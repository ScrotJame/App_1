import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/daily_quest/daily_quest_cubit.dart';
import 'package:test_abc/page/daily_quest/data/daily_quest_repository.dart';
import 'package:test_abc/page/daily_quest/data/quest_local_data_source.dart';
import 'package:test_abc/page/daily_quest/widgets/daily_quest_card.dart';
import 'package:test_abc/page/streak/streak_page.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/service/active_time_tracker.dart';
import 'package:test_abc/service/mission_service.dart';

class MockUserRepository extends Mock implements UserRepository {}

class FakeQuestDataSource implements QuestLocalDataSource {
  final Map<String, String> data = {};
  @override
  Future<String?> readString(String key) async => data[key];
  @override
  Future<void> writeString(String key, String value) async => data[key] = value;
  @override
  Future<void> remove(String key) async => data.remove(key);
}

void main() {
  late MockUserRepository mockUserRepo;
  late DailyQuestCubit dailyQuestCubit;

  setUp(() {
    mockUserRepo = MockUserRepository();
    when(() => mockUserRepo.syncStreak()).thenAnswer((_) async {});
    when(() => mockUserRepo.getCurrentUser()).thenAnswer(
      (_) async => UsersEntrieData(
        id: '1',
        keyOpen: 'test_key',
        username: 'TestUser',
        currentStreak: 2,
        longestStreak: 5,
        totalLearned: 10,
        gems: 100,
        level: 1,
        experience: 50,
        lastActiveDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    final repo = DailyQuestRepository(FakeQuestDataSource());
    final service = MissionService(repo);
    dailyQuestCubit = DailyQuestCubit(
      service,
      activeTracker: ActiveTimeTracker(),
    );
  });

  testWidgets('StreakPage displays DailyQuestCard and does not display Mark Today button', (tester) async {
    await dailyQuestCubit.initData();

    await tester.pumpWidget(
      RepositoryProvider<UserRepository>.value(
        value: mockUserRepo,
        child: BlocProvider<DailyQuestCubit>.value(
          value: dailyQuestCubit,
          child: const MaterialApp(
            localizationsDelegates: [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: [Locale('en')],
            home: StreakPage(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Should find DailyQuestCard
    expect(find.byType(DailyQuestCard), findsOneWidget);

    // Should NOT find 'Mark Today' button
    expect(find.text('Mark Today'), findsNothing);

    await dailyQuestCubit.close();
  });
}
