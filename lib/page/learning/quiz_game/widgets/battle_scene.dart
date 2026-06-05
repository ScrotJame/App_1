import 'package:flutter/material.dart';

import '../../../../commons/enums.dart';
import '../quiz_game_cubit.dart';
import 'battle_scene_controller.dart';
import 'sprite_animator.dart';

class BattleScene extends StatefulWidget {
  final QuizGameState state;

  const BattleScene({super.key, required this.state});

  @override
  State<BattleScene> createState() => _BattleSceneState();
}

class _BattleSceneState extends State<BattleScene>
    with TickerProviderStateMixin {
  late final BattleSceneController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BattleSceneController(vsync: this);
  }

  @override
  void didUpdateWidget(covariant BattleScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.onBattleStateChanged(widget.state.battleAnimState);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (!_controller.spritesLoaded) {
          return const SizedBox(
            height: 220,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Container(
          height: 275,
          width: double.infinity,
          child: ClipRRect(
            child: Stack(
              children: [
                _buildEnemyWidget,
                _buildPlayerWidget,
                _buildEnemyHpBarWidget,
                _buildPlayerInfoWidget,
                if (_controller.showDamage) _buildDamagePopupWidget,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget get _buildPlayerWidget {
    return Positioned(
      bottom: 16,
      left: 16,
      child: SpriteAnimator(
        key: const ValueKey('player_sprite'),
        controller: _controller.playerCtrl,
        imagePath: _controller.playerImagePath,
        flipHorizontally: false,
        scale: 1.5,
      ),
    );
  }

  Widget get _buildEnemyWidget {
    return Positioned(
      top: 20,
      right: 20,
      child: AnimatedBuilder(
        animation: _controller.enemyFaintController,
        builder: (context, child) {
          final opacity = _controller.enemyFaintController.isAnimating ||
                  _controller.enemyFaintController.isCompleted
              ? _controller.enemyFaintAnim.value
              : 1.0;
          return Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: SpriteAnimator(
              key: const ValueKey('enemy_sprite'),
              controller: _controller.enemyCtrl,
              imagePath: _controller.enemyImagePath,
              scale: 1.5,
            ),
          );
        },
      ),
    );
  }

  Widget get _buildEnemyHpBarWidget {
    final total = widget.state.totalQuestions;
    final correct = widget.state.correctCount;
    final hpFraction = total > 0 ? ((total - correct) / total).clamp(0.0, 1.0) : 1.0;

    return Positioned(
      top: 10,
      left: 12,
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ENEMY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF334155),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            // HP bar
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: 8,
                  width: 114 * hpFraction,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: hpFraction > 0.5
                          ? [const Color(0xFF4ADE80), const Color(0xFF16A34A)]
                          : hpFraction > 0.2
                              ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
                              : [const Color(0xFFF87171), const Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'HP ${total - correct}/$total',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _buildPlayerInfoWidget {
    return Positioned(
      bottom: 4,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '⚔️',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.state.correctCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF16A34A),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '💔',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 4),
            Text(
              '${widget.state.wrongCount}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget get _buildDamagePopupWidget {
    return AnimatedBuilder(
      animation: _controller.damagePopupController,
      builder: (context, child) {
        final progress = _controller.damagePopupAnim.value;
        final yOffset = -40 * progress;
        final opacity = (1.0 - progress).clamp(0.3, 1.0);

        return Positioned(
          top: 50 + yOffset,
          right: 60,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: 0.8 + (progress * 0.4),
              child: Text(
                _controller.damageText,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _controller.isDamageCorrect
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFDC2626),
                  shadows: const [
                    Shadow(
                      color: Colors.white,
                      blurRadius: 4,
                    ),
                    Shadow(
                      color: Colors.white,
                      blurRadius: 8,
                    ),
                  ],
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
// GROUND PAINTER — vẽ nền đất cho battle arena
// ═══════════════════════════════════════════════════════════════

class _GroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Main ground
    final groundPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6ABF69), Color(0xFF4A9E49)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), groundPaint);

    // Subtle horizontal lines for depth
    final linePaint = Paint()
      ..color = const Color(0xFF5AAE59).withValues(alpha: 0.5)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      final y = (size.height / 5) * i + 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Elliptical shadows for characters
    final shadowPaint = Paint()
      ..color = const Color(0xFF3D8B3C).withValues(alpha: 0.4);

    // Player shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.25, size.height * 0.5),
        width: 80,
        height: 16,
      ),
      shadowPaint,
    );

    // Enemy shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.72, size.height * 0.3),
        width: 60,
        height: 12,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}