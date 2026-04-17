import 'dart:convert';
import 'package:flutter/services.dart';

import '../../config/app_config.dart';

/// 演示数据加载器
class DemoDataLoader {
  static Map<String, dynamic>? _volunteersData;
  static Map<String, dynamic>? _aiResponsesData;
  static Map<String, dynamic>? _scenariosData;

  static Map<String, dynamic> _decodeJsonMap(String jsonString) {
    final decoded = json.decode(jsonString);
    if (decoded is! Map) {
      throw const FormatException('演示数据格式错误，根节点必须是对象');
    }
    return Map<String, dynamic>.from(decoded as Map);
  }

  static List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return raw.whereType<String>().toList();
  }

  /// 初始化加载所有演示数据
  static Future<void> initialize() async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoDataLoader.initialize',
    )) {
      return;
    }

    await Future.wait([
      _loadVolunteers(),
      _loadAIResponses(),
      _loadScenarios(),
    ]);
  }

  /// 加载志愿者数据
  static Future<void> _loadVolunteers() async {
    final jsonString = await rootBundle.loadString(
      'assets/demo_data/volunteers.json',
    );
    _volunteersData = _decodeJsonMap(jsonString);
  }

  /// 加载AI回复数据
  static Future<void> _loadAIResponses() async {
    final jsonString = await rootBundle.loadString(
      'assets/demo_data/ai_responses.json',
    );
    _aiResponsesData = _decodeJsonMap(jsonString);
  }

  /// 加载演示场景数据
  static Future<void> _loadScenarios() async {
    final jsonString = await rootBundle.loadString(
      'assets/demo_data/help_scenarios.json',
    );
    _scenariosData = _decodeJsonMap(jsonString);
  }

  /// 获取所有演示志愿者
  static List<Map<String, dynamic>> getDemoVolunteers() {
    if (_volunteersData == null) return [];
    return _mapList(_volunteersData!['demoVolunteers']);
  }

  /// 获取默认匹配的志愿者
  static Map<String, dynamic>? getDefaultMatchedVolunteer() {
    if (_volunteersData == null) return null;
    final volunteer = _volunteersData!['defaultMatchedVolunteer'];
    if (volunteer is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(volunteer);
  }

  /// 获取OCR场景数据
  static List<Map<String, dynamic>> getOCRScenarios() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['ocrScenarios']);
  }

  /// 获取场景描述数据
  static List<Map<String, dynamic>> getSceneDescriptions() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['sceneDescriptions']);
  }

  /// 获取颜色识别数据
  static List<Map<String, dynamic>> getColorRecognitions() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['colorRecognitions']);
  }

  /// 获取对话回复
  static List<Map<String, dynamic>> getChatResponses() {
    if (_aiResponsesData == null) return [];
    return _mapList(_aiResponsesData!['chatResponses']);
  }

  /// 根据意图获取回复
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

  /// 根据关键词检测意图
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

  /// 获取所有演示场景
  static List<Map<String, dynamic>> getScenarios() {
    if (_scenariosData == null) return [];
    return _mapList(_scenariosData!['scenarios']);
  }

  /// 获取演示流程
  static List<Map<String, dynamic>> getDemoFlow() {
    if (_scenariosData == null) return [];
    final demoFlow = _scenariosData!['demoFlow'];
    if (demoFlow is! Map) {
      return const [];
    }
    return _mapList(demoFlow['steps']);
  }

  /// 获取紧急检测关键词
  static Map<String, dynamic> getEmergencyDetection() {
    if (_aiResponsesData == null) return {};
    final detection = _aiResponsesData!['emergencyDetection'];
    if (detection is! Map) {
      return const {};
    }
    return Map<String, dynamic>.from(detection);
  }

  /// 检测是否为紧急情况
  static bool detectEmergency(String input) {
    final detection = getEmergencyDetection();
    final urgentKeywords = _stringList(detection['urgentKeywords']);
    final emergencyKeywords = _stringList(detection['emergencyKeywords']);
    final autoTriggerPhrases = _stringList(detection['autoTriggerPhrases']);

    final allKeywords = [
      ...urgentKeywords,
      ...emergencyKeywords,
      ...autoTriggerPhrases,
    ];

    for (final keyword in allKeywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
