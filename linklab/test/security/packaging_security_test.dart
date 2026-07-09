import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter 资源清单不得打包本地 .env', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final packagesDotEnv = RegExp(
      r'^\s*-\s*\.env\s*$',
      multiLine: true,
    ).hasMatch(pubspec);

    expect(packagesDotEnv, isFalse, reason: '客户端 APK 不能包含真实 API 密钥文件');
  });

  test('可提交的客户端配置不得包含或接受服务端密钥', () {
    final config = File('lib/config/api_config.dart').readAsStringSync();
    final secretAssignments = RegExp(
      r"static\s+(?:const\s+)?String\s+\w*(?:ApiKey|SecretKey|ApiSecret|AppId|Secret)\s*=\s*'([^']*)';",
    ).allMatches(config);

    final populatedSecrets = secretAssignments
        .where((match) => (match.group(1) ?? '').isNotEmpty)
        .toList();
    expect(secretAssignments, isNotEmpty);
    expect(populatedSecrets, isEmpty);
    expect(config, isNot(contains('static void initialize(')));
    expect(config, isNot(contains('static String zhipuApiKey')));
    expect(config, contains('static const String zhipuApiKey'));
  });
}
