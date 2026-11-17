import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../commons/enums.dart';
import '../../service/active_time_tracker.dart';
import '../../service/mission_service.dart';
import 'models/daily_quest_model.dart';
import 'package:test_abc/generated/l10n.dart';

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
  final Future<void> Function(int gems)? _onQuestRewarded;
  final DateTime Function() _clock;

  /// Stream side-effect: toast, snackbar, thông báo 1 lần.
  final PublishSubject<String> messageController = PublishSubject();

  /// Timer kiểm tra tương tác & đếm thời gian active định kỳ
  Timer? _activityTimer;

  /// Ngày mà các quest trong state thuộc về (null khi chưa load xong).
  DateTime? _questDay;

  /// Lần reload sang ngày mới đang chạy, để nhiều trigger cùng lúc dùng chung.
  Future<bool>? _dayRollover;

  /// Hàng đợi cập nhật: mỗi lần cập nhật đọc state sau khi lần trước đã emit
  /// xong. Nhờ vậy hai cập nhật sát nhau không ghi đè tiến độ của nhau và một
  /// quest không thể "vừa hoàn thành" hai lần (tức là thưởng gems hai lần).
  Future<void> _updateQueue = Future.value();

  DailyQuestCubit(
    this._missionService, {
    ActiveTimeTracker? activeTracker,
    Future<void> Function()? onStreakCompleted,
    Future<void> Function(int gems)? onQuestRewarded,
    DateTime Function()? clock,
  })  : _activeTracker = activeTracker ?? ActiveTimeTracker(),
        _onStreakCompleted = onStreakCompleted,
        _onQuestRewarded = onQuestRewarded,
        _clock = clock ?? DateTime.now,
        super(const DailyQuestState());

  ActiveTimeTracker get activeTracker => _activeTracker;

  // ─── INIT ──────────────────────────────────────────────────

  Future<void> initData() async {
    final now = _clock();
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));

    final result = await _missionService.getTodayQuests(now: now);
    if (isClosed) return;

    if (result.success && result.data != null) {
      final quests = result.data!;
      _questDay = DateTime(now.year, now.month, now.day);
      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        quests: quests,
      ));

      // Đồng bộ số giây active với quest mặc định: khôi phục phần đã tích lũy
      // trong ngày, hoặc về 0 khi vừa sang ngày mới (nếu không, số giây của
      // hôm qua sẽ hoàn thành quest hôm nay ngay ở tick đầu tiên).
      final defaultQuest = quests.where((q) => q.isDefault).firstOrNull;
      _activeTracker.setActiveSeconds((defaultQuest?.currentValue ?? 0) * 60);

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

  // ─── DAY ROLLOVER ───────────────────────────────────────────

  /// Quest trong state có phải của ngày hôm nay không.
  bool get _isQuestDayCurrent {
    final questDay = _questDay;
    if (questDay == null) return false;
    final now = _clock();
    return questDay.year == now.year &&
        questDay.month == now.month &&
        questDay.day == now.day;
  }

  /// Load quest của hôm nay nếu quest trong state thuộc về một ngày trước đó
  /// (app còn mở hoặc nằm nền qua nửa đêm). Trả về true khi có reload.
  ///
  /// Được gọi khi app resume, khi người dùng chạm màn hình và trước mọi lần
  /// cập nhật tiến độ.
  Future<bool> refreshIfNewDay() {
    final running = _dayRollover;
    if (running != null) return running;
    if (isClosed || _questDay == null || _isQuestDayCurrent) {
      return Future.value(false);
    }

    final rollover = initData().then((_) => true).whenComplete(() {
      _dayRollover = null;
    });
    _dayRollover = rollover;
    return rollover;
  }

  // ─── USER ACTIVITY TRACKING ─────────────────────────────────

  /// Ghi nhận người dùng vừa tương tác với màn hình (chạm/vuốt/gõ).
  void recordUserActivity([DateTime? now]) {
    _activeTracker.recordActivity(now ?? DateTime.now());
    unawaited(refreshIfNewDay());
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

    // Sang ngày mới: quest và bộ đếm đã được làm mới, tick sau mới đếm tiếp.
    if (await refreshIfNewDay()) return;

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

  Future<void> updateProgress(String questId, int newValue) =>
      _enqueue(() => _updateProgress(questId, newValue));

  Future<void> _updateProgress(String questId, int newValue) async {
    // newValue được tính trên quest của hôm qua thì không áp cho quest hôm nay.
    if (await refreshIfNewDay()) return;
    final questDay = _questDay;
    if (questDay == null || !_isQuestDayCurrent) return;

    final result = await _missionService.updateProgress(
      state.quests,
      questId,
      newValue,
      questDay: questDay,
    );
    if (_isStaleAfterSave(questDay)) return;

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

  Future<void> completeQuest(String questId) =>
      _enqueue(() => _completeQuest(questId));

  Future<void> _completeQuest(String questId) async {
    if (await refreshIfNewDay()) return;
    final questDay = _questDay;
    if (questDay == null || !_isQuestDayCurrent) return;

    final result = await _missionService.completeQuest(
      state.quests,
      questId,
      questDay: questDay,
    );
    if (_isStaleAfterSave(questDay)) return;

    if (result.success && result.data != null) {
      emit(state.copyWith(quests: result.data!.quests));
      await _handlePostUpdate(result.data!);
    }
  }

  /// Cập nhật tiến độ nhiệm vụ theo loại (QuestType).
  /// Cho phép các màn hình khác (Learning, Quiz, Feed) gọi mà không cần biết questId cụ thể.
  Future<void> onProgressByType(QuestType type, {int increment = 1}) {
    return _enqueue(() async {
      // Hành động vừa xảy ra là của hôm nay → tính vào quest của hôm nay.
      await refreshIfNewDay();
      if (!_isQuestDayCurrent) return;

      final matchingQuests = state.quests
          .where((q) => q.type == type && !q.isCompleted)
          .toList();
      for (final q in matchingQuests) {
        await _updateProgress(q.id, q.currentValue + increment);
      }
    });
  }

  // ─── PRIVATE ───────────────────────────────────────────────

  /// Trong lúc chờ lưu, cubit đã đóng hoặc quest đã được thay bằng bộ của
  /// ngày mới → kết quả vừa lưu không còn thuộc về state hiện tại.
  bool _isStaleAfterSave(DateTime questDay) =>
      isClosed || _questDay != questDay;

  Future<void> _enqueue(Future<void> Function() update) {
    final run = _updateQueue.then((_) => update());
    // Một lần cập nhật lỗi không được làm kẹt các lần sau.
    _updateQueue = run.catchError((_) {});
    return run;
  }

  Future<void> _handlePostUpdate(QuestUpdateResult updateResult) async {
    if (updateResult.newlyCompletedIds.isNotEmpty) {
      messageController.sink.add(S.current.quest_completed);
    }

    // Thưởng gems của các quest VỪA hoàn thành. newlyCompletedIds chỉ chứa
    // lần chuyển chưa xong → xong, nên mỗi quest chỉ được thưởng một lần.
    final rewardGems = updateResult.quests
        .where((q) => updateResult.newlyCompletedIds.contains(q.id))
        .fold<int>(0, (sum, q) => sum + q.rewardGems);

    if (rewardGems > 0) {
      try {
        await _onQuestRewarded?.call(rewardGems);
      } catch (_) {
        // Lỗi khi cộng gems không được làm mất streak của ngày, cũng không
        // được chặn các quest còn lại trong cùng lượt cập nhật.
      }
    }

    if (updateResult.shouldMarkStreak) {
      messageController.sink.add(S.current.all_quests_completed);
      await _onStreakCompleted?.call();
    }
  }

  @override
  Future<void> close() {
    _activityTimer?.cancel();
    messageController.close();
    return super.close();
  }
}
