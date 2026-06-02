import 'dart:async';
import 'dart:math';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/ultis/error_utils.dart';

import '../../../commons/enums.dart';
import '../../../commons/user_sesion.dart';
import '../../../models/entity/active_companion_entity.dart';
import '../../../models/tag_vocab.dart';
import '../../../database/app_db.dart';
import '../learning_cubit.dart';

part 'word_matching_state.dart';

class WordMatchingCubit extends Cubit<WordMatchingState> {
  final VocabularyRepository _repo;
  final CompanionRepository _repoCompanion;
  final LearningHistoryRepository _repoHistory;
  final LearningConfig? config;

  final PublishSubject<String> messageController = PublishSubject();
  final userKey = UserSession.instance.userKey;

  Timer? _timer;

  // ── _allVocab đã được xóa: vocab giờ sống trong state.allVocab ──

  WordMatchingCubit(
    this._repo,
    this._repoCompanion,
    this._repoHistory, {
    this.config,
  }) : super(const WordMatchingState());

  // ─── Lifecycle ──────────────────────────────────────────────

  Future<void> start() async {
    emit(state.copyWith(loadStatus: LOADSTATUS.LOADING));
    _stopTimer();

    try {
      // 1. Fetch companion
      ActiveCompanionEntity? activeCompanion;

      // 2. Fetch vocabulary
      final words = await _repo.watchAllWordsWithTags().first;
      
      // Apply filters from config
      var filtered = List<VocabularyWithTags>.from(words);
      if (config != null) {
        if (config!.language != null && config!.language!.isNotEmpty) {
          filtered = filtered.where((w) => w.word.language == config!.language).toList();
        }
        if (config!.unitId != null) {
          filtered = filtered.where((w) => w.word.unitId == config!.unitId).toList();
        }
      }

      final shuffled = List<VocabularyWithTags>.of(filtered)..shuffle();

      // Limit the number of words
      final finalWords = (config != null && config!.limitWords != null && config!.limitWords! > 0)
          ? shuffled.take(config!.limitWords!).toList()
          : shuffled;

      if (finalWords.isEmpty) {
        // Không đủ dữ liệu → báo completed sớm thay vì dùng fallback cứng
        emit(state.copyWith(
          loadStatus: LOADSTATUS.SUCCESS,
          activeCompanion: activeCompanion,
          allVocab: const [],
          gameStatus: WordMatchingGameStatus.completed,
        ));
        return;
      }

      // 3. Lưu vocab vào state (không còn _allVocab instance field)
      emit(state.copyWith(
        loadStatus: LOADSTATUS.SUCCESS,
        activeCompanion: activeCompanion,
        allVocab: finalWords,
        level: 1,
        score: 0,
      ));

      _setupLevel(1);
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      emit(state.copyWith(
        loadStatus: LOADSTATUS.FAILED,
        errorMessage: errMsg,
      ));
      messageController.sink.add(errMsg);
    }
  }

  void restart() => start();

  // ─── Gameplay Logic ─────────────────────────────────────────

  void selectLeftItem(int id) {
    if (state.gameStatus != WordMatchingGameStatus.playing) return;
    if (state.matchedIds.contains(id)) return;

    if (state.selectedLeftId == id) {
      emit(state.copyWith(clearLeftSelection: true));
      _updateItemSelectionStatus();
      return;
    }

    emit(state.copyWith(selectedLeftId: id));
    _updateItemSelectionStatus();

    if (state.selectedRightId != null) {
      _checkMatch(id, state.selectedRightId!);
    }
  }

  void selectRightItem(int id) {
    if (state.gameStatus != WordMatchingGameStatus.playing) return;
    if (state.matchedIds.contains(id)) return;

    if (state.selectedRightId == id) {
      emit(state.copyWith(clearRightSelection: true));
      _updateItemSelectionStatus();
      return;
    }

    emit(state.copyWith(selectedRightId: id));
    _updateItemSelectionStatus();

    if (state.selectedLeftId != null) {
      _checkMatch(state.selectedLeftId!, id);
    }
  }

