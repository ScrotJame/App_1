import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'splash_cubit.dart';

class SplashPage extends StatefulWidget {
  /// Gọi sau khi splash xong để navigate
  final VoidCallback onReady;

  const SplashPage({super.key, required this.onReady});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────
  late final AnimationController _logoCtrl;
  late final AnimationController _textCtrl;
  late final AnimationController _dotCtrl;
  late final AnimationController _pulseCtrl;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _dotFade;
  late final Animation<double> _pulse;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    // Logo: scale + fade-in
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    // Text: slide up + fade
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Loading dots fade
    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _dotFade = CurvedAnimation(parent: _dotCtrl, curve: Curves.easeIn);

    // Pulse glow
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    // Sequence
    _runAnimSequence();
  }

  Future<void> _runAnimSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _dotCtrl.forward();

    // Trigger logic
    context.read<SplashCubit>().init();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _dotCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _handleNavigation() {
    if (_navigated) return;
    _navigated = true;
    // Delay thêm 1 chút để user thấy animation
    Future.delayed(const Duration(milliseconds: 600), widget.onReady);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state.status == SplashStatus.newUser ||
            state.status == SplashStatus.returning) {
          _handleNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        body: Stack(
          children: [
            // ── Background decorations ─────────────────────
            _buildBackground(),

            // ── Main content ───────────────────────────────
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: _buildLogo(),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // App name
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: _buildTitle(),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: _buildTagline(),
                    ),
                  ),
                  const SizedBox(height: 60),

                  // Loading dots
                  FadeTransition(
                    opacity: _dotFade,
                    child: _buildLoadingDots(),
                  ),
                ],
              ),
            ),

            // ── Version tag bottom ─────────────────────────
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _dotFade,
                child: const Text(
                  'v1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF444444),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Logo với glow pulse ──────────────────────────────────────
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        return Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1A1A1A),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.3 * _pulse.value),
                blurRadius: 40 * _pulse.value,
                spreadRadius: 8 * _pulse.value,
              ),
              BoxShadow(
                color: const Color(0xFFFF9A3C).withOpacity(0.15 * _pulse.value),
                blurRadius: 80 * _pulse.value,
                spreadRadius: 16 * _pulse.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Center(
        child: CustomPaint(
          size: const Size(64, 80),
          painter: _SplashFlamePainter(),
        ),
      ),
    );
  }

  // ── Title ────────────────────────────────────────────────────
  Widget _buildTitle() {
    return const Text(
      'VOCAFIRE',
      style: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 6,
      ),
    );
  }

  // ── Tagline ──────────────────────────────────────────────────
  Widget _buildTagline() {
    return const Text(
      'Learn words. Build streaks.',
      style: TextStyle(
        fontSize: 13,
        color: Color(0xFF666666),
        letterSpacing: 1.2,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // ── Animated loading dots ────────────────────────────────────
  Widget _buildLoadingDots() {
    return BlocBuilder<SplashCubit, SplashState>(
      builder: (context, state) {
        final isError = state.status == SplashStatus.error;
        if (isError) {
          return Text(
            state.errorMessage ?? 'Có lỗi xảy ra',
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          );
        }
        return _AnimatedDots();
      },
    );
  }

  // ── Background orbs ──────────────────────────────────────────
  Widget _buildBackground() {
    return Stack(
      children: [
        // Top-right orb
        Positioned(
          top: -80,
          right: -60,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF6B35)
                        .withOpacity(0.08 * _pulse.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Bottom-left orb
        Positioned(
          bottom: -100,
          left: -80,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9A3C)
                        .withOpacity(0.06 * _pulse.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Animated 3-dot loader ────────────────────────────────────────
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
          (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims = _controllers
        .map((c) =>
        Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(parent: c, curve: Curves.easeInOut),
        ))
        .toList();

    // Stagger dots
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FadeTransition(
            opacity: _anims[i],
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF6B35),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Flame painter (giống streak nhưng tối hơn cho nền đen) ──────
class _SplashFlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFAA44), Color(0xFFFF4500)],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final outerPath = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.92, h * 0.18, w * 1.0, h * 0.45, w * 0.84, h * 0.65)
      ..cubicTo(w * 0.74, h * 0.8, w * 0.55, h * 0.72, w * 0.5, h * 0.62)
      ..cubicTo(w * 0.45, h * 0.72, w * 0.26, h * 0.8, w * 0.16, h * 0.65)
      ..cubicTo(w * 0.0, h * 0.45, w * 0.08, h * 0.18, w * 0.5, 0)
      ..close();

    canvas.drawPath(outerPath, outerPaint);

    // Inner glow
    final innerPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final innerPath = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..cubicTo(w * 0.7, h * 0.33, w * 0.76, h * 0.5, w * 0.64, h * 0.64)
      ..cubicTo(w * 0.57, h * 0.72, w * 0.5, h * 0.67, w * 0.5, h * 0.62)
      ..cubicTo(w * 0.5, h * 0.67, w * 0.43, h * 0.72, w * 0.36, h * 0.64)
      ..cubicTo(w * 0.24, h * 0.5, w * 0.3, h * 0.33, w * 0.5, h * 0.18)
      ..close();

    canvas.drawPath(innerPath, innerPaint);

    // Teardrop core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final corePath = Path()
      ..moveTo(w * 0.5, h * 0.2)
      ..cubicTo(w * 0.58, h * 0.3, w * 0.58, h * 0.4, w * 0.5, h * 0.44)
      ..cubicTo(w * 0.42, h * 0.4, w * 0.42, h * 0.3, w * 0.5, h * 0.2)
      ..close();

    canvas.drawPath(corePath, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}