import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'xp_state.dart';

class XpCubit extends Cubit<XpState> {
  XpCubit() : super(XpState.initial());
  // TODO: final XpRepository _repo; → inject khi có data

  void addXp(int amount) {
    int xp = state.currentXp + amount;
    int max = state.maxXp;
    int lv = state.level;

    while (xp >= max) {
      xp -= max;
      lv++;
      max = (max * 1.35).round();
    }

    emit(state.copyWith(currentXp: xp, maxXp: max, level: lv));
    // TODO: _repo.save(xp, lv);
  }

  void resetXp() => emit(XpState.initial());
}