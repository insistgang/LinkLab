import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/api_config.dart';
import 'ai_service.dart';

/// 科大讯飞语音服务
/// ASR语音识别 + TTS语音合成
/// 支持WebSocket实时识别和HTTP批量识别
class XfyunVoiceService implements AIService {
  final _client = http.Client();
  WebSocketChannel? _asrChannel;

  // 回调函数
  Function(String)? _onAsrResult;
  Function(String)? _onAsrPartialResult;
  Function()? _onAsrStart;
  Function()? _onAsrEnd;
  Function(String)? _onAsrError;

  // 状态
  bool _isAsrRunning = false;
  final _asrBuffer = StringBuffer();

  @override
  String get serviceName => 'XfyunVoiceService';

  @override
  Future<bool> isAvailable() async {
    return APIConfig.isXfyunConfigured;
  }

  @override
  Future<AIResponse> process(
    String input, {
    String? imageUrl,
    DialogContext? context,
  }) async {
    // 默认实现：语音播报输入文本
    await textToSpeech(input);
    return AIResponse(
      text: '语音播报完成',
      intent: IntentType.generalChat,
      confidence: 1.0,
    );
  }

  // ==================== ASR 语音识别 ====================

  /// 设置ASR回调
  void setAsrCallbacks({
    Function(String)? onResult,
    Function(String)? onPartialResult,
    Function()? onStart,
    Function()? onEnd,
    Function(String)? onError,
  }) {
    _onAsrResult = onResult;
    _onAsrPartialResult = onPartialResult;
    _onAsrStart = onStart;
    _onAsrEnd = onEnd;
    _onAsrError = onError;
  }

  /// 开始实时语音识别（WebSocket方式）
  /// 适合长语音输入场景
  Future<bool> startRealTimeAsr({
    String language = 'zh_cn',
    String accent = 'mandarin',
    int sampleRate = 16000,
  }) async {
    if (!APIConfig.isXfyunConfigured) {
      _onAsrError?.call('科大讯飞API未配置');
      return false;
    }

    if (_isAsrRunning) {
      await stopAsr();
    }

    try {
      // 构建鉴权URL
      final wsUrl = await _buildAsrWsUrl(
        language: language,
        accent: accent,
        sampleRate: sampleRate,
      );

      // 连接WebSocket
      _asrChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 监听消息
      _asrChannel!.stream.listen(
        _handleAsrMessage,
        onError: (error) {
          _onAsrError?.call('WebSocket错误: $error');
          _isAsrRunning = false;
        },
        onDone: () {
          _isAsrRunning = false;
          _onAsrEnd?.call();
        },
      );

      _isAsrRunning = true;
      _asrBuffer.clear();
      _onAsrStart?.call();

      return true;
    } catch (e) {
      _onAsrError?.call('启动语音识别失败: $e');
      return false;
    }
  }

  /// 发送音频数据
  /// [audioData] PCM格式音频数据
  void sendAudioData(List<int> audioData) {
    if (!_isAsrRunning || _asrChannel == null) return;

    // 将音频数据转为Base64
    final base64Audio = base64Encode(audioData);

    // 构建业务参数
    final businessParams = {
      'data': base64Audio,
      'status': 1, // 1: 中间帧
    };

    _asrChannel!.sink.add(jsonEncode(businessParams));
  }

  /// 结束音频发送
  void endAudioStream() {
    if (!_isAsrRunning || _asrChannel == null) return;

    final endParams = {
      'status': 2, // 2: 最后一帧
    };

    _asrChannel!.sink.add(jsonEncode(endParams));
  }

  /// 停止语音识别
  Future<void> stopAsr() async {
    if (_asrChannel != null) {
      endAudioStream();
      await _asrChannel!.sink.close();
      _asrChannel = null;
    }
    _isAsrRunning = false;
  }

  /// 处理ASR消息
  void _handleAsrMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final code = data['code'];

      if (code != 0) {
        final errorMsg = data['message'] ?? '识别错误';
        _onAsrError?.call('ASR错误: $errorMsg');
        return;
      }

      final result = data['data'];
      if (result == null) return;

      final ws = result['ws'] as List<dynamic>? ?? [];

      // 解析识别结果
      final buffer = StringBuffer();
      for (final item in ws) {
        final cw = item['cw'] as List<dynamic>? ?? [];
        for (final word in cw) {
          final w = word['w'] as String? ?? '';
          buffer.write(w);
        }
      }

      final text = buffer.toString();

