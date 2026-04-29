import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Model đại diện cho 1 item trong dropdown
class DropDownItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  /// Nếu true → label và icon hiển thị màu đỏ (destructive action)
  final bool isDestructive;

  /// Nếu true → vẽ divider phía trên item này (tạo nhóm)
  final bool hasDividerAbove;

  const DropDownItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
    this.hasDividerAbove = false,
  });
}

class DropDownWidget {
  static OverlayEntry? _entry;

  static void show({
    required BuildContext context,
    required GlobalKey anchorKey,
    required List<DropDownItem> items,

    /// Căn trái hay phải so với anchor
    bool alignRight = true,
  }) {
    _dismiss();

    final renderBox =
    anchorKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay =
    Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero, ancestor: overlay);
    final size = renderBox.size;

    _entry = OverlayEntry(
      builder: (_) => _DropDownOverlay(
        anchorPosition: position,
        anchorSize: size,
        items: items,
        alignRight: alignRight,
        onDismiss: _dismiss,
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  static void _dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _DropDownOverlay extends StatefulWidget {
  final Offset anchorPosition;
  final Size anchorSize;
  final List<DropDownItem> items;
  final bool alignRight;
  final VoidCallback onDismiss;

  const _DropDownOverlay({
    required this.anchorPosition,
    required this.anchorSize,
    required this.items,
    required this.alignRight,
    required this.onDismiss,
  });

  @override
  State<_DropDownOverlay> createState() => _DropDownOverlayState();
}

class _DropDownOverlayState extends State<_DropDownOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  static const _menuWidth = 220.0;
  static const _itemHeight = 44.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 180));

    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _closeAndRun(VoidCallback action) async {
    await _ctrl.reverse();
    widget.onDismiss();
    action();
  }

  @override
  Widget build(BuildContext context) {
    double left = widget.alignRight
        ? widget.anchorPosition.dx +
        widget.anchorSize.width -
        _menuWidth
        : widget.anchorPosition.dx;

    double top = widget.anchorPosition.dy + widget.anchorSize.height + 6;

    final screenWidth = MediaQuery.of(context).size.width;
    left = left.clamp(8.0, screenWidth - _menuWidth - 8);

    final originX = widget.alignRight ? 1.0 : 0.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () async {
              await _ctrl.reverse();
              widget.onDismiss();
            },
            child: const SizedBox.expand(),
          ),
        ),

        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment(originX, -1),
              child: _buildMenu(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFF2F2F7).withOpacity(0.97);
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.10)
        : Colors.black.withOpacity(0.10);

    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Container(
        width: _menuWidth,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.18),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.items.length, (i) {
            final item = widget.items[i];
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item.hasDividerAbove && i != 0)
                  Divider(height: 1, thickness: 0.5, color: dividerColor),
                _buildItem(item, isDark),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildItem(_DropDownItem item, bool isDark) {
    final normalColor = isDark ? Colors.white : Colors.black;
    final textColor =
    item.isDestructive ? CupertinoColors.destructiveRed : normalColor;
    final iconColor = item.isDestructive
        ? CupertinoColors.destructiveRed
        : (isDark ? Colors.white70 : Colors.black54);

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: () => _closeAndRun(item.onTap),
      child: Container(
        height: _itemHeight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                  letterSpacing: -0.2,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            Icon(item.icon, size: 20, color: iconColor),
          ],
        ),
      ),
    );
  }
}

typedef _DropDownItem = DropDownItem;