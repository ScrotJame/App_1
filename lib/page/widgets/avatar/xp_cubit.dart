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

    final totalXpNew = user.experience + gain;

    await _userRepository.updateUser(UsersEntrieCompanion(
      experience: Value(totalXpNew),
    ));

    final info = LevelHelper.calculate(totalXpNew);
    final levelUp = info.level > user.level;

    if (levelUp) {
      await _userRepository.updateUser(UsersEntrieCompanion(
        level: Value(info.level),
      ));
    }

    emit(state.copyWith(
      level: info.level,
      currentXp: info.currentXp,
      requiredXp: info.requiredXp,
      progress: info.progress,
      justLeveledUp: levelUp,
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

  void changeLabel(Xp type) {
    emit(state.copyWith(tab: type));
  }
}