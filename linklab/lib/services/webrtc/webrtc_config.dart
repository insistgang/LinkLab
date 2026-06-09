// WebRTC 配置文件
// 包含ICE服務器配置和WebRTC參數設置

/// WebRTC配置類
class WebRTCConfig {
  /// 私有構造函數，防止實例化
  WebRTCConfig._();

  // ==================== ICE服務器配置 ====================

  /// STUN服務器列表 - 用於獲取公網IP地址
  static const List<Map<String, dynamic>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  /// TURN服務器配置 - 用於對稱NAT穿透
  /// 注意：生產環境需要配置自己的TURN服務器
  static const List<Map<String, dynamic>> turnServers = [
    // 示例配置（需要替換爲真實的TURN服務器）
    // {
    //   'urls': 'turn:your-turn-server.com:3478',
    //   'username': 'your-username',
    //   'credential': 'your-password',
    // },
    // {
    //   // TURN over TLS（更安全）
    //   'urls': 'turns:your-turn-server.com:5349',
    //   'username': 'your-username',
    //   'credential': 'your-password',
    // },
  ];

  /// 完整的ICE服務器配置
  static Map<String, dynamic> get iceServers => {
    'iceServers': [
      ...stunServers,
      ...turnServers,
    ],
    // ICE傳輸策略
    'iceTransportPolicy': 'all', // 'all' 或 'relay'（僅使用TURN）
    // ICE候選池大小
    'iceCandidatePoolSize': 10,
  };

  // ==================== 媒體約束配置 ====================

  /// 音頻約束配置
  static Map<String, dynamic> get audioConstraints => {
    'audio': {
      'echoCancellation': true,      // 回聲消除
      'noiseSuppression': true,      // 噪聲抑制
      'autoGainControl': true,       // 自動增益控制
      'sampleRate': 48000,           // 採樣率
      'channelCount': 2,             // 聲道數（立體聲）
    },
    'video': false, // 僅語音通話
  };

  /// 低帶寬音頻約束（網絡較差時使用）
  static Map<String, dynamic> get lowBandwidthAudioConstraints => {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'sampleRate': 16000,           // 降低採樣率
      'channelCount': 1,             // 單聲道
      'bitrate': 16000,              // 降低比特率
    },
    'video': false,
  };

  // ==================== PeerConnection約束配置 ====================

  /// SDP約束配置
  static Map<String, dynamic> get sdpConstraints => {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [
      {'DtlsSrtpKeyAgreement': true},  // DTLS-SRTP密鑰協商
    ],
  };

  /// RTC配置
  static Map<String, dynamic> get rtcConfiguration => {
    ...iceServers,
    'sdpSemantics': 'unified-plan',  // 使用Unified Plan SDP語義
    'bundlePolicy': 'max-bundle',    // BUNDLE策略
    'rtcpMuxPolicy': 'require',      // RTCP複用策略
  };

  // ==================== 編解碼器偏好配置 ====================

  /// 首選音頻編解碼器優先級
  static const List<String> preferredAudioCodecs = [
    'opus',      // Opus（首選，高音質，低延遲）
    'ISAC',      // iSAC（WebRTC默認）
    'G722',      // G.722（寬帶音頻）
    'PCMU',      // G.711 mu-law
    'PCMA',      // G.711 A-law
  ];

  // ==================== 連接超時配置 ====================

  /// ICE收集超時時間（毫秒）
  static const int iceGatheringTimeout = 10000;

  /// 連接超時時間（毫秒）
  static const int connectionTimeout = 30000;

  /// 重連嘗試次數
  static const int maxReconnectAttempts = 3;

  /// 重連間隔（毫秒）
  static const int reconnectInterval = 3000;

  // ==================== 音頻處理配置 ====================

  /// 啓用語音活動檢測(VAD)
  static const bool enableVAD = true;

  /// 舒適噪聲生成
  static const bool enableCNG = true;

  /// 抖動緩衝區最小延遲（毫秒）
  static const int jitterBufferMinDelay = 50;

  /// 抖動緩衝區最大延遲（毫秒）
  static const int jitterBufferMaxDelay = 500;

  // ==================== 錄音配置 ====================

  /// 錄音採樣率
  static const int recordingSampleRate = 44100;

  /// 錄音比特率
  static const int recordingBitrate = 128000;

  /// 錄音格式
  static const String recordingFormat = 'aac'; // 'aac', 'wav', 'mp4'

  /// 最大錄音時長（分鐘）
  static const int maxRecordingDurationMinutes = 60;
}

/// 網絡質量等級
enum NetworkQuality {
  excellent,  // 優秀 (< 100ms)
  good,       // 良好 (100-200ms)
  fair,       // 一般 (200-400ms)
  poor,       // 較差 (400-800ms)
  bad,        // 很差 (> 800ms)
  unknown,    // 未知
}

/// 網絡質量評估工具類
class NetworkQualityEvaluator {
  /// 根據RTT評估網絡質量
  static NetworkQuality evaluateByRTT(int? rtt) {
    if (rtt == null) return NetworkQuality.unknown;
    if (rtt < 100) return NetworkQuality.excellent;
    if (rtt < 200) return NetworkQuality.good;
    if (rtt < 400) return NetworkQuality.fair;
    if (rtt < 800) return NetworkQuality.poor;
    return NetworkQuality.bad;
  }

  /// 根據丟包率評估網絡質量
  static NetworkQuality evaluateByPacketLoss(double? packetLoss) {
    if (packetLoss == null) return NetworkQuality.unknown;
    if (packetLoss < 0.01) return NetworkQuality.excellent;
    if (packetLoss < 0.03) return NetworkQuality.good;
    if (packetLoss < 0.08) return NetworkQuality.fair;
    if (packetLoss < 0.15) return NetworkQuality.poor;
    return NetworkQuality.bad;
  }

  /// 獲取網絡質量描述
  static String getQualityDescription(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return '網絡優秀';
      case NetworkQuality.good:
        return '網絡良好';
      case NetworkQuality.fair:
        return '網絡一般';
      case NetworkQuality.poor:
        return '網絡較差';
      case NetworkQuality.bad:
        return '網絡很差';
      case NetworkQuality.unknown:
        return '網絡狀態未知';
    }
  }

  /// 獲取網絡質量顏色（用於UI顯示）
  static String getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return '#4CAF50'; // 綠色
      case NetworkQuality.good:
        return '#8BC34A'; // 淺綠
      case NetworkQuality.fair:
        return '#FFC107'; // 黃色
      case NetworkQuality.poor:
        return '#FF9800'; // 橙色
      case NetworkQuality.bad:
        return '#F44336'; // 紅色
      case NetworkQuality.unknown:
        return '#9E9E9E'; // 灰色
    }
  }
}

/// WebRTC事件類型
enum WebRTCEventType {
  // 連接事件
  connecting,
  connected,
  disconnected,
  failed,
  closed,

  // 信令事件
  offerCreated,
  answerCreated,
  iceCandidateGenerated,
  iceGatheringComplete,

  // 媒體事件
  localStreamAdded,
  remoteStreamAdded,
  trackAdded,
  trackRemoved,

  // 錯誤事件
  error,
  permissionDenied,
  deviceNotFound,

  // 錄音事件
  recordingStarted,
  recordingStopped,
  recordingError,
}

/// WebRTC事件
class WebRTCEvent {
  final WebRTCEventType type;
  final dynamic data;
  final DateTime timestamp;
  final String? error;

  WebRTCEvent({
    required this.type,
    this.data,
    this.error,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
