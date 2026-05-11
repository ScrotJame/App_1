import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SideBar {
  static OverlayEntry? _current;

  static void show(
      BuildContext context, {
        Color color = const Color(0xFF00D4C8),
        Duration duration = const Duration(seconds: 3),
        double height = 56,
        double width = 130,
        bool isRight = true,
        double topFraction = 0.25,
        String? label ='',
        String? label2 = '',
      }) {
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;
    showOnOverlay(
      overlay,
      color: color,
      duration: duration,
      height: height,
      width: width,
      isRight: isRight,
      topFraction: topFraction,
      label: label,
      label2: label2,
    );
  }

  /// Dùng khi [context] là [NavigatorState.context] (không có Overlay tổ tiên).
  static void showOnOverlay(
    OverlayState overlay, {
    Color color = const Color(0xFF00D4C8),
    Duration duration = const Duration(seconds: 3),
    double height = 56,
    double width = 130,
    bool isRight = true,
    double topFraction = 0.25,
    String? label = '',
    String? label2 = '',
  }) {
    if (!overlay.mounted) return;
    _current?.remove();
    _current = null;

    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _SideBarWidget(
        color: color,
        duration: duration,
        height: height,
        width: width,
        isRight: isRight,
        topFraction: topFraction,
        label: label,
        label2: label2,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }

  static void hide() {
    _current?.remove();
    _current = null;
  }
}

class _SideBarWidget extends StatefulWidget {
  final Color color;
  final Duration duration;
  final double height;
  final double width;
  final bool isRight;
  final double topFraction;
  final VoidCallback? onDismiss;
  final String? label;
  final String? label2;

  const _SideBarWidget({
    this.color = const Color(0xFF00D4C8),
    this.duration = const Duration(seconds: 3),
    this.height = 56,
    this.width = 20,
    this.isRight = true,
    this.topFraction = 0.25,
    this.onDismiss,
    this.label,
    this.label2,
  });

  @override
  State<_SideBarWidget> createState() => _SideBarWidgetState();
}

class _SideBarWidgetState extends State<_SideBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slide = Tween<Offset>(
      begin: Offset(widget.isRight ? 1.0 : -1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward().then((_) async {
      await Future.delayed(widget.duration);
      if (mounted) {
        await _ctrl.reverse();
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final topPos = screenH * widget.topFraction - widget.height / 2;

    return Positioned(
      top: topPos,
      right: widget.isRight ? 0 : null,
      left: widget.isRight ? null : 0,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: () async {
            await _ctrl.reverse();
            widget.onDismiss?.call();
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.horizontal(
                left: widget.isRight ? const Radius.circular(100) : Radius.zero,
                right: widget.isRight ? Radius.zero : const Radius.circular(100),
              ),
            ),
            child: Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        widget.label ?? '',
                        style: GoogleFonts.balooBhai2(
                          fontSize: 26, fontWeight: FontWeight(700),
                          color: Colors.black,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
                Text("Len cap",
                  style:GoogleFonts.balooBhai2(
                    fontSize: 18, fontWeight: FontWeight(700),
                    color: Colors.black,
                    decoration: TextDecoration.none,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}