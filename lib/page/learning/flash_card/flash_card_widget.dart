import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_abc/models/flash_card_model.dart';

class FlipCard extends StatefulWidget {
  final FlashcardModel card;
  final bool isFlipped;
  final VoidCallback onTap;

  const FlipCard(
      {super.key,
        required this.card,
        required this.isFlipped,
        required this.onTap});

  @override
  State<FlipCard> createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _anim = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _anim.addListener(() {
      final newShowBack = _anim.value >= 0.5;
      if (newShowBack != _showBack) setState(() => _showBack = newShowBack);
    });
  }

  @override
  void didUpdateWidget(FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      widget.isFlipped ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) {
          final angle = _anim.value * math.pi;
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: _showBack
                ? Transform(
              transform: Matrix4.identity()..rotateY(math.pi),
              alignment: Alignment.center,
              child: _CardSide(card: widget.card, isFront: false),
            )
                : _CardSide(card: widget.card, isFront: true),
          );
        },
      ),
    );
  }
}

class _CardSide extends StatelessWidget {
  final FlashcardModel card;
  final bool isFront;
  const _CardSide({required this.card, required this.isFront});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isFront ? Colors.white : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            card.category.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: isFront ? const Color(0xFF29B6F6) : Colors.white54,
            ),
          ),
          const Spacer(),
          Text(
            isFront ? card.frontText : card.backText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: isFront ? const Color(0xFF1A1A2E) : Colors.white,
            ),
          ),
          if (isFront) ...[
            const SizedBox(height: 12),
            Text(card.pronunciation,
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic)),
          ],
          const Spacer(),
          Icon(isFront ? Icons.touch_app_outlined : Icons.replay_rounded,
              color: isFront ? Colors.grey : Colors.white24, size: 28),
          const SizedBox(height: 8),
          Text(
            isFront ? "Tap to reveal" : "Tap to flip back",
            style: TextStyle(
                color: isFront ? Colors.grey : Colors.white24, fontSize: 12),
          )
        ],
      ),
    );
  }
}