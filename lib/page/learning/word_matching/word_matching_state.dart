part of 'word_matching_cubit.dart';

enum WordMatchingItemStatus { idle, selected, correct, wrong }

enum WordMatchingGameStatus {
  initial,
  loading,
  playing,
  wrongAnimation, // short delay to show shake red
  roundComplete,
  completed,
  gameOver,
}

class WordMatchingItem extends Equatable {
  final int id;
  final String text;
  final bool isMeaning;
  final WordMatchingItemStatus status;

  const WordMatchingItem({
    required this.id,
    required this.text,
    required this.isMeaning,
    this.status = WordMatchingItemStatus.idle,
  });

  WordMatchingItem copyWith({
    int? id,
    String? text,
    bool? isMeaning,
    WordMatchingItemStatus? status,
  }) {
    return WordMatchingItem(
      id: id ?? this.id,
      text: text ?? this.text,
      isMeaning: isMeaning ?? this.isMeaning,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, text, isMeaning, status];
}

class WordMatchingState extends Equatable {
  final LOADSTATUS loadStatus;
  final String? errorMessage;
  final WordMatchingGameStatus gameStatus;
  final int level;

  // ── Vocabulary pool (mirrors FlashCardCubit pattern: stored in state, not a local field) ──
  final List<VocabularyWithTags> allVocab;

  final List<WordMatchingItem> leftItems;
  final List<WordMatchingItem> rightItems;
  final int? selectedLeftId;
  final int? selectedRightId;
  final Set<int> matchedIds;
  final int timeRemaining;
  final int totalTime;
  final int score;
  final double? lastFoodEarned;
  final ActiveCompanionEntity? activeCompanion;

  const WordMatchingState({
    this.loadStatus = LOADSTATUS.INITAL,
    this.errorMessage,
    this.gameStatus = WordMatchingGameStatus.initial,
    this.level = 1,
    this.allVocab = const [],
    this.leftItems = const [],
    this.rightItems = const [],
    this.selectedLeftId,
    this.selectedRightId,
    this.matchedIds = const {},
    this.timeRemaining = 30,
    this.totalTime = 30,
    this.score = 0,
    this.lastFoodEarned,
    this.activeCompanion,
  });

  bool get hasActiveCompanion => activeCompanion != null;

  double get progress =>
      (leftItems.isEmpty) ? 0 : matchedIds.length / leftItems.length;

  WordMatchingState copyWith({
    LOADSTATUS? loadStatus,
    String? errorMessage,
    WordMatchingGameStatus? gameStatus,
    int? level,
    List<VocabularyWithTags>? allVocab,
    List<WordMatchingItem>? leftItems,
    List<WordMatchingItem>? rightItems,
    int? selectedLeftId,
    int? selectedRightId,
    Set<int>? matchedIds,
    int? timeRemaining,
    int? totalTime,
    int? score,
    double? lastFoodEarned,
    ActiveCompanionEntity? activeCompanion,
    bool clearLeftSelection = false,
    bool clearRightSelection = false,
    bool clearErrorMessage = false,
  }) {
    return WordMatchingState(
      loadStatus: loadStatus ?? this.loadStatus,
      errorMessage: clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      gameStatus: gameStatus ?? this.gameStatus,
      level: level ?? this.level,
      allVocab: allVocab ?? this.allVocab,
      leftItems: leftItems ?? this.leftItems,
      rightItems: rightItems ?? this.rightItems,
      selectedLeftId: clearLeftSelection ? null : selectedLeftId ?? this.selectedLeftId,
      selectedRightId: clearRightSelection ? null : selectedRightId ?? this.selectedRightId,
      matchedIds: matchedIds ?? this.matchedIds,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      totalTime: totalTime ?? this.totalTime,
      score: score ?? this.score,
      lastFoodEarned: lastFoodEarned ?? this.lastFoodEarned,
      activeCompanion: activeCompanion ?? this.activeCompanion,
    );
  }

  @override
  List<Object?> get props => [
    loadStatus,
    errorMessage,
    gameStatus,
    level,
    allVocab,
    leftItems,
    rightItems,
    selectedLeftId,
    selectedRightId,
    matchedIds,
    timeRemaining,
    totalTime,
    score,
    lastFoodEarned,
    activeCompanion,
  ];
}