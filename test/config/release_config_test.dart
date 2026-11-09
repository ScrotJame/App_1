import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String read(String path) => File(path).readAsStringSync();

void main() {
  test('Android release has a real identity and no debug signing', () {
    final gradle = read('android/app/build.gradle.kts');

    expect(gradle, isNot(contains('applicationId = "com.example')));
    expect(gradle, isNot(contains('getByName("debug")')));
  });

  test('Android does not request store-restricted permissions', () {
    final manifest = read('android/app/src/main/AndroidManifest.xml');

    expect(manifest, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
    expect(manifest, isNot(contains('USE_EXACT_ALARM')));
    expect(manifest, isNot(contains('FOREGROUND_SERVICE_DATA_SYNC')));
    expect(read('lib/main_common.dart'), isNot(contains('manageExternalStorage')));
  });

  test('the app package does not carry env files', () {
    expect(read('pubspec.yaml'), isNot(contains(RegExp(r'-\s+\.env'))));
  });

  test('iOS has a real identity and camera and photo descriptions', () {
    final plist = read('ios/Runner/Info.plist');

    expect(plist, contains('NSCameraUsageDescription'));
    expect(plist, contains('NSPhotoLibraryUsageDescription'));
    expect(
      read('ios/Runner.xcodeproj/project.pbxproj'),
      isNot(contains('com.example.testAbc')),
    );
  });
}
