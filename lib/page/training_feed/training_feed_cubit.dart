import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../commons/enums.dart';
import '../../commons/status_comon.dart';
import '../../commons/user_sesion.dart';
import '../../helper/language_helper.dart';
import '../../models/entity/active_companion_entity.dart';
import '../../repository/companion_repository.dart';
import '../../repository/learning_history_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../service/alarm_service.dart';
import '../../service/tts_service.dart';
import '../widgets/avatar/xp_cubit.dart';
import 'widgets/training_feed_card.dart';
import 'training_feed_engine.dart';

part 'training_feed_state.dart';

class TrainingFeedCubit extends Cubit<TrainingFeedState> {
  final void Function()? onQuizAnswered;

  TrainingFeedCubit(
      this._vocabularyRepository,
      this._xpCubit,
      this._companionRepository,
      this._ttsService, {
        TrainingFeedEngine? engine,
        LearningHistoryRepository? historyRepository,
        this.onQuizAnswered,
      })  : _engine = engine ?? TrainingFeedEngine(),
        _historyRepository = historyRepository,
        super(const TrainingFeedState());

  final VocabularyRepository _vocabularyRepository;
  final XpCubit _xpCubit;
  final CompanionRepository _companionRepository;
  final TtsService _ttsService;
  final TrainingFeedEngine _engine;
  final LearningHistoryRepository? _historyRepository;

  final PublishSubject<String> messageController = PublishSubject();
  final PublishSubject<int> confettiController = PublishSubject();

  StreamSubscription<ActiveCompanionEntity?>? _companionSub;

