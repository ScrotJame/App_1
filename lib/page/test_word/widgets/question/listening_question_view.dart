import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../commons/app_colors.dart';
import '../../../../commons/enums.dart';
import '../../../../generated/l10n.dart';
import '../../../../service/tts_service.dart';
import '../../logic/test_answer.dart';
import '../../logic/test_kind_question.dart';
import 'choice_list.dart';

/// Plays the word when shown. Shows the word as text once answered, or when
/// the sound cannot be played.
class ListeningQuestionView extends StatefulWidget {
  const ListeningQuestionView({
    super.key,
    required this.question,
    required this.answer,
    required this.eliminated,
    required this.onSelect,
  });

  final ListeningQuestion question;
  final TestAnswer? answer;
  final List<int> eliminated;
  final ValueChanged<int> onSelect;

  @override
  State<ListeningQuestionView> createState() => _ListeningQuestionViewState();
}

class _ListeningQuestionViewState extends State<ListeningQuestionView> {
  late final TtsService _tts;
  bool _audioFailed = false;

  @override
  void initState() {
    super.initState();
    _tts = context.read<TtsService>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play();
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _play() async {
    TtsSpeakResult result;
    try {
      result = await _tts.speakWord(
        widget.question.spokenText,
        languageCode: widget.question.language,
      );
    } catch (_) {
      result = TtsSpeakResult.languageUnavailable;
    }
    if (!mounted) {
      // The view went away while the platform was preparing the sound.
      _tts.stop();
      return;
    }
    if (result != TtsSpeakResult.ok) setState(() => _audioFailed = true);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final q = widget.question;
    final reading = q.entry.pronunciation ?? '';
    final showText = _audioFailed || widget.answer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.kBlueBg,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: _play,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    color: AppColors.kBlueMid,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up_rounded,
                      size: 44, color: AppColors.kBlue),
                ),
              ),
              const SizedBox(height: 12),
              Text(s.test_listen_again,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.kTextMuted)),
              if (showText) ...[
                const SizedBox(height: 14),
                Text(
                  q.spokenText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textBlack,
                  ),
                ),
                if (reading.isNotEmpty)
                  Text(reading,
                      style: const TextStyle(
                          fontSize: 15, color: AppColors.kTextMuted)),
              ],
              if (_audioFailed) ...[
                const SizedBox(height: 8),
                Text(s.test_audio_failed,
                    style:
                        const TextStyle(fontSize: 12, color: AppColors.kRed)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          s.test_listen_prompt,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.kTextMuted,
          ),
        ),
        const SizedBox(height: 14),
        ChoiceList(
          question: q,
          answer: widget.answer,
          eliminated: widget.eliminated,
          onSelect: widget.onSelect,
        ),
      ],
    );
  }
}
