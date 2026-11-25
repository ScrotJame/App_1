import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../commons/app_colors.dart';

/// Building blocks that give the Test screens the look of the training feed:
/// the feed gradient, glass cards, paper text and gold buttons.

/// The feed gradient behind a transparent [Scaffold].
class TestScreenBackground extends StatelessWidget {
  const TestScreenBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: child,
      ),
    );
  }
}

PreferredSizeWidget testScreenAppBar({
  required Widget title,
  Widget? leading,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    automaticallyImplyLeading: false,
    leading: leading,
    centerTitle: true,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    iconTheme: const IconThemeData(color: AppColors.xoayPaper),
    title: DefaultTextStyle.merge(
      style: const TextStyle(
        color: AppColors.xoayPaper,
        fontWeight: FontWeight.w800,
        fontSize: 17,
      ),
      child: title,
    ),
    actions: actions,
  );
}

PreferredSizeWidget TestScreenAppBar({
  required Widget title,
  Widget? leading,
  List<Widget>? actions,
}) =>
    testScreenAppBar(title: title, leading: leading, actions: actions);

/// A translucent card, like the cards of the training feed.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.color = AppColors.xoayGlass,
    this.borderColor = AppColors.xoayGlassBorder,
    this.borderWidth = 1,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      child: child,
    );
  }
}

/// Small uppercase label with a coloured dot, as on the feed cards.
class TestScreenEyebrow extends StatelessWidget {
  const TestScreenEyebrow({
    super.key,
    required this.label,
    this.dotColor = AppColors.xoayCyan,
  });

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
        Flexible(
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppColors.xoayPaper.withValues(alpha: 0.58),
              fontWeight: FontWeight.w600,
              fontSize: 11,
              letterSpacing: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gold-to-magenta pill button. [onTap] null shows it disabled.
class TestScreenPrimaryButton extends StatelessWidget {
  const TestScreenPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
    this.height = 52,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            gradient: const LinearGradient(
              colors: [AppColors.xoayGold, AppColors.xoayMagenta],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.xoayMagenta.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: AppColors.xoayInk, strokeWidth: 2.5),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.xoayInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (icon case final i?) ...[
                      const SizedBox(width: 8),
                      Icon(i, color: AppColors.xoayInk, size: 18),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Outlined pill button in paper colour, for the second action.
class TestScreenGhostButton extends StatelessWidget {
  const TestScreenGhostButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.height = 52,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.xoayGlass,
          borderRadius: BorderRadius.circular(height / 2),
          border: Border.all(
            color: AppColors.xoayPaper.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon case final i?) ...[
              Icon(i, color: AppColors.xoayPaper, size: 17),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.xoayPaper,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dark bar pinned to the bottom of a screen, like the feed's nav bar.
class TestScreenBottomBar extends StatelessWidget {
  const TestScreenBottomBar({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: color ?? AppColors.xoayBar,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(top: BorderSide(color: AppColors.xoayGlassBorder)),
      ),
      child: child,
    );
  }
}

/// A small rounded badge: icon and text in one colour on a tint of it.
class TestScreenPill extends StatelessWidget {
  const TestScreenPill({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// An info line on a tint of [color].
class TestScreenNote extends StatelessWidget {
  const TestScreenNote({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      radius: 16,
      color: color.withValues(alpha: 0.12),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.xoayPaper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Backward compatibility aliases
@Deprecated('Use TestScreenBackground instead')
typedef XoayBackground = TestScreenBackground;

@Deprecated('Use testScreenAppBar instead')
PreferredSizeWidget xoayAppBar({
  required Widget title,
  Widget? leading,
  List<Widget>? actions,
}) =>
    testScreenAppBar(title: title, leading: leading, actions: actions);

@Deprecated('Use TestScreenEyebrow instead')
typedef XoayEyebrow = TestScreenEyebrow;

@Deprecated('Use TestScreenPrimaryButton instead')
typedef XoayPrimaryButton = TestScreenPrimaryButton;

@Deprecated('Use TestScreenGhostButton instead')
typedef XoayGhostButton = TestScreenGhostButton;

@Deprecated('Use TestScreenBottomBar instead')
typedef XoayBottomBar = TestScreenBottomBar;

@Deprecated('Use TestScreenPill instead')
typedef XoayPill = TestScreenPill;

@Deprecated('Use TestScreenNote instead')
typedef XoayNote = TestScreenNote;
