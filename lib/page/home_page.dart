import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/components/cloud_painter.dart';
import 'package:test_abc/page/widgets/app_bar_custom.dart';
import '../commons/app_images.dart';
import '../router/app_router.dart';
import '../router/router.dart';
import 'home_cubit.dart';
import 'widgets/avatar/avatar_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  static const _starOffsets = [
    Offset(0.12, 0.06),
    Offset(0.45, 0.03),
    Offset(0.78, 0.08),
    Offset(0.90, 0.04),
    Offset(0.25, 0.12),
    Offset(0.60, 0.10),
  ];

  late HomeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<HomeCubit>();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -12, end: 12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }


  Widget _buildSkyBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.mainGradient,
      ),
    );
  }

  Widget _buildStarDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildStars() {
    return LayoutBuilder(
      builder: (ctx, box) => Stack(
        children: _starOffsets
            .map(
              (s) => Positioned(
            left: s.dx * box.maxWidth,
            top: s.dy * box.maxHeight,
            child: _buildStarDot(),
          ),
        )
            .toList(),
      ),
    );
  }

  Widget _buildCloudShape(double width) {
    return SizedBox(
      width: width,
      height: width * 0.45,
      child: CustomPaint(painter: CloudPainter()),
    );
  }

  Widget _buildClouds() {
    return LayoutBuilder(
      builder: (ctx, box) => Stack(
        children: [
          Positioned(
            left: box.maxWidth * 0.04,
            top: box.maxHeight * 0.38,
            child: _buildCloudShape(box.maxWidth * 0.26),
          ),
          Positioned(
            right: box.maxWidth * 0.04,
            top: box.maxHeight * 0.33,
            child: _buildCloudShape(box.maxWidth * 0.20),
          ),
        ],
      ),
    );
  }

  Widget _buildIslandPlaceholder() {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 12,
            child: Container(
              width: 160,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5EC95C), Color(0xFF3A7D34)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.20),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.landscape_rounded,
                    size: 90,
                    color: Colors.white54,
                  ),
                  Positioned(
                    bottom: 12,
                    child: Text(
                      'Island coming soon',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIsland() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: _buildIslandPlaceholder(),
    );
  }

  Widget _buildPlayButton() {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (ctx, state) {
        return GestureDetector(
          onTap: state.isLoading ? null : () => _cubit.onPlayPressed(),
          child: AnimatedScale(
            scale: state.isLoading ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Container(
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6DD85E), Color(0xFF3BA82B)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2A7A1C).withOpacity(0.7),
                    blurRadius: 0,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: const Color(0xFF50C040).withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: state.isLoading
                  ? const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              )
                  : const Center(
                child: Text(
                  'PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Color(0xFF1A5C10),
                        offset: Offset(0, 2),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildSkyBackground(),
        _buildStars(),
        _buildClouds(),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            _buildFloatingIsland(),
            const SizedBox(height: 60),
            _buildPlayButton(),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBarCustom(
          showBack: false,
          actions: [
            XpBarWidget(avatarUrl: 'https://picsum.photos/200/300' ?? AppImages.icAvatar,),
            AppBarAction(
              icon: AppImages.icAvatar,
              onTap: () {},
            ),
          ],
        ),
        body: _buildBody());
  }
}