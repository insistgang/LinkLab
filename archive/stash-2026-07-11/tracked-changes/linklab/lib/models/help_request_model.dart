import 'package:freezed_annotation/freezed_annotation.dart';

import 'help_request_status.dart';

part 'help_request_model.freezed.dart';
part 'help_request_model.g.dart';

/// 帮助请求模型
@freezed
class HelpRequestModel with _$HelpRequestModel {
  const factory HelpRequestModel({
    required String id,
    required String seekerId,
    String?
    type, // 'ai_auto', 'async', 'realtime_voice', 'realtime_video', 'sos'
    String? intent,
    String? urgency, // 'normal', 'important', 'urgent', 'emergency'
    String?
    status, // 'created', 'ai_processing', 'ai_resolved', 'matching', 'connected', 'completed', 'cancelled', 'expired'
    Map<String, dynamic>? aiResponse,
    String? volunteerId,
    double? latitude,
    double? longitude,
    int? durationSeconds,
    int? seekerRating,
    int? volunteerRating,
    String? cancelReason,
    DateTime? createdAt,
    DateTime? matchedAt,
    DateTime? completedAt,
  }) = _HelpRequestModel;

  factory HelpRequestModel.fromJson(Map<String, dynamic> json) =>
      _$HelpRequestModelFromJson(json);

  const HelpRequestModel._();

  /// 是否为紧急请求
  bool get isEmergency => urgency == 'emergency' || type == 'sos';

  /// 是否已完成
  bool get isCompleted => requestStatus == HelpRequestStatus.completed;

  /// 是否进行中
  bool get isActive => requestStatus.isActive;

  /// AGENTS.md 唯一允许的主状态。
  HelpRequestStatus get requestStatus => HelpRequestStatus.fromWireName(status);

  /// 紧急程度标签
  String get urgencyLabel {
    switch (urgency) {
      case 'emergency':
        return '紧急';
      case 'urgent':
        return '急迫';
      case 'important':
        return '重要';
      default:
        return '普通';
    }
  }

  /// 状态标签
  String get statusLabel {
    return requestStatus.label;
  }
}

/// 异步任务模型
@freezed
class AsyncTaskModel with _$AsyncTaskModel {
  const factory AsyncTaskModel({
    required String id,
    required String helpRequestId,
    required String seekerId,
    String? volunteerId,
    required String taskType,
    required String description,
    String? imageUrl,
    String?
    status, // 'pending', 'assigned', 'processing', 'completed', 'cancelled'
    String? result,
    DateTime? createdAt,
    DateTime? assignedAt,
    DateTime? completedAt,
  }) = _AsyncTaskModel;

  factory AsyncTaskModel.fromJson(Map<String, dynamic> json) =>
      _$AsyncTaskModelFromJson(json);

  const AsyncTaskModel._();

  /// 是否待处理
  bool get isPending => status == 'pending';

  /// 是否已领取
  bool get isAssigned => status == 'assigned' || status == 'processing';

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 状态标签
  String get statusLabel {
    switch (status) {
      case 'pending':
        return '待志愿者领取';
      case 'assigned':
        return '已被领取';
      case 'processing':
        return '处理中';
      case 'completed':
        return '已回覆';
      case 'expired':
        return '已超时';
      case 'cancelled':
        return '已取消';
      default:
        return '状态未知';
    }
  }
}
