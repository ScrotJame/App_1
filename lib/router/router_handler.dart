import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';

import '../page/home_cubit.dart';
import '../page/home_page.dart';
import '../page/user/profile/profile_page.dart';


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
// TODO: thay SizedBox bằng SplashPage() khi có
Handler splashHandler = Handler(
  handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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

Handler profileHandler = Handler(
  handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
    return const ProfilePage();
  },
);