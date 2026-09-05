import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_images.dart';
import '../../../models/entity/active_companion_entity.dart';
import '../../widgets/app_gradient_header.dart';
import '../../widgets/bubble_button.dart';
import '../companion_cubit.dart';
import 'companion_widgets.dart';
import 'loading_error_screen.dart';

class CompanionActiveView extends StatelessWidget {
  final CompanionCubit cubit;
  final CompanionState state;
  final Animation<double> bounceAnim;

  const CompanionActiveView({
    super.key,
    required this.cubit,
    required this.state,
    required this.bounceAnim,
  });

  @override
  Widget build(BuildContext context) {
    final c = state.activeCompanion;
    if (c == null) return const CompanionLoadingScreen();
    final def = c.definition;

    return Container(
      color: const Color(0xFFF0FAF0),
      child: Column(
        children: [
          CompanionActiveHeader(cubit: cubit, companion: c),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      CompanionEvolutionBar(companion: c),
                      const SizedBox(height: 16),
                      CompanionSceneCard(
                          companion: c, bounceAnim: bounceAnim),
                      const SizedBox(height: 16),
                      CompanionStatChipsRow(companion: c),
                      const SizedBox(height: 16),
                      // Food inventory indicator
                      CompanionFoodInventoryBar(companion: c),
                      const SizedBox(height: 80), // space for FAB
                    ],
                  ),
                ),

                // ── Feed button (bottom-left) ─────────────────────────
                Positioned(
                  left: 20,
                  bottom: 50,
                  child: BubbleButton(
                    icon: def?.type == 'plant' ?AppImages.icWaterCan : AppImages.icPetFood,
                      label: def?.type == 'plant' ? "Tuoi cay" : "cho an",
                      onTap: () => cubit.feedCompanion()
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Feed Button ───────────────────────────────────────────────────────────────

class _FeedButton extends StatelessWidget {
  final ActiveCompanionEntity companion;
  final bool canFeed;
  final VoidCallback? onTap;

  const _FeedButton({
    required this.companion,
    required this.canFeed,
  }) : onTap = null;

  @override
  Widget build(BuildContext context) {
    final def = companion.definition;
    final isPlant = def?.type == 'plant';
    final inventory = companion.foodInventory ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: canFeed ? 1.0 : 0.45,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: canFeed
                ? (isPlant
                ? const Color(0xFF1E88E5)
                : const Color(0xFFE65100))
                : Colors.grey,
            borderRadius: BorderRadius.circular(24),
            boxShadow: canFeed
                ? [
              BoxShadow(
                color: (isPlant
                    ? const Color(0xFF1E88E5)
                    : const Color(0xFFE65100))
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isPlant ? '💧' : '🍖',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isPlant ? 'Tưới cây' : 'Cho ăn',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Kho: $inventory/${def?.maxFoodInventory ?? 10}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class CompanionActiveHeader extends StatelessWidget {
  final CompanionCubit cubit;
  final ActiveCompanionEntity companion;

  const CompanionActiveHeader({
    super.key,
    required this.cubit,
    required this.companion,
  });

  @override
  Widget build(BuildContext context) {
    final def = companion.definition;
    final levelLabel = 'Level ${companion.level}  •  Sunny Meadow';

    return AppGradientHeader(
      height: 125,
      gradientColors: const [Color(0xFF7B8FE0), Color(0xFF5B6EC7)],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _HeaderBtn(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: Colors.black87),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Companion Garden',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    levelLabel,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black45,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            _HeaderBtn(
              onTap: () => cubit.browseType(def?.type ?? 'pet'),
              child: const Icon(Icons.shopping_basket_outlined,
                  size: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _HeaderBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}