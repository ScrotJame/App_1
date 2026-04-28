import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/repository/user_repository.dart';

import '../../../database/app_db.dart';
import '../../../helper/level_helper.dart';

part 'xp_state.dart';

class XpCubit extends Cubit<XpState> {
  final UserRepository _userRepository;

  XpCubit(this._userRepository) : super(const XpState());

  // ── Load XP từ DB khi khởi động ───────────────────────────
  Future<void> loadXp() async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return;

    final info = LevelHelper.calculate(user.experience);
    emit(state.copyWith(
      level: user.level,
      currentXp: info.currentXp,
      requiredXp: info.requiredXp,
      progress: info.progress,
    ));
  }

  // ── Cộng XP (gọi từ BubbleButton) ────────────────────────
  Future<void> addXp(int gain) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return;

    final result = LevelHelper.addXp(
      currentLevel: user.level,
      currentXp: user.experience,
      gainXp: gain,
    );

    // Tính tổng xp mới để lưu vào DB
    final totalXpNew = _calcTotalXp(result.newLevel, result.newXp);

    await _userRepository.updateUser(UsersEntrieCompanion(
      level: Value(result.newLevel),
      experience: Value(totalXpNew),
    ));

    final info = LevelHelper.calculate(totalXpNew);
    emit(state.copyWith(
      level: result.newLevel,
      currentXp: info.currentXp,
      requiredXp: info.requiredXp,
      progress: info.progress,
      justLeveledUp: result.levelUp,
    ));
  }

  // Tính tổng xp tích lũy từ level + xp hiện tại
  int _calcTotalXp(int level, int currentXp) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += LevelHelper.xpRequired(i);
    }
    return total + currentXp;
  }
}