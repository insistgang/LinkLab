import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 主发布清单包含图片、语音和联网所需权限', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.CAMERA'));
    expect(manifest, contains('android.permission.RECORD_AUDIO'));
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('iOS 主发布配置包含图片、语音和相册权限说明', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('NSCameraUsageDescription'));
    expect(infoPlist, contains('NSPhotoLibraryUsageDescription'));
    expect(infoPlist, contains('NSMicrophoneUsageDescription'));
    expect(infoPlist, contains('NSSpeechRecognitionUsageDescription'));
  });
}
