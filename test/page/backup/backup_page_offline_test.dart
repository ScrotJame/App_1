import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/cubit/auth_cubit.dart';
import 'package:test_abc/database/app_db.dart';
import 'package:test_abc/page/backup/backup_page.dart';
import 'package:test_abc/repository/backup_data_repository.dart';
import 'package:test_abc/repository/user_repository.dart';
import 'package:test_abc/service/auth_service.dart';

void main() {
  testWidgets('offline backup page shows only the file flow', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final authCubit = AuthCubit(AuthService(), UserRepository(db));
    addTearDown(authCubit.close);

    await tester.pumpWidget(
      RepositoryProvider<BackupRepository>(
        create: (_) => BackupRepository(db),
        child: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const MaterialApp(home: BackupPage()),
        ),
      ),
    );

    expect(find.text('Server'), findsNothing);
    expect(find.text('Chia sẻ file backup'), findsOneWidget);
    expect(find.text('Chọn file backup'), findsOneWidget);
    expect(
      find.text(
        'Backup gồm từ vựng, unit, tag và tiến độ ôn. Companion, thành tích, '
        'lịch sử học và nhiệm vụ ngày chưa được sao lưu.',
      ),
      findsOneWidget,
    );
  });
}
