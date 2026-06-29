import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/generated/l10n.dart';

import '../../commons/enums.dart';
import '../../commons/user_sesion.dart';
import '../../helper/language_helper.dart';
import '../../models/entity/active_companion_entity.dart';
import '../../repository/companion_repository.dart';
import '../../repository/vocabulary_repository.dart';
import '../../service/tts_service.dart';
import '../widgets/avatar/xp_cubit.dart';
import 'widgets/training_feed_card.dart';
import 'training_feed_engine.dart';

part 'training_feed_state.dart';

class TrainingFeedCubit extends Cubit<TrainingFeedState> {
  TrainingFeedCubit(
      this._vocabularyRepository,
      this._xpCubit,
      this._companionRepository,
      this._ttsService, {
        TrainingFeedEngine? engine,
      })  : _engine = engine ?? TrainingFeedEngine(),
        super(const TrainingFeedState());

  final VocabularyRepository _vocabularyRepository;
  final XpCubit _xpCubit;
  final CompanionRepository _companionRepository;
  final TtsService _ttsService;
  final TrainingFeedEngine _engine;

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

  void revealCurrentCard() {
    final card = state.currentCard;
    if (card == null || card.type != TrainingFeedCardType.learn) return;

    _replaceCurrentCard(card.copyWith(
      isRevealed: true,
      isCompleted: true,
    ));
    _grantReward(card.xpPreview, card.gemsPreview);
  }

  Future<void> markCurrentCardAsLearned() async {
    final card = state.currentCard;
    if (card == null || card.word == null) return;

    final userKey = UserSession.instance.userKey;
    if (userKey.isEmpty) return;

    try {
      await _vocabularyRepository.changeWordState(card.word!.word.id, 5, userKey);
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
      await _vocabularyRepository.changeWordState(card.word!.word.id, 1, userKey);
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

  void answerCurrentQuiz(int selectedIndex) {
    final card = state.currentCard;
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

    _replaceCurrentCard(answered);

    if (isCorrect) {
      final comboBonus = state.combo >= 3 ? 3 : 0;
      _grantReward(card.xpPreview + comboBonus, card.gemsPreview);
      emit(state.copyWith(combo: state.combo + 1));
      confettiController.add(14);
    } else {
      emit(state.copyWith(combo: 0));
      messageController.add(S.current.quiz_incorrect_hint);
    }
  }

  /// Trả lời quiz âm thanh ("nghe và chọn từ đúng"). Tách riêng khỏi
  /// [answerCurrentQuiz] vì khác loại card, dù phần thưởng/combo tính
  /// tương tự — gộp chung dễ nhầm khi 1 trong 2 luật thay đổi sau này.
  void answerAudioQuiz(int selectedIndex) {
    final card = state.currentCard;
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

    _replaceCurrentCard(answered);

    if (isCorrect) {
      final comboBonus = state.combo >= 3 ? 3 : 0;
      _grantReward(card.xpPreview + comboBonus, card.gemsPreview);
      emit(state.copyWith(combo: state.combo + 1));
      confettiController.add(14);
    } else {
      emit(state.copyWith(combo: 0));
      messageController.add(S.current.audio_quiz_incorrect_hint);
    }
  }

  void claimPassiveReward() {
    final card = state.currentCard;
    if (card == null || card.type != TrainingFeedCardType.reward) return;
    if (card.isCompleted) return;

    _replaceCurrentCard(card.copyWith(isCompleted: true));
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

  void _replaceCurrentCard(TrainingFeedCard card) {
    final updated = [...state.cards];
    updated[state.currentIndex] = card;
    emit(state.copyWith(cards: updated));
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