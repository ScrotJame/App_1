import 'package:fluro/fluro.dart';
import 'package:flutter/cupertino.dart';
import 'router.dart';
import 'router_handler.dart';

class AppRouter {
  static final FluroRouter router = FluroRouter();

  static void configure() {
    router.notFoundHandler = notFoundHandler;

    router.define(Routes.splash, handler: splashHandler);
    router.define(Routes.home, handler: homeHandler);
    router.define(Routes.profile, handler: profileHandler);
    router.define(Routes.splash, handler: splashHandler);

    // TODO: thêm route mới ở đây
    // router.define(Routes.game, handler: gameHandler);
  }

  /// Navigate tới route mới
  static void navigateTo(
      context,
      String routeName, {
        Object? arguments,
        TransitionType transition = TransitionType.native,
        bool replace = false,
        bool clearStack = false,
      }) {
    router.navigateTo(
      context,
      routeName,
      routeSettings: RouteSettings(arguments: arguments),
      transition: transition,
      replace: replace,
      clearStack: clearStack,
    );
  }

  /// Navigate và xóa toàn bộ stack (dùng cho logout, splash → home)
  static void navigateAndClearStack(context, String routeName,
      {Object? arguments}) {
    navigateTo(
      context,
      routeName,
      arguments: arguments,
      clearStack: true,
      transition: TransitionType.fadeIn,
    );
  }
}