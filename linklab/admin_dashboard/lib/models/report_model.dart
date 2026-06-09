import '../constants/app_constants.dart';

// 舉報模型
class ReportModel {
  final String id;
  final ReportType type;
  final String reason;
  final String? description;
  final String reporterId;
  final String reporterName;
  final String targetId; // 被舉報內容/用戶ID
  final String targetType; // 'user', 'story', 'comment', 'community'
  final String? targetContent;
  final String? targetUserId;
  final String? targetUserName;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedBy;
  final String? processorName;
  final String? result;
  final String? action;

  ReportModel({
    required this.id,
    required this.type,
    required this.reason,
    this.description,
    required this.reporterId,
    required this.reporterName,
    required this.targetId,
    required this.targetType,
    this.targetContent,
    this.targetUserId,
    this.targetUserName,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.processedAt,
    this.processedBy,
    this.processorName,
    this.result,
    this.action,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.other,
      ),
      reason: json['reason'] ?? '',
      description: json['description'],
      reporterId: json['reporter_id'] ?? '',
      reporterName: json['reporter_name'] ?? '',
      targetId: json['target_id'] ?? '',
      targetType: json['target_type'] ?? '',
      targetContent: json['target_content'],
      targetUserId: json['target_user_id'],
      targetUserName: json['target_user_name'],
      status: ReportStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at']),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
      processedBy: json['processed_by'],
      processorName: json['processor_name'],
      result: json['result'],
      action: json['action'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'reason': reason,
      'description': description,
      'reporter_id': reporterId,
      'reporter_name': reporterName,
      'target_id': targetId,
      'target_type': targetType,
      'target_content': targetContent,
      'target_user_id': targetUserId,
      'target_user_name': targetUserName,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'processed_by': processedBy,
      'processor_name': processorName,
      'result': result,
      'action': action,
    };
  }

  String get typeText {
    switch (type) {
      case ReportType.spam:
        return '垃圾信息';
      case ReportType.harassment:
        return '騷擾行爲';
      case ReportType.inappropriate:
        return '不當內容';
      case ReportType.fraud:
        return '欺詐行爲';
      case ReportType.other:
        return '其他';
    }
  }

  String get statusText {
    switch (status) {
      case ReportStatus.pending:
        return '待處理';
      case ReportStatus.processing:
        return '處理中';
      case ReportStatus.resolved:
        return '已解決';
      case ReportStatus.dismissed:
        return '已駁回';
    }
  }

  String get targetTypeText {
    switch (targetType) {
      case 'user':
        return '用戶';
      case 'story':
        return '故事';
      case 'comment':
        return '評論';
      case 'community':
        return '社羣內容';
      default:
        return '未知';
    }
  }
}

// 舉報統計
class ReportStatistics {
  final int totalReports;
  final int pendingReports;
  final int processingReports;
  final int resolvedReports;
  final int dismissedReports;
  final double avgProcessTime; // 平均處理時間（小時）
  final List<ReportTypeCount> typeDistribution;

  ReportStatistics({
    required this.totalReports,
    required this.pendingReports,
    required this.processingReports,
    required this.resolvedReports,
    required this.dismissedReports,
    required this.avgProcessTime,
    required this.typeDistribution,
  });

  factory ReportStatistics.fromJson(Map<String, dynamic> json) {
    return ReportStatistics(
      totalReports: json['total_reports'] ?? 0,
      pendingReports: json['pending_reports'] ?? 0,
      processingReports: json['processing_reports'] ?? 0,
      resolvedReports: json['resolved_reports'] ?? 0,
      dismissedReports: json['dismissed_reports'] ?? 0,
      avgProcessTime: (json['avg_process_time'] ?? 0).toDouble(),
      typeDistribution: (json['type_distribution'] as List?)
          ?.map((e) => ReportTypeCount.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ReportTypeCount {
  final ReportType type;
  final int count;

  ReportTypeCount({
    required this.type,
    required this.count,
  });

  factory ReportTypeCount.fromJson(Map<String, dynamic> json) {
    return ReportTypeCount(
      type: ReportType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReportType.other,
      ),
      count: json['count'] ?? 0,
    );
  }
}
