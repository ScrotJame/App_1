class AppImages {
  // static final AppCommonImages commonImages =
  //     AppConfig.appIdentifier.logoImages ?? const AppCommonImages();

  AppImages._();
  static final icAvatar ='assets/images/ic_avatar.png';


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
