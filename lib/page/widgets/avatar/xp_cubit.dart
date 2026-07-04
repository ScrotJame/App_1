import 'package:bloc/bloc.dart';
import 'package:drift/drift.dart';
import 'package:equatable/equatable.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'dart:async';

import '../../../commons/enums.dart';
import '../../../database/app_db.dart';
import '../../../helper/level_helper.dart';

part 'xp_state.dart';

class XpCubit extends Cubit<XpState> {
  final UserRepository _userRepository;
  StreamSubscription<UsersEntrieData?>? _userSub;

  XpCubit(this._userRepository) : super(const XpState());

  Future<void> loadXp() async {
    _userSub ??= _userRepository.watchCurrentUser().listen((user) {
      if (user == null) return;
      final info = LevelHelper.calculate(user.experience);
      emit(state.copyWith(
        level: user.level,
        currentXp: info.currentXp,
        requiredXp: info.requiredXp,
        progress: info.progress,
      ));
    });

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

  Future<void> addGems(int gain) async {
    final user = await _userRepository.getCurrentUser();
    if (user == null) return;
    final totalGemsNew = user.gems + gain;
    await _userRepository.updateUser(UsersEntrieCompanion(
      gems: Value(totalGemsNew),
    ));
    //await loadProfile();
  }

  void acknowledgeLevelUp() {
    if (!state.justLeveledUp) return;
    emit(state.copyWith(justLeveledUp: false));
  }

  void changeLabel(Xp type) {
    emit(state.copyWith(tab: type));
  }

  @override
  Future<void> close() async {
    await _userSub?.cancel();
    return super.close();
  }
}
