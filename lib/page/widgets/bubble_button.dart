import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';



class BubbleButton extends StatefulWidget {
  final String? icon;
  final String? label;
  final double? width;
  final double? height;
  final double? widthIcon;
  final double? heightIcon;
  final Color? colorButton;
  final VoidCallback onTap;

  const BubbleButton({
    super.key,
    required this.onTap,
    this.icon,
    this.label,
    this.colorButton,
    this.width,
    this.height,
    this.widthIcon,
    this.heightIcon});

  @override
  State<BubbleButton> createState() => BubbleButtonState();
}

class BubbleButtonState extends State<BubbleButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _scaleAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.85)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.85, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.12, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward(from: 0).then((_) => widget.onTap());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: _buildBubble(),
      ),
    );
  }

  // ─── BUBBLE ───────────────────────────────────────────────
  Widget _buildBubble() {
    return
        Container(
        width: widget.width ?? 70,
        height: widget.height ?? 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6DD85E), Color(0xFF2E7D32)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B5E20).withValues(alpha: 0.8),
              blurRadius: 0,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: const Color(0xFF43A047).withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            _buildHighlight(),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    widget.icon ?? '',
                    width: widget.widthIcon ?? 25,
                  ),


                  if(widget.label != null)...[
                    const SizedBox(height: 4),
                    Text(
                    widget.label ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),]
                ],
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildHighlight() {
    return Positioned(
      top: 8,
      left: 12,
      child: Container(
        width: 22,
        height: 10,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}