import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/helper/language_helper.dart';
import 'package:test_abc/page/training_feed/widgets/action_rail.dart';
import 'package:test_abc/page/training_feed/widgets/training_feed_card.dart';
import 'package:test_abc/page/training_feed/widgets/widget_card_common.dart';

import '../../../commons/app_colors.dart';
import '../training_feed_cubit.dart';
import '../training_feed_logic.dart';

class LearnCard extends StatefulWidget {
  const LearnCard({
    super.key,
    required this.card,
  });

  final TrainingFeedCard card;

  @override
  State<LearnCard> createState() => _LearnCardState();
}

class _LearnCardState extends State<LearnCard> {
  late bool _showIpa;
  late bool _showMeaning;
  late bool _showExample;
  late bool _showMnemonic;
  bool _mnemonicOpen = false;

  SlotReelEngine? _reel;
  final ValueNotifier<int> _reelTick = ValueNotifier(0);

  String get _wordText => widget.card.title;

  @override
  void initState() {
    super.initState();
    final isAlreadyRevealed = widget.card.isRevealed || widget.card.isCompleted;
    _showIpa = isAlreadyRevealed;
    _showMeaning = isAlreadyRevealed;
    _showExample = isAlreadyRevealed;
    _showMnemonic = isAlreadyRevealed;

    if (!isAlreadyRevealed) {
      _reel = SlotReelEngine(
        word: _wordText,
        onTick: () {
          if (mounted) _reelTick.value++;
        },
        onLetterLocked: (_) => HapticFeedback.lightImpact(),
        onComplete: _revealSequence,
      )..start();
    }
  }

  @override
  void dispose() {
    _reel?.dispose();
    _reelTick.dispose();
    super.dispose();
  }

  void _revealSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() => _showIpa = true);

    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _showMeaning = true);

    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _showExample = true);

    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    setState(() => _showMnemonic = true);

    // Auto-reveal targeting card by ID
    if (!widget.card.isRevealed) {
      context.read<TrainingFeedCubit>().revealCard(widget.card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.card.word?.word;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CardShell(
          event: widget.card.event,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Eyebrow(label: S.of(context).new_word_eyebrow, dotColor: AppColors.xoayCyan),
              const SizedBox(height: 16),
              // ── Word reel (isolated rebuild) ──
              Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _reelTick,
                  builder: (context, _, __) {
                    final isRevealed = widget.card.isRevealed || _reel == null;
                    return Wrap(
                      spacing: 1,
                      children: List.generate(_wordText.length, (i) {
                        final char = _wordText[i];
                        final isSpace = char == ' ';
                        final letter = isSpace
                            ? '  '
                            : (isRevealed ? char : _reel!.displayLetters[i]);
                        final isLocked = isRevealed || _reel!.locked[i];

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          child: Text(
                            letter,
                            style: TextStyle(
                              color: isLocked
                                  ? AppColors.xoayPaper
                                  : AppColors.xoayPaper.withOpacity(0.4),
                              fontWeight: FontWeight.w900,
                              fontSize: 38,
                              height: 1.05,
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // ── IPA + POS tag ──
              AnimatedOpacity(
                opacity: _showIpa ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Center(
                  child: Text(
                    word?.pronunciation ?? '',
                    style: const TextStyle(
                      color: AppColors.xoayCyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedOpacity(
                opacity: _showIpa ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (word?.language != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.xoayCyan.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.xoayCyan.withOpacity(0.3)),
                          ),
                          child: Text(
                            LanguageHelper.getDetectedLanguageLabelTag(word?.language) ?? '',
                            style: const TextStyle(
                              color: AppColors.xoayCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (widget.card.word?.tags != null)
                        ...widget.card.word!.tags!.map((t) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.xoayGold.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.xoayGold.withOpacity(0.3)),
                            ),
                            child: Text(
                              t.tagName,
                              style: const TextStyle(
                                color: AppColors.xoayGold,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // ── Meaning ──
              AnimatedSlide(
                offset: _showMeaning ? Offset.zero : const Offset(0, 0.15),
                duration: const Duration(milliseconds: 500),
                child: AnimatedOpacity(
                  opacity: _showMeaning ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Center(
                    child: Text(
                      word?.meaning ?? '',
                      style: const TextStyle(
                        color: AppColors.xoayPaper,
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              if( word?.example != null)...[
                const SizedBox(height: 16),
                // ── Example ──
                AnimatedOpacity(
                  opacity: _showExample ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.xoayPaper.withOpacity(0.1),
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      word?.example ?? '',
                      style: TextStyle(
                        color: AppColors.xoayPaper.withOpacity(0.58),
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                  ),
                ),
              ],
              // const SizedBox(height: 18),
              // // ── Mnemonic button ──
              // AnimatedOpacity(
              //   opacity: _showMnemonic ? 1.0 : 0.0,
              //   duration: const Duration(milliseconds: 600),
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.start,
              //     children: [
              //       GestureDetector(
              //         onTap: () => setState(() => _mnemonicOpen = !_mnemonicOpen),
              //         child: Container(
              //           padding:
              //               const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              //           decoration: BoxDecoration(
              //             color: AppColors.xoayGold.withOpacity(0.1),
              //             borderRadius: BorderRadius.circular(20),
              //             border: Border.all(
              //               color: AppColors.xoayGold.withOpacity(0.25),
              //             ),
              //           ),
              //           child: const Row(
              //             mainAxisSize: MainAxisSize.min,
              //             children: [
              //               Text('💡', style: TextStyle(fontSize: 12)),
              //               SizedBox(width: 6),
              //               Text(
              //                 'Mẹo nhớ từ',
              //                 style: TextStyle(
              //                   color: AppColors.xoayGold,
              //                   fontSize: 12,
              //                   fontWeight: FontWeight.w600,
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //       AnimatedCrossFade(
              //         firstChild: const SizedBox.shrink(),
              //         secondChild: Padding(
              //           padding: const EdgeInsets.only(top: 10),
              //           child: Text(
              //             word?.example ?? '',
              //             style: TextStyle(
              //               color: AppColors.xoayPaper.withOpacity(0.58),
              //               fontSize: 13,
              //               height: 1.6,
              //             ),
              //           ),
              //         ),
              //         crossFadeState: _mnemonicOpen
              //             ? CrossFadeState.showSecond
              //             : CrossFadeState.showFirst,
              //         duration: const Duration(milliseconds: 300),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
        Positioned(
          right: 16,
          bottom: 18,
          child: const ActionRail(),
        ),
      ],
    );
  }
}