import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/page/user/profile/profile_cubit.dart';
import 'package:test_abc/repository/vocabulary_repository.dart';
import 'package:test_abc/router/router.dart';
import 'cubit/app_cubit.dart';
import 'database/app_db.dart';
import 'page/widgets/avatar/xp_cubit.dart';
import 'router/app_router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final _db = AppDatabase();

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
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AppCubit>(create: (_) => AppCubit(),),
          BlocProvider(create: (_) => XpCubit()),
          BlocProvider(create: (_) => ProfileCubit()),
          // TODO: thêm global cubit khác ở đây
        ],
        child: _buildMaterialApp(),
      ),
    );
  }

  Widget _buildMaterialApp() {
    return MaterialApp(
      title: 'Floating Island',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      onGenerateRoute: AppRouter.router.generator,
      initialRoute: Routes.home,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.0)),
          child: child!,
        );
      },
    );
  }
}