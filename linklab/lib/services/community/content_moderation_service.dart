import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/utils/logger.dart';
import '../../models/community_models.dart';

/// 內容審覈服務
class ContentModerationService {
  // 敏感詞列表（實際項目中應該從服務器獲取或配置）
  static const List<String> _sensitiveWords = [
    '暴力', '恐怖', '色情', '賭博', '毒品', '詐騙', '傳銷',
    '反動', '分裂', '極端', '仇恨', '歧視', '侮辱', '誹謗',
    '髒話', '罵人', '攻擊', '威脅', '恐嚇', '騷擾', '垃圾',
  ];

  // 敏感詞分類
  static const Map<String, List<String>> _sensitiveCategories = {
    'violence': ['暴力', '恐怖', '攻擊', '威脅', '恐嚇'],
    'pornography': ['色情', '淫穢', '性'],
    'gambling': ['賭博', '博彩', '彩票'],
    'drugs': ['毒品', '吸毒', '販毒'],
    'fraud': ['詐騙', '欺詐', '騙局'],
    'political': ['反動', '分裂', '極端'],
    'harassment': ['騷擾', '侮辱', '誹謗', '歧視'],
  };

  /// 審覈文本內容
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

      // 檢查敏感詞
      for (final word in _sensitiveWords) {
        if (text.toLowerCase().contains(word.toLowerCase())) {
          flaggedKeywords.add(word);
        }
      }

      // 分類檢測
      for (final entry in _sensitiveCategories.entries) {
        for (final word in entry.value) {
          if (text.toLowerCase().contains(word.toLowerCase())) {
            if (!detectedCategories.contains(entry.key)) {
              detectedCategories.add(entry.key);
            }
          }
        }
      }

      // 計算置信度
      final confidence = _calculateConfidence(
        textLength: text.length,
        flaggedCount: flaggedKeywords.length,
      );

      // 判斷是否通過審覈
      final isApproved = flaggedKeywords.isEmpty || confidence > 0.7;

      return ModerationResult(
        isApproved: isApproved,
        confidence: confidence,
        category: detectedCategories.isNotEmpty
            ? detectedCategories.first
            : null,
        reason: flaggedKeywords.isNotEmpty
            ? '包含敏感詞: ${flaggedKeywords.take(3).join(', ')}'
            : null,
        flaggedKeywords: flaggedKeywords,
      );
    } catch (e) {
      AppLogger.error('文本審覈失敗', e);
      // 審覈失敗時默認通過，但記錄日誌
      return const ModerationResult(
        isApproved: true,
        confidence: 0.5,
        reason: '審覈服務異常',
      );
    }
  }

  /// 批量審覈文本
  Future<List<ModerationResult>> moderateTexts(List<String> texts) async {
    final results = <ModerationResult>[];
    for (final text in texts) {
      results.add(await moderateText(text));
    }
    return results;
  }

  /// 審覈圖片內容
  Future<ModerationResult> moderateImage(File image) async {
    try {
      // 檢查文件大小
      final fileSize = await image.length();
      if (fileSize > 10 * 1024 * 1024) {
        return const ModerationResult(
          isApproved: false,
          confidence: 1.0,
          reason: '圖片大小超過10MB限制',
        );
      }

      // 這裏可以集成第三方圖片審覈API
      // 例如：阿里雲內容安全、騰訊雲天御、百度AI審覈等

      // 模擬圖片審覈結果
      // 實際項目中應該調用真實的圖片審覈服務
      return await _mockImageModeration(image);
    } catch (e) {
      AppLogger.error('圖片審覈失敗', e);
      return const ModerationResult(
        isApproved: true,
        confidence: 0.5,
        reason: '圖片審覈服務異常',
      );
    }
  }

  /// 模擬圖片審覈（實際項目中替換爲真實API）
  Future<ModerationResult> _mockImageModeration(File image) async {
    // 模擬審覈延遲
    await Future.delayed(const Duration(milliseconds: 500));

    // 默認通過
    return const ModerationResult(
      isApproved: true,
      confidence: 0.95,
    );
  }

  /// 使用阿里雲內容安全審覈圖片
  Future<ModerationResult> _aliyunImageModeration(File image) async {
    try {
      // 阿里雲內容安全API配置
      const accessKeyId = 'YOUR_ACCESS_KEY_ID';
      const accessKeySecret = 'YOUR_ACCESS_KEY_SECRET';
      const endpoint = 'https://green-cdn.cn-hangzhou.aliyuncs.com';

      // 讀取圖片並轉爲base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // 構建請求
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
        // 解析審覈結果
        return _parseAliyunResult(result);
      } else {
        throw Exception('API請求失敗: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('阿里雲圖片審覈失敗', e);
      rethrow;
    }
  }

  /// 解析阿里雲審覈結果
  ModerationResult _parseAliyunResult(Map<String, dynamic> result) {
    try {
      final data = result['data'] as List<dynamic>?;
      if (data == null || data.isEmpty) {
        return const ModerationResult(
          isApproved: false,
          confidence: 0,
          reason: '審覈結果解析失敗',
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
            ? '檢測到違規內容: ${flaggedKeywords.join(', ')}'
            : null,
        flaggedKeywords: flaggedKeywords,
      );
    } catch (e) {
      AppLogger.error('解析審覈結果失敗', e);
      return const ModerationResult(
        isApproved: false,
        confidence: 0,
        reason: '結果解析異常',
      );
    }
  }

  /// 計算置信度
  double _calculateConfidence({
    required int textLength,
    required int flaggedCount,
  }) {
    if (flaggedCount == 0) return 1.0;

    // 基於敏感詞密度計算置信度
    final density = flaggedCount / (textLength / 100);
    final confidence = 1.0 - (density * 0.3).clamp(0.0, 1.0);

    return confidence;
  }

  /// 檢查內容是否需要人工審覈
  bool needsManualReview(ModerationResult result) {
    return !result.isApproved ||
        (result.confidence < 0.8 && result.confidence > 0.3);
  }

  /// 過濾敏感詞（用*替換）
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

  /// 添加自定義敏感詞
  void addSensitiveWords(List<String> words) {
    _sensitiveWords.addAll(words);
  }

  /// 獲取敏感詞列表
  List<String> getSensitiveWords() {
    return List.unmodifiable(_sensitiveWords);
  }

  /// 實時審覈（用於輸入時檢查）
  Future<Map<String, dynamic>> realtimeCheck(String text) async {
    final result = await moderateText(text);

    return {
      'isValid': result.isApproved,
      'hasSensitiveWords': result.flaggedKeywords.isNotEmpty,
      'sensitiveWords': result.flaggedKeywords,
      'suggestion': result.isApproved
          ? null
          : '內容包含敏感信息，請修改後重試',
    };
  }
}
