import 'package:flutter/material.dart';
import 'package:test_abc/commons/app_colors.dart';
import 'package:test_abc/page/home/widgets/tiktok_top_hud.dart';
import 'package:test_abc/page/training_feed/training_feed_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.gachaDarkBg,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. TikTok Vertical Learning Feed ──
          RepaintBoundary(
            child: TrainingFeedPage(isEmbedInHome: true),
          ),

          // ── 2. Floating Glassmorphic Top HUD ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: TiktokTopHud(),
            ),
          ),
        ],
      ),
    );
  }
}
