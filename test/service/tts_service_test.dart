import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test_abc/service/tts_service.dart';

class _MockFlutterTts extends Mock implements FlutterTts {}

void main() {
  late _MockFlutterTts flutterTts;
  late TtsService tts;

  setUp(() {
    flutterTts = _MockFlutterTts();
    tts = TtsService(flutterTts: flutterTts);
  });

  test('asks the engine with the locale of the language', () async {
    when(() => flutterTts.isLanguageAvailable('ja-JP'))
        .thenAnswer((_) async => true);

    expect(await tts.isLanguageAvailable('ja'), isTrue);
  });

  test('a missing voice is false', () async {
    when(() => flutterTts.isLanguageAvailable(any()))
        .thenAnswer((_) async => false);

    expect(await tts.isLanguageAvailable('ko'), isFalse);
  });

  test('an engine error is false', () async {
    when(() => flutterTts.isLanguageAvailable(any()))
        .thenThrow(Exception('no engine'));

    expect(await tts.isLanguageAvailable('ja'), isFalse);
  });
}
