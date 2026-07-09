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
    expect(
      'android.permission.RECORD_AUDIO'.allMatches(manifest),
      hasLength(1),
    );
    expect('android.permission.INTERNET'.allMatches(manifest), hasLength(1));
    expect(
      manifest,
      contains(
        'android:name="android.hardware.camera" android:required="false"',
      ),
    );
    expect(
      manifest,
      contains(
        'android:name="android.hardware.microphone" android:required="false"',
      ),
    );
  });

  test('iOS 主发布配置包含图片、语音和相册权限说明', () {
    final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(infoPlist, contains('NSCameraUsageDescription'));
    expect(infoPlist, contains('NSPhotoLibraryUsageDescription'));
    expect(infoPlist, contains('NSMicrophoneUsageDescription'));
    expect(infoPlist, contains('NSSpeechRecognitionUsageDescription'));
    expect(
      'NSPhotoLibraryUsageDescription'.allMatches(infoPlist),
      hasLength(1),
    );
    expect('NSMicrophoneUsageDescription'.allMatches(infoPlist), hasLength(1));
    expect(
      'NSSpeechRecognitionUsageDescription'.allMatches(infoPlist),
      hasLength(1),
    );

    final cameraDescription = RegExp(
      r'NSCameraUsageDescription</key>\s*<string>([^<]+)</string>',
    ).firstMatch(infoPlist)?.group(1);
    expect(cameraDescription, contains('识别文字、颜色和环境'));
  });
}
