part of 'learning_cubit.dart';

// ═══════════════════════════════════════════════════════════════
// ENUMS
// ═══════════════════════════════════════════════════════════════

enum LearningPhase { config, flashCard, wordMatching, comingSoon }

enum LearningType {
  flashCard, // Học bằng thẻ lật (FlashCard)
  wordMatching, // Nối từ (Word Matching)
  comingSoon
}

// ═══════════════════════════════════════════════════════════════
// LEARNING CONFIG
// ═══════════════════════════════════════════════════════════════

class LearningConfig extends Equatable {
  const LearningConfig({
    this.learningType = LearningType.flashCard,
    this.limitWords,
    this.language,
    this.unitId,
  });

  final LearningType learningType;
  final int? limitWords;
  final String? language;
  final int? unitId;

  LearningConfig copyWith({
    LearningType? learningType,
    Object? limitWords = _sentinel,
    Object? language = _sentinel,
    Object? unitId = _sentinel,
  }) {
    return LearningConfig(
      learningType: learningType ?? this.learningType,
      limitWords: limitWords == _sentinel ? this.limitWords : limitWords as int?,
      language: language == _sentinel ? this.language : language as String?,
      unitId: unitId == _sentinel ? this.unitId : unitId as int?,
    );
  }

  @override
  List<Object?> get props => [learningType, limitWords, language, unitId];
}

// ═══════════════════════════════════════════════════════════════
// LEARNING STATE
// ═══════════════════════════════════════════════════════════════

class LearningState extends Equatable {
  const LearningState({
    this.phase = LearningPhase.config,
    this.config = const LearningConfig(),
    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  final LearningPhase phase;
  final LearningConfig config;
  final LOADSTATUS loadStatus;
  final String? errorMessage;

  LearningState copyWith({
    LearningPhase? phase,
    LearningConfig? config,
    LOADSTATUS? loadStatus,
    Object? errorMessage = _sentinel,
  }) {
    return LearningState(
      phase: phase ?? this.phase,
      config: config ?? this.config,
      loadStatus: loadStatus ?? this.loadStatus,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [phase, config, loadStatus, errorMessage];
}

const _sentinel = Object();
