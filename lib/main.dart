import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:test_abc/page/home_page.dart';
import 'package:test_abc/router/app_router.dart';
import 'package:test_abc/router/router.dart';
import 'app.dart';
import 'study_page.dart';

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();

  AppRouter.configure();

  runApp(const MyApp());
}