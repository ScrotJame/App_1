import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/components/bager_widget.dart';
import 'package:test_abc/components/cloud_painter.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/streak/streak_page.dart';
import 'package:test_abc/page/test_word/test_page.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/page/widgets/app_bar_custom.dart';
import 'package:test_abc/page/widgets/avatar/xp_cubit.dart';
import 'package:test_abc/page/widgets/bubble_button.dart';
import '../commons/app_images.dart';
import '../models/land_model.dart';
import '../router/app_router.dart';
import '../router/router.dart';
import 'add_word/add_word_page.dart';
import 'home_cubit.dart';
import 'learning/flash_card/flash_card_page.dart';
import 'list_word/list_word_page.dart';
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

  late final PageController _pageController;

  int _currentIndex = 0;

  static const _starOffsets = [
    Offset(0.12, 0.06),
    Offset(0.45, 0.03),
    Offset(0.78, 0.08),
    Offset(0.90, 0.04),
    Offset(0.25, 0.12),
    Offset(0.60, 0.10),
  ];

  /// Danh sách các trang có thể chuyển tới
  final List<IslandItem> _islandItems = [
    IslandItem(
      label: (ctx) => S.of(ctx).library,
      primaryColor: const Color(0xFF5EC95C),
      secondaryColor: const Color(0xFF3A7D34),
      pageBuilder: (_) => ListWordPage(),
    ),
    IslandItem(
      label: (ctx) => S.of(ctx).flash_card,
      primaryColor: const Color(0xFF5B9EF5),
      secondaryColor: const Color(0xFF2A62C0),
      pageBuilder: (_) => FlashCardPage(),
    ),
    IslandItem(
      label: (ctx) => S.of(ctx).add_word,
      primaryColor: const Color(0xFFF5A623),
      secondaryColor: const Color(0xFFC47A0A),
      pageBuilder: (_) => AddWordPage(),
    ),
    IslandItem(
      label: (ctx) => S.of(ctx).test,
      primaryColor: const Color(0xFFF52323),
      secondaryColor: const Color(0xFFC40A0A),
      pageBuilder: (_) => TestPage(),
    ),
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

    _pageController = PageController(
      viewportFraction: 0.78,
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ─── Background & Decoration ─────────────────────────────────────────────

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

  // ─── Island Carousel ─────────────────────────────────────────────────────

  /// Mỗi card trong carousel
  Widget _buildIslandCard(IslandItem item, int index) {
    final isSelected = index == _currentIndex;

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.88,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: isSelected ? 1.0 : 0.65,
        duration: const Duration(milliseconds: 250),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [item.primaryColor, item.secondaryColor],
            ),
            boxShadow: [
              BoxShadow(
                color: item.secondaryColor.withOpacity(isSelected ? 0.55 : 0.25),
                blurRadius: isSelected ? 24 : 12,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Hoa văn trang trí nền
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),
                // Nội dung chính
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      item.label(context),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Đang chọn',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Dot indicator bên dưới carousel
  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_islandItems.length, (i) {
        final isActive = i == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? Colors.white
                : Colors.white.withOpacity(0.4),
          ),
        );
      }),
    );
  }

  Widget _buildFloatingIsland() {
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _floatAnimation.value),
        child: child,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _islandItems.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _buildIslandCard(_islandItems[index], index);
              },
            ),
          ),
          const SizedBox(height: 12),
          _buildDotIndicator(),
        ],
      ),
    );
  }

  // ─── Play Button ──────────────────────────────────────────────────────────

  Widget _buildPlayButton() {
    final currentItem = _islandItems[_currentIndex];

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (ctx, state) {
        return GestureDetector(
          onTap: state.isLoading
              ? null
              : () {
            Navigator.push(
              context,
              MaterialPageRoute(
                // Mở đúng trang tương ứng với card đang chọn
                builder: currentItem.pageBuilder,
              ),
            );
          },
          child: AnimatedScale(
            scale: state.isLoading ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: AppColors.greenGradient,
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
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  const Text(
                    'PLAY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Body ────────────────────────────────────────────────────────────────

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
            const SizedBox(height: 48),
            _buildPlayButton(),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 90,
          child: BubbleButton(
            onTap: () async {
              await context.read<XpCubit>().addXp(2);

              final state = context.read<XpCubit>().state;
              if (state.justLeveledUp && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Lên Level ${state.level}!'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: const Color(0xFF50C040),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBarCustom(
        showBack: false,
        topActions: [
          XpBarWidget(
            avatarUrl: AppImages.imgAvatar ?? AppImages.icAvatar,
            onTap: () {
              AppRouter.router.navigateTo(context, Routes.profile);
            },
          ),
          AppBarAction(
            icon: AppImages.icFire,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StreakPage(),
                ),
              );
            },
          ),
        ],
        bottomActions: [
          BlocBuilder<ProfileCubit, ProfileState>(
            builder: (context, profileState) {
              final gems = profileState.data?.gems ?? 0;
              return BagerWidget(
                avatarUrl: AppImages.imgGem,
                backgroundColor: AppColors.kAmber,
                barBorder: AppColors.kRed,
                barGradient: AppColors.streakGradient,
                avatarBackground: AppColors.white,
                label: '$gems',
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}