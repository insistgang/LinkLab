import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('发布版本、应用常量与关于页保持一致', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionMatch = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(
      versionMatch,
      isNotNull,
      reason: 'pubspec.yaml 必须使用 x.y.z+build 版本格式',
    );

    final releaseVersion = versionMatch!.group(1)!;
    final buildNumber = int.parse(versionMatch.group(2)!);
    expect(releaseVersion, isNot('1.0.0'), reason: '功能更新后不能继续交付 1.0.0');
    expect(
      buildNumber,
      greaterThan(1),
      reason: '每次正式打包都应递增 Android versionCode',
    );

    final constants = File(
      'lib/core/constants/app_constants.dart',
    ).readAsStringSync();
    final constantMatch = RegExp(
      r"appVersion\s*=\s*'([^']+)'",
    ).firstMatch(constants);
    expect(constantMatch?.group(1), releaseVersion);

    final profile = File(
      'lib/screens/home/profile_screen.dart',
    ).readAsStringSync();
    expect(profile, contains('AppConstants.appVersion'));
    expect(profile, isNot(contains("subtitle: '版本 1.0.0'")));
  });
}
