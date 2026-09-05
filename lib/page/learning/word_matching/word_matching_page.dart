import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/components/popup_dialog.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import '../../../commons/enums.dart';
import '../../../repository/companion_repository.dart';
import '../../../repository/vocabulary_repository.dart';
import '../../widgets/avatar/xp_cubit.dart';
import '../learning_cubit.dart';
import 'word_matching_cubit.dart' hide WordMatchingItemStatus;

const int _kXpBaseBonus = 10;

class WordMatchingPage extends StatefulWidget {
  const WordMatchingPage({super.key});

  @override
  State<WordMatchingPage> createState() => _WordMatchingPageState();
}

class _WordMatchingPageState extends State<WordMatchingPage> {
  late WordMatchingCubit _cubit;
  StreamSubscription<String>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    final config = context.read<LearningCubit>().state.config;
    _cubit = WordMatchingCubit(
      context.read<VocabularyRepository>(),
      context.read<CompanionRepository>(),
      context.read<LearningHistoryRepository>(),
      config: config,
    );

    _messageSubscription = _cubit.messageController.stream.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _cubit.start();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F7),
        body: BlocConsumer<WordMatchingCubit, WordMatchingState>(
          listenWhen: (prev, cur) =>
              prev.gameStatus != cur.gameStatus &&
              cur.gameStatus == WordMatchingGameStatus.completed,
          listener: (context, state) {
            final scoreCount = state.score;
            final xpEarned = scoreCount * 2;
            final gemsEarned = scoreCount ~/ 2;
            final foodEarned = scoreCount / 200;

            _showResultDialog(context, state, xpEarned, gemsEarned, foodEarned);
          },
          builder: (context, state) {
            if (state.loadStatus == LOADSTATUS.LOADING ||
                state.loadStatus == LOADSTATUS.INITAL) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
              );
            }

            if (state.loadStatus == LOADSTATUS.FAILED) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage ?? 'Tải dữ liệu thất bại',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.balooBhai2(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _cubit.restart,
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
                        child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.gameStatus == WordMatchingGameStatus.gameOver) {
              return _buildGameOverView();
            }

            return Column(
              children: [
                _buildHeader(context, state),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column: Words
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: state.leftItems.map((item) {
                                final isMatched = state.matchedIds.contains(item.id);
                                return ShakeWidget(
                                  shake: item.status == WordMatchingItemStatus.wrong,
                                  child: Opacity(
                                    opacity: isMatched ? 0.6 : 1.0,
                                    child: _CardItem(
                                      text: item.text,
                                      status: item.status,
                                      onTap: () => _cubit.selectLeftItem(item.id),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Right Column: Meanings
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: state.rightItems.map((item) {
                                final isMatched = state.matchedIds.contains(item.id);
                                return ShakeWidget(
                                  shake: item.status == WordMatchingItemStatus.wrong,
                                  child: Opacity(
                                    opacity: isMatched ? 0.6 : 1.0,
                                    child: _CardItem(
                                      text: item.text,
                                      status: item.status,
                                      onTap: () => _cubit.selectRightItem(item.id),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Sub-widgets ─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, WordMatchingState state) {
    final ratio = state.totalTime == 0 ? 0.0 : state.timeRemaining / state.totalTime;
    final isLowTime = state.timeRemaining <= 5;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 190,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(40),
              bottomLeft: Radius.circular(40),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -20, right: -10, child: _bubble(90, 0.08)),
              Positioned(bottom: 20, left: 30, child: _bubble(50, 0.05)),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'WORD MATCHING ARENA',
                          style: GoogleFonts.balooBhai2(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD600),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD600).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Level ${state.level}/5',
                        style: GoogleFonts.balooBhai2(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                color: isLowTime ? Colors.redAccent : Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "Thời gian: ${state.timeRemaining}s",
                                style: GoogleFonts.balooBhai2(
                                  color: isLowTime ? Colors.redAccent : Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            "Điểm: ${state.score}",
                            style: GoogleFonts.balooBhai2(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isLowTime ? Colors.redAccent : const Color(0xFFFFD600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Round matching progression
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Tiến độ màn",
                            style: GoogleFonts.balooBhai2(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            "${state.matchedIds.length}/${state.leftItems.length}",
                            style: GoogleFonts.balooBhai2(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      );

  Widget _buildGameOverView() {
    return Container(
      color: const Color(0xFF1A1A2E),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_disabled_rounded,
                size: 96,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 24),
              Text(
                'HẾT GIỜ!',
                style: GoogleFonts.balooBhai2(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bạn đã không vượt qua thử thách kịp thời.',
                textAlign: TextAlign.center,
                style: GoogleFonts.balooBhai2(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 36),
              ElevatedButton.icon(
                onPressed: _cubit.restart,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                label: Text(
                  'THỬ LẠI NGAY',
                  style: GoogleFonts.balooBhai2(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  shadowColor: const Color(0xFF4CAF50).withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: Text(
                  'Quay lại',
                  style: GoogleFonts.balooBhai2(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResultDialog(
    BuildContext context,
    WordMatchingState state,
    int xpEarned,
    int gemsEarned,
    double foodEarned,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopUpDialog(
        icon: AppImages.imgLogo,
        message: "Thử Thách Hoàn Thành!",
        child: [
          Column(
            children: [
              Text(
                "Bạn đã kết nối chính xác tất cả các màn!",
                textAlign: TextAlign.center,
                style: GoogleFonts.balooBhai2(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("💎 $gemsEarned gems"),
                  const SizedBox(width: 12),
                  Text("⭐ $xpEarned xp"),
                  const SizedBox(width: 12),
                  Text("🍖 ${foodEarned.toStringAsFixed(1)} food"),
                ],
              ),
            ],
          ),
        ],
        onGetResult: () async {
          final xpCubit = context.read<XpCubit>();
          await xpCubit.addXp(xpEarned);
          await xpCubit.addGems(gemsEarned);
          await _cubit.earnFood(foodEarned);
        },
        onRestart: () {
          Navigator.of(context).pop();
          _cubit.restart();
        },
      ),
    );
  }
}

// ─── Shaker Animation Wrapper ─────────────────────────────────

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool shake;
  const ShakeWidget({super.key, required this.child, required this.shake});

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 7.0, end: -7.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -7.0, end: 4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 4.0, end: 0.0), weight: 1),
    ]).animate(_controller);

    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(offsetAnimation.value, 0.0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─── Individual Card Item Widget ─────────────────────────────

class _CardItem extends StatelessWidget {
  final String text;
  final WordMatchingItemStatus status;
  final VoidCallback onTap;

  const _CardItem({
    required this.text,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBg;
    Color borderCol;
    Color textCol;
    double elevationVal = 2;
    Widget? trailingIcon;

    switch (status) {
      case WordMatchingItemStatus.selected:
        cardBg = const Color(0xFFE8F5E9).withValues(alpha: 0.4);
        borderCol = const Color(0xFF4CAF50);
        textCol = const Color(0xFF2E7D32);
        elevationVal = 0;
        break;
      case WordMatchingItemStatus.correct:
        cardBg = const Color(0xFFE8F5E9);
        borderCol = const Color(0xFF4CAF50);
        textCol = const Color(0xFF2E7D32);
        elevationVal = 0;
        trailingIcon = const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16);
        break;
      case WordMatchingItemStatus.wrong:
        cardBg = const Color(0xFFFFEBEE);
        borderCol = const Color(0xFFEF5350);
        textCol = const Color(0xFFC62828);
        elevationVal = 0;
        trailingIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF5350), size: 16);
        break;
      case WordMatchingItemStatus.idle:
      default:
        cardBg = Colors.white;
        borderCol = Colors.transparent;
        textCol = const Color(0xFF1A1A2E);
        break;
    }

    final isMatched = status == WordMatchingItemStatus.correct;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: isMatched ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderCol,
              width: borderCol == Colors.transparent ? 1.5 : 2.0,
            ),
            boxShadow: borderCol == Colors.transparent
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.balooBhai2(
                    fontSize: 13.5,
                    fontWeight: borderCol == Colors.transparent ? FontWeight.w500 : FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 6),
                trailingIcon,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
