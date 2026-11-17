part of 'training_feed_cubit.dart';

class TrainingFeedState extends Equatable {
  const TrainingFeedState({
    this.loadStatus = LOADSTATUS.INITAL,
    this.cards = const [],
    this.currentIndex = 0,
    this.combo = 0,
    this.xpEarned = 0,
    this.gemsEarned = 0,
    this.bonusProgress = 0,
    this.errorMessage,
    this.activeCompanion,
  });

  final LOADSTATUS loadStatus;
  final List<TrainingFeedCard> cards;
  final int currentIndex;
  final int combo;
  final int xpEarned;
  final int gemsEarned;

  /// Correct quiz answers since the last bonus card was claimed, capped at
  /// [bonusRequirement].
  final int bonusProgress;
  final String? errorMessage;
  final ActiveCompanionEntity? activeCompanion;

  /// Correct quiz answers a bonus card costs.
  static const int bonusRequirement = 3;

  bool get isBonusUnlocked => bonusProgress >= bonusRequirement;

  /// Correct quiz answers still missing before a bonus card can be claimed.
  int get bonusAnswersLeft =>
      isBonusUnlocked ? 0 : bonusRequirement - bonusProgress;

  TrainingFeedCard? get currentCard {
    if (cards.isEmpty || currentIndex >= cards.length) return null;
    return cards[currentIndex];
  }

  TrainingFeedState copyWith({
    LOADSTATUS? loadStatus,
    List<TrainingFeedCard>? cards,
    int? currentIndex,
    int? combo,
    int? xpEarned,
    int? gemsEarned,
    int? bonusProgress,
    Object? errorMessage = _sentinel,
    ActiveCompanionEntity? activeCompanion,
  }) {
    return TrainingFeedState(
      loadStatus: loadStatus ?? this.loadStatus,
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      combo: combo ?? this.combo,
      xpEarned: xpEarned ?? this.xpEarned,
      gemsEarned: gemsEarned ?? this.gemsEarned,
      bonusProgress: bonusProgress ?? this.bonusProgress,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      activeCompanion: activeCompanion ?? this.activeCompanion,
    );
  }

  @override
  List<Object?> get props => [
        loadStatus,
        cards,
        currentIndex,
        combo,
        xpEarned,
        gemsEarned,
        bonusProgress,
        errorMessage,
        activeCompanion,
      ];
}

const _sentinel = Object();
