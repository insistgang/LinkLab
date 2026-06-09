import 'package:freezed_annotation/freezed_annotation.dart';

import 'help_request_status.dart';

part 'help_request_model.freezed.dart';
part 'help_request_model.g.dart';

/// 幫助請求模型
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

  /// 是否爲緊急請求
  bool get isEmergency => urgency == 'emergency' || type == 'sos';

  /// 是否已完成
  bool get isCompleted => requestStatus == HelpRequestStatus.completed;

  /// 是否進行中
  bool get isActive => requestStatus.isActive;

  /// AGENTS.md 唯一允許的主狀態。
  HelpRequestStatus get requestStatus => HelpRequestStatus.fromWireName(status);

  /// 緊急程度標籤
  String get urgencyLabel {
    switch (urgency) {
      case 'emergency':
        return '緊急';
      case 'urgent':
        return '急迫';
      case 'important':
        return '重要';
      default:
        return '普通';
    }
  }

  /// 狀態標籤
  String get statusLabel {
    return requestStatus.label;
  }
}

/// 異步任務模型
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

  /// 是否待處理
  bool get isPending => status == 'pending';

  /// 是否已領取
  bool get isAssigned => status == 'assigned' || status == 'processing';

  /// 是否已完成
  bool get isCompleted => status == 'completed';

  /// 狀態標籤
  String get statusLabel {
    switch (status) {
      case 'pending':
        return '待志願者領取';
      case 'assigned':
        return '已被領取';
      case 'processing':
        return '處理中';
      case 'completed':
        return '已回覆';
      case 'expired':
        return '已超時';
      case 'cancelled':
        return '已取消';
      default:
        return '狀態未知';
    }
  }
}
