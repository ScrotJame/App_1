import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/commons/app_images.dart';

class GachaStreakBadge extends StatefulWidget {
  final int streak;
  final VoidCallback? onTap;

  const GachaStreakBadge({
    super.key,
    required this.streak,
    this.onTap,
  });

  @override
  State<GachaStreakBadge> createState() => _GachaStreakBadgeState();
}

class _GachaStreakBadgeState extends State<GachaStreakBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.streak > 0 ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0x33FF4500),
                Color(0x22FF8C00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.streak > 0
                  ? AppColors.gachaFlameOrange.withValues(alpha: 0.7)
                  : Colors.white24,
              width: 1.2,
            ),
            boxShadow: widget.streak > 0
                ? [
                    BoxShadow(
                      color: AppColors.gachaFlameRed.withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AppImages.icFire,
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.streak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: AppColors.gachaFlameRed,
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