  Future<void> load() async {
    emit(state.copyWith(
      loadStatus: LOADSTATUS.LOADING,
      errorMessage: null,
    ));

    await _companionSub?.cancel();
    final userKey = UserSession.instance.userKey;
    if (userKey.isNotEmpty) {
      _companionSub = _companionRepository.watchActiveCompanion(userKey).listen((activeCompanion) {
        emit(state.copyWith(activeCompanion: activeCompanion));
      });
    }

    try {
      final words = await _vocabularyRepository.watchAllWordsWithTags().first;
      final deck = _engine.buildInitialDeck(words);

      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        cards: deck,
        currentIndex: 0,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: S.current.error_load_feed(e.toString()),
      ));
    }
  }

  Future<void> onPageChanged(int index) async {
    emit(state.copyWith(currentIndex: index));

    if (state.cards.length - index <= 4) {
      await _appendMoreCards();
    }
  }

  void revealCard(String cardId) {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    final card = index != -1 ? state.cards[index] : state.currentCard;
    if (card == null || card.type != TrainingFeedCardType.learn || card.isRevealed) return;

    // Revealing the meaning is not an answer, so it pays nothing.
    _replaceCard(card.copyWith(
      isRevealed: true,
      isCompleted: true,
    ));
  }

  void revealCurrentCard() {
    if (state.currentCard != null) {
      revealCard(state.currentCard!.id);
    }
  }

  Future<void> markCurrentCardAsLearned() async {
    final card = state.currentCard;
    if (card == null || card.word == null) return;

    final userKey = UserSession.instance.userKey;
    if (userKey.isEmpty) return;

    try {
      await _vocabularyRepository.markWordMastered(card.word!.word.id, userKey);
      unawaited(AlarmService.syncReviewReminder(_vocabularyRepository));
      messageController.add(S.current.memorized);
      confettiController.add(10);
    } catch (e) {
      messageController.add(S.current.error_remember_word(e.toString()));
    }
  }

  Future<void> saveCurrentCardForReview() async {
    final card = state.currentCard;
    if (card == null || card.word == null) return;

    final userKey = UserSession.instance.userKey;
    if (userKey.isEmpty) return;

    try {
      await _vocabularyRepository.returnWordToReview(card.word!.word.id, userKey);
      unawaited(AlarmService.syncReviewReminder(_vocabularyRepository));
      messageController.add(S.current.saved_for_review);
    } catch (e) {
      messageController.add(S.current.error_save_review(e.toString()));
    }
  }

  Future<void> pronounceCurrentWord() async {
    final card = state.currentCard;
    if (card == null || card.word == null) return;

    final word = card.word!.word;
    final result = await _ttsService.speakWord(word.word, languageCode: word.language);

    switch (result) {
      case TtsSpeakResult.ok:
      //messageController.add(' Phát âm: ${word.word}');
        break;
      case TtsSpeakResult.languageUnavailable:
        messageController.add(
          S.current.tts_voice_unavailable(LanguageHelper.getDetectedLanguageLabelTag(word.language) ?? ''),
        );
        await _ttsService.openVoiceDataInstaller();
        break;
      case TtsSpeakResult.empty:
        break;
    }
  }

  void answerQuizCard(String cardId, int selectedIndex) {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    final card = index != -1 ? state.cards[index] : state.currentCard;
    if (card == null ||
        card.type != TrainingFeedCardType.quiz ||
        card.isAnswered) {
      return;
    }

    final answered = card.copyWith(
      selectedChoiceIndex: selectedIndex,
      isCompleted: true,
    );
    final isCorrect = selectedIndex == card.correctChoiceIndex;

    _replaceCard(answered);
    onQuizAnswered?.call();
    unawaited(_recordAnswer(card, isCorrect));

    _settleAnswer(card, isCorrect, S.current.quiz_incorrect_hint);
  }

  void answerCurrentQuiz(int selectedIndex) {
    if (state.currentCard != null) {
      answerQuizCard(state.currentCard!.id, selectedIndex);
    }
  }

  void answerAudioQuizCard(String cardId, int selectedIndex) {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    final card = index != -1 ? state.cards[index] : state.currentCard;
    if (card == null ||
        card.type != TrainingFeedCardType.audioQuiz ||
        card.isAnswered) {
      return;
    }

    final answered = card.copyWith(
      selectedChoiceIndex: selectedIndex,
      isCompleted: true,
    );
    final isCorrect = selectedIndex == card.correctChoiceIndex;

    _replaceCard(answered);
    onQuizAnswered?.call();
    unawaited(_recordAnswer(card, isCorrect));

    _settleAnswer(card, isCorrect, S.current.audio_quiz_incorrect_hint);
  }

  void answerAudioQuiz(int selectedIndex) {
    if (state.currentCard != null) {
      answerAudioQuizCard(state.currentCard!.id, selectedIndex);
    }
  }

  void claimRewardCard(String cardId) {
    final index = state.cards.indexWhere((c) => c.id == cardId);
    final card = index != -1 ? state.cards[index] : state.currentCard;
    if (card == null || card.type != TrainingFeedCardType.reward) return;
    if (card.isCompleted) return;

    // The bonus has to be earned with quiz answers; swiping to it is not
    // enough.
    if (!state.isBonusUnlocked) {
      messageController
          .add(S.current.reward_locked_hint(state.bonusAnswersLeft));
      return;
    }

    _replaceCard(card.copyWith(isCompleted: true));
    emit(state.copyWith(bonusProgress: 0));
    _grantReward(card.xpPreview, card.gemsPreview);
    confettiController.add(48);

    final List<String> rewards = [];
    if (card.xpPreview > 0) {
      rewards.add('+${card.xpPreview} XP');
    }
    if (card.gemsPreview > 0) {
      rewards.add('+${card.gemsPreview} Gems');
    }
    messageController.add(S.current.claimed_rewards(rewards.join(S.current.and_connector)));
  }

  void claimPassiveReward() {
    if (state.currentCard != null) {
      claimRewardCard(state.currentCard!.id);
    }
  }

  /// Reward, combo and bonus progress of an answered quiz card.
  void _settleAnswer(
    TrainingFeedCard card,
    bool isCorrect,
    String incorrectHint,
  ) {
    if (!isCorrect) {
      emit(state.copyWith(combo: 0));
      messageController.add(incorrectHint);
      return;
    }

    // With a single choice there was nothing to get wrong.
    if (card.choices.length < 2) return;

    final comboBonus = state.combo >= 3 ? 3 : 0;
    final bonusProgress =
        state.bonusProgress >= TrainingFeedState.bonusRequirement
            ? state.bonusProgress
            : state.bonusProgress + 1;
    emit(state.copyWith(
      combo: state.combo + 1,
      bonusProgress: bonusProgress,
    ));
    _grantReward(card.xpPreview + comboBonus, card.gemsPreview);
    confettiController.add(14);
  }

  Future<void> _appendMoreCards() async {
    try {
      final words = await _vocabularyRepository.watchAllWordsWithTags().first;
      if (words.isEmpty) return;

      final updatedCards = [...state.cards];
      for (int i = 0; i < 6; i++) {
        final previousType = updatedCards.isNotEmpty ? updatedCards.last.type : null;
        final nextCard = _engine.nextCard(
          words,
          updatedCards.length,
          previousType: previousType,
        );
        updatedCards.add(nextCard);
      }

      emit(state.copyWith(cards: updatedCards));
    } catch (_) {
      // Keep the current deck usable if background refill fails.
    }
  }

  void _replaceCard(TrainingFeedCard card) {
    final index = state.cards.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      if (state.currentIndex < state.cards.length) {
        final updated = [...state.cards];
        updated[state.currentIndex] = card;
        emit(state.copyWith(cards: updated));
      }
      return;
    }
    final updated = [...state.cards];
    updated[index] = card;
    emit(state.copyWith(cards: updated));
  }

  void _replaceCurrentCard(TrainingFeedCard card) => _replaceCard(card);

  /// Writes the answer to the word's counters and the learning history.
  Future<void> _recordAnswer(TrainingFeedCard card, bool isCorrect) async {
    final history = _historyRepository;
    final word = card.word?.word;
    if (history == null || word == null) return;
    try {
      await history.recordAnswer(
        userKey: UserSession.instance.userKey,
        wordId: word.id,
        wordLevelSnapshot: word.level,
        sessionType: SessionType.feed,
        isCorrect: isCorrect,
      );
    } catch (_) {
      // Statistics must never interrupt the feed.
    }
  }

  Future<void> _grantReward(int xp, int gems) async {
    if (xp <= 0 && gems <= 0) return;

    emit(state.copyWith(
      xpEarned: state.xpEarned + xp,
      gemsEarned: state.gemsEarned + gems,
    ));

    if (xp > 0) await _xpCubit.addXp(xp);
    if (gems > 0) await _xpCubit.addGems(gems);
  }

  @override
  Future<void> close() {
    _companionSub?.cancel();
    messageController.close();
    confettiController.close();
    return super.close();
  }
}