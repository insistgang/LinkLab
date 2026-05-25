import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../config/api_config.dart';
import '../../core/utils/logger.dart';

class XfyunAsrService {
  static final XfyunAsrService _instance = XfyunAsrService._internal();
  factory XfyunAsrService() => _instance;
  XfyunAsrService._internal();

  WebSocketChannel? _channel;
  final AudioRecorder _recorder = AudioRecorder();

  bool _isListening = false;
  bool _isConnected = false;
  final StringBuffer _resultBuffer = StringBuffer();
  Completer<String>? _recognitionCompleter;

  static const int _frameSize = 1280;
  static const int _sampleRate = 16000;

  bool get isListening => _isListening;

  /// 识别已有的音频数据
  Future<String> recognize(Uint8List audioData) async {
    if (!APIConfig.isXfyunConfigured) {
      throw Exception('讯飞 API 未配置');
    }

    final completer = Completer<String>();
    _resultBuffer.clear();

    try {
      final wsUrl = _buildAuthUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      final streamSub = _channel!.stream.listen(
        (message) {
          _handleMessage(message, completer);
        },
        onError: (error) {
          if (!completer.isCompleted) {
            completer.completeError(Exception('WebSocket 错误: $error'));
          }
        },
        onDone: () {
          if (!completer.isCompleted) {
            completer.complete(_resultBuffer.toString());
          }
        },
      );

      await _channel!.ready;
      _isConnected = true;

      await _sendFirstFrame();
      await _sendAudioFrames(audioData);
      _sendLastFrame();

      final result = await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          if (_resultBuffer.isNotEmpty) {
            return _resultBuffer.toString();
          }
          throw TimeoutException('语音识别超时');
        },
      );

      await streamSub.cancel();
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;

