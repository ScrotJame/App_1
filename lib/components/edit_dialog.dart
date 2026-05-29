import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UpdateDialog extends StatefulWidget {
  final String? initialValue;
  final Color? tagColor;
  final VoidCallback? onCancel;
  final ValueChanged<String>? onUpdate;

  const UpdateDialog({
    super.key,
    this.initialValue,
    this.tagColor,
    this.onCancel,
    this.onUpdate,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();

    _textController = TextEditingController(text: widget.initialValue ?? '');

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final tagColor = widget.tagColor ?? const Color(0xFF5B8DEF);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Chỉnh sửa Tag',
                          style: GoogleFonts.balooBhai2(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      // Close (X) button
                      GestureDetector(
                        onTap: () {
                          widget.onCancel?.call();
                          _dismiss();
                        },
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFFB0B8C1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Text field ───────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        // Colored dot indicator
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: tagColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: GoogleFonts.balooBhai2(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Nhập tên tag...',
                              hintStyle: GoogleFonts.balooBhai2(
                                fontSize: 15,
                                color: const Color(0xFFB0B8C1),
                              ),
                              isCollapsed: true,
                            ),
                            cursorColor: tagColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Buttons ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: Row(
                    children: [
                      // Cancel button
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onCancel?.call();
                              _dismiss();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDDE2E8),
                              foregroundColor: const Color(0xFF5A6470),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.balooBhai2(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Update button
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onUpdate?.call(_textController.text.trim());
                              _dismiss();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4A90E2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: GoogleFonts.balooBhai2(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Cập nhật'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper to show the dialog ─────────────────────────────────────────────────
Future<void> showUpdateDialog(
    BuildContext context, {
      String? initialValue,
      Color? tagColor,
      VoidCallback? onCancel,
      ValueChanged<String>? onUpdate,
    }) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => UpdateDialog(
      initialValue: initialValue,
      tagColor: tagColor,
      onCancel: onCancel,
      onUpdate: onUpdate,
    ),
  );
}