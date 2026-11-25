import 'package:flutter/material.dart';

import '../../../../commons/app_colors.dart';
import '../../../../generated/l10n.dart';
import '../../logic/test_answer.dart';
import '../../logic/test_kind_question.dart';
import '../ui_test_components.dart';
import 'question_card.dart';

/// The field takes focus when the question appears and loses it once the
/// question is answered (also when the time runs out).
class TypingQuestionView extends StatefulWidget {
  const TypingQuestionView({
    super.key,
    required this.question,
    required this.answer,
    required this.revealed,
    required this.onSubmit,
  });

  final TypingQuestion question;
  final TestAnswer? answer;

  /// Characters shown by hints.
  final int revealed;
  final ValueChanged<String> onSubmit;

  @override
  State<TypingQuestionView> createState() => _TypingQuestionViewState();
}

class _TypingQuestionViewState extends State<TypingQuestionView> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.answer == null) _focusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(TypingQuestionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer == null && widget.answer != null) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Done on the keyboard and the Check button: an empty field is not an
  /// answer (only "don't know" sends one).
  void _submitTyped(String text) {
    if (text.trim().isEmpty) return;
    _submit(text);
  }

  void _submit(String text) {
    FocusScope.of(context).unfocus();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final answered = widget.answer != null;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.xoayGlassBorder),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QuestionCard(label: s.fieldMeaning, text: widget.question.prompt),
        const SizedBox(height: 10),
        QuestionPrompt(s.test_typing_prompt),
        const SizedBox(height: 14),
        if (widget.revealed > 0) ...[
          Text(
            widget.question.hintMask(widget.revealed),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: AppColors.xoayGold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          enabled: !answered,
          // No enableSuggestions: false: on Android Flutter turns it into a
          // visible-password field, and Gboard then blocks Japanese/Chinese
          // input.
          autocorrect: false,
          textAlign: TextAlign.center,
          textInputAction: TextInputAction.done,
          onSubmitted: answered ? null : _submitTyped,
          cursorColor: AppColors.xoayGold,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.xoayPaper,
          ),
          decoration: InputDecoration(
            hintText: s.test_typing_hint_text,
            hintStyle: const TextStyle(
              color: AppColors.xoayPaperDim,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: AppColors.xoaySurface2.withValues(alpha: 0.7),
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide:
                  const BorderSide(color: AppColors.xoayGold, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!answered)
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _submit(''),
                  child: Text(
                    s.test_dont_know,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.xoayPaperDim,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TestScreenPrimaryButton(
                  label: s.test_submit,
                  height: 48,
                  onTap: () => _submitTyped(_controller.text),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
