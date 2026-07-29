import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 内容审核服务
class ContentModerationService {
  // 敏感词列表（实际项目中应该从服务器获取或配置）
  static const List<String> _sensitiveWords = [
    '暴力', '恐怖', '色情', '赌博', '毒品', '诈骗', '传销',
    '反动', '分裂', '极端', '仇恨', '歧视', '侮辱', '诽谤',
    '脏话', '骂人', '攻击', '威胁', '恐吓', '骚扰', '垃圾',
  ];

  // 敏感词分类
  static const Map<String, List<String>> _sensitiveCategories = {
    'violence': ['暴力', '恐怖', '攻击', '威胁', '恐吓'],
    'pornography': ['色情', '淫秽', '性'],
    'gambling': ['赌博', '博彩', '彩票'],
    'drugs': ['毒品', '吸毒', '贩毒'],
    'fraud': ['诈骗', '欺诈', '骗局'],
    'political': ['反动', '分裂', '极端'],
    'harassment': ['骚扰', '侮辱', '诽谤', '歧视'],
  };

  /// 审核文本内容
  Future<ModerationResult> moderateText(String text) async {
    try {
      if (text.isEmpty) {
        return const ModerationResult(
          isApproved: true,
          confidence: 1.0,
        );
      }

      final flaggedKeywords = <String>[];
      final detectedCategories = <String>[];

      // 检查敏感词
      for (final word in _sensitiveWords) {
        if (text.toLowerCase().contains(word.toLowerCase())) {
          flaggedKeywords.add(word);
        }
      }

      // 分类检测
      for (final entry in _sensitiveCategories.entries) {
        for (final word in entry.value) {
          if (text.toLowerCase().contains(word.toLowerCase())) {
            if (!detectedCategories.contains(entry.key)) {
              detectedCategories.add(entry.key);
            }
          }
        }
      }

      // 计算置信度
      final confidence = _calculateConfidence(
        textLength: text.length,
        flaggedCount: flaggedKeywords.length,
      );

      // 判断是否通过审核
      final isApproved = flaggedKeywords.isEmpty || confidence > 0.7;

      return ModerationResult(
        isApproved: isApproved,
        confidence: confidence,
        category: detectedCategories.isNotEmpty
            ? detectedCategories.first
            : null,
        reason: flaggedKeywords.isNotEmpty
            ? '包含敏感词: ${flaggedKeywords.take(3).join(', ')}'
            : null,
        flaggedKeywords: flaggedKeywords,
      );
    } catch (e) {
      AppLogger.error('文本审核失败', e);
      // 审核失败时默认通过，但记录日志
      return const ModerationResult(
        isApproved: true,
        confidence: 0.5,
        reason: '审核服务异常',
      );
    }
  }

  /// 批量审核文本
  Future<List<ModerationResult>> moderateTexts(List<String> texts) async {
    final results = <ModerationResult>[];
    for (final text in texts) {
      results.add(await moderateText(text));
    }
    return results;
  }

