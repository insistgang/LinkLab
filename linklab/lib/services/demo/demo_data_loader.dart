import 'dart:convert';
import 'package:flutter/services.dart';

/// 演示数据加载器
class DemoDataLoader {
  static Map<String, dynamic>? _volunteersData;
  static Map<String, dynamic>? _aiResponsesData;
  static Map<String, dynamic>? _scenariosData;

  /// 初始化加载所有演示数据
  static Future<void> initialize() async {
    await Future.wait([
      _loadVolunteers(),
      _loadAIResponses(),
      _loadScenarios(),
    ]);
  }

  /// 加载志愿者数据
  static Future<void> _loadVolunteers() async {
    final jsonString = await rootBundle.loadString('assets/demo_data/volunteers.json');
    _volunteersData = json.decode(jsonString);
  }

  /// 加载AI回复数据
  static Future<void> _loadAIResponses() async {
    final jsonString = await rootBundle.loadString('assets/demo_data/ai_responses.json');
    _aiResponsesData = json.decode(jsonString);
  }

  /// 加载演示场景数据
  static Future<void> _loadScenarios() async {
    final jsonString = await rootBundle.loadString('assets/demo_data/help_scenarios.json');
    _scenariosData = json.decode(jsonString);
  }

  /// 获取所有演示志愿者
  static List<Map<String, dynamic>> getDemoVolunteers() {
    if (_volunteersData == null) return [];
    return List<Map<String, dynamic>>.from(_volunteersData!['demoVolunteers'] ?? []);
  }

  /// 获取默认匹配的志愿者
  static Map<String, dynamic>? getDefaultMatchedVolunteer() {
    if (_volunteersData == null) return null;
    return _volunteersData!['defaultMatchedVolunteer'];
  }

  /// 获取OCR场景数据
  static List<Map<String, dynamic>> getOCRScenarios() {
    if (_aiResponsesData == null) return [];
    return List<Map<String, dynamic>>.from(_aiResponsesData!['ocrScenarios'] ?? []);
  }

  /// 获取场景描述数据
  static List<Map<String, dynamic>> getSceneDescriptions() {
    if (_aiResponsesData == null) return [];
    return List<Map<String, dynamic>>.from(_aiResponsesData!['sceneDescriptions'] ?? []);
  }

  /// 获取颜色识别数据
  static List<Map<String, dynamic>> getColorRecognitions() {
    if (_aiResponsesData == null) return [];
    return List<Map<String, dynamic>>.from(_aiResponsesData!['colorRecognitions'] ?? []);
  }

  /// 获取对话回复
  static List<Map<String, dynamic>> getChatResponses() {
    if (_aiResponsesData == null) return [];
    return List<Map<String, dynamic>>.from(_aiResponsesData!['chatResponses'] ?? []);
  }

  /// 根据意图获取回复
  static String getChatResponseByIntent(String intent) {
    final responses = getChatResponses();
    final response = responses.firstWhere(
      (r) => r['intent'] == intent,
      orElse: () => responses.firstWhere(
        (r) => r['intent'] == 'fallback',
        orElse: () => {'responses': ['抱歉，我不太明白']},
      ),
    );
    final responseList = List<String>.from(response['responses'] ?? []);
    if (responseList.isEmpty) return '抱歉，我不太明白';
    return responseList[DateTime.now().millisecond % responseList.length];
  }

  /// 根据关键词检测意图
  static String detectIntent(String input) {
    final responses = getChatResponses();
    for (final response in responses) {
      final keywords = List<String>.from(response['keywords'] ?? []);
      for (final keyword in keywords) {
        if (input.contains(keyword)) {
          return response['intent'];
        }
      }
    }
    return 'fallback';
  }

  /// 获取所有演示场景
  static List<Map<String, dynamic>> getScenarios() {
    if (_scenariosData == null) return [];
    return List<Map<String, dynamic>>.from(_scenariosData!['scenarios'] ?? []);
  }

  /// 获取演示流程
  static List<Map<String, dynamic>> getDemoFlow() {
    if (_scenariosData == null) return [];
    return List<Map<String, dynamic>>.from(_scenariosData!['demoFlow']?['steps'] ?? []);
  }

  /// 获取紧急检测关键词
  static Map<String, dynamic> getEmergencyDetection() {
    if (_aiResponsesData == null) return {};
    return _aiResponsesData!['emergencyDetection'] ?? {};
  }

  /// 检测是否为紧急情况
  static bool detectEmergency(String input) {
    final detection = getEmergencyDetection();
    final urgentKeywords = List<String>.from(detection['urgentKeywords'] ?? []);
    final emergencyKeywords = List<String>.from(detection['emergencyKeywords'] ?? []);
    final autoTriggerPhrases = List<String>.from(detection['autoTriggerPhrases'] ?? []);

    final allKeywords = [...urgentKeywords, ...emergencyKeywords, ...autoTriggerPhrases];

    for (final keyword in allKeywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}
