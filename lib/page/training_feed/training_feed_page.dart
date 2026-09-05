import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/models/entity/active_companion_entity.dart';
import 'package:test_abc/page/training_feed/screen/audio_quizz_card.dart';
import 'package:test_abc/page/training_feed/screen/empty_card.dart';
import 'package:test_abc/page/training_feed/screen/learn_card.dart';
import 'package:test_abc/page/training_feed/screen/break_card.dart';
import 'package:test_abc/page/training_feed/screen/reward_card.dart';
import 'package:test_abc/page/training_feed/widgets/feed_message_widget.dart';
import 'package:test_abc/page/widgets/bubble_button.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/ultis/extension/label_extension.dart';

import '../../commons/app_colors.dart';
import '../../commons/enums.dart';
import '../../repository/vocabulary_repository.dart';
import '../../router/router.dart';
import '../../service/tts_service.dart';
import '../daily_quest/daily_quest_cubit.dart';
import '../daily_quest/models/daily_quest_model.dart';
import '../widgets/avatar/xp_cubit.dart';
import '../widgets/bottom_bar_custom.dart';
import 'screen/quizz_card.dart';
import 'widgets/training_feed_card.dart';
import 'widgets/snappy_feed_scroll_physics.dart';
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
        context.read<TtsService>(),
        onQuizAnswered: () {
          try {
            context.read<DailyQuestCubit>().onProgressByType(QuestType.feedQuiz);
          } catch (_) {}
        },
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

class _TrainingFeedViewState extends State<_TrainingFeedView> {
  final _pageController = PageController();
  final _scrollHintVisible = ValueNotifier<bool>(true);

  // Toast
  final _toastKey = GlobalKey<_ToastOverlayState>();

  // Confetti
  final _confettiKey = GlobalKey<_ConfettiOverlayState>();

  // Companion Bubble
  final _companionKey = GlobalKey<_CompanionBubbleButtonState>();

  StreamSubscription<String>? _messageSubscription;
  StreamSubscription<int>? _confettiSubscription;

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
    _scrollHintVisible.dispose();
    _messageSubscription?.cancel();
    _confettiSubscription?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    if (_scrollHintVisible.value) {
      _scrollHintVisible.value = false;
    }
    final cubit = context.read<TrainingFeedCubit>();
    cubit.onPageChanged(index);
    _companionKey.currentState?.maybeTriggerBubble(cubit.state.activeCompanion);
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
      child: BlocBuilder<TrainingFeedCubit, TrainingFeedState>(
        buildWhen: (previous, current) =>
            previous.loadStatus != current.loadStatus ||
            previous.errorMessage != current.errorMessage,
        builder: (context, state) {
          if (state.loadStatus == LOADSTATUS.LOADING) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.xoayPaper,
              ),
            );
          } else if (state.loadStatus == LOADSTATUS.FAILED) {
            return FeedMessage(
              title: S.of(context).feed_unavailable,
              message: state.errorMessage ?? S.of(context).please_try_again,
              actionLabel: S.of(context).retry,
              onAction: () => context.read<TrainingFeedCubit>().load(),
            );
          }

          return Stack(
            children: [
              // ── Feed PageView (Granular Rebuild Scope) ──
              BlocBuilder<TrainingFeedCubit, TrainingFeedState>(
                buildWhen: (previous, current) =>
                    previous.cards.length != current.cards.length ||
                    previous.loadStatus != current.loadStatus,
                builder: (context, state) {
                  if (state.cards.isEmpty) {
                    return EmptyCard(isEmbedInHome: widget.isEmbedInHome);
                  }

                  return PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.vertical,
                    pageSnapping: false,
                    physics: const SnappyFeedScrollPhysics(
                      snapThreshold: 0.12,
                      parent: BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                    ),
                    itemCount: state.cards.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return _TrainingFeedCardItem(
                        key: ValueKey(state.cards[index].id),
                        index: index,
                        isEmbedInHome: widget.isEmbedInHome,
                      );
                    },
                  );
                },
              ),

              // ── Top bar (self-contained stats observer) ──
              if (!widget.isEmbedInHome) const _TopBar(),

              // ── Companion Bubble Button ──
              Positioned(
                bottom: 115,
                left: 20,
                child: _CompanionBubbleButton(key: _companionKey),
              ),

              // ── Scroll hint ──
              ValueListenableBuilder<bool>(
                valueListenable: _scrollHintVisible,
                builder: (context, visible, _) {
                  return visible ? const _ScrollHint() : const SizedBox.shrink();
                },
              ),

              // ── Bottom nav bar (always visible) ──
              const _BottomNavBar(),

              // ── Toast ──
              _ToastOverlay(key: _toastKey),

              // ── Confetti ──
              _ConfettiOverlay(key: _confettiKey),
            ],
          );
        },
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
// COMPANION BUBBLE BUTTON
// ═══════════════════════════════════════════════════════════════

class _CompanionBubbleButton extends StatefulWidget {
  const _CompanionBubbleButton({super.key});

  @override
  State<_CompanionBubbleButton> createState() => _CompanionBubbleButtonState();
}

class _CompanionBubbleButtonState extends State<_CompanionBubbleButton> {
  String? _companionMessage;
  bool _companionBubbleVisible = false;
  Timer? _companionBubbleTimer;

