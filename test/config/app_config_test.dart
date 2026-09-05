import 'package:flutter_test/flutter_test.dart';
import 'package:test_abc/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    test('Dev flavor properties are correct', () {
      final devConfig = AppConfig(
        flavor: AppFlavor.dev,
        appName: 'Dungeonary Dev',
        envFileName: '.env.dev',
      );

      expect(devConfig.flavor, AppFlavor.dev);
      expect(devConfig.appName, 'Dungeonary Dev');
      expect(devConfig.envFileName, '.env.dev');
      expect(devConfig.isDev, isTrue);
      expect(devConfig.isProd, isFalse);
    });

    test('Prod flavor properties are correct', () {
      final prodConfig = AppConfig(
        flavor: AppFlavor.prod,
        appName: 'Dungeonary',
        envFileName: '.env.prod',
      );

      expect(prodConfig.flavor, AppFlavor.prod);
      expect(prodConfig.appName, 'Dungeonary');
      expect(prodConfig.envFileName, '.env.prod');
      expect(prodConfig.isDev, isFalse);
      expect(prodConfig.isProd, isTrue);
    });

    test('Singleton instance getter and setter work as expected', () {
      final config = AppConfig(
        flavor: AppFlavor.dev,
        appName: 'Dungeonary Dev',
        envFileName: '.env.dev',
      );

      AppConfig.setInstance(config);
      expect(AppConfig.instance, equals(config));
      expect(AppConfig.instance.isDev, isTrue);
    });
  });
}
