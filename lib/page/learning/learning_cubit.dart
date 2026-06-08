import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';

import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';
import '../../models/tag_vocab.dart';

part 'learning_state.dart';

class LearningCubit extends Cubit<LearningState> {
  final VocabularyRepository _vocabularyRepository;

  LearningCubit(this._vocabularyRepository) : super(const LearningState());

  final PublishSubject<String> messageController = PublishSubject();

  // ─── Config Setters ──────────────────────────────────────────

  void setLearningType(LearningType type) {
    emit(state.copyWith(
      config: state.config.copyWith(learningType: type),
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  void setLimitWords(int? limit) {
    emit(state.copyWith(
      config: state.config.copyWith(limitWords: limit),
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  void setLanguage(String? language) {
    emit(state.copyWith(
      config: state.config.copyWith(language: language),
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  void setUnitId(int? unitId) {
    emit(state.copyWith(
      config: state.config.copyWith(unitId: unitId),
      loadStatus: LOADSTATUS.INITAL,
      errorMessage: null,
    ));
  }

  // ─── Navigation ──────────────────────────────────────────────

  /// Validate config và chuyển sang phase học tương ứng
  Future<void> startLearning() async {
    emit(state.copyWith(
      loadStatus: LOADSTATUS.LOADING,
      errorMessage: null,
    ));

    try {
      // Tải từ vựng để kiểm tra số lượng
      final words = await _vocabularyRepository.watchAllWordsWithTags().first;

      // Lọc từ vựng theo cấu hình
      var filtered = List<VocabularyWithTags>.from(words);
      if (state.config.language != null && state.config.language!.isNotEmpty) {
        filtered = filtered.where((w) => w.word.language == state.config.language).toList();
      }
      if (state.config.unitId != null) {
        filtered = filtered.where((w) => w.word.unitId == state.config.unitId).toList();
      }

      final totalAvailable = filtered.length;
      final requestedLimit = state.config.limitWords;

      // Xác định số lượng từ tối thiểu cho từng kiểu học
      final minRequired = switch (state.config.learningType) {
        LearningType.flashCard => 1,
        LearningType.wordMatching => 2,
        LearningType.quizGame => 2,
        LearningType.comingSoon => 0,
      };

      if (totalAvailable < minRequired) {
        final errMsg = 'Không đủ số lượng từ để học. Cần ít nhất $minRequired từ (hiện có $totalAvailable từ).';
        emit(state.copyWith(
          loadStatus: LOADSTATUS.FAILED,
          errorMessage: errMsg,
        ));
        messageController.sink.add(errMsg);
        return;
      }



      final phase = switch (state.config.learningType) {
        LearningType.flashCard => LearningPhase.flashCard,
        LearningType.wordMatching => LearningPhase.wordMatching,
        LearningType.quizGame => LearningPhase.quizGame,
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
