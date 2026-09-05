import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:test_abc/page/backup/backup_cubit.dart';
import 'package:test_abc/page/list_unit/list_unit_cubit.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/repository/achievement_repository.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/companion_repository.dart';
import 'package:test_abc/repository/inventory_repository.dart';
import 'package:test_abc/repository/learning_history_repository.dart';
import 'package:test_abc/repository/shop_repository.dart';
import 'package:test_abc/repository/tag_repository.dart';
import 'package:test_abc/repository/unit_repository.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/service/auth_service.dart';
import 'package:test_abc/service/mission_service.dart';
import 'package:test_abc/service/tts_service.dart';
import 'commons/enums.dart';
import 'components/side_bar.dart';
import 'cubit/app_cubit.dart';
import 'cubit/auth_cubit.dart';
import 'database/app_db.dart';
import 'generated/l10n.dart';
import 'main.dart' show pronunciationService;
import 'page/daily_quest/daily_quest_cubit.dart';
import 'page/daily_quest/data/daily_quest_repository.dart';
import 'page/daily_quest/data/quest_local_data_source.dart';
import 'page/widgets/avatar/xp_cubit.dart';
import 'router/go_router_config.dart';
import 'service/pronunciation_service.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final _db = AppDatabase();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createGoRouter();
  }

  @override
  void dispose() {
    _router.dispose();
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
        RepositoryProvider<InventoryRepository>(
            create:(_) => InventoryRepository(_db)),
        RepositoryProvider<AchievementRepository>(
            create:(_) => AchievementRepository(_db)),
        RepositoryProvider<LearningHistoryRepository>(
            create:(_) => LearningHistoryRepository(_db)),
        RepositoryProvider<AuthService>(
            create: (_) => AuthService()),
        RepositoryProvider<TtsService>(
          create: (_) => TtsService(),
          dispose: (service) => service.dispose(),
        ),
        RepositoryProvider<PronunciationService>.value(
          value: pronunciationService,
        ),
        // ── Daily Quest DI chain ────────────────────────────
        // Thứ tự QUAN TRỌNG: DataSource → Repository → Service
        RepositoryProvider<QuestLocalDataSource>(
          create: (_) => SharedPrefsQuestDataSource(),
        ),
        RepositoryProvider<DailyQuestRepository>(
          create: (ctx) => DailyQuestRepository(
            ctx.read<QuestLocalDataSource>(),
          ),
        ),
        RepositoryProvider<MissionService>(
          create: (ctx) => MissionService(
            ctx.read<DailyQuestRepository>(),
          ),
        ),
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
            create: (ctx) => ListUnitCubit(ctx.read<UnitRepository>(), ctx.read<VocabularyRepository>())
          ),
          BlocProvider<AuthCubit>(
            create: (ctx) => AuthCubit(
              ctx.read<AuthService>(),
              ctx.read<UserRepository>(),
            )..init(),
          ),
          BlocProvider<BackupCubit>(
            create: (ctx) => BackupCubit(ctx.read<BackupRepository>()),
          ),
          BlocProvider<DailyQuestCubit>(
            create: (ctx) => DailyQuestCubit(
              ctx.read<MissionService>(),
              onStreakCompleted: () => ctx.read<UserRepository>().markTodayStreak(),
            )..initData(),
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
              final overlay = rootNavigatorKey.currentState?.overlay;
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
          child: BlocListener<AuthCubit, AuthState>(
            // Chỉ bắt đúng thời điểm CHUYỂN sang authenticated, tránh gọi
            // lại autoSyncFromServer() mỗi khi AuthState rebuild vì lý do
            // khác (ví dụ chỉ đổi errorMessage).
            listenWhen: (previous, current) =>
            previous.status != AuthStatus.authenticated &&
                current.status == AuthStatus.authenticated,
            listener: (context, authState) {
              // Đăng nhập xong (kể cả trên máy mới) -> tự động tải bản
              // backup mới nhất từ Firestore về, không cần người dùng
              // nhập secret key thủ công.
              context.read<BackupCubit>().autoSyncFromServer();
            },
            child: MaterialApp.router(
              routerConfig: _router,
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
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),

                textTheme: GoogleFonts.balooBhai2TextTheme(
                  Theme.of(context).textTheme,
                ),

                primaryTextTheme: GoogleFonts.balooBhai2TextTheme(
                  Theme.of(context).primaryTextTheme,
                ),
              ),
              builder: (context, child) {
                return Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: (_) {
                    try {
                      context.read<DailyQuestCubit>().recordUserActivity();
                    } catch (_) {}
                  },
                  child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child!,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}