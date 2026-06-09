import 'dart:convert';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';

/// 演示數據加載器
class DemoDataLoader {
  static Map<String, dynamic>? _volunteersData;
  static Map<String, dynamic>? _matchingVolunteersData;
  static Map<String, dynamic>? _aiResponsesData;
  static Map<String, dynamic>? _scenariosData;

  static Map<String, dynamic> _decodeJsonMap(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('演示數據格式錯誤，根節點必須是對象');
    }
    return Map<String, dynamic>.from(decoded);
  }

  static List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map<String, dynamic>>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList();
  }

  /// 初始化加載所有演示數據
  static Future<void> initialize() async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoDataLoader.initialize',
    )) {
      return;
    }

    await Future.wait([
      _loadVolunteers(),
      _loadMatchingVolunteers(),
      _loadAIResponses(),
      _loadScenarios(),
    ]);
  }

  /// 加載志願者數據
  static Future<void> _loadVolunteers() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/demo_data/volunteers.json',
      );
      _volunteersData = _decodeJsonMap(jsonString);
    } catch (error) {
      AppLogger.warning('志願者 demo 數據加載失敗，使用空數據降級：$error');
      _volunteersData = const <String, dynamic>{};
    }
  }

  /// 加載 F9 demo 匹配志願者數據
  static Future<void> _loadMatchingVolunteers() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/demo_data/demo_volunteers.json',
      );
      _matchingVolunteersData = _decodeJsonMap(jsonString);
    } catch (error) {
      AppLogger.warning('F9 匹配 demo 志願者數據加載失敗，使用空數據降級：$error');
      _matchingVolunteersData = const <String, dynamic>{};
    }
  }

  /// 加載AI回覆數據
  static Future<void> _loadAIResponses() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/demo_data/ai_responses.json',
      );
      _aiResponsesData = _decodeJsonMap(jsonString);
    } catch (error) {
      AppLogger.warning('AI demo 數據加載失敗，使用空數據降級：$error');
      _aiResponsesData = const <String, dynamic>{};
    }
  }

  /// 加載演示場景數據
  static Future<void> _loadScenarios() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/demo_data/help_scenarios.json',
      );
      _scenariosData = _decodeJsonMap(jsonString);
    } catch (error) {
      AppLogger.warning('場景 demo 數據加載失敗，使用空數據降級：$error');
      _scenariosData = const <String, dynamic>{};
    }
  }

  /// 獲取所有演示志願者
  static List<Map<String, dynamic>> getDemoVolunteers() {
    if (_volunteersData == null) return [];
    return _mapList(_volunteersData!['demoVolunteers']);
  }

  /// 獲取 F9 本地匹配引擎使用的 demo 志願者
  static List<Map<String, dynamic>> getMatchingDemoVolunteers() {
    if (_matchingVolunteersData == null) return [];
    return _mapList(_matchingVolunteersData!['demoVolunteers']);
  }

  /// 獲取默認匹配的志願者
  static Map<String, dynamic>? getDefaultMatchedVolunteer() {
    if (_volunteersData == null) return null;
    final volunteer = _volunteersData!['defaultMatchedVolunteer'];
    if (volunteer is! Map<String, dynamic>) {
      return null;
    }
    return Map<String, dynamic>.from(volunteer);
  }

  /// 獲取OCR場景數據
  static List<Map<String, dynamic>> getOCRScenarios() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['ocrScenarios']);
  }

  /// 獲取場景描述數據
  static List<Map<String, dynamic>> getSceneDescriptions() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['sceneDescriptions']);
  }

  /// 獲取顏色識別數據
  static List<Map<String, dynamic>> getColorRecognitions() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['colorRecognitions']);
  }

  /// 獲取對話回覆
  static List<Map<String, dynamic>> getChatResponses() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['chatResponses']);
  }

  /// 根據意圖獲取回覆
  static String getChatResponseByIntent(String intent) {
    final responses = getChatResponses();
    final response = responses.firstWhere(
      (r) => r['intent'] == intent,
      orElse: () => responses.firstWhere(
        (r) => r['intent'] == 'fallback',
        orElse: () => <String, dynamic>{
          'responses': ['抱歉，我不太明白'],
        },
      ),
    );
    final responseList = _stringList(response['responses']);
    if (responseList.isEmpty) return '抱歉，我不太明白';
    return responseList[DateTime.now().millisecond % responseList.length];
  }

  /// 根據關鍵詞檢測意圖
  static String detectIntent(String input) {
    final responses = getChatResponses();
    for (final response in responses) {
      final keywords = _stringList(response['keywords']);
      for (final keyword in keywords) {
        if (input.contains(keyword)) {
          return response['intent'] as String? ?? 'fallback';
        }
      }
    }
    return 'fallback';
  }

  /// 獲取所有演示場景
  static List<Map<String, dynamic>> getScenarios() {
    if (_scenariosData == null) return [];
    return _mapList(_scenariosData!['scenarios']);
  }

  /// 獲取演示流程
  static List<Map<String, dynamic>> getDemoFlow() {
    if (_scenariosData == null) return [];
    final demoFlow = _scenariosData!['demoFlow'];
    if (demoFlow is! Map<String, dynamic>) {
      return const [];
    }
    return _mapList(demoFlow['steps']);
  }

  /// 獲取緊急檢測關鍵詞
  static Map<String, dynamic> getEmergencyDetection() {
    if (_aiResponsesData == null) return {};
    final detection = _aiResponsesData!['emergencyDetection'];
    if (detection is! Map<String, dynamic>) {
      return const {};
    }
    return Map<String, dynamic>.from(detection);
  }

  /// 檢測是否爲緊急情況
  static bool detectEmergency(String input) {
    final detection = getEmergencyDetection();
    final urgentKeywords = _stringList(detection['urgentKeywords']);
    final emergencyKeywords = _stringList(detection['emergencyKeywords']);
    final autoTriggerPhrases = _stringList(detection['autoTriggerPhrases']);

    final allKeywords = [
      ...urgentKeywords,
      ...emergencyKeywords,
      ...autoTriggerPhrases,
      '暈倒',
      '摔倒',
      '緊急',
      '救命',
    ];

    for (final keyword in allKeywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
