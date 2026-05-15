import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../router/app_router.dart';
import '../router/router.dart';

class PopUpDialog extends StatefulWidget {

  final String? icon;
  final String? message;
  final bool onClose;
  final List<Widget>? child;
  final VoidCallback? onGetResult;
  final VoidCallback? onRestart;

  const PopUpDialog({
    super.key,
    this.icon,
    this.message,
    this.onClose = true,
    this.child,
    this.onRestart, this.onGetResult});

  @override
  State<PopUpDialog> createState() => _PopUpDialogState();
}

class _PopUpDialogState extends State<PopUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF2196F3),
      foregroundColor: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
      ),
    );

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null)
                  Image.asset(widget.icon!, width: 48, height: 48)
                else
                  const Icon(Icons.info_outline, size: 48, color: Colors.blue),

                const SizedBox(height: 16),

                Text(
                  widget.message ?? '',
                  style: GoogleFonts.balooBhai2(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (widget.child != null) ...[
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.child!,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Row(
                  children: [
                    if (widget.onClose)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: ()
                            {
                              widget.onGetResult?.call();
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                Routes.home,
                                    (route) => false,
                              );
                            },
                            style: buttonStyle.copyWith(
                              backgroundColor: WidgetStateProperty.all(Colors.grey[200]),
                              foregroundColor: WidgetStateProperty.all(Colors.black87),
                            ),
                            child: const Text('THOÁT'),
                          ),
                        ),
                      ),

                    if (widget.onClose && widget.onRestart != null)
                      const SizedBox(width: 12),

                    if (widget.onRestart != null)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: widget.onRestart,
                            style: buttonStyle,
                            child: const Text('HỌC LẠI'),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
