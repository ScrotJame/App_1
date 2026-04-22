import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:test_abc/commons/app_colors.dart';

import '../../commons/app_colors.dart';

class AppBarCustom extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final Widget? leading;

  const AppBarCustom({
    super.key,
    this.title,
    this.showBack = true,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  Color get _bgColor =>
      backgroundColor ?? AppColors.mainTopSky.withOpacity(0.85);

  Color get _fgColor => foregroundColor ?? Colors.white;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        height: preferredSize.height + MediaQuery.of(context).padding.top,
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        decoration: BoxDecoration(
          color: showBack  ? _bgColor : Color(0xFF1A3A8F),
          border: Border(
            bottom: BorderSide(
              color: showBack  ? Colors.white.withOpacity(0.12) : Colors.transparent,
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
      child: Row(
        children: [
          _buildLeading(context),

          if(title != null) ...[
            const SizedBox(width: 4),
            Expanded(child: _buildTitle()),
          ],

          if (actions != null)
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: _buildActions(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (leading != null) return leading!;
    if (!showBack) return const SizedBox(width: 8);

    return _AppBarIconButton(
      foregroundColor: _fgColor,
      onTap: () => onBackPressed != null
          ? onBackPressed!()
          : Navigator.of(context).maybePop(),
      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
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

  List<Widget> _buildActions() {
    return actions!
        .map((action) => action)
        .toList();
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
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
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
  final VoidCallback onTap;
  final Color? color;

  const AppBarAction({
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