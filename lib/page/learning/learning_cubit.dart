import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../commons/enums.dart';

part 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  LearningCubit() : super(const LearningState());

  final PublishSubject<String> messageController = PublishSubject();

  // ─── Config Setters ──────────────────────────────────────────

  void setLearningType(LearningType type) {
    emit(state.copyWith(
      config: state.config.copyWith(learningType: type),
    ));
  }

  void setLimitWords(int? limit) {
    emit(state.copyWith(
      config: state.config.copyWith(limitWords: limit),
    ));
  }

  void setLanguage(String? language) {
    emit(state.copyWith(
      config: state.config.copyWith(language: language),
    ));
  }

  void setUnitId(int? unitId) {
    emit(state.copyWith(
      config: state.config.copyWith(unitId: unitId),
    ));
  }

  // ─── Navigation ──────────────────────────────────────────────

  /// Validate config và chuyển sang phase học tương ứng
  void startLearning() {
    emit(state.copyWith(
      loadStatus: LOADSTATUS.LOADING,
      errorMessage: null,
    ));

    try {
      final phase = switch (state.config.learningType) {
        LearningType.flashCard => LearningPhase.flashCard,
        LearningType.wordMatching => LearningPhase.wordMatching,
        LearningType.comingSoon => LearningPhase.comingSoon
      };

      emit(state.copyWith(
        phase: phase,
        loadStatus: LOADSTATUS.SUCCESS,
      ));
    } catch (e) {
      final errMsg = 'Có lỗi xảy ra: $e';
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: errMsg,
      ));
      messageController.sink.add(errMsg);
    }
  }

  /// Trở về màn config
  void goToConfig() {
    emit(state.copyWith(
      phase: LearningPhase.config,
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  @override
  Future<void> close() {
    messageController.close();
    return super.close();
  }
}
