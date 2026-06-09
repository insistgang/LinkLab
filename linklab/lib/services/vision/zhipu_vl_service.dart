import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../core/utils/logger.dart';

class ZhipuVlService {
  final http.Client _client;

  ZhipuVlService({http.Client? client}) : _client = client ?? http.Client();

  bool get isConfigured => APIConfig.isZhipuConfigured;

  Future<String> describeScene(String imagePath) async {
    return _callVisionApi(
      imagePath,
      '請詳細描述這張圖片的場景，包括主要物體、環境、光線等。用簡潔的中文回答，適合視障用戶理解。',
    );
  }

  Future<String> recognizeColor(String imagePath) async {
    return _callVisionApi(imagePath, '請識別這張圖片中的主要顏色，列出前3-5種顏色及其分佈位置。');
  }

  Future<String> identifyObject(String imagePath) async {
    return _callVisionApi(imagePath, '請識別這張圖片中的主要物體，用簡潔的中文描述。');
  }

  Future<String> recognizeMoney(String imagePath) async {
    return _callVisionApi(imagePath, '請識別這是什麼面額的鈔票/紙幣，用中文回答。');
  }

  Future<String> checkMedicine(String imagePath) async {
    return _callVisionApi(imagePath, '請識別這是什麼藥品，包括藥品名稱、用法用量等關鍵信息。用中文回答。');
  }

  Future<String> _callVisionApi(String imagePath, String prompt) async {
    if (!isConfigured) {
      throw const ZhipuVlException(
        '智譜AI API密鑰未配置',
        ZhipuVlErrorType.notConfigured,
      );
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw ZhipuVlException(
        '圖片文件不存在: $imagePath',
        ZhipuVlErrorType.fileNotFound,
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ZhipuVlException(
        '圖片過大，請壓縮後重試（最大10MB）',
        ZhipuVlErrorType.imageTooLarge,
      );
    }

    final base64Image = base64Encode(bytes);
    final mimeType = _detectMimeType(imagePath);

    final url = Uri.parse('${APIConfig.zhipuBaseUrl}/chat/completions');

    final requestBody = jsonEncode({
      'model': APIConfig.zhipuVlModel,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'},
            },
          ],
        },
      ],
    });

    try {
      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${APIConfig.zhipuApiKey}',
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: APIConfig.requestTimeoutSeconds));

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ZhipuVlException(
        '網絡連接失敗，請檢查網絡設置',
        ZhipuVlErrorType.network,
        e.toString(),
      );
    } on TimeoutException catch (e) {
      throw ZhipuVlException(
        '請求超時，請稍後重試',
        ZhipuVlErrorType.timeout,
        e.toString(),
      );
    } on ZhipuVlException {
      rethrow;
    } catch (e) {
      throw ZhipuVlException(
        '視覺識別失敗: $e',
        ZhipuVlErrorType.unknown,
        e.toString(),
      );
    }
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const ZhipuVlException(
        'API認證失敗，請檢查API密鑰配置',
        ZhipuVlErrorType.authFailed,
      );
    }
    if (response.statusCode == 429) {
      throw const ZhipuVlException(
        'API調用頻率過高，請稍後重試',
        ZhipuVlErrorType.rateLimited,
      );
    }
    if (response.statusCode != 200) {
      throw ZhipuVlException(
        'AI服務暫時不可用 (HTTP ${response.statusCode})',
        ZhipuVlErrorType.serverError,
        response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final error = data['error'];
    if (error != null) {
      final errorMsg = error is Map<String, dynamic>
          ? (error['message']?.toString() ?? '未知錯誤')
          : error.toString();
      throw ZhipuVlException(
        'API錯誤: $errorMsg',
        ZhipuVlErrorType.serverError,
        errorMsg,
      );
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const ZhipuVlException('AI返回結果爲空', ZhipuVlErrorType.emptyResult);
    }

    final firstChoice = choices.first as Map<String, dynamic>?;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.isEmpty) {
      throw const ZhipuVlException('AI未能識別圖片內容', ZhipuVlErrorType.emptyResult);
    }

    AppLogger.info('智譜AI視覺識別成功，響應長度: ${content.length}');
    return content;
  }

  String _detectMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg';
    }
  }

  void dispose() {
    _client.close();
  }
}

enum ZhipuVlErrorType {
  notConfigured,
  fileNotFound,
  imageTooLarge,
  network,
  timeout,
  authFailed,
  rateLimited,
  serverError,
  emptyResult,
  unknown,
}

class ZhipuVlException implements Exception {
  final String message;
  final ZhipuVlErrorType type;
  final String? detail;

  const ZhipuVlException(this.message, this.type, [this.detail]);

  @override
  String toString() => 'ZhipuVlException[$type]: $message';
}
