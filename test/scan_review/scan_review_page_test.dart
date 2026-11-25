import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test_abc/commons/enums.dart';
import 'package:test_abc/generated/l10n.dart';
import 'package:test_abc/page/scan_review/draft/scan_card.dart';
import 'package:test_abc/page/scan_review/draft/scan_draft.dart';
import 'package:test_abc/page/scan_review/scan_draft_cubit.dart';
import 'package:test_abc/page/scan_review/scan_review_page.dart';

class _MockDraftCubit extends MockCubit<ScanDraftState>
    implements ScanDraftCubit {}

void main() {
  late _MockDraftCubit cubit;
  late PublishSubject<String> messages;

  setUpAll(() async {
    await S.load(const Locale('en'));
  });

  setUp(() {
    cubit = _MockDraftCubit();
    messages = PublishSubject<String>();
    addTearDown(messages.close);
    when(() => cubit.messageController).thenAnswer((_) => messages);
    when(() => cubit.load()).thenAnswer((_) async {});
    when(() => cubit.keep(any())).thenAnswer((_) async {});
    when(() => cubit.discard(any())).thenAnswer((_) async {});
    when(() => cubit.undo()).thenAnswer((_) async {});
    when(() => cubit.save()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester, ScanDraftState state) async {
    whenListen(cubit, const Stream<ScanDraftState>.empty(),
        initialState: state);
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: BlocProvider<ScanDraftCubit>.value(
        value: cubit,
        child: const ScanReviewPage(),
      ),
    ));
    await tester.pump();
  }

  ScanDraft oneCard() =>
      const ScanDraft().add(word: '猫', meaning: 'cat', language: 'ja');

  testWidgets('hiện thẻ hiện tại và nút Giữ / Bỏ gọi cubit', (tester) async {
    await pumpPage(tester,
        ScanDraftState(draft: oneCard(), loadStatus: LOADSTATUS.SUCCESS));

    expect(find.text('猫'), findsOneWidget);
    expect(find.text('cat'), findsOneWidget);
    expect(find.text('Card 1 of 1'), findsOneWidget);
    verify(() => cubit.load()).called(1);

    await tester.tap(find.text('Keep'));
    verify(() => cubit.keep(1)).called(1);
    await tester.tap(find.text('Discard'));
    verify(() => cubit.discard(1)).called(1);
  });

  testWidgets('hiện cảnh báo trùng', (tester) async {
    await pumpPage(
        tester,
        ScanDraftState(
          draft: oneCard(),
          loadStatus: LOADSTATUS.SUCCESS,
          duplicates: const {1: DuplicateKind.stored},
        ));

    expect(find.text('Already saved in this unit'), findsOneWidget);
  });

  testWidgets('duyệt xong thì hiện tổng kết và lưu', (tester) async {
    await pumpPage(
        tester,
        ScanDraftState(
            draft: oneCard().keep(1), loadStatus: LOADSTATUS.SUCCESS));

    expect(find.text('Keeping 1 · discarding 0'), findsOneWidget);
    await tester.tap(find.text('Save 1 word'));
    verify(() => cubit.save()).called(1);
    await tester.tap(find.text('Undo'));
    verify(() => cubit.undo()).called(1);
  });

  testWidgets('bỏ hết thì nút chính là Thoát', (tester) async {
    await pumpPage(
        tester,
        ScanDraftState(
            draft: oneCard().discard(1), loadStatus: LOADSTATUS.SUCCESS));

    expect(find.text('Exit'), findsOneWidget);
    expect(find.text('Save 0 words'), findsNothing);
  });

  PopScope reviewPopScope(WidgetTester tester) =>
      tester.widget<PopScope>(find.descendant(
        of: find.byType(ScanReviewPage),
        matching: find.byWidgetPredicate((w) => w is PopScope),
      ));

  testWidgets('không đang lưu thì quay lại được', (tester) async {
    await pumpPage(
        tester,
        ScanDraftState(
            draft: oneCard().keep(1), loadStatus: LOADSTATUS.SUCCESS));
    expect(reviewPopScope(tester).canPop, isTrue);
  });

  testWidgets('đang lưu thì không cho quay lại', (tester) async {
    await pumpPage(
        tester,
        ScanDraftState(
          draft: oneCard().keep(1),
          loadStatus: LOADSTATUS.SUCCESS,
          saveStatus: LOADSTATUS.LOADING,
        ));
    expect(reviewPopScope(tester).canPop, isFalse);
  });

  testWidgets('nạp lỗi thì cho thử lại', (tester) async {
    await pumpPage(
        tester,
        ScanDraftState(draft: oneCard(), loadStatus: LOADSTATUS.FAILED));

    await tester.tap(find.text('Try again'));
    verify(() => cubit.load()).called(2);
  });
}
