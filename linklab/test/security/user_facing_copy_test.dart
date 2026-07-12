import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('核心用户界面不暴露竞赛与研发内部术语', () {
    const paths = [
      'lib/screens/ai_chat/demo_ai_chat_screen.dart',
      'lib/screens/home/seeker_home_screen.dart',
      'lib/screens/home/profile_screen.dart',
      'lib/screens/home/community_screen.dart',
      'lib/screens/auth/preference_screen.dart',
      'lib/services/demo/demo_ai_service.dart',
    ];
    const forbiddenTerms = [
      'F33 与 F36',
      'SOS Mock',
      '页面稿',
      '竞赛演示模式已锁定',
      '竞赛展示',
      '3 分钟 Demo 主线',
      'V1.0 蓝图',
      '标准化需求',
      '本 Demo',
      '演示天气',
      '本地演示档案',
      '避免首屏功能过载',
      '标准化问题',
      '匹配演示',
      '主链路的终态',
      '主线记录',
      '演示账号',
      '演示用户',
      'SOS 基础广播',
      'SOS 演示链路',
      'MVP 主线',
      '当前可演示功能',
      '当前演示范围',
      '版本 1.0.0 Demo',
      '建议开启后再演示',
      '前端状态',
      '基础广播流程',
      '志愿者广播',
      '在线演示',
      '主流程演示',
      'AI Agent × 真人互助',
    ];
    final offenders = <String>[];

    for (final path in paths) {
      final lines = File(path).readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        for (final term in forbiddenTerms) {
          if (lines[index].contains(term)) {
            offenders.add('$path:${index + 1} -> $term');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          '请把面向用户的文案改成用户能直接理解的表达：\n'
          '${offenders.join('\n')}',
    );
  });
}
