import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/models/entity/active_companion_entity.dart';
import 'package:test_abc/page/companion/companion_page.dart';
import 'package:test_abc/page/training_feed/widgets/rail_button_widget.dart';
import 'package:test_abc/page/widgets/bubble_button.dart';
import 'package:test_abc/repository/companion_repository.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';
import '../add_word/add_word_page.dart';
import '../list_word/list_word_page.dart';
import '../shop/shop_page.dart';
import '../test_word/test_page.dart';
import '../widgets/avatar/xp_cubit.dart';
import '../widgets/bottom_bar_custom.dart';
import 'widgets/training_feed_card.dart';
import 'training_feed_cubit.dart';
import 'training_feed_logic.dart';

class TrainingFeedPage extends StatelessWidget {
  final bool isEmbedInHome;
  const TrainingFeedPage({super.key, this.isEmbedInHome = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrainingFeedCubit(
        context.read<VocabularyRepository>(),
        context.read<XpCubit>(),
        context.read<CompanionRepository>(),
      )..load(),
      child: _TrainingFeedView(isEmbedInHome: isEmbedInHome),
    );
  }
}

class _TrainingFeedView extends StatefulWidget {
  final bool isEmbedInHome;
  const _TrainingFeedView({this.isEmbedInHome = false});

  @override
  State<_TrainingFeedView> createState() => _TrainingFeedViewState();
}

