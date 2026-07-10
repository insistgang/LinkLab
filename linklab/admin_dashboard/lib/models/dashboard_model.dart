// 仪表盘指标数据模型
class DashboardMetrics {
  final int dau; // 日活跃用户
  final int mau; // 月活跃用户
  final double dauChange; // DAU变化率
  final double mauChange; // MAU变化率

  final double responseRate; // 求助响应率
  final double responseRateChange;

  final double volunteerRetention; // 志愿者留存率
  final double volunteerRetentionChange;

  final double aiResolutionRate; // AI解决率
  final double aiResolutionRateChange;

  final double avgCallDuration; // 平均通话时长（分钟）
  final double avgCallDurationChange;

  final double satisfaction; // 用户满意度
  final double satisfactionChange;

  final int totalCalls; // 总通话数
  final int totalCallsChange;

  final int newUsers; // 新增用户
  final int newUsersChange;

  DashboardMetrics({
    required this.dau,
    required this.mau,
    required this.dauChange,
    required this.mauChange,
    required this.responseRate,
    required this.responseRateChange,
    required this.volunteerRetention,
    required this.volunteerRetentionChange,
    required this.aiResolutionRate,
    required this.aiResolutionRateChange,
    required this.avgCallDuration,
    required this.avgCallDurationChange,
    required this.satisfaction,
    required this.satisfactionChange,
    required this.totalCalls,
    required this.totalCallsChange,
    required this.newUsers,
    required this.newUsersChange,
  });

  factory DashboardMetrics.fromJson(Map<String, dynamic> json) {
    return DashboardMetrics(
      dau: json['dau'] ?? 0,
      mau: json['mau'] ?? 0,
      dauChange: (json['dau_change'] ?? 0).toDouble(),
      mauChange: (json['mau_change'] ?? 0).toDouble(),
      responseRate: (json['response_rate'] ?? 0).toDouble(),
      responseRateChange: (json['response_rate_change'] ?? 0).toDouble(),
      volunteerRetention: (json['volunteer_retention'] ?? 0).toDouble(),
      volunteerRetentionChange: (json['volunteer_retention_change'] ?? 0).toDouble(),
      aiResolutionRate: (json['ai_resolution_rate'] ?? 0).toDouble(),
      aiResolutionRateChange: (json['ai_resolution_rate_change'] ?? 0).toDouble(),
      avgCallDuration: (json['avg_call_duration'] ?? 0).toDouble(),
      avgCallDurationChange: (json['avg_call_duration_change'] ?? 0).toDouble(),
      satisfaction: (json['satisfaction'] ?? 0).toDouble(),
      satisfactionChange: (json['satisfaction_change'] ?? 0).toDouble(),
      totalCalls: json['total_calls'] ?? 0,
      totalCallsChange: json['total_calls_change'] ?? 0,
      newUsers: json['new_users'] ?? 0,
      newUsersChange: json['new_users_change'] ?? 0,
    );
  }
}

// 趋势数据点
class TrendDataPoint {
  final DateTime date;
  final double value;
  final String? label;

  TrendDataPoint({
    required this.date,
    required this.value,
    this.label,
  });

  factory TrendDataPoint.fromJson(Map<String, dynamic> json) {
    return TrendDataPoint(
      date: DateTime.parse(json['date']),
      value: (json['value'] ?? 0).toDouble(),
      label: json['label'],
    );
  }
}

// 趋势数据
class TrendData {
  final List<TrendDataPoint> dau; // DAU趋势
  final List<TrendDataPoint> mau; // MAU趋势
  final List<TrendDataPoint> calls; // 通话趋势
  final List<TrendDataPoint> newUsers; // 新用户趋势

  TrendData({
    required this.dau,
    required this.mau,
    required this.calls,
    required this.newUsers,
  });

  factory TrendData.fromJson(Map<String, dynamic> json) {
    return TrendData(
      dau: (json['dau'] as List?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      mau: (json['mau'] as List?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      calls: (json['calls'] as List?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
      newUsers: (json['new_users'] as List?)
          ?.map((e) => TrendDataPoint.fromJson(e))
          .toList() ?? [],
    );
  }
}

// 分布数据
class DistributionData {
  final String name;
  final double value;
  final String? color;

  DistributionData({
    required this.name,
    required this.value,
    this.color,
  });

  factory DistributionData.fromJson(Map<String, dynamic> json) {
    return DistributionData(
      name: json['name'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      color: json['color'],
    );
  }
}

// 用户分布数据
class UserDistribution {
  final List<DistributionData> userType; // 用户类型分布
  final List<DistributionData> disabilityType; // 残障类型分布
  final List<DistributionData> skillDistribution; // 技能分布
  final List<DistributionData> regionDistribution; // 地区分布

  UserDistribution({
    required this.userType,
    required this.disabilityType,
    required this.skillDistribution,
    required this.regionDistribution,
  });

  factory UserDistribution.fromJson(Map<String, dynamic> json) {
    return UserDistribution(
      userType: (json['user_type'] as List?)
          ?.map((e) => DistributionData.fromJson(e))
          .toList() ?? [],
      disabilityType: (json['disability_type'] as List?)
          ?.map((e) => DistributionData.fromJson(e))
          .toList() ?? [],
      skillDistribution: (json['skill_distribution'] as List?)
          ?.map((e) => DistributionData.fromJson(e))
          .toList() ?? [],
      regionDistribution: (json['region_distribution'] as List?)
          ?.map((e) => DistributionData.fromJson(e))
          .toList() ?? [],
    );
  }
}

// 对比数据
class ComparisonData {
  final String category;
  final double current;
  final double previous;

  ComparisonData({
    required this.category,
    required this.current,
    required this.previous,
  });

  factory ComparisonData.fromJson(Map<String, dynamic> json) {
    return ComparisonData(
      category: json['category'] ?? '',
      current: (json['current'] ?? 0).toDouble(),
      previous: (json['previous'] ?? 0).toDouble(),
    );
  }
}

// 求助类型分布
class HelpTypeDistribution {
  final List<ComparisonData> weekly; // 本周数据
  final List<ComparisonData> monthly; // 本月数据

  HelpTypeDistribution({
    required this.weekly,
    required this.monthly,
  });

  factory HelpTypeDistribution.fromJson(Map<String, dynamic> json) {
    return HelpTypeDistribution(
      weekly: (json['weekly'] as List?)
          ?.map((e) => ComparisonData.fromJson(e))
          .toList() ?? [],
      monthly: (json['monthly'] as List?)
          ?.map((e) => ComparisonData.fromJson(e))
          .toList() ?? [],
    );
  }
}