      return result;
    } catch (e) {
      await _channel?.sink.close();
      _channel = null;
      _isConnected = false;
      rethrow;
    }
  }

  /// 开始录音并识别
  Future<String> startListening() async {
    if (!APIConfig.isXfyunConfigured) {
      throw Exception('讯飞 API 未配置');
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;
    _resultBuffer.clear();
    _recognitionCompleter = Completer<String>();

    try {
      final wsUrl = _buildAuthUrl();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _channel!.stream.listen(
        (message) {
          _handleMessage(message, _recognitionCompleter!);
        },
        onError: (error) {
          AppLogger.error('ASR WebSocket 错误', error);
          _isListening = false;
          if (_recognitionCompleter != null &&
              !_recognitionCompleter!.isCompleted) {
            _recognitionCompleter!
                .completeError(Exception('WebSocket 错误: $error'));
          }
        },
        onDone: () {
          _isListening = false;
          if (_recognitionCompleter != null &&
              !_recognitionCompleter!.isCompleted) {
            _recognitionCompleter!.complete(_resultBuffer.toString());
          }
        },
      );

      await _channel!.ready;
      _isConnected = true;

      await _sendFirstFrame();

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _sampleRate,
          numChannels: 1,
          bitRate: 256000,
        ),
        path: await _tempAudioPath,
      );

      _startAudioCaptureLoop();

      return _recognitionCompleter!.future;
    } catch (e) {
      _isListening = false;
      await _cleanup();
      rethrow;
    }
  }

  /// 停止录音并返回识别结果
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _recorder.stop();
    } catch (e) {
      AppLogger.warning('停止录音失败: $e');
    }

    if (_isConnected && _channel != null) {
      _sendLastFrame();
    }

    await Future.delayed(const Duration(milliseconds: 500));
    await _cleanup();
  }

  // ────────────── 音频采集循环 ──────────────

  Timer? _audioTimer;

  void _startAudioCaptureLoop() {
    _audioTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isListening || !_isConnected || _channel == null) {
        _audioTimer?.cancel();
        return;
      }

      try {
        final path = await _tempAudioPath;
        final file = File(path);
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          final dataFrame = _buildDataFrame(bytes, isFirst: false);
          _channel!.sink.add(jsonEncode(dataFrame));
          await file.writeAsBytes([]);
        }
      } on FileSystemException {
        // 文件尚不存在，忽略
      } catch (e) {
        AppLogger.debug('音频采集循环异常: $e');
      }
    });
  }

  // ────────────── WebSocket 帧构建 ──────────────

  Map<String, dynamic> _buildFirstFrame() {
    return {
      'common': {'app_id': APIConfig.xfyunAppId},
      'business': {
        'language': 'zh_cn',
        'accent': 'mandarin',
        'domain': 'iat',
        'vad_eos': 3000,
        'dwa': 'wpgs',
        'ptt': 0,
        'nbest': 1,
        'wbest': 1,
      },
      'data': {
        'status': 0,
        'format': 'audio/L16;rate=$_sampleRate',
        'encoding': 'raw',
        'audio': '',
      },
    };
  }

  Map<String, dynamic> _buildDataFrame(
    Uint8List audioData, {
    bool isFirst = false,
  }) {
    return {
      'data': {
        'status': isFirst ? 0 : 1,
        'format': 'audio/L16;rate=$_sampleRate',
        'encoding': 'raw',
        'audio': base64Encode(audioData),
      },
    };
  }

  Map<String, dynamic> _buildLastFrame() {
    return {
      'data': {
        'status': 2,
        'format': 'audio/L16;rate=$_sampleRate',
        'encoding': 'raw',
        'audio': '',
      },
    };
  }

  Future<void> _sendFirstFrame() async {
    final frame = _buildFirstFrame();
    _channel!.sink.add(jsonEncode(frame));
  }

  Future<void> _sendAudioFrames(Uint8List audioData) async {
    int offset = 0;
    while (offset < audioData.length) {
      final end =
          (offset + _frameSize) > audioData.length
              ? audioData.length
              : offset + _frameSize;
      final chunk = audioData.sublist(offset, end);
      final frame = _buildDataFrame(chunk);
      _channel!.sink.add(jsonEncode(frame));
      offset = end;
      await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  void _sendLastFrame() {
    if (_channel != null && _isConnected) {
      final frame = _buildLastFrame();
      _channel!.sink.add(jsonEncode(frame));
    }
  }

  // ────────────── 消息处理 ──────────────

  void _handleMessage(dynamic message, Completer<String> completer) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final code = data['code'] as int?;

      if (code != 0) {
        final msg = data['message'] as String? ?? '未知错误';
        AppLogger.warning('讯飞 ASR 错误: code=$code, msg=$msg');
        if (!completer.isCompleted) {
          completer.completeError(Exception('ASR 错误 [$code]: $msg'));
        }
        return;
      }

      final resultData = data['data'] as Map<String, dynamic>?;
      if (resultData == null) return;

      final result = resultData['result'] as Map<String, dynamic>?;
      if (result == null) return;

      final ws = (result['ws'] as List<dynamic>?) ?? [];
      final pgs = result['pgs'] as String? ?? '';

      final segBuffer = StringBuffer();
      for (final item in ws) {
        final cw = (item as Map<String, dynamic>)['cw'] as List<dynamic>? ?? [];
        for (final word in cw) {
          final w = (word as Map<String, dynamic>)['w'] as String? ?? '';
          segBuffer.write(w);
        }
      }

      final segText = segBuffer.toString();

      if (pgs == 'apd') {
        _resultBuffer.write(segText);
      } else if (pgs == 'rpl') {
        _resultBuffer.clear();
        _resultBuffer.write(segText);
      } else {
        _resultBuffer.write(segText);
      }

      final status = resultData['status'] as int? ?? 0;
      if (status == 2) {
        if (!completer.isCompleted) {
          completer.complete(_resultBuffer.toString());
        }
      }
    } catch (e) {
      AppLogger.error('解析 ASR 消息失败', e);
    }
  }

  // ────────────── 签名生成（HMAC-SHA256） ──────────────

  String _buildAuthUrl() {
    final now = DateTime.now().toUtc();
    final date = _formatHttpDate(now);

    final signatureOrigin =
        'host: iat-api.xfyun.cn\ndate: $date\nGET /v2/iat HTTP/1.1';
    final signatureBytes = _hmacSha256(
      utf8.encode(APIConfig.xfyunApiSecret),
      utf8.encode(signatureOrigin),
    );
    final signature = base64Encode(signatureBytes);

    final authorization =
        'api_key="${APIConfig.xfyunApiKey}", algorithm="hmac-sha256", headers="host date request-line", signature="$signature"';

    final authorizationBase64 = base64Encode(utf8.encode(authorization));
    final dateEncoded = Uri.encodeComponent(date);
    final authEncoded = Uri.encodeComponent(authorizationBase64);

    return '${APIConfig.xfyunAsrWsUrl}?authorization=$authEncoded&date=$dateEncoded';
  }

  List<int> _hmacSha256(List<int> key, List<int> data) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).bytes;
  }

  String _formatHttpDate(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = days[date.weekday - 1];
    final month = months[date.month - 1];
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    final s = date.second.toString().padLeft(2, '0');

    return '$day, $d $month ${date.year} $h:$m:$s GMT';
  }

  // ────────────── 辅助方法 ──────────────

  Future<String> get _tempAudioPath async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}${Platform.pathSeparator}xfyun_asr_temp.wav';
  }

  Future<void> _cleanup() async {
    _audioTimer?.cancel();
    _audioTimer = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      // ignore
    }

    if (_channel != null) {
      try {
        await _channel!.sink.close();
      } catch (e) {
        // ignore
      }
      _channel = null;
    }

    _isConnected = false;
    _isListening = false;
  }

  void dispose() {
    _cleanup();
    _recorder.dispose();
  }
}
