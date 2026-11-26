import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/service/pronunciation_service.dart';

void main() {
  test('lời gọi thứ hai chờ lần khởi tạo đang chạy', () async {
    var calls = 0;
    final gate = Completer<void>();
    final service = PronunciationService(loader: () {
      calls++;
      return gate.future;
    });

    final first = service.ensureInitialized();
    var secondDone = false;
    final second = service.ensureInitialized().then<void>((_) {
      secondDone = true;
    });
    await Future<void>.delayed(Duration.zero);

    expect(calls, 1);
    expect(secondDone, isFalse);

    gate.complete();
    await Future.wait([first, second]);
    expect(secondDone, isTrue);

    await service.ensureInitialized();
    expect(calls, 1);
  });

  test('khởi tạo lỗi thì lần sau thử lại', () async {
    var calls = 0;
    final service = PronunciationService(loader: () async {
      calls++;
      if (calls == 1) throw StateError('no dictionary');
    });

    await expectLater(service.ensureInitialized(), throwsStateError);
    await service.ensureInitialized();
    expect(calls, 2);
  });
}
