/// SosFacade 统一输出模型
///
/// AGENTS.md §6.1：SOS 流程标准化结果。
class SOSResultModel {
  final bool success;
  final String? error;
  final String status; // idle | undo_window | broadcasting | notifying | active | cancelled | completed
  final int responderCount;
  final int notifiedContactCount;
  final DateTime? triggeredAt;
  final DateTime? undoDeadline;

  const SOSResultModel({
    required this.success,
    this.error,
    required this.status,
    this.responderCount = 0,
    this.notifiedContactCount = 0,
    this.triggeredAt,
    this.undoDeadline,
  });

  factory SOSResultModel.idle() {
    return const SOSResultModel(
      success: true,
      status: 'idle',
    );
  }

  factory SOSResultModel.undoWindow({required DateTime deadline}) {
    return SOSResultModel(
      success: true,
      status: 'undo_window',
      triggeredAt: DateTime.now(),
      undoDeadline: deadline,
    );
  }

  factory SOSResultModel.broadcasting({int responderCount = 0}) {
    return SOSResultModel(
      success: true,
      status: 'broadcasting',
      triggeredAt: DateTime.now(),
      responderCount: responderCount,
    );
  }

  factory SOSResultModel.active({
    required int responderCount,
    required int notifiedContactCount,
  }) {
    return SOSResultModel(
      success: true,
      status: 'active',
      triggeredAt: DateTime.now(),
      responderCount: responderCount,
      notifiedContactCount: notifiedContactCount,
    );
  }

  factory SOSResultModel.cancelled() {
    return const SOSResultModel(
      success: true,
      status: 'cancelled',
    );
  }

  factory SOSResultModel.completed() {
    return const SOSResultModel(
      success: true,
      status: 'completed',
    );
  }

  factory SOSResultModel.error(String errorMessage) {
    return SOSResultModel(
      success: false,
      status: 'error',
      error: errorMessage,
    );
  }

  bool get isActive => status == 'active' || status == 'broadcasting';
  bool get isInUndoWindow => status == 'undo_window';
}