  /// 审核图片内容
  Future<ModerationResult> moderateImage(File image) async {
    try {
      // 检查文件大小
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) {
        return const ModerationResult(
          isApproved: false,
          confidence: 1.0,
          reason: '图片大小超过10MB限制',
        );
      }

      // 这里可以集成第三方图片审核API
      // 例如：阿里云内容安全、腾讯云天御、百度AI审核等

      // 模拟图片审核结果
      // 实际项目中应该调用真实的图片审核服务
      return await _mockImageModeration(image);
    } catch (e) {
      AppLogger.error('图片审核失败', e);
      return const ModerationResult(
        isApproved: true,
        confidence: 0.5,
        reason: '图片审核服务异常',
      );
    }
  }

  /// 模拟图片审核（实际项目中替换为真实API）
  Future<ModerationResult> _mockImageModeration(File image) async {
    // 模拟审核延迟
    await Future.delayed(const Duration(milliseconds: 500));

    // 默认通过
    return const ModerationResult(
      isApproved: true,
      confidence: 0.95,
    );
  }

  /// 使用阿里云内容安全审核图片
  Future<ModerationResult> _aliyunImageModeration(File image) async {
    try {
      // 阿里云内容安全API配置
      const accessKeyId = 'YOUR_ACCESS_KEY_ID';
      const accessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
      const endpoint = 'https://green-cdn.cn-hangzhou.aliyuncs.com';

      // 读取图片并转为base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 构建请求
      final response = await http.post(
        Uri.parse('$endpoint/green/image/scan'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessKeyId',
        },
        body: jsonEncode({
          'scenes': ['porn', 'terrorism', 'ad', 'qrcode', 'live', 'logo'],
          'tasks': [
            {
              'dataId': DateTime.now().millisecondsSinceEpoch.toString(),
              'url': 'data:image/jpeg;base64,$base64Image',
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // 解析审核结果
        return _parseAliyunResult(result);
      } else {
        throw Exception('API请求失败: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('阿里云图片审核失败', e);
      rethrow;
    }
  }

  /// 解析阿里云审核结果
  ModerationResult _parseAliyunResult(Map<String, dynamic> result) {
    try {
      final data = result['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return const ModerationResult(
          isApproved: false,
          confidence: 0,
          reason: '审核结果解析失败',
        );
      }

      final taskResult = data.first as Map<String, dynamic>;
      final results = taskResult['results'] as List<dynamic>?;

      if (results == null || results.isEmpty) {
        return const ModerationResult(
          isApproved: true,
          confidence: 1.0,
        );
      }

      bool isApproved = true;
      double maxConfidence = 0;
      String? category;
      final flaggedKeywords = <String>[];

      for (final item in results) {
        final scene = item['scene'] as String?;
        final suggestion = item['suggestion'] as String?;
        final rate = item['rate'] as double? ?? 0;

        if (suggestion == 'block') {
          isApproved = false;
          category = scene;
          flaggedKeywords.add(scene ?? 'unknown');
        } else if (suggestion == 'review') {
          maxConfidence = 0.5;
        }

        if (rate > maxConfidence) {
          maxConfidence = rate;
        }
      }

      return ModerationResult(
        isApproved: isApproved,
        confidence: isApproved ? 1 - maxConfidence : maxConfidence,
        category: category,
        reason: flaggedKeywords.isNotEmpty
            ? '检测到违规内容: ${flaggedKeywords.join(', ')}'
            : null,
        flaggedKeywords: flaggedKeywords,
      );
    } catch (e) {
      AppLogger.error('解析审核结果失败', e);
      return const ModerationResult(
        isApproved: false,
        confidence: 0,
        reason: '结果解析异常',
      );
    }
  }

  /// 计算置信度
  double _calculateConfidence({
    required int textLength,
    required int flaggedCount,
  }) {
    if (flaggedCount == 0) return 1.0;

    // 基于敏感词密度计算置信度
    final density = flaggedCount / (textLength / 100);
    final confidence = 1.0 - (density * 0.3).clamp(0.0, 1.0);

    return confidence;
  }

  /// 检查内容是否需要人工审核
  bool needsManualReview(ModerationResult result) {
    return !result.isApproved ||
        (result.confidence < 0.8 && result.confidence > 0.3);
  }

  /// 过滤敏感词（用*替换）
  String filterSensitiveWords(String text) {
    var filteredText = text;
    for (final word in _sensitiveWords) {
      final replacement = '*' * word.length;
      filteredText = filteredText.replaceAll(
        RegExp(word, caseSensitive: false),
        replacement,
      );
    }
    return filteredText;
  }

  /// 添加自定义敏感词
  void addSensitiveWords(List<String> words) {
    _sensitiveWords.addAll(words);
  }

  /// 获取敏感词列表
  List<String> getSensitiveWords() {
    return List.unmodifiable(_sensitiveWords);
  }

  /// 实时审核（用于输入时检查）
  Future<Map<String, dynamic>> realtimeCheck(String text) async {
    final result = await moderateText(text);

    return {
      'isValid': result.isApproved,
      'hasSensitiveWords': result.flaggedKeywords.isNotEmpty,
      'sensitiveWords': result.flaggedKeywords,
      'suggestion': result.isApproved
          ? null
          : '内容包含敏感信息，请修改后重试',
    };
  }
}
