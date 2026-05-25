import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'ai_service.dart';

/// OCR服务
/// F2 文字识别与朗读的核心实现
/// 支持百度OCR API（在线）和降级方案
class OcrService implements AIService {
  final AIServiceConfig _config;
  String? _accessToken;
  DateTime? _tokenExpireTime;

  OcrService({required AIServiceConfig config}) : _config = config;

  @override
  String get serviceName => 'OcrService';

  @override
  Future<bool> isAvailable() async {
    if (_config.baiduOcrApiKey == null || _config.baiduOcrSecretKey == null) {
      return false;
    }
    try {
      await _ensureAccessToken();
      return _accessToken != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    if (imageUrl == null) {
      return AIResponse.error('OCR服务需要图片输入');
    }

    try {
      // 1. 读取图片文件
      final imageFile = File(imageUrl);
      if (!await imageFile.exists()) {
        return AIResponse.error('图片文件不存在');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. 调用OCR识别
      final result = await _recognizeText(base64Image);

      // 3. 检查是否是药品标签
      final isMedicineLabel = _isMedicineLabel(result.text);

      // 4. 构建响应
      final responseText = _buildResponseText(result, isMedicineLabel);

      return AIResponse(
        text: responseText,
        intent: IntentType.textRecognition,
        urgency: isMedicineLabel ? UrgencyLevel.important : UrgencyLevel.normal,
        needsHuman: isMedicineLabel, // 药品标签强制转人工
        confidence: result.confidence,
        extraData: {
          'rawText': result.text,
          'words': result.words,
          'isMedicineLabel': isMedicineLabel,
          'language': result.language,
        },
      );
    } catch (e) {
      return AIResponse.error('OCR识别失败: $e');
    }
  }

  /// 识别文字（通用文字识别高精度版）
  Future<OcrResult> _recognizeText(String base64Image) async {
    await _ensureAccessToken();

    final url = Uri.parse(
      'https://aip.baidubce.com/rest/2.0/ocr/v1/accurate_basic?access_token=$_accessToken',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'image': base64Image,
        'detect_direction': 'true',
        'paragraph': 'true',
        'probability': 'true',
      },
    ).timeout(Duration(seconds: _config.timeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('OCR API请求失败: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data['error_code'] != null) {
      throw Exception('OCR API错误: ${data['error_msg']}');
    }

    return _parseOcrResult(data);
  }

  /// 解析OCR结果
  OcrResult _parseOcrResult(Map<String, dynamic> data) {
    final wordsResult = data['words_result'] as List<dynamic>? ?? [];

    final words = wordsResult.map((item) {
      return OcrWord(
        text: item['words'] as String,
        confidence: (item['probability']?['average'] as num?)?.toDouble() ?? 0.9,
        location: item['location'] != null
            ? Rect(
                left: item['location']['left'] as int,
                top: item['location']['top'] as int,
                width: item['location']['width'] as int,
                height: item['location']['height'] as int,
              )
            : null,
      );
    }).toList();

    final fullText = words.map((w) => w.text).join('\n');
    final avgConfidence = words.isEmpty
        ? 0.0
        : words.map((w) => w.confidence).reduce((a, b) => a + b) / words.length;

    return OcrResult(
      text: fullText,
      words: words,
      confidence: avgConfidence,
      language: _detectLanguage(fullText),
    );
  }

  /// 检测语言
  String _detectLanguage(String text) {
    // 简单检测：包含中文字符则为中文
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    if (chineseRegex.hasMatch(text)) {
      return 'zh';
    }
    return 'en';
  }

  /// 判断是否是药品标签
  bool _isMedicineLabel(String text) {
    final medicineKeywords = [
      '药品', '药物', '药片', '胶囊', '颗粒', '口服液',
      '用法用量', '适应症', '禁忌', '不良反应',
      '国药准字', '处方药', 'OTC', '非处方药',
      '生产日期', '有效期', '批号',
      'medication', 'dosage', 'prescription',
      'tablet', 'capsule', 'mg', 'ml',
    ];

    final lowerText = text.toLowerCase();
    return medicineKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// 构建响应文本
  String _buildResponseText(OcrResult result, bool isMedicineLabel) {
    if (result.text.isEmpty) {
      return '未能识别到文字，请尝试重新拍摄，确保光线充足、文字清晰可见。';
    }

    final buffer = StringBuffer();

    if (isMedicineLabel) {
      buffer.writeln('检测到药品标签，识别结果如下：');
      buffer.writeln();
    } else {
      buffer.writeln('识别到以下内容：');
      buffer.writeln();
    }

    buffer.writeln(result.text);

    if (isMedicineLabel) {
      buffer.writeln();
      buffer.writeln('【重要提醒】这是药品标签，用药前请务必向志愿者或医生确认用法用量，确保用药安全。');
    }

    return buffer.toString();
  }

  /// 确保AccessToken有效
  Future<void> _ensureAccessToken() async {
    if (_accessToken != null &&
        _tokenExpireTime != null &&
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return;
    }

    if (_config.baiduOcrApiKey == null || _config.baiduOcrSecretKey == null) {
      throw Exception('百度OCR API密钥未配置');
    }

    final url = Uri.parse(
      'https://aip.baidubce.com/oauth/2.0/token?grant_type=client_credentials'
      '&client_id=${_config.baiduOcrApiKey}'
      '&client_secret=${_config.baiduOcrSecretKey}',
    );

    final response = await http.post(url).timeout(
      Duration(seconds: _config.timeoutSeconds),
    );

    if (response.statusCode != 200) {
      throw Exception('获取AccessToken失败: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'];
    final expiresIn = data['expires_in'] as int? ?? 2592000; // 默认30天
    _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600)); // 提前1小时刷新
  }

  /// 识别身份证（特殊场景）
  Future<AIResponse> recognizeIdCard(String imageUrl, {bool isFront = true}) async {
    try {
      await _ensureAccessToken();

      final imageFile = File(imageUrl);
      final base64Image = base64Encode(await imageFile.readAsBytes());

      final url = Uri.parse(
        'https://aip.baidubce.com/rest/2.0/ocr/v1/idcard?access_token=$_accessToken',
      );

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'image': base64Image,
          'id_card_side': isFront ? 'front' : 'back',
        },
      ).timeout(Duration(seconds: _config.timeoutSeconds));

      final data = jsonDecode(response.body);

      if (data['error_code'] != null) {
        throw Exception(data['error_msg']);
      }

      final wordsResult = data['words_result'] as Map<String, dynamic>;

      return AIResponse(
        text: '身份证识别成功',
        intent: IntentType.textRecognition,
        extraData: {
          'idCardInfo': wordsResult.map((k, v) =>
            MapEntry(k, (v as Map<String, dynamic>)['words']),
          ),
        },
      );
    } catch (e) {
      return AIResponse.error('身份证识别失败: $e');
    }
  }
}

/// OCR识别结果
class OcrResult {
  final String text;
  final List<OcrWord> words;
  final double confidence;
  final String language;

  const OcrResult({
    required this.text,
    required this.words,
    required this.confidence,
    required this.language,
  });
}

/// OCR单词
class OcrWord {
  final String text;
  final double confidence;
  final Rect? location;

  const OcrWord({
    required this.text,
    required this.confidence,
    this.location,
  });
}

/// 矩形区域
class Rect {
  final int left;
  final int top;
  final int width;
  final int height;

  const Rect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}
