import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:android_intent_plus/android_intent.dart';

import '../commons/enums.dart';

class TtsService {
  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();

  final FlutterTts _flutterTts;

  Future<TtsSpeakResult> speakWord(String? text, {String? languageCode}) async {
    final word = text?.trim();
    if (word == null || word.isEmpty) return TtsSpeakResult.empty;

    final locale = _localeFromLanguageCode(languageCode);

    final available = await _flutterTts.isLanguageAvailable(locale);
    if (available != true) {
      return TtsSpeakResult.languageUnavailable;
    }

    await _flutterTts.stop();
    await _flutterTts.awaitSpeakCompletion(false);
    await _flutterTts.setLanguage(locale);
    await _flutterTts.setSpeechRate(0.45);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(word);
    return TtsSpeakResult.ok;
  }

  /// Mở thẳng màn hình "Install voice data" của Google TTS (chỉ Android).
  Future<void> openVoiceDataInstaller() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final intent = AndroidIntent(
      action: 'android.speech.tts.engine.INSTALL_TTS_DATA',
    );
    try {
      await intent.launch();
    } catch (_) {
    }
  }

  Future<void> stop() => _flutterTts.stop();

  Future<void> dispose() async {
    await _flutterTts.stop();
  }

  String _localeFromLanguageCode(String? languageCode) {
    switch (languageCode?.trim().toLowerCase()) {
      case 'ja':
        return 'ja-JP';
      case 'zh':
        return 'zh-CN';
      case 'ko':
        return 'ko-KR';
      case 'vi':
        return 'vi-VN';
      case 'fr':
        return 'fr-FR';
      case 'de':
        return 'de-DE';
      case 'es':
        return 'es-ES';
      case 'ru':
        return 'ru-RU';
      case 'th':
        return 'th-TH';
      case 'en':
      default:
        return 'en-US';
    }
  }
}