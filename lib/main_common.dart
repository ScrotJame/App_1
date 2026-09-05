import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:permission_handler/permission_handler.dart';

import 'app.dart';
import 'config/app_config.dart';
import 'firebase_options.dart';
import 'service/pronunciation_service.dart';

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  if (await Permission.scheduleExactAlarm.isDenied) {
    await Permission.scheduleExactAlarm.request();
  }
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

/// Singleton instance — khởi tạo 1 lần, dùng chung cho toàn app
final pronunciationService = PronunciationService();

Future<void> mainCommon(AppConfig config) async {
  AppConfig.setInstance(config);

  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: config.envFileName);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GoogleSignIn.instance.initialize();
  await _requestPermissions();

  // Khởi tạo dictionary cho pronunciation (kuromoji, pinyin) — chạy nền, không chặn cold-start
  unawaited(pronunciationService.ensureInitialized());

  runApp(const MyApp());
}
