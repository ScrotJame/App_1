import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/models/entity/achivement_entity.dart';
import 'package:test_abc/repository/achievement_repository.dart';

part 'achievement_state.dart';

class AchievementCubit extends Cubit<AchievementState> {
  final AchievementRepository _repo;

  // ── Side-effect streams (không lưu vào State) ────────────────
  /// Bắn danh sách thành tựu vừa mở khóa → UI hiện popup
  final PublishSubject<List<AchivementEntity>> newUnlockController =
  PublishSubject();

  /// Bắn thông báo lỗi dạng chuỗi → UI hiện Flushbar
  final PublishSubject<String> messageController = PublishSubject();

  AchievementCubit(this._repo) : super(const AchievementState());

  void setUser(UsersEntrieData? user) {
    emit(state.copyWith(user: user));
  }

  // ── Khởi tạo dữ liệu trang ───────────────────────────────────
  Future<void> initData(String userKey) async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    try {
      final raw = await _repo.getAllAchievements(userKey: userKey);
      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        achievements: _mapAchievements(raw),
      ));
    } catch (e) {
      emit(state.copyWith(loadStatus: LOADSTATUS.FAILED));
    }
  }

  // ── Filter theo category ─────────────────────────────────────
  void onFilterCategory(String? category) {
    emit(state.copyWith(
      selectedCategory: category,
      clearCategory: category == null,
    ));
  }

  // ── Được gọi từ SessionCubit sau mỗi session học ─────────────
  // KHÔNG phải từ UI người dùng
  Future<void> checkAfterLearning({
    required String userKey,
    required int totalLearned,
    required int currentStreak,
    required int unitsCompleted,
  }) async {
    try {
      final newlyUnlocked = await _repo.checkAndUnlock(
        userKey: userKey,
        totalLearned: totalLearned,
        currentStreak: currentStreak,
        unitsCompleted: unitsCompleted,
        learnedAt: DateTime.now(),
      );

      if (newlyUnlocked.isNotEmpty) {
        // Bắn side effect để UI hiện popup — không emit vào State
        newUnlockController.sink.add(newlyUnlocked);

        // Refresh danh sách nếu trang đang mở
        if (state.loadStatus == LOADSTATUS.SUCCESS) {
          await initData(userKey);
        }
      }
    } catch (e) {
    }
  }

  // ── Safe mapping (null defensive) ────────────────────────────
  List<AchivementEntity> _mapAchievements(List<AchivementEntity> raw) {
    return raw
        .map(
          (e) => AchivementEntity(
        id: e.id ?? '',
        code: e.code ?? '',
        category: e.category ?? '',
        titleKey: e.titleKey ?? '',
        descriptionKey: e.descriptionKey ?? '',
        iconKey: e.iconKey ?? '',
        targetValue: e.targetValue ?? 0,
        isVisible: e.isVisible ?? false,
        currentValue: e.currentValue ?? 0,
        isUnlocked: e.isUnlocked ?? false,
        unlockedAt: e.unlockedAt,
      ),
    )
        .toList();
  }

  // ── Cleanup ───────────────────────────────────────────────────
  @override
  Future<void> close() {
    newUnlockController.close();
    messageController.close();
    return super.close();
  }
}