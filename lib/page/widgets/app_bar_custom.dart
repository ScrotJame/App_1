import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../commons/app_colors.dart';

class AppBarCustom extends StatelessWidget
    implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final List<Widget>? topActions;
  final List<Widget>? bottomActions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? leading;

  const AppBarCustom({
    super.key,
    this.title,
    this.showBack = true,
    this.topActions,
    this.bottomActions,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.leading,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    bottomActions != null ? 190 : 60,
  );

  Color get _bgColor =>
      backgroundColor ?? AppColors.mainTopSky.withOpacity(0.85);

  Color get _fgColor => foregroundColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top,
        ),
        decoration: BoxDecoration(
          color: showBack
              ? _bgColor
              : const Color(0xFF1A3A8F),
          border: Border(
            bottom: BorderSide(
              color: showBack
                  ? Colors.white.withOpacity(0.12)
                  : Colors.transparent,
              width: 0.5,
            ),
          ),
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildLeading(context),

              if (title != null) ...[
                const SizedBox(width: 4),
                Expanded(child: _buildTitle()),
              ],

              if (topActions != null)
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: topActions!,
                  ),
                ),
            ],
          ),

          if (bottomActions != null) ...[
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: bottomActions!,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leading != null) return leading!;
    if (!showBack) return const SizedBox(width: 8);

    return _AppBarIconButton(
      foregroundColor: _fgColor,
      onTap: () {
        if (onBackPressed != null) {
          onBackPressed!();
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: const Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 18,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      title ?? "",
      style: TextStyle(
        color: _fgColor,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Icon button dùng trong AppBarCustom ───────────────────────
class _AppBarIconButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final Color foregroundColor;

  const _AppBarIconButton({
    required this.child,
    required this.onTap,
    required this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        child: IconTheme(
          data: IconThemeData(color: foregroundColor, size: 18),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class AppBarAction extends StatelessWidget {
  final String? icon;
  final String? label;
  final VoidCallback? onTap;
  final Color? color;

  const AppBarAction({
    super.key,
    required this.icon,
    this.onTap,
    this.color,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Image.asset(
                icon!,
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label ?? '',
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppBarIcon extends StatelessWidget {
  final String? icon;
  final VoidCallback onTap;
  final Color? color;

  const AppBarIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _AppBarIconButton(
      foregroundColor: color ?? Colors.white,
      onTap: onTap,
      child: Image.asset(icon!),
    );
  }
}