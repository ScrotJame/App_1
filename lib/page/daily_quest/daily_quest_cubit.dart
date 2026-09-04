import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../commons/enums.dart';
import '../../service/mission_service.dart';
import 'models/daily_quest_model.dart';

part 'daily_quest_state.dart';

/// ─── DAILY QUEST CUBIT ──────────────────────────────────────────────
/// Cubit "mỏng" — chỉ làm 2 việc:
///   1. Gọi MissionService (delegate logic)
///   2. Emit state mới (quản lý UI)
///
/// KHÔNG chứa: business logic, serialize, random, streak calculation.
/// Tất cả nằm trong MissionService.
///
/// Timer periodic 1 phút để đếm thời gian user ở trong app
/// → auto-complete quest mặc định "Ở trong app 5 phút".
class DailyQuestCubit extends Cubit<DailyQuestState> {
  final MissionService _missionService;

  /// Stream side-effect: toast, snackbar, thông báo 1 lần.
  /// UI lắng nghe qua StreamSubscription tại initState().
  final PublishSubject<String> messageController = PublishSubject();

  /// Timer đếm phút — tick mỗi 1 phút để cập nhật quest mặc định.
  Timer? _minuteTimer;

  DailyQuestCubit(this._missionService) : super(const DailyQuestState());

  // ─── INIT ──────────────────────────────────────────────────

  Future<void> initData() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));

    final result = await _missionService.getTodayQuests();

    if (result.success && result.data != null) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        quests: result.data,
      ));
      // Bắt đầu đếm phút sau khi load thành công
      _startMinuteTimer();
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

  // ─── TIMER ─────────────────────────────────────────────────
  /// Mỗi 1 phút → gọi MissionService.onTimerTick()
  /// → quest mặc định +1 progress (0→1→2→3→4→5 = done).
  /// Timer tự dừng khi quest mặc định đã hoàn thành.

  void _startMinuteTimer() {
    _minuteTimer?.cancel();

    // Kiểm tra nếu default quest đã complete → không cần timer
    final hasIncompleteDefault =
        state.quests.any((q) => q.isDefault && !q.isCompleted);
    if (!hasIncompleteDefault) return;

    _minuteTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _onMinuteTick(),
    );
  }

  Future<void> _onMinuteTick() async {
    if (state.loadStatus != LOADSTATUS.SUCCESS) return;

    final result = await _missionService.onTimerTick(state.quests);

    if (result.success && result.data != null) {
      emit(state.copyWith(quests: result.data!.quests));
      _handlePostUpdate(result.data!);

      // Dừng timer nếu default quest đã hoàn thành
      final allDefaultDone =
          result.data!.quests.where((q) => q.isDefault).every((q) => q.isCompleted);
      if (allDefaultDone) {
        _minuteTimer?.cancel();
      }
    }
  }

  // ─── UPDATE PROGRESS ───────────────────────────────────────
  /// Gọi từ bên ngoài module khi user hoàn thành hành động.
  /// Ví dụ: LearningCubit học xong 3 từ → gọi updateProgress('learn_5', 3)

  Future<void> updateProgress(String questId, int newValue) async {
    final result = await _missionService.updateProgress(
      state.quests,
      questId,
      newValue,
    );

    if (result.success && result.data != null) {
      emit(state.copyWith(quests: result.data!.quests));
      _handlePostUpdate(result.data!);
    }
  }

  // ─── COMPLETE QUEST ────────────────────────────────────────

  Future<void> completeQuest(String questId) async {
    final result = await _missionService.completeQuest(
      state.quests,
      questId,
    );

    if (result.success && result.data != null) {
      emit(state.copyWith(quests: result.data!.quests));
      _handlePostUpdate(result.data!);
    }
  }

  // ─── PRIVATE ───────────────────────────────────────────────

  /// Xử lý sau khi update thành công:
  /// - Thông báo quest vừa hoàn thành
  /// - Thông báo streak nếu tất cả xong
  void _handlePostUpdate(QuestUpdateResult updateResult) {
    if (updateResult.newlyCompletedIds.isNotEmpty) {
      messageController.sink.add('✅ Hoàn thành nhiệm vụ!');
    }

    if (updateResult.shouldMarkStreak) {
      messageController.sink.add('🎉 Hoàn thành tất cả nhiệm vụ hôm nay!');
      // TODO: Gọi StreakCubit.markToday() từ UI listener
    }
  }

  @override
  Future<void> close() {
    _minuteTimer?.cancel();
    messageController.close();
    return super.close();
  }
}
