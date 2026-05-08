class AppImages {
  // static final AppCommonImages commonImages =
  //     AppConfig.appIdentifier.logoImages ?? const AppCommonImages();

  AppImages._();
  static final imgLogo ='assets/images/ic_logo.png';
  static final icAvatar ='assets/images/ic_avatar.png';
  static final icFire ='assets/images/ic_fire.png';
  static final icFire2 ='assets/images/ic_fire_2.png';

  static final imgAvatar ='assets/avatar/img_avatar.png';
  static final imgAvatar2 ='assets/avatar/img_avatar_2.png';
  static final imgAvatar3 ='assets/avatar/img_avatar_3.png';
  static final imgAvatar4 ='assets/avatar/img_avatar_4.png';
  static final imgAvatar5 ='assets/avatar/img_avatar_5.png';

  ///svg
  static final icScanFile ='assets/vector/ic_scan_file.svg';
  static final icAccount ='assets/vector/ic_account.svg';
  static final icBackup ='assets/vector/ic_backup.svg';
  static final icHelpAndSupport ='assets/vector/ic_help_and_support.svg';
  static final icLogOut ='assets/vector/ic_log_out.svg';
  static final icPrivacy ='assets/vector/ic_privacy.svg';
  static final icEdit ='assets/vector/ic_edit_pencil.svg';
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
