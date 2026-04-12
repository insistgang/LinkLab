import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'webrtc_config.dart';

/// 录音状态
enum RecordingState {
  idle,       // 空闲
  recording,  // 录音中
  paused,     // 暂停
  stopped,    // 已停止
  error,      // 错误
}

/// 录音信息
class RecordingInfo {
  final String filePath;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final int fileSize;
  final String format;

  RecordingInfo({
    required this.filePath,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.fileSize,
    required this.format,
  });

  /// 获取格式化的时长
  String get formattedDuration {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 获取格式化的文件大小
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 通话录音服务
/// 支持录制本地音频流并保存到文件
class CallRecordingService {
  static final CallRecordingService _instance = CallRecordingService._internal();
  factory CallRecordingService() => _instance;
  CallRecordingService._internal();

  // ==================== 录音组件 ====================

  /// FlutterSound录音器
  FlutterSoundRecorder? _recorder;

  /// 录音会话
  StreamSubscription? _recordingDataSubscription;

  // ==================== 状态流控制器 ====================

  /// 录音状态流
  final _stateController = StreamController<RecordingState>.broadcast();

  /// 录音时长流
  final _durationController = StreamController<Duration>.broadcast();

  /// 录音电平流（用于显示音量指示）
  final _levelController = StreamController<double>.broadcast();

  /// 错误流
  final _errorController = StreamController<String>.broadcast();

  // ==================== 状态 ====================

  /// 当前录音状态
  RecordingState _state = RecordingState.idle;

  /// 录音开始时间
  DateTime? _startTime;

  /// 录音暂停时间
  DateTime? _pauseTime;

  /// 累计录音时长
  Duration _recordedDuration = Duration.zero;

  /// 当前录音文件路径
  String? _currentFilePath;

  /// 计时器
  Timer? _durationTimer;

  /// 是否已初始化
  bool _isInitialized = false;

  // ==================== Getters ====================

  /// 录音状态流
  Stream<RecordingState> get stateStream => _stateController.stream;

  /// 录音时长流
  Stream<Duration> get durationStream => _durationController.stream;

  /// 录音电平流
  Stream<double> get levelStream => _levelController.stream;

  /// 错误流
  Stream<String> get errorStream => _errorController.stream;

  /// 当前录音状态
  RecordingState get state => _state;

  /// 是否正在录音
  bool get isRecording => _state == RecordingState.recording;

  /// 是否已暂停
  bool get isPaused => _state == RecordingState.paused;

  /// 当前录音文件路径
  String? get currentFilePath => _currentFilePath;

  /// 当前录音时长
  Duration get currentDuration {
    if (_state == RecordingState.recording && _startTime != null) {
      return _recordedDuration + DateTime.now().difference(_startTime!);
    }
    return _recordedDuration;
  }

  // ==================== 初始化方法 ====================

  /// 初始化录音服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _recorder = FlutterSoundRecorder();

      // 打开录音器
      await _recorder!.openRecorder();

      // 设置订阅（用于获取录音电平）
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      _isInitialized = true;
      print('[Recording] 录音服务已初始化');
    } catch (e) {
      _emitError('初始化录音服务失败: $e');
      throw Exception('初始化录音服务失败: $e');
    }
  }

  /// 检查并请求权限
  Future<bool> checkPermissions() async {
    try {
      // 检查麦克风权限
      var microphoneStatus = await Permission.microphone.status;
      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();
      }

      // 检查存储权限（Android）
      if (Platform.isAndroid) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        // Android 13+ 需要更细粒度的权限
        if (await Permission.audio.isRestricted == false) {
          var audioStatus = await Permission.audio.status;
          if (!audioStatus.isGranted) {
            await Permission.audio.request();
          }
        }
      }

