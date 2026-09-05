import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/page/daily_quest/daily_quest_cubit.dart';
import 'package:test_abc/page/daily_quest/data/daily_quest_repository.dart';
import 'package:test_abc/page/daily_quest/data/quest_local_data_source.dart';
import 'package:test_abc/page/daily_quest/models/daily_quest_model.dart';
import 'package:test_abc/page/daily_quest/widgets/daily_quest_card.dart';
import 'package:test_abc/service/active_time_tracker.dart';
import 'package:test_abc/service/mission_service.dart';

class FakeQuestLocalDataSource implements QuestLocalDataSource {
  final Map<String, String> storage = {};
  @override
  Future<String?> readString(String key) async => storage[key];
  @override
  Future<void> writeString(String key, String value) async => storage[key] = value;
  @override
  Future<void> remove(String key) async => storage.remove(key);
}

void main() {
  group('DailyQuestCard Widget Tests', () {
    late FakeQuestLocalDataSource fakeDataSource;
    late DailyQuestRepository repository;
    late MissionService missionService;

    setUp(() {
      fakeDataSource = FakeQuestLocalDataSource();
      repository = DailyQuestRepository(fakeDataSource);
      missionService = MissionService(repository);
    });

    testWidgets('shows quest items and progress when quests are in progress', (tester) async {
      final cubit = DailyQuestCubit(
        missionService,
        activeTracker: ActiveTimeTracker(),
      );
      await cubit.initData();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const DailyQuestCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Nhiệm vụ hàng ngày'), findsOneWidget);
      expect(find.text('Sử dụng app 5 phút'), findsOneWidget);
      // Not completed yet
      expect(find.text('Đã hoàn thành'), findsNothing);

      await cubit.close();
    });

    testWidgets('shows dimmed card and "Đã hoàn thành" status when all 3 quests are done', (tester) async {
      final cubit = DailyQuestCubit(
        missionService,
        activeTracker: ActiveTimeTracker(),
      );
      await cubit.initData();

      for (final q in cubit.state.quests) {
        await cubit.completeQuest(q.id);
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: cubit,
              child: const DailyQuestCard(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show 'Đã hoàn thành'
      expect(find.textContaining('Đã hoàn thành'), findsWidgets);

      await cubit.close();
    });
  });
}