  void showBubble(String msg) {
    _companionBubbleTimer?.cancel();
    if (mounted) {
      setState(() {
        _companionMessage = msg;
        _companionBubbleVisible = true;
      });
    }
    _companionBubbleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _companionBubbleVisible = false);
      }
    });
  }

  void maybeTriggerBubble(ActiveCompanionEntity? companion) {
    if (companion == null) return;
    final random = Random();
    if (random.nextDouble() > 0.3) return;

    final isPlant = companion.definition?.type == 'plant';
    final plantMessages = [
      S.of(context).companion_plant_msg_1,
      S.of(context).companion_plant_msg_2,
      S.of(context).companion_plant_msg_3,
      S.of(context).companion_plant_msg_4,
      S.of(context).companion_plant_msg_5,
    ];
    final petMessages = [
      S.of(context).companion_pet_msg_1,
      S.of(context).companion_pet_msg_2,
      S.of(context).companion_pet_msg_3,
      S.of(context).companion_pet_msg_4,
      S.of(context).companion_pet_msg_5,
      S.of(context).companion_pet_msg_6,
    ];

    final pool = isPlant ? plantMessages : petMessages;
    final msg = pool[random.nextInt(pool.length)];
    final emoji = companion.definition?.iconKey ?? '🐾';
    final name = companion.displayName;

    showBubble('$emoji $name: $msg');
  }

  @override
  void dispose() {
    _companionBubbleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TrainingFeedCubit, TrainingFeedState>(
      listenWhen: (previous, current) =>
          (previous.loadStatus != current.loadStatus && current.loadStatus == LOADSTATUS.SUCCESS) ||
          (previous.activeCompanion == null && current.activeCompanion != null),
      listener: (context, state) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            maybeTriggerBubble(state.activeCompanion);
          }
        });
      },
      buildWhen: (previous, current) => previous.activeCompanion != current.activeCompanion,
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            BubbleButton(
              width: 45,
              height: 45,
              icon: AppImages.icCompanion,
              onTap: () {
                final userKey = UserSession.instance.userKey;
                context.push(Routes.companionPath(userKey));
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
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP BAR
// ═══════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrainingFeedCubit, TrainingFeedState>(
      buildWhen: (previous, current) =>
          previous.xpEarned != current.xpEarned ||
          previous.combo != current.combo ||
          previous.gemsEarned != current.gemsEarned,
      builder: (context, state) {
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
              Colors.black.withValues(alpha: 0.6),
              Colors.black.withValues(alpha: 0.3),
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
                      color: Colors.white.withValues(alpha: 0.1),
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
                    Text(
                      S.of(context).training_title,
                      style: const TextStyle(
                        color: AppColors.xoayPaper,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      S.of(context).swipe_to_learn,
                      style: TextStyle(
                        color: AppColors.xoayPaper.withValues(alpha: 0.58),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
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
      },
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
// CARD ITEM & VIEW DISPATCHER
// ═══════════════════════════════════════════════════════════════

class _TrainingFeedCardItem extends StatelessWidget {
  const _TrainingFeedCardItem({
    super.key,
    required this.index,
    required this.isEmbedInHome,
  });

  final int index;
  final bool isEmbedInHome;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<TrainingFeedCubit, TrainingFeedState, TrainingFeedCard?>(
      selector: (state) =>
          index < state.cards.length ? state.cards[index] : null,
      builder: (context, card) {
        if (card == null) return const SizedBox.shrink();
        return RepaintBoundary(
          child: _TrainingFeedCardView(
            key: ValueKey('view_${card.id}'),
            card: card,
            isEmbedInHome: isEmbedInHome,
          ),
        );
      },
    );
  }
}

class _TrainingFeedCardView extends StatelessWidget {
  const _TrainingFeedCardView({
    super.key,
    required this.card,
    required this.isEmbedInHome,
  });

  final TrainingFeedCard card;
  final bool isEmbedInHome;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        isEmbedInHome ? (topPadding + 68) : (topPadding + 80),
        16,
        105,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: switch (card.type) {
            TrainingFeedCardType.learn => LearnCard(key: ValueKey('learn_${card.id}'), card: card),
            TrainingFeedCardType.quiz => QuizCard(key: ValueKey('quiz_${card.id}'), card: card),
            TrainingFeedCardType.reward => RewardCard(key: ValueKey('reward_${card.id}'), card: card),
            TrainingFeedCardType.breakPoint => BreakCard(key: ValueKey('break_${card.id}'), card: card),
            TrainingFeedCardType.audioQuiz => AudioQuizCard(key: ValueKey('audio_${card.id}'), card: card),
          },
        ),
      ),
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
            context.push(Routes.listWord);
          } else if (index == 1) {
            context.push(Routes.addWord);
          } else if (index == 3) {
            context.push(Routes.test);
          } else if (index == 4) {
            context.push(Routes.shop);
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book_rounded),
            label: S.of(context).library.capitalize(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: S.of(context).add_word.capitalize(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: S.of(context).home.capitalize(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.quiz_rounded),
            label: S.of(context).test.capitalize(),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_rounded),
            label: S.of(context).shop.capitalize(),
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
                color: AppColors.xoayPaper.withValues(alpha: 0.58),
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.of(context).swipe_up_to_continue,
            style: TextStyle(
              color: AppColors.xoayPaper.withValues(alpha: 0.58),
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
                color: Colors.black.withValues(alpha: 0.25),
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