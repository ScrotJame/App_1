import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/commons/app_images.dart';
import 'package:test_abc/commons/user_sesion.dart';
import 'package:test_abc/router/router.dart';

class TiktokSideActions extends StatefulWidget {
  final VoidCallback? onSoundTap;
  final VoidCallback? onBookmarkTap;
  final VoidCallback? onCompanionTap;

  const TiktokSideActions({
    super.key,
    this.onSoundTap,
    this.onBookmarkTap,
    this.onCompanionTap,
  });

  @override
  State<TiktokSideActions> createState() => _TiktokSideActionsState();
}

class _TiktokSideActionsState extends State<TiktokSideActions> {
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── 1. Companion / Mascot Button ──
        _buildActionItem(
          iconWidget: Image.asset(
            AppImages.icCompanion,
            width: 26,
            height: 26,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.pets_rounded,
              color: AppColors.gachaGold,
              size: 24,
            ),
          ),
          label: 'Pet',
          onTap: () {
            HapticFeedback.lightImpact();
            final userKey = UserSession.instance.userKey;
            context.push(Routes.companionPath(userKey));
            widget.onCompanionTap?.call();
          },
        ),

        const SizedBox(height: 14),

        // ── 2. Heart / Bookmark Button with animation ──
        _buildActionItem(
          iconWidget: AnimatedScale(
            scale: _isBookmarked ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutBack,
            child: Icon(
              _isBookmarked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isBookmarked ? AppColors.gachaMagenta : Colors.white,
              size: 26,
            ),
          ),
          label: 'Lưu',
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _isBookmarked = !_isBookmarked);
            widget.onBookmarkTap?.call();
          },
        ),

        const SizedBox(height: 14),

        // ── 3. Quick Audio Pronunciation ──
        _buildActionItem(
          iconWidget: const Icon(
            Icons.volume_up_rounded,
            color: AppColors.gachaNeonCyan,
            size: 26,
          ),
          label: 'Phát âm',
          onTap: () {
            HapticFeedback.lightImpact();
            widget.onSoundTap?.call();
          },
        ),
      ],
    );
  }

  Widget _buildActionItem({
    required Widget iconWidget,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.gachaGlassBg,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: iconWidget),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