      // 判断是否是最终结果
      final status = result['status'] as int? ?? 0;
      if (status == 2) {
        // 最终结果
        _asrBuffer.write(text);
        _onAsrResult?.call(_asrBuffer.toString());
        _asrBuffer.clear();
      } else {
        // 中间结果
        _onAsrPartialResult?.call(text);
      }
    } catch (e) {
      _onAsrError?.call('解析ASR结果失败: $e');
    }
  }

  /// 语音识别（HTTP方式）
  /// 适合短语音识别场景
  /// [audioFile] 音频文件路径
  Future<APIResponse<String>> speechToText(File audioFile) async {
    if (!APIConfig.isXfyunConfigured) {
      return APIResponse.failure(APIError(
        type: APIErrorType.authentication,
        message: '科大讯飞API未配置',
      ));
    }

    try {
      // 读取音频文件
      final audioBytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      // 构建请求参数
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final param = {
        'engine_type': 'sms16k',
        'aue': 'raw',
      };
      final paramBase64 = base64Encode(utf8Encode(jsonEncode(param)));

      // 计算checksum
      final checksumSource =
          '${APIConfig.xfyunApiKey}${timestamp}${paramBase64}${base64Audio}';
      final checksum = md5.convert(utf8Encode(checksumSource)).toString();

      final url = Uri.parse(APIConfig.xfyunAsrHttpUrl);

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
              'X-Appid': APIConfig.xfyunAppId,
              'X-CurTime': timestamp.toString(),
              'X-Param': paramBase64,
              'X-CheckSum': checksum,
            },
            body: {'audio': base64Audio},
          )
          .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

      return _handleHttpAsrResponse(response);
    } on SocketException catch (e) {
      return APIResponse.failure(APIError.network(e.toString()));
    } on TimeoutException catch (e) {
      return APIResponse.failure(APIError.timeout(e.toString()));
    } catch (e) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: '语音识别失败',
        originalError: e.toString(),
      ));
    }
  }

  /// 处理HTTP ASR响应
  APIResponse<String> _handleHttpAsrResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final data = jsonDecode(response.body);
    final code = data['code'];

    if (code != '0') {
      final message = data['desc'] ?? '识别失败';

      if (code == '10105' || code == '10106') {
        return APIResponse.failure(APIError.authentication(message));
      }

      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: message,
        originalError: 'Code: $code',
      ));
    }

    final result = data['data'] as String? ?? '';
    return APIResponse.success(result);
  }

  /// 构建ASR WebSocket URL
  Future<String> _buildAsrWsUrl({
    required String language,
    required String accent,
    required int sampleRate,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTime = timestamp + 300; // 5分钟有效期

    // 构建业务参数
    final business = {
      'language': language,
      'accent': accent,
      'sample_rate': sampleRate,
      'domain': 'iat',
      'vad_eos': 3000, // VAD尾端点检测时间
    };

    final common = {'app_id': APIConfig.xfyunAppId};

    final data = {
      'status': 0,
      'format': 'audio/L16;rate=$sampleRate',
      'encoding': 'raw',
      'audio': '', // 第一帧不发送音频数据
    };

    final params = {
      'common': common,
      'business': business,
      'data': data,
    };

    // 计算签名
    final signature = await _generateXfyunSignature(
      timestamp: timestamp,
      expireTime: expireTime,
    );

    return '${APIConfig.xfyunAsrWsUrl}?appid=${APIConfig.xfyunAppId}'
        '&ts=$timestamp'
        '&signa=$signature'
        '&fd=linkable_asr_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ==================== TTS 语音合成 ====================

  /// 文字转语音
  /// [text] 要合成的文本
  /// [voice] 发音人（可选）
  /// [speed] 语速（0-100，默认50）
  /// [volume] 音量（0-100，默认50）
  /// [pitch] 音调（0-100，默认50）
  Future<APIResponse<List<int>>> textToSpeech(
    String text, {
    String voice = 'xiaoyan',
    int speed = 50,
    int volume = 50,
    int pitch = 50,
  }) async {
    if (!APIConfig.isXfyunConfigured) {
      return APIResponse.failure(APIError(
        type: APIErrorType.authentication,
        message: '科大讯飞API未配置',
      ));
    }

    try {
      // 构建业务参数
      final business = {
        'aue': 'lame', // MP3格式
        'sfl': 1, // 开启流式返回
        'auf': 'audio/L16;rate=16000',
        'vcn': voice,
        'speed': speed,
        'volume': volume,
        'pitch': pitch,
        'tte': 'UTF8',
      };

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final paramBase64 = base64Encode(utf8Encode(jsonEncode(business)));

      // 计算checksum
      final checksumSource =
          '${APIConfig.xfyunApiKey}${timestamp}${paramBase64}${base64Encode(utf8Encode(text))}';
      final checksum = md5.convert(utf8Encode(checksumSource)).toString();

      final url = Uri.parse(APIConfig.xfyunTtsHttpUrl);

      final response = await _client
          .post(
            url,
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded; charset=utf-8',
              'X-Appid': APIConfig.xfyunAppId,
              'X-CurTime': timestamp.toString(),
              'X-Param': paramBase64,
              'X-CheckSum': checksum,
            },
            body: {'text': base64Encode(utf8Encode(text))},
          )
          .timeout(Duration(seconds: APIConfig.requestTimeoutSeconds));

      return _handleTtsResponse(response);
    } on SocketException catch (e) {
      return APIResponse.failure(APIError.network(e.toString()));
    } on TimeoutException catch (e) {
      return APIResponse.failure(APIError.timeout(e.toString()));
    } catch (e) {
      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: '语音合成失败',
        originalError: e.toString(),
      ));
    }
  }

  /// 处理TTS响应
  APIResponse<List<int>> _handleTtsResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final contentType = response.headers['content-type'] ?? '';

    // 如果是JSON，说明有错误
    if (contentType.contains('application/json')) {
      final data = jsonDecode(response.body);
      final code = data['code'];
      final message = data['message'] ?? '合成失败';

      if (code == '10105' || code == '10106') {
        return APIResponse.failure(APIError.authentication(message));
      }

      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: message,
      ));
    }

    // 返回音频数据
    return APIResponse.success(response.bodyBytes);
  }

  /// 流式语音合成（WebSocket）
  /// 适合长文本实时合成
  Stream<List<int>> textToSpeechStream(
    String text, {
    String voice = 'xiaoyan',
    int speed = 50,
    int volume = 50,
    int pitch = 50,
  }) async* {
    if (!APIConfig.isXfyunConfigured) {
      throw Exception('科大讯飞API未配置');
    }

    final wsUrl = await _buildTtsWsUrl();
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    // 发送合成请求
    final request = {
      'common': {'app_id': APIConfig.xfyunAppId},
      'business': {
        'aue': 'raw',
        'vcn': voice,
        'speed': speed,
        'volume': volume,
        'pitch': pitch,
        'tte': 'UTF8',
      },
      'data': {
        'status': 2, // 一次性发送
        'text': base64Encode(utf8Encode(text)),
      },
    };

    channel.sink.add(jsonEncode(request));

    await for (final message in channel.stream) {
      final data = jsonDecode(message as String);
      final code = data['code'];

      if (code != 0) {
        channel.sink.close();
        throw Exception(data['message'] ?? '合成错误');
      }

      final audioData = data['data']?['audio'] as String?;
      if (audioData != null && audioData.isNotEmpty) {
        yield base64Decode(audioData);
      }

      final status = data['data']?['status'] as int? ?? 0;
      if (status == 2) {
        // 合成完成
        channel.sink.close();
        break;
      }
    }
  }

  /// 构建TTS WebSocket URL
  Future<String> _buildTtsWsUrl() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTime = timestamp + 300;

    final signature = await _generateXfyunSignature(
      timestamp: timestamp,
      expireTime: expireTime,
    );

    return '${APIConfig.xfyunTtsWsUrl}?appid=${APIConfig.xfyunAppId}'
        '&ts=$timestamp'
        '&signa=$signature';
  }

  // ==================== 工具方法 ====================

  /// 生成科大讯飞签名
  Future<String> _generateXfyunSignature({
    required int timestamp,
    required int expireTime,
  }) async {
    // 使用API Secret生成HMAC-SHA256签名
    final key = utf8Encode(APIConfig.xfyunApiSecret);
    final message = utf8Encode('${APIConfig.xfyunAppId}${timestamp}');

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);

    return base64Encode(digest.bytes);
  }

  /// 获取支持的语音列表
  List<Map<String, String>> getSupportedVoices() {
    return [
      {'name': 'xiaoyan', 'desc': '小燕（女声，标准）'},
      {'name': 'xiaoyu', 'desc': '小宇（男声，标准）'},
      {'name': 'catherine', 'desc': '凯瑟琳（英文女声）'},
      {'name': 'henry', 'desc': '亨利（英文男声）'},
      {'name': 'vixy', 'desc': '小琪（女声，温柔）'},
      {'name': 'xiaoqi', 'desc': '小琪（女声，活泼）'},
      {'name': 'viyu', 'desc': '小宇（男声，磁性）'},
    ];
  }

  /// 获取支持的语言列表
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'zh_cn', 'desc': '中文（普通话）'},
      {'code': 'zh_hk', 'desc': '中文（粤语）'},
      {'code': 'en_us', 'desc': '英语（美式）'},
    ];
  }

  /// 释放资源
  void dispose() {
    _asrChannel?.sink.close();
    _client.close();
  }
}

/// 语音识别结果
class AsrResult {
  final String text;
  final bool isFinal;
  final double confidence;
  final int startTime;
  final int endTime;

  const AsrResult({
    required this.text,
    required this.isFinal,
    this.confidence = 0.0,
    this.startTime = 0,
    this.endTime = 0,
  });
}

/// 语音合成结果
class TtsResult {
  final List<int> audioData;
  final String format;
  final int sampleRate;

  const TtsResult({
    required this.audioData,
    required this.format,
    required this.sampleRate,
  });
}
