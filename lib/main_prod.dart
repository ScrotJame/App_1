import 'config/app_config.dart';
import 'main_common.dart';

void main() async {
  final config = AppConfig(
    flavor: AppFlavor.prod,
    appName: 'Dungeonary',
    envFileName: '.env.prod',
  );

  await mainCommon(config);
}
