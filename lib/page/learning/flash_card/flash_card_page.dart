import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/components/popup_dialog.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import '../../../commons/enums.dart';
import '../../../repository/companion_repository.dart';
import '../../../repository/vocabulary_repository.dart';
import '../../../router/router.dart';
import '../../widgets/avatar/xp_cubit.dart';
import '../learning_cubit.dart';
import 'flash_card_cubit.dart';
import 'flash_card_widget.dart';


const int _kXpSessionBonus = 2;

class FlashCardPage extends StatefulWidget {
  const FlashCardPage({super.key});

  @override
  State<FlashCardPage> createState() => _FlashCardPageState();
}

class _FlashCardPageState extends State<FlashCardPage> {
  late FlashCardCubit _cubit;
  StreamSubscription<String>? _messageSubscription;

  @override
  void initState() {
    super.initState();
    final config = context.read<LearningCubit>().state.config;
    _cubit = FlashCardCubit(
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
        body: BlocConsumer<FlashCardCubit, FlashCardState>(
          listenWhen: (prev, cur) =>
          prev.status != cur.status &&
              cur.status == FlashcardArenaStatus.completed,
          listener: (context, state) async {
            final count = state.totalCards * 10;
            final xpEarned = _kXpSessionBonus * count;
            final gemsEarned = count;
            final foodEarned = count / 100;

            _showResultDialog(context, state, xpEarned, gemsEarned, foodEarned);
          },

          builder: (context, state) {
            if (state.loadstatus == LOADSTATUS.LOADING ||
                state.loadstatus == LOADSTATUS.INITAL) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF42C8F5)),
              );
            }
            if (state.loadstatus == LOADSTATUS.FAILED) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Tải dữ liệu thất bại',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final card = state.currentCard;
            if (card == null) return const SizedBox.shrink();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeader(context, state),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Column(
                      children: [
                        Expanded(
                          child: FlipCard(
                            key: ValueKey(card.word.id),
                            card: card,
                            isFlipped: state.isFlipped,
                            onTap: _cubit.flipCard,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (state.isFlipped)
                          _RatingSection(
                            selected: state.pendingRating,
                            onRated: _cubit.rateCard,
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: _flipButton(_cubit.flipCard),
                          ),
                        const SizedBox(height: 20),
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

  Widget _buildHeader(BuildContext context, FlashCardState state) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(50),
              bottomLeft: Radius.circular(50),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF42C8F5), Color(0xFF1E9FD8)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(top: -20, right: -10, child: _bubble(100, 0.09)),
              Positioned(bottom: 20, left: 40, child: _bubble(50, 0.06)),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'FLASHCARD ARENA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD600),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD600).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${state.displayIndex}/${state.totalCards}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF5D4037),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 25),
                // Thanh tiến độ học tập giống Profile
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Session Progress",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "${(state.progress * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: state.progress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF4CAF50)),
                        ),
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
      color: Colors.white.withOpacity(opacity),
    ),
  );

  void _showResultDialog(
      BuildContext context,
      FlashCardState state,
      int xpEarned,
      int gemsEarned,
      double foodEarned,
      ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopUpDialog(
        icon: AppImages.imgLogo,
        message: "Session Complete!",
        child: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("💎 $gemsEarned gems"),
              const SizedBox(width: 8),
              Text("⭐ $xpEarned xp"),
              const SizedBox(width: 8),
              Text("🍖 ${foodEarned.toStringAsFixed(1)} food"),
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
          context.read<FlashCardCubit>().restart();
        },
      ),
    );
  }

  Widget _nextButton(VoidCallback onTap){
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
      label: const Text(
        'Next Card',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42C8F5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _flipButton(VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.flip_camera_android_rounded, size: 20, color: Colors.white),
      label: const Text(
        'FLIP CARD TO REVIEW',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.2),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF42C8F5),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        shadowColor: const Color(0xFF42C8F5).withOpacity(0.4),
      ),
    );
  }
}




class _RatingSection extends StatelessWidget {
  final DifficultyRating? selected;
  final ValueChanged<DifficultyRating> onRated;

  const _RatingSection({required this.selected, required this.onRated});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "How was this card?",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildRateItem(DifficultyRating.again, '😞', 'Again', Colors.red),
              _buildRateItem(
                  DifficultyRating.hard, '😐', 'Hard', Colors.orange),
              _buildRateItem(DifficultyRating.good, '🙂', 'Good', Colors.blue),
              _buildRateItem(
                  DifficultyRating.easy, '😊', 'Easy', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRateItem(
      DifficultyRating rating, String emoji, String label, Color color) {
    final isSelected = selected == rating;
    return GestureDetector(
      onTap: () => onRated(rating),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultDialog extends StatelessWidget {
  final FlashCardState state;
  final VoidCallback onRestart;
  final VoidCallback onClose;

  const _ResultDialog(
      {required this.state, required this.onRestart, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌱', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 16),
            const Text('Session Complete!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('You reviewed ${state.totalCards} cards today.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRestart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A2E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text('Practice Again',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClose,
              child: const Text('Back to Home',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}