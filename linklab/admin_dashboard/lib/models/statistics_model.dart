// 統計數據模型
class DailyReport {
  final DateTime date;
  final int newUsers;
  final int activeUsers;
  final int totalCalls;
  final double avgCallDuration;
  final double satisfaction;
  final int helpRequests;
  final int helpResponses;
  final double responseRate;
  final int aiCalls;
  final double aiResolutionRate;

  DailyReport({
    required this.date,
    required this.newUsers,
    required this.activeUsers,
    required this.totalCalls,
    required this.avgCallDuration,
    required this.satisfaction,
    required this.helpRequests,
    required this.helpResponses,
    required this.responseRate,
    required this.aiCalls,
    required this.aiResolutionRate,
  });

  factory DailyReport.fromJson(Map<String, dynamic> json) {
    return DailyReport(
      date: DateTime.parse(json['date']),
      newUsers: json['new_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalCalls: json['total_calls'] ?? 0,
      avgCallDuration: (json['avg_call_duration'] ?? 0).toDouble(),
      satisfaction: (json['satisfaction'] ?? 0).toDouble(),
      helpRequests: json['help_requests'] ?? 0,
      helpResponses: json['help_responses'] ?? 0,
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      aiCalls: json['ai_calls'] ?? 0,
      aiResolutionRate: (json['ai_resolution_rate'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'new_users': newUsers,
      'active_users': activeUsers,
      'total_calls': totalCalls,
      'avg_call_duration': avgCallDuration,
      'satisfaction': satisfaction,
      'help_requests': helpRequests,
      'help_responses': helpResponses,
      'response_rate': responseRate,
      'ai_calls': aiCalls,
      'ai_resolution_rate': aiResolutionRate,
    };
  }
}

// 用戶增長報表
class UserGrowthReport {
  final DateTime date;
  final int newDisabledUsers;
  final int newVolunteerUsers;
  final int totalDisabledUsers;
  final int totalVolunteerUsers;
  final int activeDisabledUsers;
  final int activeVolunteerUsers;
  final double volunteerRetentionRate;

  UserGrowthReport({
    required this.date,
    required this.newDisabledUsers,
    required this.newVolunteerUsers,
    required this.totalDisabledUsers,
    required this.totalVolunteerUsers,
    required this.activeDisabledUsers,
    required this.activeVolunteerUsers,
    required this.volunteerRetentionRate,
  });

  factory UserGrowthReport.fromJson(Map<String, dynamic> json) {
    return UserGrowthReport(
      date: DateTime.parse(json['date']),
      newDisabledUsers: json['new_disabled_users'] ?? 0,
      newVolunteerUsers: json['new_volunteer_users'] ?? 0,
      totalDisabledUsers: json['total_disabled_users'] ?? 0,
      totalVolunteerUsers: json['total_volunteer_users'] ?? 0,
      activeDisabledUsers: json['active_disabled_users'] ?? 0,
      activeVolunteerUsers: json['active_volunteer_users'] ?? 0,
      volunteerRetentionRate: (json['volunteer_retention_rate'] ?? 0).toDouble(),
    );
  }
}

// 求助類型統計
class HelpTypeStatistics {
  final String type;
  final int count;
  final double percentage;
  final double avgResponseTime;
  final double avgDuration;
  final double satisfaction;

  HelpTypeStatistics({
    required this.type,
    required this.count,
    required this.percentage,
    required this.avgResponseTime,
    required this.avgDuration,
    required this.satisfaction,
  });

  factory HelpTypeStatistics.fromJson(Map<String, dynamic> json) {
    return HelpTypeStatistics(
      type: json['type'] ?? '',
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      avgResponseTime: (json['avg_response_time'] ?? 0).toDouble(),
      avgDuration: (json['avg_duration'] ?? 0).toDouble(),
      satisfaction: (json['satisfaction'] ?? 0).toDouble(),
    );
  }
}

// 志願者績效報表
class VolunteerPerformanceReport {
  final String volunteerId;
  final String volunteerName;
  final int totalCalls;
  final int totalMinutes;
  final double avgRating;
  final int helpCount;
  final double responseRate;
  final int rank;

  VolunteerPerformanceReport({
    required this.volunteerId,
    required this.volunteerName,
    required this.totalCalls,
    required this.totalMinutes,
    required this.avgRating,
    required this.helpCount,
    required this.responseRate,
    required this.rank,
  });

  factory VolunteerPerformanceReport.fromJson(Map<String, dynamic> json) {
    return VolunteerPerformanceReport(
      volunteerId: json['volunteer_id'] ?? '',
      volunteerName: json['volunteer_name'] ?? '',
      totalCalls: json['total_calls'] ?? 0,
      totalMinutes: json['total_minutes'] ?? 0,
      avgRating: (json['avg_rating'] ?? 0).toDouble(),
      helpCount: json['help_count'] ?? 0,
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      rank: json['rank'] ?? 0,
    );
  }
}

// 報表查詢參數
class ReportQueryParams {
  final DateTime startDate;
  final DateTime endDate;
  final String? type;
  final String? groupBy; // 'day', 'week', 'month'

  ReportQueryParams({
    required this.startDate,
    required this.endDate,
    this.type,
    this.groupBy = 'day',
  });

  Map<String, dynamic> toJson() {
    return {
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'type': type,
      'group_by': groupBy,
    };
  }
}
