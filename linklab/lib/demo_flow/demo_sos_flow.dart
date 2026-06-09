// 演示版SOS緊急流程
// 處理SOS觸發、通知和響應

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/utils/logger.dart';
import '../screens/call/demo_exports.dart';
import 'demo_matching_flow.dart';

/// SOS觸發方式
enum SOSTriggerType {
  longPress,    // 長按3秒
  powerButton,  // 電源鍵3次
  voice,        // 語音觸發
  manual,       // 手動點擊
}

/// 演示版SOS流程控制器
class DemoSOSFlow {
  static bool _isActive = false;
  static Timer? _responseTimer;

  static bool get isActive => _isActive;

  /// 觸發SOS流程
  static Future<void> triggerSOS(
    BuildContext context, {
    SOSTriggerType type = SOSTriggerType.manual,
  }) async {
    if (_isActive) return;

    _isActive = true;

    // 震動反饋
    HapticFeedback.heavyImpact();

    // 進入SOS頁面
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const DemoSOSScreen(),
        ),
      );
    }

    // 模擬發送短信給緊急聯繫人
    await _sendEmergencySMS();

    // 5秒後自動匹配
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

  /// SOS解決
  static void resolveSOS() {
    _isActive = false;
    _responseTimer?.cancel();
  }

  /// 模擬發送緊急短信
  static Future<void> _sendEmergencySMS() async {
    // 演示模式：僅打印日誌
    // 真實版本會調用SMS API
    AppLogger.info('[DEMO] 發送緊急短信給聯繫人');
    AppLogger.verbose('[DEMO] - 聯繫人1: 138****0001');
    AppLogger.verbose('[DEMO] - 聯繫人2: 139****0002');
    AppLogger.verbose('[DEMO] - 短信內容: 【共感LinkAble緊急求助】您的親友觸發了SOS...');

    // 模擬延遲
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// 自動匹配志願者
  static void _autoMatchVolunteer(BuildContext context) {
    if (!_isActive) return;

    AppLogger.info('[DEMO] SOS響應：匹配到志願者');

    // 導航到通話頁面
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const DemoCallScreen(),
        ),
      );
    }
  }
}

/// SOS快捷觸發器
class DemoSOSTrigger {
  // 電源鍵計數
  static DateTime? _lastPowerKeyTime;
  static int _powerKeyCount = 0;
  static const int _triggerCount = 3;
  static const int _timeWindowMs = 3000;

  /// 處理電源鍵事件（由原生代碼調用）
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
      // 觸發SOS
      // 需要BuildContext，這裏僅記錄狀態
      AppLogger.warning('[DEMO] 電源鍵SOS觸發（3次）');
    }
  }

  /// 檢查語音觸發
  static bool checkVoiceTrigger(String text) {
    final sosKeywords = [
      '緊急求助',
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
  /// 長按觸發時間（毫秒）
  static const int longPressDurationMs = 3000;

  /// 自動響應時間（秒）
  static const int autoResponseDelaySeconds = 5;

  /// 模擬緊急聯繫人
  static const List<Map<String, String>> emergencyContacts = [
    {'name': '兒子', 'phone': '138****0001'},
    {'name': '女兒', 'phone': '139****0002'},
  ];

  /// 模擬短信內容模板
  static String getSMSTemplate(String location) {
    return '【共感LinkAble緊急求助】您的親友觸發了SOS求助，'
        '位置: $location，請儘快聯繫確認安全。';
  }
}
