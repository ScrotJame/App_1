import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/home_cubit.dart';

class GachaCtaButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  const GachaCtaButton({
    super.key,
    this.label = 'HỌC TIẾP',
    this.onPressed,
    this.width = 160,
    this.height = 46,
  });

  @override
  State<GachaCtaButton> createState() => _GachaCtaButtonState();
}

class _GachaCtaButtonState extends State<GachaCtaButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        return GestureDetector(
          onTapDown: isLoading ? null : _handleTapDown,
          onTapUp: isLoading ? null : _handleTapUp,
          onTapCancel: isLoading ? null : _handleTapCancel,
          onTap: isLoading
              ? null
              : () {
                  context.read<HomeCubit>().onPlayPressed();
                  widget.onPressed?.call();
                },
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: widget.width,
              height: widget.height,
              transform: Matrix4.translationValues(0, _isPressed ? 3 : 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    AppColors.gachaNeonCyan,
                    Color(0xFF3B82F6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: _isPressed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1D4ED8).withValues(alpha: 0.5),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : [
                        const BoxShadow(
                          color: Color(0xFF1E40AF),
                          offset: Offset(0, 4),
                          blurRadius: 0,
                        ),
                        BoxShadow(
                          color: AppColors.gachaNeonCyan.withValues(alpha: 0.35),
                          offset: const Offset(0, 4),
                          blurRadius: 12,
                        ),
                      ],
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              shadows: [
                                Shadow(
                                  color: Color(0x66000000),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
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
      },
    );
  }
}
