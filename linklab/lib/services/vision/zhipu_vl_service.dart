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
      '请详细描述这张图片的场景，包括主要物体、环境、光线等。用简洁的中文回答，适合视障用户理解。',
    );
  }

  Future<String> recognizeColor(String imagePath) async {
    return _callVisionApi(imagePath, '请识别这张图片中的主要颜色，列出前3-5种颜色及其分布位置。');
  }

  Future<String> identifyObject(String imagePath) async {
    return _callVisionApi(imagePath, '请识别这张图片中的主要物体，用简洁的中文描述。');
  }

  Future<String> recognizeMoney(String imagePath) async {
    return _callVisionApi(imagePath, '请识别这是什么面额的钞票/纸币，用中文回答。');
  }

  Future<String> checkMedicine(String imagePath) async {
    return _callVisionApi(imagePath, '请识别这是什么药品，包括药品名称、用法用量等关键信息。用中文回答。');
  }

  Future<String> _callVisionApi(String imagePath, String prompt) async {
    if (!isConfigured) {
      throw const ZhipuVlException(
        '智谱AI API密钥未配置',
        ZhipuVlErrorType.notConfigured,
      );
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw ZhipuVlException(
        '图片文件不存在: $imagePath',
        ZhipuVlErrorType.fileNotFound,
      );
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw const ZhipuVlException(
        '图片过大，请压缩后重试（最大10MB）',
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
        '网络连接失败，请检查网络设置',
        ZhipuVlErrorType.network,
        e.toString(),
      );
    } on TimeoutException catch (e) {
      throw ZhipuVlException(
        '请求超时，请稍后重试',
        ZhipuVlErrorType.timeout,
        e.toString(),
      );
    } on ZhipuVlException {
      rethrow;
    } catch (e) {
      throw ZhipuVlException(
        '视觉识别失败: $e',
        ZhipuVlErrorType.unknown,
        e.toString(),
      );
    }
  }

  String _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw const ZhipuVlException(
        'API认证失败，请检查API密钥配置',
        ZhipuVlErrorType.authFailed,
      );
    }
    if (response.statusCode == 429) {
      throw const ZhipuVlException(
        'API调用频率过高，请稍后重试',
        ZhipuVlErrorType.rateLimited,
      );
    }
    if (response.statusCode != 200) {
      throw ZhipuVlException(
        'AI服务暂时不可用 (HTTP ${response.statusCode})',
        ZhipuVlErrorType.serverError,
        response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    final error = data['error'];
    if (error != null) {
      final errorMsg = error is Map<String, dynamic>
          ? (error['message']?.toString() ?? '未知错误')
          : error.toString();
      throw ZhipuVlException(
        'API错误: $errorMsg',
        ZhipuVlErrorType.serverError,
        errorMsg,
      );
    }

    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw const ZhipuVlException('AI返回结果为空', ZhipuVlErrorType.emptyResult);
    }

    final firstChoice = choices.first as Map<String, dynamic>?;
    final message = firstChoice?['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;

    if (content == null || content.isEmpty) {
      throw const ZhipuVlException('AI未能识别图片内容', ZhipuVlErrorType.emptyResult);
    }

    AppLogger.info('智谱AI视觉识别成功，响应长度: ${content.length}');
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
