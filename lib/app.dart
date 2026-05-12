import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:test_abc/page/list_unit/list_unit_cubit.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/shop_repository.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/router/router.dart';
import 'components/side_bar.dart';
import 'cubit/app_cubit.dart';
import 'database/app_db.dart';
import 'generated/l10n.dart';
import 'page/widgets/avatar/xp_cubit.dart';
import 'router/app_router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final _db = AppDatabase();
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppDatabase>(
          create: (_) => _db,
        ),
        RepositoryProvider<VocabularyRepository>(
          create: (_) => VocabularyRepository(_db),
        ),
        RepositoryProvider<TagRepository>(
            create: (_) => TagRepository(_db)
        ),
        RepositoryProvider<UserRepository>(
            create: (_) => UserRepository(_db)),
        RepositoryProvider<UnitRepository>(
            create: (_) => UnitRepository(_db)),
        RepositoryProvider<BackupRepository>(
            create: (_) => BackupRepository(_db)),
        RepositoryProvider<ShopRepository>(
            create:(_) => ShopRepository(_db)),
        RepositoryProvider<CompanionRepository>(
            create:(_) => CompanionRepository(_db)),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppCubit>(create: (_) => AppCubit()..loadLocale()),
          BlocProvider(
            create: (ctx) => XpCubit(ctx.read<UserRepository>())..loadXp(),
          ),
          BlocProvider(
            create: (ctx) => ProfileCubit(ctx.read<UserRepository>())..loadProfile(),
          ),
          BlocProvider<ListUnitCubit>(
            create: (ctx) => ListUnitCubit(ctx.read<UnitRepository>())
          ),
        ],
        child: _buildMaterialApp(),
      ),
    );
  }

  Widget _buildMaterialApp() {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return BlocListener<XpCubit, XpState>(
          listenWhen: (previous, current) =>
              current.justLeveledUp && !previous.justLeveledUp,
          listener: (context, xpState) {
            final xp = context.read<XpCubit>();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final overlay = _navigatorKey.currentState?.overlay;
              if (overlay != null && overlay.mounted) {
                SideBar.showOnOverlay(
                  overlay,
                  isRight: true,
                  color: const Color(0xFF00D4C8),
                  topFraction: 0.15,
                  label: '${xpState.level}',
                );
              }
              xp.acknowledgeLevelUp();
            });
          },
          child: MaterialApp(
            navigatorKey: _navigatorKey,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: state.locale,
            title: 'Floating Island',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(useMaterial3: true),
            onGenerateRoute: AppRouter.router.generator,
            initialRoute: Routes.splash,
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(1.0)),
                child: child!,
              );
            },
          ),
        );
      },
    );
  }
}