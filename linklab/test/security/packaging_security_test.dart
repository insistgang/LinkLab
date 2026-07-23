import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linklab/services/local_storage.dart';

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

  test('客户端不得将认证令牌复制到 SharedPreferences', () {
    final sessionService = File(
      'lib/services/app_session_service.dart',
    ).readAsStringSync();
    final localStorage = File(
      'lib/services/local_storage.dart',
    ).readAsStringSync();

    expect(sessionService, isNot(contains('saveAuthToken')));
    expect(localStorage, isNot(contains('saveAuthToken')));
  });

  test('升级后初始化会清除旧版本遗留的明文认证令牌', () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'legacy-plaintext-token',
    });

    await LocalStorage().initialize();
    final preferences = await SharedPreferences.getInstance();

    expect(preferences.containsKey('auth_token'), isFalse);
  });

  test('真实语音接口不得使用明文 HTTP', () {
    final config = File('lib/config/api_config.dart').readAsStringSync();

    expect(config, isNot(contains("'http://api.xfyun.cn")));
  });
}
