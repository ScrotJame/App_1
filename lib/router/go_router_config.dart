import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../commons/user_sesion.dart';
import '../database/app_db.dart';
import '../page/achievement/achievement_page.dart';
import '../page/add_word/add_word_page.dart';
import '../page/backup/backup_page.dart';
import '../page/companion/companion_page.dart';
import '../page/home_cubit.dart';
import '../page/home_page.dart';
import '../page/learning_history/learning_history_page.dart';
import '../page/list_unit/list_unit_page.dart';
import '../page/list_word/list_word_page.dart';
import '../page/scan_vocab/scan_vocab_page.dart';
import '../page/shop/shop_page.dart';
import '../page/splash/splash_cubit.dart';
import '../page/splash/splash_page.dart';
import '../page/streak/streak_page.dart';
import '../page/test_word/test_page.dart';
import '../page/user/inventory/inventory_page.dart';
import '../page/user/profile/profile_page.dart';
import '../repository/user_repository.dart';
import 'router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createGoRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    routes: [
      // ── Splash ──────────────────────────────────────────────
      GoRoute(
        path: Routes.splash,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => SplashCubit(context.read<UserRepository>()),
            child: SplashPage(
              onReady: () => context.go(Routes.home),
            ),
          );
        },
      ),

      // ── Home ────────────────────────────────────────────────
      GoRoute(
        path: Routes.home,
        builder: (context, state) {
          return BlocProvider(
            create: (_) => HomeCubit(),
            child: const HomePage(),
          );
        },
      ),

      // ── Profile ─────────────────────────────────────────────
      GoRoute(
        path: Routes.profile,
        builder: (context, state) => const ProfilePage(),
      ),

      // ── Learning History ────────────────────────────────────
      GoRoute(
        path: Routes.learningHistory,
        builder: (context, state) => const LearningHistoryPage(),
      ),

      // ── List Word (no params) ──────────────────────────────
      GoRoute(
        path: Routes.listWord,
        builder: (context, state) => const ListWordPage(),
      ),

      // ── List Unit ──────────────────────────────────────────
      GoRoute(
        path: Routes.listUnit,
        builder: (context, state) => const ListUnitPage(),
      ),

      // ── Add Word ───────────────────────────────────────────
      GoRoute(
        path: Routes.addWord,
        builder: (context, state) => const AddWordPage(),
      ),

      // ── Test ───────────────────────────────────────────────
      GoRoute(
        path: Routes.test,
        builder: (context, state) => const TestPage(),
      ),

      // ── Shop ───────────────────────────────────────────────
      GoRoute(
        path: Routes.shop,
        builder: (context, state) => const ShopPage(),
      ),

      // ── Scan Vocab ─────────────────────────────────────────
      GoRoute(
        path: Routes.scanVocab,
        builder: (context, state) => const ScanVocabPage(),
      ),

      // ── Streak ─────────────────────────────────────────────
      GoRoute(
        path: Routes.streak,
        builder: (context, state) => const StreakPage(),
      ),

      // ── Companion (path param: userKey) ────────────────────
      GoRoute(
        path: Routes.companion,
        builder: (context, state) {
          final userKey = state.pathParameters['userKey'] ?? '';
          return CompanionPage(userKey: userKey);
        },
      ),

      // ── Inventory ──────────────────────────────────────────
      GoRoute(
        path: Routes.inventory,
        builder: (context, state) => const InventoryPage(),
      ),

      // ── Achievement ────────────────────────────────────────
      GoRoute(
        path: Routes.achievement,
        builder: (context, state) => const AchievementPage(),
      ),

      // ── Backup ─────────────────────────────────────────────
      GoRoute(
        path: Routes.backup,
        builder: (context, state) => const BackupPage(),
      ),
    ],

    // ── 404 ────────────────────────────────────────────────────
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Text('404: ${state.uri.toString()}'),
        ),
      );
    },
  );
}
