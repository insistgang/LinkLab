import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'ai_service.dart';

/// OCR服務
/// F2 文字識別與朗讀的核心實現
/// 支持百度OCR API（在線）和降級方案
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
      return AIResponse.error('OCR服務需要圖片輸入');
    }

    try {
      // 1. 讀取圖片文件
      final imageFile = File(imageUrl);
      if (!await imageFile.exists()) {
        return AIResponse.error('圖片文件不存在');
      }

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. 調用OCR識別
      final result = await _recognizeText(base64Image);

      // 3. 檢查是否是藥品標籤
      final isMedicineLabel = _isMedicineLabel(result.text);

      // 4. 構建響應
      final responseText = _buildResponseText(result, isMedicineLabel);

      return AIResponse(
        text: responseText,
        intent: IntentType.textRecognition,
        urgency: isMedicineLabel ? UrgencyLevel.important : UrgencyLevel.normal,
        needsHuman: isMedicineLabel, // 藥品標籤強制轉人工
        confidence: result.confidence,
        extraData: {
          'rawText': result.text,
          'words': result.words,
          'isMedicineLabel': isMedicineLabel,
          'language': result.language,
        },
      );
    } catch (e) {
      return AIResponse.error('OCR識別失敗: $e');
    }
  }

  /// 識別文字（通用文字識別高精度版）
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
      throw Exception('OCR API請求失敗: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (data['error_code'] != null) {
      throw Exception('OCR API錯誤: ${data['error_msg']}');
    }

    return _parseOcrResult(data);
  }

  /// 解析OCR結果
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

  /// 檢測語言
  String _detectLanguage(String text) {
    // 簡單檢測：包含中文字符則爲中文
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    if (chineseRegex.hasMatch(text)) {
      return 'zh';
    }
    return 'en';
  }

  /// 判斷是否是藥品標籤
  bool _isMedicineLabel(String text) {
    final medicineKeywords = [
      '藥品', '藥物', '藥片', '膠囊', '顆粒', '口服液',
      '用法用量', '適應症', '禁忌', '不良反應',
      '國藥準字', '處方藥', 'OTC', '非處方藥',
      '生產日期', '有效期', '批號',
      'medication', 'dosage', 'prescription',
      'tablet', 'capsule', 'mg', 'ml',
    ];

    final lowerText = text.toLowerCase();
    return medicineKeywords.any((keyword) => lowerText.contains(keyword));
  }

  /// 構建響應文本
  String _buildResponseText(OcrResult result, bool isMedicineLabel) {
    if (result.text.isEmpty) {
      return '未能識別到文字，請嘗試重新拍攝，確保光線充足、文字清晰可見。';
    }

    final buffer = StringBuffer();

    if (isMedicineLabel) {
      buffer.writeln('檢測到藥品標籤，識別結果如下：');
      buffer.writeln();
    } else {
      buffer.writeln('識別到以下內容：');
      buffer.writeln();
    }

    buffer.writeln(result.text);

    if (isMedicineLabel) {
      buffer.writeln();
      buffer.writeln('【重要提醒】這是藥品標籤，用藥前請務必向志願者或醫生確認用法用量，確保用藥安全。');
    }

    return buffer.toString();
  }

  /// 確保AccessToken有效
  Future<void> _ensureAccessToken() async {
    if (_accessToken != null &&
        _tokenExpireTime != null &&
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return;
    }

    if (_config.baiduOcrApiKey == null || _config.baiduOcrSecretKey == null) {
      throw Exception('百度OCR API密鑰未配置');
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
      throw Exception('獲取AccessToken失敗: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    _accessToken = data['access_token'];
    final expiresIn = data['expires_in'] as int? ?? 2592000; // 默認30天
    _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600)); // 提前1小時刷新
  }

  /// 識別身份證（特殊場景）
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
        text: '身份證識別成功',
        intent: IntentType.textRecognition,
        extraData: {
          'idCardInfo': wordsResult.map((k, v) =>
            MapEntry(k, (v as Map<String, dynamic>)['words']),
          ),
        },
      );
    } catch (e) {
      return AIResponse.error('身份證識別失敗: $e');
    }
  }
}

/// OCR識別結果
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

/// OCR單詞
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

/// 矩形區域
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
