class AppImages {
  // static final AppCommonImages commonImages =
  //     AppConfig.appIdentifier.logoImages ?? const AppCommonImages();

  AppImages._();
  static final icAvatar ='assets/images/ic_avatar.png';
  static final icFire ='assets/images/ic_fire.png';
  static final icFire2 ='assets/images/ic_fire_2.png';

  static final imgAvatar ='assets/avatar/img_avatar.png';
  static final imgAvatar2 ='assets/avatar/img_avatar_2.png';
  static final imgAvatar3 ='assets/avatar/img_avatar_3.png';
  static final imgAvatar4 ='assets/avatar/img_avatar_4.png';
  static final imgAvatar5 ='assets/avatar/img_avatar_5.png';

  static final icScanFile ='assets/vector/ic_scan_file.png';
}

class AppLogoImages {
  final String suffix;

  const AppLogoImages({this.suffix = 'ra'});

}

class RealAgentImages extends AppLogoImages {
  const RealAgentImages()
      : super(
    suffix: 'ra',
  );
}

class DXAgentImages extends AppLogoImages {
  const DXAgentImages()
      : super(
    suffix: 'dxa',
  );
}

///
class AppCommonImages {
  final String folderName;
  final String folderNameLogo;
  const AppCommonImages(
      {this.folderName = 'dx_agent', this.folderNameLogo = 'dx_agent'});

  String get icLogoDrawer =>
      'assets/images_logo/$folderNameLogo/ic_logo_drawer.png';
  String get icLogoMini =>
      'assets/images_logo/$folderNameLogo/ic_logo_mini.png';
  String get icLogo => 'assets/images_logo/$folderNameLogo/ic_logo.png';
  String get icLogoSplash =>
      'assets/images_logo/$folderNameLogo/ic_logo_splash.png';
  String get bgSplash => 'assets/images_logo/$folderNameLogo/bg_splash.png';
}

class DxAgentImages extends AppCommonImages {
  const DxAgentImages()
      : super(
    folderName: 'propsale',
    folderNameLogo: 'dx_agent',
  );
}
