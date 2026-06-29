// Logic riêng cho "Quiz âm thanh" — nghe phát âm rồi chọn đúng từ.
//
// Tách khỏi `training_feed_engine.dart` để không trộn logic random/chọn
// nhiễu với quiz chữ (`_quizCard`). Hai loại quiz có bản chất khác nhau:
// - Quiz chữ: hiện sẵn chữ, chọn ĐÚNG NGHĨA.
// - Quiz âm thanh: ẩn chữ, chỉ nghe phát âm, chọn ĐÚNG CHỮ trong số các từ
//   có chữ viết dễ nhầm (random trong toàn bộ danh sách từ).
//
// File này chỉ làm 1 việc: build ra `TrainingFeedCard` kiểu `audioQuiz`.
// Không phụ thuộc Cubit, không phụ thuộc TtsService — phát âm thật sự do
// `TrainingFeedCubit.pronounceCurrentWord()` xử lý khi user bấm nút nghe,
// file này chỉ chuẩn bị dữ liệu (từ nào, đáp án nào, nhiễu nào).

import 'dart:math';

import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';

import '../../../models/tag_vocab.dart';


/// Dựng 1 card audio-quiz từ [word] đã được chọn (theo trọng số) ở engine.
///
/// [allWords] dùng để lấy đáp án nhiễu (các từ khác). [random] truyền vào
/// để test được deterministic, không tạo `Random()` mới ở đây.
TrainingFeedCard buildAudioQuizCard({
  required String idSeed,
  required VocabularyWithTags word,
  required List<VocabularyWithTags> allWords,
  required TrainingFeedEvent event,
  required Random random,
}) {
  final others = allWords
      .where((item) => item.word.id != word.word.id)
      .toList()
    ..shuffle(random);

  final choices = <String>[
    word.word.word,
    ...others.take(3).map((item) => item.word.word),
  ]..shuffle(random);

  return TrainingFeedCard(
    id: idSeed,
    type: TrainingFeedCardType.audioQuiz,
    title: S.current.audio_quiz_title,
    subtitle: S.current.audio_quiz_subtitle,
    word: word,
    choices: choices,
    correctChoiceIndex: choices.indexOf(word.word.word),
    event: event,
    xpPreview: (10 * event.multiplier).round(),
    gemsPreview: event.isActive ? 3 : 1,
  );
}