import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../config/api_config.dart';
import 'ai_service.dart';

/// 百度OCR服务
/// F2 文字识别与朗读的核心实现
/// 支持通用文字识别、高精度识别、手写体识别
class BaiduOCRService implements AIService {
  String? _accessToken;
  DateTime? _tokenExpireTime;
  final _client = http.Client();

  @override
  String get serviceName => 'BaiduOCRService';

  @override
  Future<bool> isAvailable() async {
    if (!APIConfig.isBaiduOcrConfigured) {
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
      final result = await recognizeText(File(imageUrl));

      if (!result.isSuccess) {
        return AIResponse.error(result.error?.message ?? 'OCR识别失败');
      }

      final ocrResult = result.data!;

      // 检查是否是药品标签
      final isMedicineLabel = _isMedicineLabel(ocrResult.text);

      // 构建响应
      final responseText = _buildResponseText(ocrResult, isMedicineLabel);

      return AIResponse(
        text: responseText,
        intent: IntentType.textRecognition,
        urgency: isMedicineLabel ? UrgencyLevel.important : UrgencyLevel.normal,
        needsHuman: isMedicineLabel,
        confidence: ocrResult.confidence,
        extraData: {
          'rawText': ocrResult.text,
          'words': ocrResult.words.map((w) => w.text).toList(),
          'isMedicineLabel': isMedicineLabel,
          'language': ocrResult.language,
        },
      );
    } catch (e) {
      return AIResponse.error('OCR识别失败: $e');
    }
  }

  /// 通用文字识别（标准版）
  /// 适用于普通印刷体文字识别
  Future<APIResponse<OCRResult>> recognizeText(File image) async {
    return await _recognizeWithRetry(
      image: image,
      endpoint: '/general_basic',
      params: {
        'detect_direction': 'true',
        'paragraph': 'true',
        'probability': 'true',
      },
    );
  }

  /// 通用文字识别（高精度版）
  /// 适用于小字、模糊、复杂背景等场景
  Future<APIResponse<OCRResult>> recognizeAccurate(File image) async {
    return await _recognizeWithRetry(
      image: image,
      endpoint: '/accurate_basic',
      params: {
        'detect_direction': 'true',
        'paragraph': 'true',
        'probability': 'true',
      },
    );
  }

  /// 手写文字识别
  /// 适用于手写体文字识别
  Future<APIResponse<OCRResult>> recognizeHandwriting(File image) async {
    return await _recognizeWithRetry(
      image: image,
      endpoint: '/handwriting',
      params: {
        'detect_direction': 'true',
        'probability': 'true',
      },
    );
  }

  /// 身份证识别
  /// [isFront] true为正面（人像面），false为背面（国徽面）
  Future<APIResponse<IdCardResult>> recognizeIdCard(File image, {bool isFront = true}) async {
    try {
      await _ensureAccessToken();

      final base64Image = base64Encode(await image.readAsBytes());

      final url = Uri.parse(
        '${APIConfig.baiduOcrBaseUrl}/idcard?access_token=$_accessToken',
      );

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'image': base64Image,
              'id_card_side': isFront ? 'front' : 'back',
            },
          )
          .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

