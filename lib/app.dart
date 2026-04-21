import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_abc/router/router.dart';
import 'cubit/app_cubit.dart';
import 'page/widgets/avatar/xp_cubit.dart';
import 'router/app_router.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AppCubit>(create: (_) => AppCubit(),),
        BlocProvider(create: (_) => XpCubit()),
        // TODO: thêm global cubit khác ở đây
      ],
      child: _buildMaterialApp(),
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