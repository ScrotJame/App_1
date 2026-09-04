import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';

class GachaNextCardTeaser extends StatefulWidget {
  final VoidCallback? onTap;

  const GachaNextCardTeaser({
    super.key,
    this.onTap,
  });

  @override
  State<GachaNextCardTeaser> createState() => _GachaNextCardTeaserState();
}

class _GachaNextCardTeaserState extends State<GachaNextCardTeaser>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _bounceAnimation.value),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.gachaGlassBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gachaNeonCyan.withValues(alpha: 0.4),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gachaNeonCyan.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.gachaNeonCyan,
                size: 16,
              ),
              SizedBox(width: 4),
              Text(
                'Vuốt để khám phá tiếp theo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '✨',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
