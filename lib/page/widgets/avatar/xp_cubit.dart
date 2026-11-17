import 'package:bloc/bloc.dart';
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

  /// The sum and the level are written by the repository in one step, so
  /// gains that arrive back to back are all kept.
  Future<void> addXp(int gain) async {
    final result = await _userRepository.addXp(gain);
    if (result == null || isClosed) return;

    final info = LevelHelper.calculate(result.experience);
    emit(state.copyWith(
      level: result.level,
      currentXp: info.currentXp,
      requiredXp: info.requiredXp,
      progress: info.progress,
      justLeveledUp: result.leveledUp ? true : null,
    ));
  }

  Future<void> addGems(int gain) async {
    await _userRepository.addGems(gain);
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