      return microphoneStatus.isGranted;
    } catch (e) {
      _emitError('权限检查失败: $e');
      return false;
    }
  }

  // ==================== 录音控制方法 ====================

  /// 开始录音
  ///
  /// [customFileName] - 自定义文件名（可选）
  /// [codec] - 音频编码格式
  Future<RecordingInfo?> startRecording({
    String? customFileName,
    Codec codec = Codec.aacADTS,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_state == RecordingState.recording) {
      throw Exception('正在录音中，请先停止当前录音');
    }

    // 检查权限
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('需要麦克风权限才能录音');
    }

    try {
      // 生成文件路径
      final filePath = await _generateFilePath(
        customFileName: customFileName,
        codec: codec,
      );
      _currentFilePath = filePath;

      // 开始录音
      await _recorder!.startRecorder(
        toFile: filePath,
        codec: codec,
        sampleRate: WebRTCConfig.recordingSampleRate,
        bitRate: WebRTCConfig.recordingBitrate,
        numChannels: 1, // 单声道
      );

      // 监听录音数据（获取音量电平）
      _recordingDataSubscription = _recorder!.onProgress!.listen((event) {
        // 发送音量电平（0.0 - 1.0）
        final decibels = event.decibels ?? 0;
        final normalizedLevel = _normalizeDecibels(decibels);
        _levelController.add(normalizedLevel);
      });

      // 更新状态
      _state = RecordingState.recording;
      _startTime = DateTime.now();
      _stateController.add(_state);

      // 启动计时器
      _startDurationTimer();

      print('[Recording] 开始录音: $filePath');

      return RecordingInfo(
        filePath: filePath,
        startTime: _startTime!,
        duration: Duration.zero,
        fileSize: 0,
        format: _getFormatFromCodec(codec),
      );
    } catch (e) {
      _state = RecordingState.error;
      _stateController.add(_state);
      _emitError('开始录音失败: $e');
      return null;
    }
  }

  /// 暂停录音
  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) return;

    try {
      await _recorder!.pauseRecorder();

      // 计算已录音时长
      if (_startTime != null) {
        _recordedDuration += DateTime.now().difference(_startTime!);
      }

      _pauseTime = DateTime.now();
      _state = RecordingState.paused;
      _stateController.add(_state);

      // 停止计时器
      _stopDurationTimer();

      print('[Recording] 录音已暂停');
    } catch (e) {
      _emitError('暂停录音失败: $e');
    }
  }

  /// 恢复录音
  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) return;

    try {
      await _recorder!.resumeRecorder();

      _startTime = DateTime.now();
      _pauseTime = null;
      _state = RecordingState.recording;
      _stateController.add(_state);

      // 启动计时器
      _startDurationTimer();

      print('[Recording] 录音已恢复');
    } catch (e) {
      _emitError('恢复录音失败: $e');
    }
  }

  /// 停止录音
  Future<RecordingInfo?> stopRecording() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return null;
    }

    try {
      // 停止录音
      final filePath = await _recorder!.stopRecorder();

      // 计算最终时长
      if (_state == RecordingState.recording && _startTime != null) {
        _recordedDuration += DateTime.now().difference(_startTime!);
      }

      // 取消订阅
      await _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;

      // 停止计时器
      _stopDurationTimer();

      // 获取文件信息
      final file = File(filePath ?? _currentFilePath ?? '');
      int fileSize = 0;
      if (await file.exists()) {
        fileSize = await file.length();
      }

      final endTime = DateTime.now();

      final info = RecordingInfo(
        filePath: filePath ?? _currentFilePath ?? '',
        startTime: _startTime ?? endTime.subtract(_recordedDuration),
        endTime: endTime,
        duration: _recordedDuration,
        fileSize: fileSize,
        format: _getFormatFromFilePath(filePath ?? _currentFilePath ?? ''),
      );

      // 重置状态
      _state = RecordingState.stopped;
      _stateController.add(_state);

      print('[Recording] 录音已停止: ${info.formattedDuration}, ${info.formattedFileSize}');

      return info;
    } catch (e) {
      _state = RecordingState.error;
      _stateController.add(_state);
      _emitError('停止录音失败: $e');
      return null;
    }
  }

  /// 取消录音（不保存文件）
  Future<void> cancelRecording() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return;
    }

    try {
      // 停止录音
      await _recorder!.stopRecorder();

      // 取消订阅
      await _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;

      // 停止计时器
      _stopDurationTimer();

      // 删除临时文件
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 重置状态
      _state = RecordingState.idle;
      _recordedDuration = Duration.zero;
      _startTime = null;
      _pauseTime = null;
      _currentFilePath = null;
      _stateController.add(_state);

      print('[Recording] 录音已取消');
    } catch (e) {
      _emitError('取消录音失败: $e');
    }
  }

  // ==================== 文件管理方法 ====================

  /// 获取录音文件列表
  Future<List<RecordingInfo>> getRecordings() async {
    try {
      final directory = await _getRecordingsDirectory();
      final files = await directory.list().toList();

      final recordings = <RecordingInfo>[];

      for (final file in files.whereType<File>()) {
        final stat = await file.stat();
        if (stat.type == FileSystemEntityType.file) {
          recordings.add(RecordingInfo(
            filePath: file.path,
            startTime: stat.modified.subtract(const Duration(minutes: 5)), // 估算
            duration: Duration.zero, // 无法从文件获取
            fileSize: stat.size,
            format: _getFormatFromFilePath(file.path),
          ));
        }
      }

      // 按时间排序（最新的在前）
      recordings.sort((a, b) => b.startTime.compareTo(a.startTime));

      return recordings;
    } catch (e) {
      _emitError('获取录音列表失败: $e');
      return [];
    }
  }

  /// 删除录音文件
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('[Recording] 录音已删除: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      _emitError('删除录音失败: $e');
      return false;
    }
  }

  /// 重命名录音文件
  Future<String?> renameRecording(String oldPath, String newName) async {
    try {
      final oldFile = File(oldPath);
      if (!await oldFile.exists()) return null;

      final directory = oldFile.parent;
      final extension = oldFile.path.split('.').last;
      final newPath = '${directory.path}/$newName.$extension';

      final newFile = await oldFile.rename(newPath);
      return newFile.path;
    } catch (e) {
      _emitError('重命名录音失败: $e');
      return null;
    }
  }

  /// 获取录音文件
  Future<File?> getRecordingFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      _emitError('获取录音文件失败: $e');
      return null;
    }
  }

  /// 导出录音文件到指定路径
  Future<bool> exportRecording(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return false;

      await sourceFile.copy(destinationPath);
      print('[Recording] 录音已导出: $destinationPath');
      return true;
    } catch (e) {
      _emitError('导出录音失败: $e');
      return false;
    }
  }

  // ==================== 内部辅助方法 ====================

  /// 生成录音文件路径
  Future<String> _generateFilePath({
    String? customFileName,
    Codec codec = Codec.aacADTS,
  }) async {
    final directory = await _getRecordingsDirectory();

    final timestamp = DateTime.now();
    final fileName = customFileName ??
        'call_${timestamp.year}${timestamp.month.toString().padLeft(2, '0')}${timestamp.day.toString().padLeft(2, '0')}_'
            '${timestamp.hour.toString().padLeft(2, '0')}${timestamp.minute.toString().padLeft(2, '0')}${timestamp.second.toString().padLeft(2, '0')}';

    final extension = _getExtensionFromCodec(codec);
    return '${directory.path}/$fileName.$extension';
  }

  /// 获取录音目录
  Future<Directory> _getRecordingsDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Android: 使用应用私有目录
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // iOS: 使用文档目录
      directory = await getApplicationDocumentsDirectory();
    } else {
      // 其他平台
      directory = await getApplicationDocumentsDirectory();
    }

    final recordingsDir = Directory('${directory.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    return recordingsDir;
  }

  /// 启动时长计时器
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationController.add(currentDuration);

      // 检查最大录音时长
      if (currentDuration.inMinutes >= WebRTCConfig.maxRecordingDurationMinutes) {
        stopRecording();
      }
    });
  }

  /// 停止时长计时器
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 标准化分贝值到0-1范围
  double _normalizeDecibels(double decibels) {
    // 将分贝值映射到0-1范围
    // 假设范围是 -60dB 到 0dB
    const minDb = -60.0;
    const maxDb = 0.0;

    if (decibels <= minDb) return 0.0;
    if (decibels >= maxDb) return 1.0;

    return (decibels - minDb) / (maxDb - minDb);
  }

  /// 从Codec获取文件扩展名
  String _getExtensionFromCodec(Codec codec) {
    switch (codec) {
      case Codec.aacADTS:
      case Codec.aacMP4:
        return 'aac';
      case Codec.opusOGG:
      case Codec.opusWebM:
        return 'opus';
      case Codec.vorbisOGG:
        return 'ogg';
      case Codec.pcm16:
      case Codec.pcm16WAV:
        return 'wav';
      case Codec.flac:
        return 'flac';
      case Codec.mp3:
        return 'mp3';
      default:
        return 'aac';
    }
  }

  /// 从Codec获取格式名称
  String _getFormatFromCodec(Codec codec) {
    switch (codec) {
      case Codec.aacADTS:
      case Codec.aacMP4:
        return 'AAC';
      case Codec.opusOGG:
      case Codec.opusWebM:
        return 'Opus';
      case Codec.vorbisOGG:
        return 'Vorbis';
      case Codec.pcm16:
      case Codec.pcm16WAV:
        return 'WAV';
      case Codec.flac:
        return 'FLAC';
      case Codec.mp3:
        return 'MP3';
      default:
        return 'AAC';
    }
  }

  /// 从文件路径获取格式
  String _getFormatFromFilePath(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'aac':
        return 'AAC';
      case 'opus':
        return 'Opus';
      case 'ogg':
        return 'Vorbis';
      case 'wav':
        return 'WAV';
      case 'flac':
        return 'FLAC';
      case 'mp3':
        return 'MP3';
      default:
        return extension.toUpperCase();
    }
  }

  /// 发送错误
  void _emitError(String error) {
    print('[Recording] 错误: $error');
    _errorController.add(error);
  }

  /// 释放资源
  Future<void> dispose() async {
    // 停止录音
    if (_state == RecordingState.recording || _state == RecordingState.paused) {
      await stopRecording();
    }

    // 取消订阅
    await _recordingDataSubscription?.cancel();

    // 停止计时器
    _stopDurationTimer();

    // 关闭录音器
    await _recorder?.closeRecorder();
    _recorder = null;

    // 关闭流控制器
    _stateController.close();
    _durationController.close();
    _levelController.close();
    _errorController.close();

    _isInitialized = false;
  }
}
