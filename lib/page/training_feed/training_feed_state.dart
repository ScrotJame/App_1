part of 'training_feed_cubit.dart';

class TrainingFeedState extends Equatable {
  const TrainingFeedState({
    this.loadStatus = LOADSTATUS.INITAL,
    this.cards = const [],
    this.currentIndex = 0,
    this.combo = 0,
    this.xpEarned = 0,
    this.gemsEarned = 0,
    this.errorMessage,
  });

  final LOADSTATUS loadStatus;
  final List<TrainingFeedCard> cards;
  final int currentIndex;
  final int combo;
  final int xpEarned;
  final int gemsEarned;
  final String? errorMessage;

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
    Object? errorMessage = _sentinel,
  }) {
    return TrainingFeedState(
      loadStatus: loadStatus ?? this.loadStatus,
      cards: cards ?? this.cards,
      currentIndex: currentIndex ?? this.currentIndex,
      combo: combo ?? this.combo,
      xpEarned: xpEarned ?? this.xpEarned,
      gemsEarned: gemsEarned ?? this.gemsEarned,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
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
        errorMessage,
      ];
}

const _sentinel = Object();
