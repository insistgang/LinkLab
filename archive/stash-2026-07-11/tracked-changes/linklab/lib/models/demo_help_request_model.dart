class DemoHelpRequestModel {
  const DemoHelpRequestModel({
    required this.id,
    required this.seekerId,
    required this.type,
    required this.title,
    required this.description,
    required this.schedulePreference,
    required this.locationMode,
    required this.accessibilityNeeded,
    required this.status,
    required this.createdAt,
    this.volunteerId,
    this.volunteerName,
    this.volunteerAvatar,
    this.assignedVolunteerAccountId,
    this.cancelReason,
  });

  final String id;
  final String seekerId;
  final String? volunteerId;
  final String? volunteerName;
  final String? volunteerAvatar;
  final String type;
  final String title;
  final String description;
  final String schedulePreference;
  final String locationMode;
  final bool accessibilityNeeded;
  final String status;
  final DateTime createdAt;
  final String? assignedVolunteerAccountId;
  final String? cancelReason;

  factory DemoHelpRequestModel.fromJson(Map<String, dynamic> json) {
    return DemoHelpRequestModel(
      id: '${json['id'] ?? ''}',
      seekerId: '${json['seekerId'] ?? ''}',
      volunteerId: json['volunteerId']?.toString(),
      volunteerName: json['volunteerName']?.toString(),
      volunteerAvatar: json['volunteerAvatar']?.toString(),
      type: '${json['type'] ?? ''}',
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
      schedulePreference: '${json['schedulePreference'] ?? ''}',
      locationMode: '${json['locationMode'] ?? ''}',
      accessibilityNeeded: json['accessibilityNeeded'] == true,
      status: '${json['status'] ?? DemoHelpRequestStatus.waitingMatch}',
      createdAt:
          DateTime.tryParse('${json['createdAt'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      assignedVolunteerAccountId: json['assignedVolunteerAccountId']
          ?.toString(),
      cancelReason: json['cancelReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seekerId': seekerId,
      'volunteerId': volunteerId,
      'volunteerName': volunteerName,
      'volunteerAvatar': volunteerAvatar,
      'type': type,
      'title': title,
      'description': description,
      'schedulePreference': schedulePreference,
      'locationMode': locationMode,
      'accessibilityNeeded': accessibilityNeeded,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'assignedVolunteerAccountId': assignedVolunteerAccountId,
      'cancelReason': cancelReason,
    };
  }

  DemoHelpRequestModel copyWith({
    String? id,
    String? seekerId,
    String? volunteerId,
    String? volunteerName,
    String? volunteerAvatar,
    String? type,
    String? title,
    String? description,
    String? schedulePreference,
    String? locationMode,
    bool? accessibilityNeeded,
    String? status,
    DateTime? createdAt,
    String? assignedVolunteerAccountId,
    String? cancelReason,
  }) {
    return DemoHelpRequestModel(
      id: id ?? this.id,
      seekerId: seekerId ?? this.seekerId,
      volunteerId: volunteerId ?? this.volunteerId,
      volunteerName: volunteerName ?? this.volunteerName,
      volunteerAvatar: volunteerAvatar ?? this.volunteerAvatar,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      schedulePreference: schedulePreference ?? this.schedulePreference,
      locationMode: locationMode ?? this.locationMode,
      accessibilityNeeded: accessibilityNeeded ?? this.accessibilityNeeded,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      assignedVolunteerAccountId:
          assignedVolunteerAccountId ?? this.assignedVolunteerAccountId,
      cancelReason: cancelReason ?? this.cancelReason,
    );
  }

  bool get canCancel {
    return status == DemoHelpRequestStatus.waitingMatch ||
        status == DemoHelpRequestStatus.pending ||
        status == DemoHelpRequestStatus.inProgress;
  }

  String get statusLabel {
    switch (status) {
      case DemoHelpRequestStatus.waitingMatch:
        return '待匹配';
      case DemoHelpRequestStatus.pending:
        return '待处理';
      case DemoHelpRequestStatus.inProgress:
        return '进行中';
      case DemoHelpRequestStatus.completed:
        return '已完成';
      case DemoHelpRequestStatus.cancelled:
        return '已取消';
      default:
        return status;
    }
  }

  String get locationModeLabel {
    switch (locationMode) {
      case DemoHelpLocationMode.online:
        return '线上';
      case DemoHelpLocationMode.offline:
        return '线下';
      case DemoHelpLocationMode.flexible:
        return '线上/线下皆可';
      default:
        return locationMode;
    }
  }

  String get typeLabel {
    switch (type) {
      case 'companion_chat':
        return '陪伴聊天';
      case 'reading_support':
        return '读屏识别';
      case 'travel_assist':
        return '出行协助';
      case 'medical_support':
        return '医疗陪护';
      case 'device_help':
        return '设备使用';
      case 'other':
        return '其他帮助';
      default:
        return type;
    }
  }

  String get accessibilityLabel => accessibilityNeeded ? '需要无障碍支持' : '常规支持即可';
}

class DemoHelpRequestStatus {
  static const String waitingMatch = 'waiting_match';
  static const String pending = 'pending';
  static const String inProgress = 'in_progress';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
}

class DemoHelpLocationMode {
  static const String online = 'online';
  static const String offline = 'offline';
  static const String flexible = 'flexible';
}