  Future<void> _checkMatch(int leftId, int rightId) async {
    if (leftId == rightId) {
      // ─── CORRECT MATCH ───────────────────
      final updatedMatched = Set<int>.from(state.matchedIds)..add(leftId);

      final leftItems = state.leftItems.map((e) {
        if (e.id == leftId) return e.copyWith(status: WordMatchingItemStatus.correct);
        return e;
      }).toList();

      final rightItems = state.rightItems.map((e) {
        if (e.id == rightId) return e.copyWith(status: WordMatchingItemStatus.correct);
        return e;
      }).toList();

      emit(state.copyWith(
        matchedIds: updatedMatched,
        leftItems: leftItems,
        rightItems: rightItems,
        score: state.score + 10,
        clearLeftSelection: true,
        clearRightSelection: true,
      ));

      if (updatedMatched.length == state.leftItems.length) {
        _stopTimer();
        emit(state.copyWith(gameStatus: WordMatchingGameStatus.roundComplete));

        await Future.delayed(const Duration(milliseconds: 1000));

        if (state.level >= 5) {
          await _completeSession();
        } else {
          _setupLevel(state.level + 1);
        }
      }
    } else {
      // ─── MISMATCH / WRONG ─────────────────
      final leftItems = state.leftItems.map((e) {
        if (e.id == leftId) return e.copyWith(status: WordMatchingItemStatus.wrong);
        return e;
      }).toList();

      final rightItems = state.rightItems.map((e) {
        if (e.id == rightId) return e.copyWith(status: WordMatchingItemStatus.wrong);
        return e;
      }).toList();

      emit(state.copyWith(
        gameStatus: WordMatchingGameStatus.wrongAnimation,
        leftItems: leftItems,
        rightItems: rightItems,
      ));

      await Future.delayed(const Duration(milliseconds: 500));

      if (isClosed) return;

      final resetLeft = state.leftItems.map((e) {
        if (e.id == leftId) return e.copyWith(status: WordMatchingItemStatus.idle);
        return e;
      }).toList();

      final resetRight = state.rightItems.map((e) {
        if (e.id == rightId) return e.copyWith(status: WordMatchingItemStatus.idle);
        return e;
      }).toList();

      emit(state.copyWith(
        gameStatus: WordMatchingGameStatus.playing,
        leftItems: resetLeft,
        rightItems: resetRight,
        clearLeftSelection: true,
        clearRightSelection: true,
      ));
    }
  }

  // ─── Level Initialization Helpers ───────────────────────────

  void _setupLevel(int level) {
    final pairCount = 5 + level;

    // Dùng state.allVocab thay vì _allVocab instance field
    final shuffledVocab = List<VocabularyWithTags>.from(state.allVocab)..shuffle();
    final roundVocab = shuffledVocab.take(min(pairCount, shuffledVocab.length)).toList();

    final leftItems = roundVocab
        .map((e) => WordMatchingItem(id: e.word.id, text: e.word.word, isMeaning: false))
        .toList()
      ..shuffle();

    final rightItems = roundVocab
        .map((e) => WordMatchingItem(id: e.word.id, text: e.word.meaning, isMeaning: true))
        .toList()
      ..shuffle();

    final roundTime = pairCount * 5 + 5;

    emit(state.copyWith(
      level: level,
      leftItems: leftItems,
      rightItems: rightItems,
      matchedIds: {},
      clearLeftSelection: true,
      clearRightSelection: true,
      timeRemaining: roundTime,
      totalTime: roundTime,
      gameStatus: WordMatchingGameStatus.playing,
    ));

    _startTimer();
  }

  void _updateItemSelectionStatus() {
    final left = state.leftItems.map((item) {
      if (state.matchedIds.contains(item.id)) {
        return item.copyWith(status: WordMatchingItemStatus.correct);
      }
      if (item.id == state.selectedLeftId) {
        return item.copyWith(status: WordMatchingItemStatus.selected);
      }
      return item.copyWith(status: WordMatchingItemStatus.idle);
    }).toList();

    final right = state.rightItems.map((item) {
      if (state.matchedIds.contains(item.id)) {
        return item.copyWith(status: WordMatchingItemStatus.correct);
      }
      if (item.id == state.selectedRightId) {
        return item.copyWith(status: WordMatchingItemStatus.selected);
      }
      return item.copyWith(status: WordMatchingItemStatus.idle);
    }).toList();

    emit(state.copyWith(leftItems: left, rightItems: right));
  }

  // ─── Timer Handlers ──────────────────────────────────────────

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (state.timeRemaining <= 1) {
        _stopTimer();
        emit(state.copyWith(
          timeRemaining: 0,
          gameStatus: WordMatchingGameStatus.gameOver,
        ));
      } else {
        emit(state.copyWith(timeRemaining: state.timeRemaining - 1));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ─── Reward & History Saves ─────────────────────────────────

  Future<void> _completeSession() async {
    _stopTimer();
    emit(state.copyWith(gameStatus: WordMatchingGameStatus.completed));

    try {
      final futures = state.leftItems.map((item) {
        return _repoHistory.logWordLearned(
          userKey: userKey,
          wordId: item.id,
          wordLevelSnapshot: 1,
          sessionType: 'WordMatching',
          isCorrect: true,
        );
      });
      await Future.wait(futures);
    } catch (_) {
      // safe fallback
    }
  }

  Future<void> earnFood(double wordsCount) async {
    if (!state.hasActiveCompanion || wordsCount <= 0) return;

    try {
      final foodEarned = await _repoCompanion.earnFood(
        userKey: userKey,
        wordsLearned: wordsCount,
      );

      if (foodEarned > 0) {
        emit(state.copyWith(lastFoodEarned: foodEarned));
      }
    } catch (e) {
      final errMsg = ErrorUtils.networkErrorToMessage(e);
      messageController.sink.add(errMsg);
    }
  }

  @override
  Future<void> close() {
    _stopTimer();
    messageController.close();
    return super.close();
  }
}