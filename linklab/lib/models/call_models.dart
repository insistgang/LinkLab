// 通話相關數據模型

/// 通話狀態
enum CallState {
  idle,           // 空閒
  matching,       // 匹配中
  connecting,     // 連接中
  ringing,        // 響鈴中
  connected,      // 已連接
  reconnecting,   // 重連中
  ended,          // 已結束
  failed,         // 失敗
}

/// 通話角色
enum CallRole {
  seeker,     // 求助者
  volunteer,  // 志願者
}

/// 通話信息
class CallInfo {
  final String callId;
  final String roomId;
  final String seekerId;
  String? volunteerId;
  final CallRole myRole;
  CallState state;
  DateTime? startTime;
  DateTime? endTime;
  bool isMuted;
  bool isSpeakerOn;

  CallInfo({
    required this.callId,
    required this.roomId,
    required this.seekerId,
    this.volunteerId,
    required this.myRole,
    this.state = CallState.idle,
    this.startTime,
    this.endTime,
    this.isMuted = false,
    this.isSpeakerOn = true,
  });
}

/// 信令消息類型
enum SignalingType {
  offer,
  answer,
  iceCandidate,
  join,
  leave,
  ready,
  bye,
}

/// 信令消息
class SignalingMessage {
  final SignalingType type;
  final String roomId;
  final String fromUserId;
  final String? toUserId;
  final dynamic data;
  final DateTime timestamp;

  SignalingMessage({
    required this.type,
    required this.roomId,
    required this.fromUserId,
    this.toUserId,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'room_id': roomId,
    'from_user_id': fromUserId,
    'to_user_id': toUserId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory SignalingMessage.fromJson(Map<String, dynamic> json) => SignalingMessage(
    type: SignalingType.values.firstWhere((e) => e.name == json['type'] as String),
    roomId: json['room_id'] as String,
    fromUserId: json['from_user_id'] as String,
    toUserId: json['to_user_id'] as String?,
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}

/// 匹配結果
class MatchingResult {
  final String helpRequestId;
  final List<MatchedVolunteer> volunteers;
  final DateTime timeoutAt;

  MatchingResult({
    required this.helpRequestId,
    required this.volunteers,
    required this.timeoutAt,
  });

  factory MatchingResult.fromJson(Map<String, dynamic> json) => MatchingResult(
    helpRequestId: json['helpRequestId'] as String,
    volunteers: (json['volunteers'] as List<dynamic>)
        .map((v) => MatchedVolunteer.fromJson(v as Map<String, dynamic>))
        .toList(),
    timeoutAt: DateTime.parse(json['timeoutAt'] as String),
  );
}

/// 匹配的志願者
class MatchedVolunteer {
  final String id;
  final String userId;
  final double score;
  final double distance;
  final List<String> skills;

  MatchedVolunteer({
    required this.id,
    required this.userId,
    required this.score,
    required this.distance,
    required this.skills,
  });

  factory MatchedVolunteer.fromJson(Map<String, dynamic> json) => MatchedVolunteer(
    id: json['id'] as String,
    userId: json['userId'] as String,
    score: (json['score'] as num).toDouble(),
    distance: (json['distance'] as num).toDouble(),
    skills: List<String>.from((json['skills'] as List<dynamic>?) ?? []),
  );
}

/// 通話結束原因
enum CallEndReason {
  userHangup,       // 用戶掛斷
  remoteHangup,     // 對方掛斷
  timeout,          // 超時
  networkError,     // 網絡錯誤
  noResponse,       // 無響應
  systemError,      // 系統錯誤
}

/// 通話統計
class CallStats {
  final Duration duration;
  final int bytesReceived;
  final int bytesSent;
  final double? averageBitrate;
  final int? packetLoss;

  CallStats({
    required this.duration,
    required this.bytesReceived,
    required this.bytesSent,
    this.averageBitrate,
    this.packetLoss,
  });
}
