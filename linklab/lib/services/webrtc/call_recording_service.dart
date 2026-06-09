import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/logger.dart';
import 'webrtc_config.dart';

/// 錄音狀態
enum RecordingState {
  idle,       // 空閒
  recording,  // 錄音中
  paused,     // 暫停
  stopped,    // 已停止
  error,      // 錯誤
}

/// 錄音信息
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

  /// 獲取格式化的時長
  String get formattedDuration {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// 獲取格式化的文件大小
  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// 通話錄音服務
/// 支持錄製本地音頻流並保存到文件
class CallRecordingService {
  static final CallRecordingService _instance = CallRecordingService._internal();
  factory CallRecordingService() => _instance;
  CallRecordingService._internal();

  // ==================== 錄音組件 ====================

  /// FlutterSound錄音器
  FlutterSoundRecorder? _recorder;

  /// 錄音會話
  StreamSubscription? _recordingDataSubscription;

  // ==================== 狀態流控制器 ====================

  /// 錄音狀態流
  final _stateController = StreamController<RecordingState>.broadcast();

  /// 錄音時長流
  final _durationController = StreamController<Duration>.broadcast();

  /// 錄音電平流（用於顯示音量指示）
  final _levelController = StreamController<double>.broadcast();

  /// 錯誤流
  final _errorController = StreamController<String>.broadcast();

  // ==================== 狀態 ====================

  /// 當前錄音狀態
  RecordingState _state = RecordingState.idle;

  /// 錄音開始時間
  DateTime? _startTime;

  /// 錄音暫停時間
  DateTime? _pauseTime;

  /// 累計錄音時長
  Duration _recordedDuration = Duration.zero;

  /// 當前錄音文件路徑
  String? _currentFilePath;

  /// 計時器
  Timer? _durationTimer;

  /// 是否已初始化
  bool _isInitialized = false;

  // ==================== Getters ====================

  /// 錄音狀態流
  Stream<RecordingState> get stateStream => _stateController.stream;

  /// 錄音時長流
  Stream<Duration> get durationStream => _durationController.stream;

  /// 錄音電平流
  Stream<double> get levelStream => _levelController.stream;

  /// 錯誤流
  Stream<String> get errorStream => _errorController.stream;

  /// 當前錄音狀態
  RecordingState get state => _state;

  /// 是否正在錄音
  bool get isRecording => _state == RecordingState.recording;

  /// 是否已暫停
  bool get isPaused => _state == RecordingState.paused;

  /// 當前錄音文件路徑
  String? get currentFilePath => _currentFilePath;

  /// 當前錄音時長
  Duration get currentDuration {
    if (_state == RecordingState.recording && _startTime != null) {
      return _recordedDuration + DateTime.now().difference(_startTime!);
    }
    return _recordedDuration;
  }

  // ==================== 初始化方法 ====================

  /// 初始化錄音服務
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _recorder = FlutterSoundRecorder();

      // 打開錄音器
      await _recorder!.openRecorder();

      // 設置訂閱（用於獲取錄音電平）
      await _recorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100),
      );

      _isInitialized = true;
      AppLogger.info('[Recording] 錄音服務已初始化');
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 初始化錄音服務失敗', error, stackTrace);
      _emitError('初始化錄音服務失敗: $error');
      throw Exception('初始化錄音服務失敗: $error');
    }
  }

  /// 檢查並請求權限
  Future<bool> checkPermissions() async {
    try {
      // 檢查麥克風權限
      var microphoneStatus = await Permission.microphone.status;
      if (!microphoneStatus.isGranted) {
        microphoneStatus = await Permission.microphone.request();
      }

      // 檢查存儲權限（Android）
      if (Platform.isAndroid) {
        var storageStatus = await Permission.storage.status;
        if (!storageStatus.isGranted) {
          storageStatus = await Permission.storage.request();
        }

        // Android 13+ 需要更細粒度的權限
        if (await Permission.audio.isRestricted == false) {
          var audioStatus = await Permission.audio.status;
          if (!audioStatus.isGranted) {
            await Permission.audio.request();
          }
        }
      }

      return microphoneStatus.isGranted;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 權限檢查失敗', error, stackTrace);
      _emitError('權限檢查失敗: $error');
      return false;
    }
  }

  // ==================== 錄音控制方法 ====================

  /// 開始錄音
  ///
  /// [customFileName] - 自定義文件名（可選）
  /// [codec] - 音頻編碼格式
  Future<RecordingInfo?> startRecording({
    String? customFileName,
    Codec codec = Codec.aacADTS,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_state == RecordingState.recording) {
      throw Exception('正在錄音中，請先停止當前錄音');
    }

    // 檢查權限
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      throw Exception('需要麥克風權限才能錄音');
    }

    try {
      // 生成文件路徑
      final filePath = await _generateFilePath(
        customFileName: customFileName,
        codec: codec,
      );
      _currentFilePath = filePath;

      // 開始錄音
      await _recorder!.startRecorder(
        toFile: filePath,
        codec: codec,
        sampleRate: WebRTCConfig.recordingSampleRate,
        bitRate: WebRTCConfig.recordingBitrate,
        numChannels: 1, // 單聲道
      );

      // 監聽錄音數據（獲取音量電平）
      _recordingDataSubscription = _recorder!.onProgress!.listen((event) {
        // 發送音量電平（0.0 - 1.0）
        final decibels = event.decibels ?? 0;
        final normalizedLevel = _normalizeDecibels(decibels);
        _levelController.add(normalizedLevel);
      });

      // 更新狀態
      _state = RecordingState.recording;
      _startTime = DateTime.now();
      _stateController.add(_state);

      // 啓動計時器
      _startDurationTimer();

      AppLogger.info('[Recording] 開始錄音: $filePath');

      return RecordingInfo(
        filePath: filePath,
        startTime: _startTime!,
        duration: Duration.zero,
        fileSize: 0,
        format: _getFormatFromCodec(codec),
      );
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 開始錄音失敗', error, stackTrace);
      _state = RecordingState.error;
      _stateController.add(_state);
      _emitError('開始錄音失敗: $error');
      return null;
    }
  }

  /// 暫停錄音
  Future<void> pauseRecording() async {
    if (_state != RecordingState.recording) return;

    try {
      await _recorder!.pauseRecorder();

      // 計算已錄音時長
      if (_startTime != null) {
        _recordedDuration += DateTime.now().difference(_startTime!);
      }

      _pauseTime = DateTime.now();
      _state = RecordingState.paused;
      _stateController.add(_state);

      // 停止計時器
      _stopDurationTimer();

      AppLogger.info('[Recording] 錄音已暫停');
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 暫停錄音失敗', error, stackTrace);
      _emitError('暫停錄音失敗: $error');
    }
  }

  /// 恢復錄音
  Future<void> resumeRecording() async {
    if (_state != RecordingState.paused) return;

    try {
      await _recorder!.resumeRecorder();

      _startTime = DateTime.now();
      _pauseTime = null;
      _state = RecordingState.recording;
      _stateController.add(_state);

      // 啓動計時器
      _startDurationTimer();

      AppLogger.info('[Recording] 錄音已恢復');
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 恢復錄音失敗', error, stackTrace);
      _emitError('恢復錄音失敗: $error');
    }
  }

  /// 停止錄音
  Future<RecordingInfo?> stopRecording() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return null;
    }

    try {
      // 停止錄音
      final filePath = await _recorder!.stopRecorder();

      // 計算最終時長
      if (_state == RecordingState.recording && _startTime != null) {
        _recordedDuration += DateTime.now().difference(_startTime!);
      }

      // 取消訂閱
      await _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;

      // 停止計時器
      _stopDurationTimer();

      // 獲取文件信息
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

      // 重置狀態
      _state = RecordingState.stopped;
      _stateController.add(_state);

      AppLogger.info(
        '[Recording] 錄音已停止: ${info.formattedDuration}, ${info.formattedFileSize}',
      );

      return info;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 停止錄音失敗', error, stackTrace);
      _state = RecordingState.error;
      _stateController.add(_state);
      _emitError('停止錄音失敗: $error');
      return null;
    }
  }

  /// 取消錄音（不保存文件）
  Future<void> cancelRecording() async {
    if (_state != RecordingState.recording && _state != RecordingState.paused) {
      return;
    }

    try {
      // 停止錄音
      await _recorder!.stopRecorder();

      // 取消訂閱
      await _recordingDataSubscription?.cancel();
      _recordingDataSubscription = null;

      // 停止計時器
      _stopDurationTimer();

      // 刪除臨時文件
      if (_currentFilePath != null) {
        final file = File(_currentFilePath!);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // 重置狀態
      _state = RecordingState.idle;
      _recordedDuration = Duration.zero;
      _startTime = null;
      _pauseTime = null;
      _currentFilePath = null;
      _stateController.add(_state);

      AppLogger.info('[Recording] 錄音已取消');
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 取消錄音失敗', error, stackTrace);
      _emitError('取消錄音失敗: $error');
    }
  }

  // ==================== 文件管理方法 ====================

  /// 獲取錄音文件列表
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
            duration: Duration.zero, // 無法從文件獲取
            fileSize: stat.size,
            format: _getFormatFromFilePath(file.path),
          ));
        }
      }

      // 按時間排序（最新的在前）
      recordings.sort((a, b) => b.startTime.compareTo(a.startTime));

      return recordings;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 獲取錄音列表失敗', error, stackTrace);
      _emitError('獲取錄音列表失敗: $error');
      return [];
    }
  }

  /// 刪除錄音文件
  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('[Recording] 錄音已刪除: $filePath');
        return true;
      }
      return false;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 刪除錄音失敗', error, stackTrace);
      _emitError('刪除錄音失敗: $error');
      return false;
    }
  }

  /// 重命名錄音文件
  Future<String?> renameRecording(String oldPath, String newName) async {
    try {
      final oldFile = File(oldPath);
      if (!await oldFile.exists()) return null;

      final directory = oldFile.parent;
      final extension = oldFile.path.split('.').last;
      final newPath = '${directory.path}/$newName.$extension';

      final newFile = await oldFile.rename(newPath);
      return newFile.path;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 重命名錄音失敗', error, stackTrace);
      _emitError('重命名錄音失敗: $error');
      return null;
    }
  }

  /// 獲取錄音文件
  Future<File?> getRecordingFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 獲取錄音文件失敗', error, stackTrace);
      _emitError('獲取錄音文件失敗: $error');
      return null;
    }
  }

  /// 導出錄音文件到指定路徑
  Future<bool> exportRecording(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) return false;

      await sourceFile.copy(destinationPath);
      AppLogger.info('[Recording] 錄音已導出: $destinationPath');
      return true;
    } catch (error, stackTrace) {
      AppLogger.error('[Recording] 導出錄音失敗', error, stackTrace);
      _emitError('導出錄音失敗: $error');
      return false;
    }
  }

  // ==================== 內部輔助方法 ====================

  /// 生成錄音文件路徑
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

  /// 獲取錄音目錄
  Future<Directory> _getRecordingsDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      // Android: 使用應用私有目錄
      directory = await getApplicationDocumentsDirectory();
    } else if (Platform.isIOS) {
      // iOS: 使用文檔目錄
      directory = await getApplicationDocumentsDirectory();
    } else {
      // 其他平臺
      directory = await getApplicationDocumentsDirectory();
    }

    final recordingsDir = Directory('${directory.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    return recordingsDir;
  }

  /// 啓動時長計時器
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationController.add(currentDuration);

      // 檢查最大錄音時長
      if (currentDuration.inMinutes >= WebRTCConfig.maxRecordingDurationMinutes) {
        stopRecording();
      }
    });
  }

  /// 停止時長計時器
  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  /// 標準化分貝值到0-1範圍
  double _normalizeDecibels(double decibels) {
    // 將分貝值映射到0-1範圍
    // 假設範圍是 -60dB 到 0dB
    const minDb = -60.0;
    const maxDb = 0.0;

    if (decibels <= minDb) return 0.0;
    if (decibels >= maxDb) return 1.0;

    return (decibels - minDb) / (maxDb - minDb);
  }

  /// 從Codec獲取文件擴展名
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

  /// 從Codec獲取格式名稱
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

  /// 從文件路徑獲取格式
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

  /// 發送錯誤
  void _emitError(String error) {
    AppLogger.error('[Recording] $error');
    _errorController.add(error);
  }

  /// 釋放資源
  Future<void> dispose() async {
    // 停止錄音
    if (_state == RecordingState.recording || _state == RecordingState.paused) {
      await stopRecording();
    }

    // 取消訂閱
    await _recordingDataSubscription?.cancel();

    // 停止計時器
    _stopDurationTimer();

    // 關閉錄音器
    await _recorder?.closeRecorder();
    _recorder = null;

    // 關閉流控制器
    _stateController.close();
    _durationController.close();
    _levelController.close();
    _errorController.close();

    _isInitialized = false;
  }
}
