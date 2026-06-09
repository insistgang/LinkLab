import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../config/api_config.dart';
import 'ai_service.dart';

/// 科大訊飛語音服務
/// ASR語音識別 + TTS語音合成
/// 支持WebSocket實時識別和HTTP批量識別
class XfyunVoiceService implements AIService {
  final _client = http.Client();
  WebSocketChannel? _asrChannel;

  // 回調函數
  Function(String)? _onAsrResult;
  Function(String)? _onAsrPartialResult;
  Function()? _onAsrStart;
  Function()? _onAsrEnd;
  Function(String)? _onAsrError;

  // 狀態
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
    // 默認實現：語音播報輸入文本
    await textToSpeech(input);
    return AIResponse(
      text: '語音播報完成',
      intent: IntentType.generalChat,
      confidence: 1.0,
    );
  }

  // ==================== ASR 語音識別 ====================

  /// 設置ASR回調
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

  /// 開始實時語音識別（WebSocket方式）
  /// 適合長語音輸入場景
  Future<bool> startRealTimeAsr({
    String language = 'zh_cn',
    String accent = 'mandarin',
    int sampleRate = 16000,
  }) async {
    if (!APIConfig.isXfyunConfigured) {
      _onAsrError?.call('科大訊飛API未配置');
      return false;
    }

    if (_isAsrRunning) {
      await stopAsr();
    }

    try {
      // 構建鑑權URL
      final wsUrl = await _buildAsrWsUrl(
        language: language,
        accent: accent,
        sampleRate: sampleRate,
      );

      // 連接WebSocket
      _asrChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // 監聽消息
      _asrChannel!.stream.listen(
        _handleAsrMessage,
        onError: (error) {
          _onAsrError?.call('WebSocket錯誤: $error');
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
      _onAsrError?.call('啓動語音識別失敗: $e');
      return false;
    }
  }

  /// 發送音頻數據
  /// [audioData] PCM格式音頻數據
  void sendAudioData(List<int> audioData) {
    if (!_isAsrRunning || _asrChannel == null) return;

    // 將音頻數據轉爲Base64
    final base64Audio = base64Encode(audioData);

    // 構建業務參數
    final businessParams = {
      'data': base64Audio,
      'status': 1, // 1: 中間幀
    };

    _asrChannel!.sink.add(jsonEncode(businessParams));
  }

  /// 結束音頻發送
  void endAudioStream() {
    if (!_isAsrRunning || _asrChannel == null) return;

    final endParams = {
      'status': 2, // 2: 最後一幀
    };

    _asrChannel!.sink.add(jsonEncode(endParams));
  }

  /// 停止語音識別
  Future<void> stopAsr() async {
    if (_asrChannel != null) {
      endAudioStream();
      await _asrChannel!.sink.close();
      _asrChannel = null;
    }
    _isAsrRunning = false;
  }

  /// 處理ASR消息
  void _handleAsrMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String);
      final code = data['code'];

      if (code != 0) {
        final errorMsg = data['message'] ?? '識別錯誤';
        _onAsrError?.call('ASR錯誤: $errorMsg');
        return;
      }

      final result = data['data'];
      if (result == null) return;

      final ws = result['ws'] as List<dynamic>? ?? [];

      // 解析識別結果
      final buffer = StringBuffer();
      for (final item in ws) {
        final cw = item['cw'] as List<dynamic>? ?? [];
        for (final word in cw) {
          final w = word['w'] as String? ?? '';
          buffer.write(w);
        }
      }

      final text = buffer.toString();

      // 判斷是否是最終結果
      final status = result['status'] as int? ?? 0;
      if (status == 2) {
        // 最終結果
        _asrBuffer.write(text);
        _onAsrResult?.call(_asrBuffer.toString());
        _asrBuffer.clear();
      } else {
        // 中間結果
        _onAsrPartialResult?.call(text);
      }
    } catch (e) {
      _onAsrError?.call('解析ASR結果失敗: $e');
    }
  }

  /// 語音識別（HTTP方式）
  /// 適合短語音識別場景
  /// [audioFile] 音頻文件路徑
  Future<APIResponse<String>> speechToText(File audioFile) async {
    if (!APIConfig.isXfyunConfigured) {
      return APIResponse.failure(APIError(
        type: APIErrorType.authentication,
        message: '科大訊飛API未配置',
      ));
    }

    try {
      // 讀取音頻文件
      final audioBytes = await audioFile.readAsBytes();
      final base64Audio = base64Encode(audioBytes);

      // 構建請求參數
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final param = {
        'engine_type': 'sms16k',
        'aue': 'raw',
      };
      final paramBase64 = base64Encode(utf8Encode(jsonEncode(param)));

      // 計算checksum
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
        message: '語音識別失敗',
        originalError: e.toString(),
      ));
    }
  }

  /// 處理HTTP ASR響應
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
      final message = data['desc'] ?? '識別失敗';

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

  /// 構建ASR WebSocket URL
  Future<String> _buildAsrWsUrl({
    required String language,
    required String accent,
    required int sampleRate,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expireTime = timestamp + 300; // 5分鐘有效期

    // 構建業務參數
    final business = {
      'language': language,
      'accent': accent,
      'sample_rate': sampleRate,
      'domain': 'iat',
      'vad_eos': 3000, // VAD尾端點檢測時間
    };

    final common = {'app_id': APIConfig.xfyunAppId};

    final data = {
      'status': 0,
      'format': 'audio/L16;rate=$sampleRate',
      'encoding': 'raw',
      'audio': '', // 第一幀不發送音頻數據
    };

    final params = {
      'common': common,
      'business': business,
      'data': data,
    };

    // 計算簽名
    final signature = await _generateXfyunSignature(
      timestamp: timestamp,
      expireTime: expireTime,
    );

    return '${APIConfig.xfyunAsrWsUrl}?appid=${APIConfig.xfyunAppId}'
        '&ts=$timestamp'
        '&signa=$signature'
        '&fd=linkable_asr_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ==================== TTS 語音合成 ====================

  /// 文字轉語音
  /// [text] 要合成的文本
  /// [voice] 發音人（可選）
  /// [speed] 語速（0-100，默認50）
  /// [volume] 音量（0-100，默認50）
  /// [pitch] 音調（0-100，默認50）
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
        message: '科大訊飛API未配置',
      ));
    }

    try {
      // 構建業務參數
      final business = {
        'aue': 'lame', // MP3格式
        'sfl': 1, // 開啓流式返回
        'auf': 'audio/L16;rate=16000',
        'vcn': voice,
        'speed': speed,
        'volume': volume,
        'pitch': pitch,
        'tte': 'UTF8',
      };

      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final paramBase64 = base64Encode(utf8Encode(jsonEncode(business)));

      // 計算checksum
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
        message: '語音合成失敗',
        originalError: e.toString(),
      ));
    }
  }

  /// 處理TTS響應
  APIResponse<List<int>> _handleTtsResponse(http.Response response) {
    if (response.statusCode != 200) {
      return APIResponse.failure(APIError.serviceUnavailable(
        'HTTP ${response.statusCode}',
        response.statusCode,
      ));
    }

    final contentType = response.headers['content-type'] ?? '';

    // 如果是JSON，說明有錯誤
    if (contentType.contains('application/json')) {
      final data = jsonDecode(response.body);
      final code = data['code'];
      final message = data['message'] ?? '合成失敗';

      if (code == '10105' || code == '10106') {
        return APIResponse.failure(APIError.authentication(message));
      }

      return APIResponse.failure(APIError(
        type: APIErrorType.unknown,
        message: message,
      ));
    }

    // 返回音頻數據
    return APIResponse.success(response.bodyBytes);
  }

  /// 流式語音合成（WebSocket）
  /// 適合長文本實時合成
  Stream<List<int>> textToSpeechStream(
    String text, {
    String voice = 'xiaoyan',
    int speed = 50,
    int volume = 50,
    int pitch = 50,
  }) async* {
    if (!APIConfig.isXfyunConfigured) {
      throw Exception('科大訊飛API未配置');
    }

    final wsUrl = await _buildTtsWsUrl();
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));

    // 發送合成請求
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
        'status': 2, // 一次性發送
        'text': base64Encode(utf8Encode(text)),
      },
    };

    channel.sink.add(jsonEncode(request));

    await for (final message in channel.stream) {
      final data = jsonDecode(message as String);
      final code = data['code'];

      if (code != 0) {
        channel.sink.close();
        throw Exception(data['message'] ?? '合成錯誤');
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

  /// 構建TTS WebSocket URL
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

  /// 生成科大訊飛簽名
  Future<String> _generateXfyunSignature({
    required int timestamp,
    required int expireTime,
  }) async {
    // 使用API Secret生成HMAC-SHA256簽名
    final key = utf8Encode(APIConfig.xfyunApiSecret);
    final message = utf8Encode('${APIConfig.xfyunAppId}${timestamp}');

    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(message);

    return base64Encode(digest.bytes);
  }

  /// 獲取支持的語音列表
  List<Map<String, String>> getSupportedVoices() {
    return [
      {'name': 'xiaoyan', 'desc': '小燕（女聲，標準）'},
      {'name': 'xiaoyu', 'desc': '小宇（男聲，標準）'},
      {'name': 'catherine', 'desc': '凱瑟琳（英文女聲）'},
      {'name': 'henry', 'desc': '亨利（英文男聲）'},
      {'name': 'vixy', 'desc': '小琪（女聲，溫柔）'},
      {'name': 'xiaoqi', 'desc': '小琪（女聲，活潑）'},
      {'name': 'viyu', 'desc': '小宇（男聲，磁性）'},
    ];
  }

  /// 獲取支持的語言列表
  List<Map<String, String>> getSupportedLanguages() {
    return [
      {'code': 'zh_cn', 'desc': '中文（普通話）'},
      {'code': 'zh_hk', 'desc': '中文（粵語）'},
      {'code': 'en_us', 'desc': '英語（美式）'},
    ];
  }

  /// 釋放資源
  void dispose() {
    _asrChannel?.sink.close();
    _client.close();
  }
}

/// 語音識別結果
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

/// 語音合成結果
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
