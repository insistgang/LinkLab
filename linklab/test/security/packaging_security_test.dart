import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter 资源清单不得打包本地 .env', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final packagesDotEnv = RegExp(
      r'^\s*-\s*\.env\s*$',
      multiLine: true,
    ).hasMatch(pubspec);

    expect(
      packagesDotEnv,
      isFalse,
      reason: '客户端 APK 不能包含真实 API 密钥文件',
    );
  });

  test('可提交的 API 配置不得包含客户端密钥', () {
    final config = File('lib/config/api_config.dart').readAsStringSync();
    final secretAssignments = RegExp(
      r"static String \w*(?:ApiKey|SecretKey|ApiSecret|AppId|Secret) = '([^']*)';",
    ).allMatches(config);

    final populatedSecrets = secretAssignments
        .where((match) => (match.group(1) ?? '').isNotEmpty)
        .toList();
    expect(populatedSecrets, isEmpty);
  });
}