      return _handleIdCardResponse(response);
    } on SocketException catch (e) {
      return APIResponse.failure(APIError.network(e.toString()));
    } on TimeoutException catch (e) {
      return APIResponse.failure(APIError.timeout(e.toString()));
    } catch (e) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: '身份证识别失败',
        originalError: e.toString(),
      ));
    }
  }

  /// 银行卡识别
  Future<APIResponse<BankCardResult>> recognizeBankCard(File image) async {
    try {
      await _ensureAccessToken();

      final base64Image = base64Encode(await image.readAsBytes());

      final url = Uri.parse(
        '${APIConfig.baiduOcrBaseUrl}/bankcard?access_token=$_accessToken',
      );

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'image': base64Image},
          )
          .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

      return _handleBankCardResponse(response);
    } on SocketException catch (e) {
      return APIResponse.failure(APIError.network(e.toString()));
    } on TimeoutException catch (e) {
      return APIResponse.failure(APIError.timeout(e.toString()));
    } catch (e) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: '银行卡识别失败',
        originalError: e.toString(),
      ));
    }
  }

  /// 营业执照识别
  Future<APIResponse<BusinessLicenseResult>> recognizeBusinessLicense(File image) async {
    try {
      await _ensureAccessToken();

      final base64Image = base64Encode(await image.readAsBytes());

      final url = Uri.parse(
        '${APIConfig.baiduOcrBaseUrl}/business_license?access_token=$_accessToken',
      );

      final response = await _client
          .post(
            url,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {'image': base64Image},
          )
          .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

      return _handleBusinessLicenseResponse(response);
    } on SocketException catch (e) {
      return APIResponse.failure(APIError.network(e.toString()));
    } on TimeoutException catch (e) {
      return APIResponse.failure(APIError.timeout(e.toString()));
    } catch (e) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: '营业执照识别失败',
        originalError: e.toString(),
      ));
    }
  }

  /// 带重试机制的OCR识别
  Future<APIResponse<OCRResult>> _recognizeWithRetry({
    required File image,
    required String endpoint,
    required Map<String, String> params,
    int maxRetries = 3,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await _recognize(image, endpoint, params);
      } catch (e) {
        attempts++;
        if (attempts >= maxRetries) {
          if (e is APIError) {
            return APIResponse.failure(e);
          }
          return APIResponse.failure(APIError(
            type: APIErrorType.unknown,
            message: 'OCR识别失败，已重试$maxRetries次',
            originalError: e.toString(),
          ));
        }
        // 等待后重试
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    return APIResponse.failure(APIError(
      type: APIErrorType.unknown,
      message: 'OCR识别失败',
    ));
  }

  /// 执行OCR识别
  Future<APIResponse<OCRResult>> _recognize(
    File image,
    String endpoint,
    Map<String, String> params,
  ) async {
    await _ensureAccessToken();

    final base64Image = base64Encode(await image.readAsBytes());

    // 检查图片大小（百度OCR限制4MB）
    final imageBytes = base64Decode(base64Image);
    if (imageBytes.length > 4 * 1024 * 1024) {
      return APIResponse.failure(APIError(
        type: APIErrorType.invalidParameter,
        message: '图片过大，请压缩后重试',
      ));
    }

    final url = Uri.parse(
      '${APIConfig.baiduOcrBaseUrl}$endpoint?access_token=$_accessToken',
    );

    final body = {
      'image': base64Image,
      ...params,
    };

    final response = await _client
        .post(
          url,
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: body,
        )
        .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

    return _handleOCRResponse(response);
  }

  /// 处理OCR响应
  APIResponse<OCRResult> _handleOCRResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);

    // 检查错误码
    final errorCode = data['error_code'];
    if (errorCode != null) {
      final errorMsg = data['error_msg'] ?? '未知错误';

      switch (errorCode) {
        case 110:
        case 111:
          return APIResponse.failure(APIError.authentication(errorMsg));
        case 17:
        case 18:
          return APIResponse.failure(APIError.quotaExceeded(errorMsg));
        case 216201:
          return APIResponse.failure(APIError(
            type: APIErrorType.invalidParameter,
            message: '图片格式错误',
            originalError: errorMsg,
          ));
        case 216202:
          return APIResponse.failure(APIError(
            type: APIErrorType.invalidParameter,
            message: '图片过大',
            originalError: errorMsg,
          ));
        default:
          return APIResponse.failure(APIError(
            type: APIErrorType.unknown,
            message: '识别失败: $errorMsg',
            originalError: errorMsg,
          ));
      }
    }

    // 解析成功结果
    final wordsResult = data['words_result'] as List<dynamic>? ?? [];

    if (wordsResult.isEmpty) {
      return APIResponse.success(OCRResult(
        text: '',
        words: [],
        confidence: 0.0,
        language: 'unknown',
      ));
    }

    final words = wordsResult.map((item) {
      final probability = item['probability'] as Map<String, dynamic>?;
      final location = item['location'] as Map<String, dynamic>?;

      return OCRWord(
        text: item['words'] as String? ?? '',
        confidence: (probability?['average'] as num?)?.toDouble() ?? 0.9,
        location: location != null
            ? Rect(
                left: location['left'] as int? ?? 0,
                top: location['top'] as int? ?? 0,
                width: location['width'] as int? ?? 0,
                height: location['height'] as int? ?? 0,
              )
            : null,
      );
    }).toList();

    final fullText = words.map((w) => w.text).join('\n');
    final avgConfidence = words.isEmpty
        ? 0.0
        : words.map((w) => w.confidence).reduce((a, b) => a + b) / words.length;

    return APIResponse.success(OCRResult(
      text: fullText,
      words: words,
      confidence: avgConfidence,
      language: _detectLanguage(fullText),
    ));
  }

  /// 处理身份证响应
  APIResponse<IdCardResult> _handleIdCardResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);

    final errorCode = data['error_code'];
    if (errorCode != null) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: data['error_msg'] ?? '身份证识别失败',
      ));
    }

    final wordsResult = data['words_result'] as Map<String, dynamic>? ?? {};

    return APIResponse.success(IdCardResult(
      name: _extractWord(wordsResult, '姓名'),
      gender: _extractWord(wordsResult, '性别'),
      ethnicity: _extractWord(wordsResult, '民族'),
      birth: _extractWord(wordsResult, '出生'),
      address: _extractWord(wordsResult, '住址'),
      idNumber: _extractWord(wordsResult, '公民身份号码'),
      issuingAuthority: _extractWord(wordsResult, '签发机关'),
      validPeriod: _extractWord(wordsResult, '有效期限'),
    ));
  }

  /// 处理银行卡响应
  APIResponse<BankCardResult> _handleBankCardResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);

    final errorCode = data['error_code'];
    if (errorCode != null) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: data['error_msg'] ?? '银行卡识别失败',
      ));
    }

    final result = data['result'] as Map<String, dynamic>? ?? {};

    return APIResponse.success(BankCardResult(
      cardNumber: result['bank_card_number'] as String? ?? '',
      bankName: result['bank_name'] as String? ?? '',
      cardType: result['bank_card_type'] as String? ?? '',
      validDate: result['valid_date'] as String? ?? '',
    ));
  }

  /// 处理营业执照响应
  APIResponse<BusinessLicenseResult> _handleBusinessLicenseResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);

    final errorCode = data['error_code'];
    if (errorCode != null) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: data['error_msg'] ?? '营业执照识别失败',
      ));
    }

    final wordsResult = data['words_result'] as Map<String, dynamic>? ?? {};

    return APIResponse.success(BusinessLicenseResult(
      companyName: _extractWord(wordsResult, '单位名称'),
      legalPerson: _extractWord(wordsResult, '法人'),
      licenseNumber: _extractWord(wordsResult, '证件编号'),
      address: _extractWord(wordsResult, '地址'),
      validPeriod: _extractWord(wordsResult, '有效期'),
    ));
  }

  /// 提取字段值
  String _extractWord(Map<String, dynamic> wordsResult, String key) {
    final field = wordsResult[key] as Map<String, dynamic>?;
    return field?['words'] as String? ?? '';
  }

  /// 确保AccessToken有效
  Future<void> _ensureAccessToken() async {
    // 检查内存中的token
    if (_accessToken != null &&
        _tokenExpireTime != null &&
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return;
    }

    // 检查全局配置中的token
    if (APIConfig.isBaiduOcrTokenValid) {
      _accessToken = APIConfig.baiduOcrAccessToken;
      _tokenExpireTime = DateTime.now().add(const Duration(hours: 23));
      return;
    }

    // 重新获取token
    await _fetchAccessToken();
  }

  /// 获取AccessToken
  Future<void> _fetchAccessToken() async {
    if (!APIConfig.isBaiduOcrConfigured) {
      throw Exception('百度OCR API密钥未配置');
    }

    final url = Uri.parse(
      '${APIConfig.baiduOcrTokenUrl}?grant_type=client_credentials'
      '&client_id=${APIConfig.baiduOcrApiKey}'
      '&client_secret=${APIConfig.baiduOcrSecretKey}',
    );

    final response = await _client
        .post(url)
        .timeout(Duration(seconds: APIConfig.connectionTimeoutSeconds));

    if (response.statusCode != 200) {
      throw Exception('获取AccessToken失败: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    final error = data['error'];
    if (error != null) {
      throw Exception('获取AccessToken失败: $error - ${data['error_description']}');
    }

    _accessToken = data['access_token'];
    final expiresIn = data['expires_in'] as int? ?? 2592000; // 默认30天

    // 提前1小时刷新
    _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600));

    // 同步到全局配置
    APIConfig.setBaiduOcrAccessToken(_accessToken!, expiresIn);
  }

  /// 检测语言
  String _detectLanguage(String text) {
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    final englishRegex = RegExp(r'[a-zA-Z]');

    final hasChinese = chineseRegex.hasMatch(text);
    final hasEnglish = englishRegex.hasMatch(text);

    if (hasChinese && hasEnglish) {
      return 'mixed';
    } else if (hasChinese) {
      return 'zh';
    } else if (hasEnglish) {
      return 'en';
    }
    return 'unknown';
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
  String _buildResponseText(OCRResult result, bool isMedicineLabel) {
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

  /// 释放资源
  void dispose() {
    _client.close();
  }
}

/// OCR识别结果
class OCRResult {
  final String text;
  final List<OCRWord> words;
  final double confidence;
  final String language;

  const OCRResult({
    required this.text,
    required this.words,
    required this.confidence,
    required this.language,
  });
}

/// OCR单词
class OCRWord {
  final String text;
  final double confidence;
  final Rect? location;

  const OCRWord({
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

/// 身份证识别结果
class IdCardResult {
  final String name;
  final String gender;
  final String ethnicity;
  final String birth;
  final String address;
  final String idNumber;
  final String issuingAuthority;
  final String validPeriod;

  const IdCardResult({
    this.name = '',
    this.gender = '',
    this.ethnicity = '',
    this.birth = '',
    this.address = '',
    this.idNumber = '',
    this.issuingAuthority = '',
    this.validPeriod = '',
  });

  bool get isEmpty => name.isEmpty && idNumber.isEmpty;
}

/// 银行卡识别结果
class BankCardResult {
  final String cardNumber;
  final String bankName;
  final String cardType;
  final String validDate;

  const BankCardResult({
    this.cardNumber = '',
    this.bankName = '',
    this.cardType = '',
    this.validDate = '',
  });

  bool get isEmpty => cardNumber.isEmpty;
}

/// 营业执照识别结果
class BusinessLicenseResult {
  final String companyName;
  final String legalPerson;
  final String licenseNumber;
  final String address;
  final String validPeriod;

  const BusinessLicenseResult({
    this.companyName = '',
    this.legalPerson = '',
    this.licenseNumber = '',
    this.address = '',
    this.validPeriod = '',
  });

  bool get isEmpty => companyName.isEmpty;
}
