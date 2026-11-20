import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:test_abc/router/go_router_config.dart';
import 'package:test_abc/router/router.dart';

void main() {
  test('offline release has no shop or inventory routes', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final router = createGoRouter();
    addTearDown(router.dispose);

    final paths = router.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toList();

    expect(paths, isNot(contains(Routes.shop)));
    expect(paths, isNot(contains(Routes.inventory)));
    expect(paths, contains(Routes.backup));
  });

  test('the daily review has a route', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final router = createGoRouter();
    addTearDown(router.dispose);

    final paths = router.configuration.routes
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toList();

    expect(Routes.dailyReview, '/daily_review');
    expect(paths, contains(Routes.dailyReview));
  });
}
