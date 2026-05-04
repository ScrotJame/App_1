part of 'flash_card_cubit.dart';



class FlashCardState {
  final FlashcardArenaStatus status;
  final List<VocabularyWithTags> cards;
  final int currentIndex;
  final bool isFlipped;
  final List<FlashcardResult> results;
  final DifficultyRating? pendingRating; // highlight trước khi advance
  final LOADSTATUS? loadstatus;
  final String? errorMessage;

  const FlashCardState({
    this.status = FlashcardArenaStatus.initial,
    this.cards = const [],
    this.currentIndex = 0,
    this.isFlipped = false,
    this.results = const [],
    this.pendingRating,
    this.loadstatus = LOADSTATUS.INITAL,
    this.errorMessage,
  });

  // ── Computed ────────────────────────────────
  VocabularyWithTags? get currentCard =>
      currentIndex < cards.length ? cards[currentIndex] : null;

  int get totalCards => cards.length;

  /// 1-based cho display (e.g. "12/20")
  int get displayIndex => currentIndex + 1;

  double get progress =>
      totalCards == 0 ? 0 : currentIndex / totalCards;

  int countRating(DifficultyRating r) =>
      results.where((e) => e.rating == r).length;

  // ── copyWith ────────────────────────────────
  FlashCardState copyWith({
    FlashcardArenaStatus? status,
    List<VocabularyWithTags>? cards,
    int? currentIndex,
    bool? isFlipped,
    List<FlashcardResult>? results,
    DifficultyRating? pendingRating,
    bool clearPending = false,
    LOADSTATUS? loadstatus,
    String? errorMessage,
  }) =>
      FlashCardState(
        status: status ?? this.status,
        cards: cards ?? this.cards,
        currentIndex: currentIndex ?? this.currentIndex,
        isFlipped: isFlipped ?? this.isFlipped,
        results: results ?? this.results,
        pendingRating: clearPending ? null : pendingRating ?? this.pendingRating,
        loadstatus:  loadstatus ?? this.loadstatus,
        errorMessage: errorMessage ?? this. errorMessage,
      );

  @override
  List<Object?> get props =>[
    status,
    cards,
    currentIndex,
    isFlipped,
    results,
    pendingRating,
    loadstatus,
    errorMessage,
  ];
}