// 演示版SOS紧急流程
// 处理SOS触发、通知和响应

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/call/demo_exports.dart';
import 'demo_matching_flow.dart';

/// SOS触发方式
enum SOSTriggerType {
  longPress,    // 长按3秒
  powerButton,  // 电源键3次
  voice,        // 语音触发
  manual,       // 手动点击
}

/// 演示版SOS流程控制器
class DemoSOSFlow {
  static bool _isActive = false;
  static Timer? _responseTimer;

  static bool get isActive => _isActive;

  /// 触发SOS流程
  static Future<void> triggerSOS(
    BuildContext context, {
    SOSTriggerType type = SOSTriggerType.manual,
  }) async {
    if (_isActive) return;

    _isActive = true;

    // 震动反馈
    HapticFeedback.heavyImpact();

    // 进入SOS页面
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DemoSOSScreen(),
        ),
      );
    }

    // 模拟发送短信给紧急联系人
    await _sendEmergencySMS();

    // 5秒后自动匹配
    _responseTimer?.cancel();
    _responseTimer = Timer(const Duration(seconds: 5), () {
      if (context.mounted) {
        _autoMatchVolunteer(context);
      }
    });
  }

  /// 取消SOS
  static void cancelSOS() {
    _isActive = false;
    _responseTimer?.cancel();
  }

  /// SOS解决
  static void resolveSOS() {
    _isActive = false;
    _responseTimer?.cancel();
  }

  /// 模拟发送紧急短信
  static Future<void> _sendEmergencySMS() async {
    // 演示模式：仅打印日志
    // 真实版本会调用SMS API
    print('[DEMO] 发送紧急短信给联系人:');
    print('- 联系人1: 138****0001');
    print('- 联系人2: 139****0002');
    print('- 短信内容: 【共感LinkAble紧急求助】您的亲友触发了SOS...');

    // 模拟延迟
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 自动匹配志愿者
  static void _autoMatchVolunteer(BuildContext context) {
    if (!_isActive) return;

    print('[DEMO] SOS响应：匹配到志愿者');

    // 导航到通话页面
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DemoCallScreen(),
        ),
      );
    }
  }
}

/// SOS快捷触发器
class DemoSOSTrigger {
  // 电源键计数
  static DateTime? _lastPowerKeyTime;
  static int _powerKeyCount = 0;
  static const int _triggerCount = 3;
  static const int _timeWindowMs = 3000;

  /// 处理电源键事件（由原生代码调用）
  static void onPowerKeyPressed() {
    final now = DateTime.now();

    if (_lastPowerKeyTime == null ||
        now.difference(_lastPowerKeyTime!).inMilliseconds > _timeWindowMs) {
      _powerKeyCount = 1;
    } else {
      _powerKeyCount++;
    }

    _lastPowerKeyTime = now;

    if (_powerKeyCount >= _triggerCount) {
      _powerKeyCount = 0;
      // 触发SOS
      // 需要BuildContext，这里仅记录状态
      print('[DEMO] 电源键SOS触发（3次）');
    }
  }

  /// 检查语音触发
  static bool checkVoiceTrigger(String text) {
    final sosKeywords = [
      '紧急求助',
      '救命',
      'SOS',
      'help',
      'emergency',
    ];

    return sosKeywords.any((keyword) =>
        text.toLowerCase().contains(keyword.toLowerCase()));
  }
}

/// SOS演示配置
class DemoSOSConfig {
  /// 长按触发时间（毫秒）
  static const int longPressDurationMs = 3000;

  /// 自动响应时间（秒）
  static const int autoResponseDelaySeconds = 5;

  /// 模拟紧急联系人
  static const List<Map<String, String>> emergencyContacts = [
    {'name': '儿子', 'phone': '138****0001'},
    {'name': '女儿', 'phone': '139****0002'},
  ];

  /// 模拟短信内容模板
  static String getSMSTemplate(String location) {
    return '【共感LinkAble紧急求助】您的亲友触发了SOS求助，'
        '位置: $location，请尽快联系确认安全。';
  }
}
