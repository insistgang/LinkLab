// WebRTC 配置文件
// 包含ICE服务器配置和WebRTC参数设置

/// WebRTC配置类
class WebRTCConfig {
  /// 私有构造函数，防止实例化
  WebRTCConfig._();

  // ==================== ICE服务器配置 ====================

  /// STUN服务器列表 - 用于获取公网IP地址
  static const List<Map<String, dynamic>> stunServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {'urls': 'stun:stun3.l.google.com:19302'},
    {'urls': 'stun:stun4.l.google.com:19302'},
  ];

  /// TURN服务器配置 - 用于对称NAT穿透
  /// 注意：生产环境需要配置自己的TURN服务器
  static const List<Map<String, dynamic>> turnServers = [
    // 示例配置（需要替换为真实的TURN服务器）
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

  /// 完整的ICE服务器配置
  static Map<String, dynamic> get iceServers => {
    'iceServers': [
      ...stunServers,
      ...turnServers,
    ],
    // ICE传输策略
    'iceTransportPolicy': 'all', // 'all' 或 'relay'（仅使用TURN）
    // ICE候选池大小
    'iceCandidatePoolSize': 10,
  };

  // ==================== 媒体约束配置 ====================

  /// 音频约束配置
  static Map<String, dynamic> get audioConstraints => {
    'audio': {
      'echoCancellation': true,      // 回声消除
      'noiseSuppression': true,      // 噪声抑制
      'autoGainControl': true,       // 自动增益控制
      'sampleRate': 48000,           // 采样率
      'channelCount': 2,             // 声道数（立体声）
    },
    'video': false, // 仅语音通话
  };

  /// 低带宽音频约束（网络较差时使用）
  static Map<String, dynamic> get lowBandwidthAudioConstraints => {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'sampleRate': 16000,           // 降低采样率
      'channelCount': 1,             // 单声道
      'bitrate': 16000,              // 降低比特率
    },
    'video': false,
  };

  // ==================== PeerConnection约束配置 ====================

  /// SDP约束配置
  static Map<String, dynamic> get sdpConstraints => {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [
      {'DtlsSrtpKeyAgreement': true},  // DTLS-SRTP密钥协商
    ],
  };

  /// RTC配置
  static Map<String, dynamic> get rtcConfiguration => {
    ...iceServers,
    'sdpSemantics': 'unified-plan',  // 使用Unified Plan SDP语义
    'bundlePolicy': 'max-bundle',    // BUNDLE策略
    'rtcpMuxPolicy': 'require',      // RTCP复用策略
  };

  // ==================== 编解码器偏好配置 ====================

  /// 首选音频编解码器优先级
  static const List<String> preferredAudioCodecs = [
    'opus',      // Opus（首选，高音质，低延迟）
    'ISAC',      // iSAC（WebRTC默认）
    'G722',      // G.722（宽带音频）
    'PCMU',      // G.711 mu-law
    'PCMA',      // G.711 A-law
  ];

  // ==================== 连接超时配置 ====================

  /// ICE收集超时时间（毫秒）
  static const int iceGatheringTimeout = 10000;

  /// 连接超时时间（毫秒）
  static const int connectionTimeout = 30000;

  /// 重连尝试次数
  static const int maxReconnectAttempts = 3;

  /// 重连间隔（毫秒）
  static const int reconnectInterval = 3000;

  // ==================== 音频处理配置 ====================

  /// 启用语音活动检测(VAD)
  static const bool enableVAD = true;

  /// 舒适噪声生成
  static const bool enableCNG = true;

  /// 抖动缓冲区最小延迟（毫秒）
  static const int jitterBufferMinDelay = 50;

  /// 抖动缓冲区最大延迟（毫秒）
  static const int jitterBufferMaxDelay = 500;

  // ==================== 录音配置 ====================

  /// 录音采样率
  static const int recordingSampleRate = 44100;

  /// 录音比特率
  static const int recordingBitrate = 128000;

  /// 录音格式
  static const String recordingFormat = 'aac'; // 'aac', 'wav', 'mp4'

  /// 最大录音时长（分钟）
  static const int maxRecordingDurationMinutes = 60;
}

/// 网络质量等级
enum NetworkQuality {
  excellent,  // 优秀 (< 100ms)
  good,       // 良好 (100-200ms)
  fair,       // 一般 (200-400ms)
  poor,       // 较差 (400-800ms)
  bad,        // 很差 (> 800ms)
  unknown,    // 未知
}

/// 网络质量评估工具类
class NetworkQualityEvaluator {
  /// 根据RTT评估网络质量
  static NetworkQuality evaluateByRTT(int? rtt) {
    if (rtt == null) return NetworkQuality.unknown;
    if (rtt < 100) return NetworkQuality.excellent;
    if (rtt < 200) return NetworkQuality.good;
    if (rtt < 400) return NetworkQuality.fair;
    if (rtt < 800) return NetworkQuality.poor;
    return NetworkQuality.bad;
  }

  /// 根据丢包率评估网络质量
  static NetworkQuality evaluateByPacketLoss(double? packetLoss) {
    if (packetLoss == null) return NetworkQuality.unknown;
    if (packetLoss < 0.01) return NetworkQuality.excellent;
    if (packetLoss < 0.03) return NetworkQuality.good;
    if (packetLoss < 0.08) return NetworkQuality.fair;
    if (packetLoss < 0.15) return NetworkQuality.poor;
    return NetworkQuality.bad;
  }

  /// 获取网络质量描述
  static String getQualityDescription(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return '网络优秀';
      case NetworkQuality.good:
        return '网络良好';
      case NetworkQuality.fair:
        return '网络一般';
      case NetworkQuality.poor:
        return '网络较差';
      case NetworkQuality.bad:
        return '网络很差';
      case NetworkQuality.unknown:
        return '网络状态未知';
    }
  }

  /// 获取网络质量颜色（用于UI显示）
  static String getQualityColor(NetworkQuality quality) {
    switch (quality) {
      case NetworkQuality.excellent:
        return '#4CAF50'; // 绿色
      case NetworkQuality.good:
        return '#8BC34A'; // 浅绿
      case NetworkQuality.fair:
        return '#FFC107'; // 黄色
      case NetworkQuality.poor:
        return '#FF9800'; // 橙色
      case NetworkQuality.bad:
        return '#F44336'; // 红色
      case NetworkQuality.unknown:
        return '#9E9E9E'; // 灰色
    }
  }
}

/// WebRTC事件类型
enum WebRTCEventType {
  // 连接事件
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

  // 媒体事件
  localStreamAdded,
  remoteStreamAdded,
  trackAdded,
  trackRemoved,

  // 错误事件
  error,
  permissionDenied,
  deviceNotFound,

  // 录音事件
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
