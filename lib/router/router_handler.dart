import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/repository/user_repository.dart';

import '../database/app_db.dart';
import '../page/home_cubit.dart';
import '../page/home_page.dart';
import '../page/splash/splash_cubit.dart';
import '../page/splash/splash_page.dart';
import '../page/user/profile/profile_page.dart';
import 'app_router.dart';
import 'router.dart';

// ── Not found ──────────────────────────────────────────────────
Handler notFoundHandler = Handler(
  handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
    final routeName = context?.settings?.name ?? 'NULL';
    return Scaffold(
      body: Center(child: Text('404: $routeName')),
    );
  },
);

// ── Splash ─────────────────────────────────────────────────────
Handler splashHandler = Handler(
  handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
    final ctx = context!;
    return BlocProvider(
      create: (_) => SplashCubit(ctx.read<AppDatabase>(), ctx.read<UserRepository>()),
      child: SplashPage(
        onReady: () => AppRouter.navigateAndClearStack(ctx, Routes.home),
      ),
    );
  },
);

// ── Home ───────────────────────────────────────────────────────
Handler homeHandler = Handler(
  handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
    return BlocProvider(
      create: (_) => HomeCubit(),
      child: const HomePage(),
    );
  },
);

// ── Profile ────────────────────────────────────────────────────
Handler profileHandler = Handler(
  handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
    return const ProfilePage();
  },
);