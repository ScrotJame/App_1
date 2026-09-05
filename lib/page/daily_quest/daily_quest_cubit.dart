import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../commons/enums.dart';
import '../../service/active_time_tracker.dart';
import '../../service/mission_service.dart';
import 'models/daily_quest_model.dart';

part 'daily_quest_state.dart';

/// ─── DAILY QUEST CUBIT ──────────────────────────────────────────────
/// Quản lý UI state của Daily Quests:
///   1. Gọi MissionService (load quests, update progress, random pool)
///   2. Đếm thời gian sử dụng active (ActiveTimeTracker với idle threshold 30s)
///   3. Tự động kích hoạt chuỗi khi cả 3 nhiệm vụ hoàn thành
class DailyQuestCubit extends Cubit<DailyQuestState> {
  final MissionService _missionService;
  final ActiveTimeTracker _activeTracker;
  final Future<void> Function()? _onStreakCompleted;

  /// Stream side-effect: toast, snackbar, thông báo 1 lần.
  final PublishSubject<String> messageController = PublishSubject();

  /// Timer kiểm tra tương tác & đếm thời gian active định kỳ
  Timer? _activityTimer;

  DailyQuestCubit(
    this._missionService, {
    ActiveTimeTracker? activeTracker,
    Future<void> Function()? onStreakCompleted,
  })  : _activeTracker = activeTracker ?? ActiveTimeTracker(),
        _onStreakCompleted = onStreakCompleted,
        super(const DailyQuestState());

  ActiveTimeTracker get activeTracker => _activeTracker;

  // ─── INIT ──────────────────────────────────────────────────

  Future<void> initData() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));

    final result = await _missionService.getTodayQuests();

    if (result.success && result.data != null) {
      final quests = result.data!;
      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        quests: quests,
      ));

      // Khôi phục số giây từ quest mặc định (nếu đã tích lũy trước đó)
      final defaultQuest = quests.where((q) => q.isDefault).firstOrNull;
      if (defaultQuest != null && defaultQuest.currentValue > 0) {
        _activeTracker.setActiveSeconds(defaultQuest.currentValue * 60);
      }

      // Bắt đầu timer đếm active time nếu quest mặc định chưa xong
      _startActivityTimer();
    } else {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: result.error,
      ));
      if (result.error != null) {
        messageController.sink.add(result.error!);
      }
    }
  }

  // ─── USER ACTIVITY TRACKING ─────────────────────────────────

  /// Ghi nhận người dùng vừa tương tác với màn hình (chạm/vuốt/gõ).
  void recordUserActivity([DateTime? now]) {
    _activeTracker.recordActivity(now ?? DateTime.now());
  }

  void _startActivityTimer() {
    _activityTimer?.cancel();

    final hasIncompleteDefault =
        state.quests.any((q) => q.isDefault && !q.isCompleted);
    if (!hasIncompleteDefault) return;

    // Chạy định kỳ mỗi 1 giây để theo dõi active/idle chính xác
    _activityTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => onActivityTick(stepSeconds: 1),
    );
  }

  /// Xử lý 1 tick thời gian hoạt động
  Future<void> onActivityTick({DateTime? now, int stepSeconds = 1}) async {
    if (state.loadStatus != LOADSTATUS.SUCCESS) return;

    final defaultQuest =
        state.quests.where((q) => q.isDefault && !q.isCompleted).firstOrNull;
    if (defaultQuest == null) {
      _activityTimer?.cancel();
      return;
    }

    final currentTime = now ?? DateTime.now();
    _activeTracker.tick(currentTime, step: Duration(seconds: stepSeconds));

    // Quy đổi số giây active ra phút
    final currentMinutes = (_activeTracker.activeSeconds ~/ 60)
        .clamp(0, defaultQuest.targetValue);

    if (currentMinutes > defaultQuest.currentValue) {
      await updateProgress(defaultQuest.id, currentMinutes);
    }
  }

  // ─── UPDATE PROGRESS ───────────────────────────────────────

  Future<void> updateProgress(String questId, int newValue) async {
    final result = await _missionService.updateProgress(
      state.quests,
      questId,
      newValue,
    );

    if (result.success && result.data != null) {
      emit(state.copyWith(quests: result.data!.quests));
      await _handlePostUpdate(result.data!);

      // Nếu quest mặc định đã xong thì hủy timer đếm giờ
      final defaultDone = result.data!.quests
          .where((q) => q.isDefault)
          .every((q) => q.isCompleted);
      if (defaultDone) {
        _activityTimer?.cancel();
      }
    }
  }

  // ─── COMPLETE QUEST (SHORTCUT) ───────────────────────────────

  Future<void> completeQuest(String questId) async {
    final result = await _missionService.completeQuest(
      state.quests,
      questId,
    );

    if (result.success && result.data != null) {
      emit(state.copyWith(quests: result.data!.quests));
      await _handlePostUpdate(result.data!);
    }
  }

  /// Cập nhật tiến độ nhiệm vụ theo loại (QuestType).
  /// Cho phép các màn hình khác (Learning, Quiz, Feed) gọi mà không cần biết questId cụ thể.
  Future<void> onProgressByType(QuestType type, {int increment = 1}) async {
    final matchingQuests = state.quests
        .where((q) => q.type == type && !q.isCompleted)
        .toList();
    for (final q in matchingQuests) {
      await updateProgress(q.id, q.currentValue + increment);
    }
  }

  // ─── PRIVATE ───────────────────────────────────────────────

  Future<void> _handlePostUpdate(QuestUpdateResult updateResult) async {
    if (updateResult.newlyCompletedIds.isNotEmpty) {
      messageController.sink.add('✅ Hoàn thành nhiệm vụ!');
    }

    if (updateResult.shouldMarkStreak) {
      messageController.sink.add('🎉 Hoàn thành tất cả nhiệm vụ hôm nay!');
      if (_onStreakCompleted != null) {
        await _onStreakCompleted!.call();
      }
    }
  }

  @override
  Future<void> close() {
    _activityTimer?.cancel();
    messageController.close();
    return super.close();
  }
}