class _TrainingFeedViewState extends State<_TrainingFeedView>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  bool _scrollHintVisible = true;

  // Toast
  final _toastKey = GlobalKey<_ToastOverlayState>();

  // Confetti
  final _confettiKey = GlobalKey<_ConfettiOverlayState>();

  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<int>? _confettiSubscription;

  String? _companionMessage;
  bool _companionBubbleVisible = false;
  Timer? _companionBubbleTimer;

  void _showCompanionBubble(String msg) {
    _companionBubbleTimer?.cancel();
    setState(() {
      _companionMessage = msg;
      _companionBubbleVisible = true;
    });
    _companionBubbleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _companionBubbleVisible = false);
      }
    });
  }

  void _maybeTriggerCompanionBubble(ActiveCompanionEntity? companion) {
    if (companion == null) return;

    // 30% chance to show
    final random = Random();
    if (random.nextDouble() > 0.3) return;

    final isPlant = companion.definition?.type == 'plant';
    final plantMessages = [
      'Tưới nước cho tớ bằng cách học từ nhé! 💧',
      'Mỗi từ mới là một giọt nước mát lành! 🌱',
      'Tớ đang lớn thêm một chút rồi nè! 🌸',
      'Cùng phát triển mỗi ngày nhé! ☀️',
      'Hãy học thêm từ vựng để tớ ra hoa nha! 🌼',
    ];
    final petMessages = [
      'Cho tớ ăn bằng cách học từ mới nha! 🍖',
      'Tớ đói rồi, cùng học từ vựng nào! 🐾',
      'Gâu gâu! Bạn hôm nay tuyệt vời quá! 🐶',
      'Chơi cùng tớ bằng cách học bài nhé! ⚽',
      'Tớ luôn đồng hành cùng bạn! ❤️',
      'Đừng quên ôn lại từ vựng nhé! 🧠',
    ];

    final pool = isPlant ? plantMessages : petMessages;
    final msg = pool[random.nextInt(pool.length)];

    final emoji = companion.definition?.iconKey ?? '🐾';
    final name = companion.displayName;

    _showCompanionBubble('$emoji $name: $msg');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messageSubscription == null) {
      final cubit = context.read<TrainingFeedCubit>();
      _messageSubscription = cubit.messageController.stream.listen(_showToast);
      _confettiSubscription = cubit.confettiController.stream.listen((count) {
        _showConfetti(count: count);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _messageSubscription?.cancel();
    _confettiSubscription?.cancel();
    _companionBubbleTimer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_scrollHintVisible) {
      setState(() => _scrollHintVisible = false);
    }
    final cubit = context.read<TrainingFeedCubit>();
    cubit.onPageChanged(index);
    _maybeTriggerCompanionBubble(cubit.state.activeCompanion);
  }

  void _showToast(String msg) {
    _toastKey.currentState?.show(msg);
  }

  void _showConfetti({int count = 24, List<Color>? colors}) {
    _confettiKey.currentState?.burst(
      count: count,
      colors: colors ??
          const [
            AppColors.xoayCyan,
            AppColors.xoayGold,
          ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedContent = DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.mainGradient),
      child: BlocListener<TrainingFeedCubit, TrainingFeedState>(
        listenWhen: (previous, current) {
          return (previous.loadStatus != current.loadStatus && current.loadStatus == LOADSTATUS.SUCCESS) ||
              (previous.activeCompanion == null && current.activeCompanion != null);
        },
        listener: (context, state) {
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              _maybeTriggerCompanionBubble(state.activeCompanion);
            }
          });
        },
        child: BlocBuilder<TrainingFeedCubit, TrainingFeedState>(
          builder: (context, state) {
          if (state.loadStatus == LOADSTATUS.LOADING) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.xoayPaper,
              ),
            );
          }

          if (state.loadStatus == LOADSTATUS.FAILED) {
            return _FeedMessage(
              title: 'Feed unavailable',
              message: state.errorMessage ?? 'Please try again.',
              actionLabel: 'Retry',
              onAction: () => context.read<TrainingFeedCubit>().load(),
            );
          }

          if (state.cards.isEmpty) {
            return const _FeedMessage(
              title: 'No words yet',
              message: 'Add vocabulary first, then come back here.',
            );
          }

          return Stack(
            children: [
              // ── Feed ──
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: state.cards.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _TrainingFeedCardView(
                    card: state.cards[index],
                    isEmbedInHome: widget.isEmbedInHome,
                  );
                },
              ),

              // ── Top bar ──
              if (!widget.isEmbedInHome) _TopBar(state: state),

              Positioned(
                bottom: 115,
                left: 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    BubbleButton(
                      width: 45,
                      height: 45,
                      icon: AppImages.icCompanion,
                      onTap: () {
                        final userKey = UserSession.instance.userKey;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CompanionPage(userKey: userKey),
                          ),
                        );
                      },
                    ),
                    if (state.activeCompanion != null && _companionBubbleVisible && _companionMessage != null)
                      Positioned(
                        bottom: 60,
                        left: 0,
                        child: AnimatedOpacity(
                          opacity: _companionBubbleVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: _SpeechBubble(message: _companionMessage!),
                        ),
                      ),
                  ],
                ),
              ),
              // ── Scroll hint ──
              if (_scrollHintVisible) const _ScrollHint(),

              // ── Bottom nav bar ──
              const _BottomNavBar(),

              // ── Toast ──
              _ToastOverlay(key: _toastKey),

              // ── Confetti ──
              _ConfettiOverlay(key: _confettiKey),
            ],
          );
        },
      ),
    ),
  );

    if (widget.isEmbedInHome) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: feedContent,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: feedContent,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({required this.state});

  final TrainingFeedState state;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final progress = LevelProgress.fromXp(state.xpEarned);
    final xpPercent = progress.xpPercent;
    final level = progress.level;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, top + 10, 16, 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.6),
              Colors.black.withOpacity(0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row: brand + stats
            Row(
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.xoayPaper,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Brand
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TRAINING',
                      style: TextStyle(
                        color: AppColors.xoayPaper,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'swipe to learn',
                      style: TextStyle(
                        color: AppColors.xoayPaper.withOpacity(0.58),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Stats
                _StatChip(icon: '🔥', value: '${state.combo}'),
                const SizedBox(width: 8),
                _StatChip(icon: '💎', value: '${state.gemsEarned}'),
                const SizedBox(width: 8),
                // Level pill
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppColors.xoayGold, AppColors.xoayMagenta],
                    ),
                  ),
                  child: Text(
                    'Lv.$level',
                    style: const TextStyle(
                      color: Color(0xFF0B0A14),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // XP Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: xpPercent,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.xoayGold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.value});

  final String icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.xoayPaper,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD VIEW DISPATCHER
// ═══════════════════════════════════════════════════════════════

class _TrainingFeedCardView extends StatelessWidget {
  const _TrainingFeedCardView({
    required this.card,
    required this.isEmbedInHome,
  });

  final TrainingFeedCard card;
  final bool isEmbedInHome;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        isEmbedInHome ? 12 : (MediaQuery.of(context).padding.top + 80),
        20,
        110,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: switch (card.type) {
            TrainingFeedCardType.learn => _LearnCard(card: card),
            TrainingFeedCardType.quiz => _QuizCard(card: card),
            TrainingFeedCardType.reward => _RewardCard(card: card),
            TrainingFeedCardType.breakPoint => _BreakCard(card: card),
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EYEBROW LABEL
// ═══════════════════════════════════════════════════════════════

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label, this.dotColor = AppColors.xoayCyan});

  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppColors.xoayPaper.withOpacity(0.58),
            fontWeight: FontWeight.w500,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// LEARN CARD — slot-machine word reveal
// ═══════════════════════════════════════════════════════════════

class _LearnCard extends StatefulWidget {
  const _LearnCard({
    required this.card,
  });

  final TrainingFeedCard card;

  @override
  State<_LearnCard> createState() => _LearnCardState();
}

class _LearnCardState extends State<_LearnCard> {
  bool _showIpa = false;
  bool _showMeaning = false;
  bool _showExample = false;
  bool _showMnemonic = false;
  bool _mnemonicOpen = false;

  late final SlotReelEngine _reel;

  String get _wordText => widget.card.title;

  @override
  void initState() {
    super.initState();
    _reel = SlotReelEngine(
      word: _wordText,
      onTick: () => setState(() {}),
      onLetterLocked: (_) => HapticFeedback.lightImpact(),
      onComplete: _revealSequence,
    )..start();
  }

  @override
  void dispose() {
    _reel.dispose();
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

    // Auto-reveal
    if (!widget.card.isRevealed) {
      context.read<TrainingFeedCubit>().revealCurrentCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final word = widget.card.word?.word;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        _CardShell(
          event: widget.card.event,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _Eyebrow(label: 'TỪ MỚI', dotColor: AppColors.xoayCyan),
              const SizedBox(height: 16),
              // ── Word reel ──
              Center(
                child: Wrap(
                  spacing: 1,
                  children: List.generate(_wordText.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      child: Text(
                        _wordText[i] == ' ' ? '  ' : _reel.displayLetters[i],
                        style: TextStyle(
                          color: _reel.locked[i]
                              ? AppColors.xoayPaper
                              : AppColors.xoayPaper.withOpacity(0.4),
                          fontWeight: FontWeight.w900,
                          fontSize: 38,
                          height: 1.05,
                        ),
                      ),
                    );
                  }),
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
          child: const _ActionRail(),
        ),
      ],
    );
  }
}

class _QuizCard extends StatelessWidget {
  const _QuizCard({
    required this.card,
  });

  final TrainingFeedCard card;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      event: card.event,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _Eyebrow(label: 'ĐOÁN NGHĨA NHANH', dotColor: AppColors.xoayCyan),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.xoayPaper,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: 'Từ '),
                TextSpan(
                  text: card.title,
                  style: const TextStyle(
                    color: AppColors.xoayCyan,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                const TextSpan(text: ' nghĩa là gì?'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // ── 2x2 Grid ──
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: card.choices.length,
            itemBuilder: (context, index) {
              return _QuizOption(
                label: card.choices[index],
                isSelected: card.selectedChoiceIndex == index,
                isCorrect: card.correctChoiceIndex == index,
                isAnswered: card.isAnswered,
                onTap: () {
                  context.read<TrainingFeedCubit>().answerCurrentQuiz(index);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuizOption extends StatelessWidget {
  const _QuizOption({
    required this.label,
    required this.isSelected,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color bgColor = AppColors.xoaySurface2;
    Color borderColor = AppColors.xoayLine;
    Color textColor = AppColors.xoayPaper;

    if (isAnswered && isCorrect) {
      bgColor = AppColors.xoayCyan.withOpacity(0.12);
      borderColor = AppColors.xoayCyan;
      textColor = AppColors.xoayCyan;
    } else if (isAnswered && isSelected) {
      bgColor = AppColors.xoayMagenta.withOpacity(0.12);
      borderColor = AppColors.xoayMagenta;
      textColor = AppColors.xoayMagenta;
    }

    return GestureDetector(
      onTap: isAnswered ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REWARD / JACKPOT CARD — shimmer
// ═══════════════════════════════════════════════════════════════

class _RewardCard extends StatelessWidget {
  const _RewardCard({
    required this.card,
  });

  final TrainingFeedCard card;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      shimmer: true,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Eyebrow(label: 'JACKPOT 🎰', dotColor: AppColors.xoayGold),
            const SizedBox(height: 18),
            // Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppColors.xoayGold, AppColors.xoayGoldDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.xoayGold.withOpacity(0.35),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: const Text(
                '🎉 BẤT NGỜ HÔM NAY',
                style: TextStyle(
                  color: Color(0xFF0B0A14),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Reward details (Dynamic XP & Gems side-by-side)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (card.xpPreview > 0) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${card.xpPreview}',
                        style: const TextStyle(
                          color: AppColors.xoayGold,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'XP THƯỞNG',
                        style: TextStyle(
                          color: AppColors.xoayPaper.withOpacity(0.58),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
                if (card.xpPreview > 0 && card.gemsPreview > 0)
                  const SizedBox(width: 36),
                if (card.gemsPreview > 0) ...[
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '+${card.gemsPreview}',
                        style: const TextStyle(
                          color: AppColors.xoayCyan,
                          fontWeight: FontWeight.w900,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '💎 GEMS',
                        style: TextStyle(
                          color: AppColors.xoayCyan.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const SizedBox(height: 28),
            // Claim
            _XoayButton(
              label: card.isCompleted ? 'Đã nhận' : 'Nhận thưởng',
              icon: card.isCompleted
                  ? Icons.check_rounded
                  : Icons.card_giftcard_rounded,
              onTap: () {
                context.read<TrainingFeedCubit>().claimPassiveReward();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BREAK CARD
// ═══════════════════════════════════════════════════════════════

class _BreakCard extends StatelessWidget {
  const _BreakCard({required this.card});

  final TrainingFeedCard card;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Eyebrow(
              label: 'NGHỈ NGƠI',
              dotColor: AppColors.xoayPaperDim,
            ),
            const SizedBox(height: 18),
            const Icon(Icons.flag_rounded, color: AppColors.xoayPaper, size: 52),
            const SizedBox(height: 22),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.xoayPaper,
                fontSize: 30,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              card.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.xoayPaper.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 28),
            _XoayButton(
              label: 'Rời đi',
              icon: Icons.check_rounded,
              onTap: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD SHELL (backdrop + event badge)
// ═══════════════════════════════════════════════════════════════

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.event = const TrainingFeedEvent.none(),
    this.shimmer = false,
  });

  final Widget child;
  final TrainingFeedEvent event;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: shimmer
              ? AppColors.xoayGold.withOpacity(0.25)
              : Colors.white.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (event.isActive)
            Align(
              alignment: Alignment.topCenter,
              child: _EventBadge(event: event),
            ),
          Padding(
            padding: EdgeInsets.only(top: event.isActive ? 42 : 0),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _EventBadge extends StatelessWidget {
  const _EventBadge({required this.event});

  final TrainingFeedEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.xoayGold, AppColors.xoayMagenta],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        '${event.title} x${event.multiplier.toStringAsFixed(event.multiplier == event.multiplier.roundToDouble() ? 0 : 2)}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTION RAIL
// ═══════════════════════════════════════════════════════════════

class _ActionRail extends StatelessWidget {
  const _ActionRail();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TrainingFeedCubit>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RailButton(
          icon: Icons.favorite_rounded,
          label: 'Đã thuộc',
          isActive: false,
          activeColor: AppColors.xoayMagenta,
          onTap: cubit.markCurrentCardAsLearned,
        ),
        const SizedBox(height: 18),
        RailButton(
          icon: Icons.bookmark_rounded,
          label: 'Ôn lại',
          isActive: false,
          activeColor: AppColors.xoayGold,
          onTap: cubit.saveCurrentCardForReview,
        ),
        const SizedBox(height: 18),
        RailButton(
          icon: Icons.volume_up_rounded,
          label: 'Phát âm',
          isActive: false,
          activeColor: AppColors.xoayCyan,
          onTap: cubit.pronounceCurrentWord,
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BOTTOM NAVIGATION BAR
// ═══════════════════════════════════════════════════════════════

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: LodgeBottomNavBar(
        selectedIndex: 2,
        backgroundColor: const Color(0xE6141120),
        selectedItemColor: AppColors.xoayGold,
        unselectedItemColor: AppColors.xoayPaperDim,
        centerButtonColor: AppColors.xoayGold,
        centerIcon: const Icon(
          Icons.home_rounded,
          color: Color(0xFF0B0A14),
          size: 30,
        ),
        onCenterButtonPressed: () {},
        onTabSelected: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListWordPage()),
            );
          } else if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddWordPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TestPage()),
            );
          } else if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShopPage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Thư viện',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            label: 'Thêm từ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz_rounded),
            label: 'Kiểm tra',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_rounded),
            label: 'Shop',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SCROLL HINT
// ═══════════════════════════════════════════════════════════════

class _ScrollHint extends StatefulWidget {
  const _ScrollHint();

  @override
  State<_ScrollHint> createState() => _ScrollHintState();
}

class _ScrollHintState extends State<_ScrollHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _ctrl.value * 6),
                child: child,
              );
            },
            child: Text(
              '⌃',
              style: TextStyle(
                color: AppColors.xoayPaper.withOpacity(0.58),
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'LƯỚT LÊN ĐỂ TIẾP TỤC',
            style: TextStyle(
              color: AppColors.xoayPaper.withOpacity(0.58),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOAST OVERLAY
// ═══════════════════════════════════════════════════════════════

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({super.key});

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  String _message = '';
  bool _visible = false;
  Timer? _timer;

  void show(String msg) {
    _timer?.cancel();
    setState(() {
      _message = msg;
      _visible = true;
    });
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Positioned(
      top: top + 60,
      left: 0,
      right: 0,
      child: Center(
        child: AnimatedSlide(
          offset: _visible ? Offset.zero : const Offset(0, -0.4),
          duration: const Duration(milliseconds: 300),
          child: AnimatedOpacity(
            opacity: _visible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xF014111E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.xoayLine),
              ),
              child: Text(
                _message,
                style: const TextStyle(
                  color: AppColors.xoayPaper,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONFETTI OVERLAY
// ═══════════════════════════════════════════════════════════════

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay({super.key});

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay> {
  final List<ConfettoModel> _confetti = [];
  final _random = Random();
  int _idCounter = 0;

  void burst({int count = 24, List<Color>? colors}) {
    final palette = colors ?? [AppColors.xoayCyan, AppColors.xoayGold];
    setState(() {
      _confetti.addAll(generateConfetti(
        count: count,
        palette: palette,
        idStart: _idCounter,
        random: _random,
      ));
      _idCounter += count;
    });
  }

  void _removeConfetto(int id) {
    setState(() => _confetti.removeWhere((c) => c.id == id));
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: _confetti.map((c) {
            return _ConfettoWidget(
              key: ValueKey(c.id),
              confetto: c,
              onDone: () => _removeConfetto(c.id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ConfettoWidget extends StatefulWidget {
  const _ConfettoWidget({
    super.key,
    required this.confetto,
    required this.onDone,
  });

  final ConfettoModel confetto;
  final VoidCallback onDone;

  @override
  State<_ConfettoWidget> createState() => _ConfettoWidgetState();
}

class _ConfettoWidgetState extends State<_ConfettoWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _yAnim;
  late final Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.confetto.duration,
    );
    _yAnim = Tween<double>(begin: -12, end: 640).animate(_ctrl);
    _opacityAnim = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.6, 1.0)),
    );
    _ctrl.forward().then((_) => widget.onDone());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          left: widget.confetto.left * width,
          top: _yAnim.value,
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Transform.rotate(
              angle: widget.confetto.rotation +
                  _ctrl.value * 7.3, // ~420 degrees
              child: Container(
                width: widget.confetto.size,
                height: widget.confetto.size * 0.4,
                decoration: BoxDecoration(
                  color: widget.confetto.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════

class _XoayButton extends StatelessWidget {
  const _XoayButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [AppColors.xoayGold, AppColors.xoayMagenta],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF0B0A14), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF0B0A14),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedMessage extends StatelessWidget {
  const _FeedMessage({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.xoayPaper,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.xoayPaper.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              _XoayButton(
                label: actionLabel!,
                icon: Icons.refresh_rounded,
                onTap: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COMPANION SPEECH BUBBLE
// ═══════════════════════════════════════════════════════════════

class _SpeechBubble extends StatelessWidget {
  final String message;

  const _SpeechBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 220),
          decoration: BoxDecoration(
            color: const Color(0xF014111E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.xoayLine, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.xoayPaper,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: CustomPaint(
            size: const Size(12, 6),
            painter: _BubbleTrianglePainter(),
          ),
        ),
      ],
    );
  }
}

class _BubbleTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xF014111E)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = AppColors.xoayLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final borderPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0);

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}