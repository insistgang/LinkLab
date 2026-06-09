import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../../../config/api_config.dart';
import 'ai_service.dart';

/// 百度OCR服務
/// F2 文字識別與朗讀的核心實現
/// 支持通用文字識別、高精度識別、手寫體識別
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
      return AIResponse.error('OCR服務需要圖片輸入');
    }

    try {
      final result = await recognizeText(File(imageUrl));

      if (!result.isSuccess) {
        return AIResponse.error(result.error?.message ?? 'OCR識別失敗');
      }

      final ocrResult = result.data!;

      // 檢查是否是藥品標籤
      final isMedicineLabel = _isMedicineLabel(ocrResult.text);

      // 構建響應
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
      return AIResponse.error('OCR識別失敗: $e');
    }
  }

  /// 通用文字識別（標準版）
  /// 適用於普通印刷體文字識別
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

  /// 通用文字識別（高精度版）
  /// 適用於小字、模糊、複雜背景等場景
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

  /// 手寫文字識別
  /// 適用於手寫體文字識別
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

  /// 身份證識別
  /// [isFront] true爲正面（人像面），false爲背面（國徽面）
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
        message: '身份證識別失敗',
        originalError: e.toString(),
      ));
    }
  }

  /// 銀行卡識別
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
        message: '銀行卡識別失敗',
        originalError: e.toString(),
      ));
    }
  }

  /// 營業執照識別
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
        message: '營業執照識別失敗',
        originalError: e.toString(),
      ));
    }
  }

  /// 帶重試機制的OCR識別
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
            message: 'OCR識別失敗，已重試$maxRetries次',
            originalError: e.toString(),
          ));
        }
        // 等待後重試
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      }
    }

    return APIResponse.failure(APIError(
      type: APIErrorType.unknown,
      message: 'OCR識別失敗',
    ));
  }

  /// 執行OCR識別
  Future<APIResponse<OCRResult>> _recognize(
    File image,
    String endpoint,
    Map<String, String> params,
  ) async {
    await _ensureAccessToken();

    final base64Image = base64Encode(await image.readAsBytes());

    // 檢查圖片大小（百度OCR限制4MB）
    final imageBytes = base64Decode(base64Image);
    if (imageBytes.length > 4 * 1024 * 1024) {
      return APIResponse.failure(APIError(
        type: APIErrorType.invalidParameter,
        message: '圖片過大，請壓縮後重試',
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

  /// 處理OCR響應
  APIResponse<OCRResult> _handleOCRResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);

    // 檢查錯誤碼
    final errorCode = data['error_code'];
    if (errorCode != null) {
      final errorMsg = data['error_msg'] ?? '未知錯誤';

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
            message: '圖片格式錯誤',
            originalError: errorMsg,
          ));
        case 216202:
          return APIResponse.failure(APIError(
            type: APIErrorType.invalidParameter,
            message: '圖片過大',
            originalError: errorMsg,
          ));
        default:
          return APIResponse.failure(APIError(
            type: APIErrorType.unknown,
            message: '識別失敗: $errorMsg',
            originalError: errorMsg,
          ));
      }
    }

    // 解析成功結果
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

  /// 處理身份證響應
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
        message: data['error_msg'] ?? '身份證識別失敗',
      ));
    }

    final wordsResult = data['words_result'] as Map<String, dynamic>? ?? {};

    return APIResponse.success(IdCardResult(
      name: _extractWord(wordsResult, '姓名'),
      gender: _extractWord(wordsResult, '性別'),
      ethnicity: _extractWord(wordsResult, '民族'),
      birth: _extractWord(wordsResult, '出生'),
      address: _extractWord(wordsResult, '住址'),
      idNumber: _extractWord(wordsResult, '公民身份號碼'),
      issuingAuthority: _extractWord(wordsResult, '簽發機關'),
      validPeriod: _extractWord(wordsResult, '有效期限'),
    ));
  }

  /// 處理銀行卡響應
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
        message: data['error_msg'] ?? '銀行卡識別失敗',
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

  /// 處理營業執照響應
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
        message: data['error_msg'] ?? '營業執照識別失敗',
      ));
    }

    final wordsResult = data['words_result'] as Map<String, dynamic>? ?? {};

    return APIResponse.success(BusinessLicenseResult(
      companyName: _extractWord(wordsResult, '單位名稱'),
      legalPerson: _extractWord(wordsResult, '法人'),
      licenseNumber: _extractWord(wordsResult, '證件編號'),
      address: _extractWord(wordsResult, '地址'),
      validPeriod: _extractWord(wordsResult, '有效期'),
    ));
  }

  /// 提取字段值
  String _extractWord(Map<String, dynamic> wordsResult, String key) {
    final field = wordsResult[key] as Map<String, dynamic>?;
    return field?['words'] as String? ?? '';
  }

  /// 確保AccessToken有效
  Future<void> _ensureAccessToken() async {
    // 檢查內存中的token
    if (_accessToken != null &&
        _tokenExpireTime != null &&
        DateTime.now().isBefore(_tokenExpireTime!)) {
      return;
    }

    // 檢查全局配置中的token
    if (APIConfig.isBaiduOcrTokenValid) {
      _accessToken = APIConfig.baiduOcrAccessToken;
      _tokenExpireTime = DateTime.now().add(const Duration(hours: 23));
      return;
    }

    // 重新獲取token
    await _fetchAccessToken();
  }

  /// 獲取AccessToken
  Future<void> _fetchAccessToken() async {
    if (!APIConfig.isBaiduOcrConfigured) {
      throw Exception('百度OCR API密鑰未配置');
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
      throw Exception('獲取AccessToken失敗: HTTP ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    final error = data['error'];
    if (error != null) {
      throw Exception('獲取AccessToken失敗: $error - ${data['error_description']}');
    }

    _accessToken = data['access_token'];
    final expiresIn = data['expires_in'] as int? ?? 2592000; // 默認30天

    // 提前1小時刷新
    _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 3600));

    // 同步到全局配置
    APIConfig.setBaiduOcrAccessToken(_accessToken!, expiresIn);
  }

  /// 檢測語言
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
  String _buildResponseText(OCRResult result, bool isMedicineLabel) {
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

  /// 釋放資源
  void dispose() {
    _client.close();
  }
}

/// OCR識別結果
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

/// OCR單詞
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

/// 身份證識別結果
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

/// 銀行卡識別結果
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

/// 營業執照識別結果
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
