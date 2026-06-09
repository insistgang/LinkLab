/// CallSessionFacade 統一輸出模型
///
/// AGENTS.md §12.2：通話狀態標準化。
class CallStatusModel {
  final bool success;
  final String? error;
  final String status; // idle | connecting | ringing | connected | ended | failed | disconnected
  final String? volunteerId;
  final String? volunteerName;
  final Duration callDuration;
  final bool isMuted;
  final bool isSpeakerOn;

  const CallStatusModel({
    required this.success,
    this.error,
    required this.status,
    this.volunteerId,
    this.volunteerName,
    this.callDuration = Duration.zero,
    this.isMuted = false,
    this.isSpeakerOn = true,
  });

  factory CallStatusModel.idle() {
    return const CallStatusModel(
      success: true,
      status: 'idle',
    );
  }

  factory CallStatusModel.connecting({
    required String volunteerId,
    String? volunteerName,
  }) {
    return CallStatusModel(
      success: true,
      status: 'connecting',
      volunteerId: volunteerId,
      volunteerName: volunteerName,
    );
  }

  factory CallStatusModel.connected({
    required String volunteerId,
    String? volunteerName,
    Duration callDuration = Duration.zero,
  }) {
    return CallStatusModel(
      success: true,
      status: 'connected',
      volunteerId: volunteerId,
      volunteerName: volunteerName,
      callDuration: callDuration,
    );
  }

  factory CallStatusModel.ended({Duration callDuration = Duration.zero}) {
    return CallStatusModel(
      success: true,
      status: 'ended',
      callDuration: callDuration,
    );
  }

  factory CallStatusModel.disconnected() {
    return const CallStatusModel(
      success: false,
      status: 'disconnected',
      error: '通話已斷開',
    );
  }

  factory CallStatusModel.error(String errorMessage) {
    return CallStatusModel(
      success: false,
      status: 'failed',
      error: errorMessage,
    );
  }

  bool get isInCall => status == 'connected';
  bool get isConnecting => status == 'connecting' || status == 'ringing';
}
