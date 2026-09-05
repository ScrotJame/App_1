import 'config/app_config.dart';
import 'main_common.dart';

void main() async {
  final config = AppConfig(
    flavor: AppFlavor.dev,
    appName: 'Dungeonary Dev',
    envFileName: '.env.dev',
  );

  await mainCommon(config);
}
