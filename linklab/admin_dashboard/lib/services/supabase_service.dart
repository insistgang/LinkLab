import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/dashboard_model.dart';
import '../models/content_model.dart';
import '../models/report_model.dart';
import '../models/statistics_model.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // 初始化
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // 获取当前用户
  User? get currentUser => client.auth.currentUser;

  // 检查是否已登录
  bool get isAuthenticated => currentUser != null;

  // 登录
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 登出
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ========== 用户管理 ==========

  // 获取用户列表
  Future<UserListResponse> getUsers({
    int page = 1,
    int pageSize = 20,
    String? search,
    UserStatus? status,
    UserRole? role,
    String? userType, // 'disabled', 'volunteer'
  }) async {
    var query = client.from('users').select('*');

    if (search != null && search.isNotEmpty) {
      query = query.or('email.ilike.%$search%,display_name.ilike.%$search%,phone.ilike.%$search%');
    }

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (role != null) {
      query = query.eq('role', role.name);
    }

    if (userType == 'disabled') {
      query = query.not('disability_type', 'is', null);
    } else if (userType == 'volunteer') {
      query = query.not('volunteer_level', 'is', null);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);

    final users = (response as List?)
        ?.map((json) => UserModel.fromJson(json))
        .toList() ?? [];

    return UserListResponse(
      users: users,
      total: users.length + (page * pageSize), // Approximate for now
      page: page,
      pageSize: pageSize,
    );
  }

  // 获取用户详情
  Future<UserModel?> getUserById(String userId) async {
    try {
      final response = await client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // 封禁/解封用户
  Future<void> updateUserStatus(String userId, UserStatus status) async {
    await client.from('users').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // 审核认证
  Future<void> verifyUser(String userId, VerificationStatus status, {String? reason}) async {
    await client.from('users').update({
      'verification_status': status.name,
      'verification_reason': reason,
      'verified_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // ========== 仪表盘数据 ==========

  // 获取核心指标
  Future<DashboardMetrics> getDashboardMetrics() async {
    // 实际项目中应该调用RPC函数或聚合查询
    // 这里模拟数据
    return DashboardMetrics(
      dau: 1234,
      mau: 5678,
      dauChange: 5.2,
      mauChange: 3.8,
      responseRate: 87.5,
      responseRateChange: 2.1,
      volunteerRetention: 78.3,
      volunteerRetentionChange: -1.5,
      aiResolutionRate: 45.2,
      aiResolutionRateChange: 5.8,
      avgCallDuration: 12.5,
      avgCallDurationChange: 0.8,
      satisfaction: 4.6,
      satisfactionChange: 0.2,
      totalCalls: 3456,
      totalCallsChange: 156,
      newUsers: 89,
      newUsersChange: 12,
    );
  }

  // 获取趋势数据
  Future<TrendData> getTrendData({required DateTime startDate, required DateTime endDate}) async {
    // 模拟7天趋势数据
    final now = DateTime.now();
    return TrendData(
      dau: List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return TrendDataPoint(
          date: date,
          value: 1000 + (i * 50) + (i % 3) * 100,
        );
      }),
      mau: List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return TrendDataPoint(
          date: date,
          value: 5000 + (i * 100) + (i % 3) * 200,
        );
      }),
      calls: List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return TrendDataPoint(
          date: date,
          value: 400 + (i * 20) + (i % 3) * 50,
        );
      }),
      newUsers: List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return TrendDataPoint(
          date: date,
          value: 50 + (i * 5) + (i % 3) * 10,
        );
      }),
    );
  }

  // 获取分布数据
  Future<UserDistribution> getDistributionData() async {
    return UserDistribution(
      userType: [
        DistributionData(name: '残障用户', value: 65),
        DistributionData(name: '志愿者', value: 35),
      ],
      disabilityType: [
        DistributionData(name: '视力障碍', value: 40),
        DistributionData(name: '听力障碍', value: 25),
        DistributionData(name: '肢体障碍', value: 20),
        DistributionData(name: '其他', value: 15),
      ],
      skillDistribution: [
        DistributionData(name: '导盲', value: 30),
        DistributionData(name: '手语', value: 25),
        DistributionData(name: '生活协助', value: 35),
        DistributionData(name: '其他', value: 10),
      ],
      regionDistribution: [
        DistributionData(name: '北京', value: 25),
        DistributionData(name: '上海', value: 20),
        DistributionData(name: '广州', value: 15),
        DistributionData(name: '深圳', value: 15),
        DistributionData(name: '其他', value: 25),
      ],
    );
  }

  // ========== 内容管理 ==========

  // 获取故事列表
  Future<List<StoryModel>> getStories({
    int page = 1,
    int pageSize = 20,
    ContentStatus? status,
    bool? isFeatured,
  }) async {
    var query = client.from('stories').select('*');

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (isFeatured != null) {
      query = query.eq('is_featured', isFeatured);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);

    return (response as List?)
        ?.map((json) => StoryModel.fromJson(json))
        .toList() ?? [];
  }

  // 更新故事状态
  Future<void> updateStoryStatus(String storyId, ContentStatus status) async {
    await client.from('stories').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
      if (status == ContentStatus.published)
        'published_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  // 设置精选故事
  Future<void> setStoryFeatured(String storyId, bool isFeatured) async {
    await client.from('stories').update({
      'is_featured': isFeatured,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  // 获取社群内容列表
  Future<List<CommunityContentModel>> getCommunityContent({
    int page = 1,
    int pageSize = 20,
    ContentStatus? status,
    String? groupId,
  }) async {
    var query = client.from('community_content').select('*');

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (groupId != null) {
      query = query.eq('group_id', groupId);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);

    return (response as List?)
        ?.map((json) => CommunityContentModel.fromJson(json))
        .toList() ?? [];
  }

  // 更新社群内容状态
  Future<void> updateContentStatus(String contentId, ContentStatus status) async {
    await client.from('community_content').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', contentId);
  }

  // ========== 举报处理 ==========

  // 获取举报列表
  Future<List<ReportModel>> getReports({
    int page = 1,
    int pageSize = 20,
    ReportStatus? status,
    ReportType? type,
  }) async {
    var query = client.from('reports').select('*');

    if (status != null) {
      query = query.eq('status', status.name);
    }

    if (type != null) {
      query = query.eq('type', type.name);
    }

    final response = await query
        .order('created_at', ascending: false)
        .range((page - 1) * pageSize, page * pageSize - 1);

    return (response as List?)
        ?.map((json) => ReportModel.fromJson(json))
        .toList() ?? [];
  }

  // 处理举报
  Future<void> processReport(
    String reportId, {
    required ReportStatus status,
    required String result,
    String? action,
  }) async {
    await client.from('reports').update({
      'status': status.name,
      'result': result,
      'action': action,
      'processed_at': DateTime.now().toIso8601String(),
      'processed_by': currentUser?.id,
    }).eq('id', reportId);
  }

  // 获取举报统计
  Future<ReportStatistics> getReportStatistics() async {
    return ReportStatistics(
      totalReports: 128,
      pendingReports: 23,
      processingReports: 8,
      resolvedReports: 89,
      dismissedReports: 8,
      avgProcessTime: 4.5,
      typeDistribution: [
        ReportTypeCount(type: ReportType.spam, count: 45),
        ReportTypeCount(type: ReportType.harassment, count: 32),
        ReportTypeCount(type: ReportType.inappropriate, count: 28),
        ReportTypeCount(type: ReportType.fraud, count: 15),
        ReportTypeCount(type: ReportType.other, count: 8),
      ],
    );
  }

  // ========== 数据统计 ==========

  // 获取日报表
  Future<List<DailyReport>> getDailyReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client
        .from('daily_reports')
        .select('*')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date');

    return (response as List?)
        ?.map((json) => DailyReport.fromJson(json))
        .toList() ?? [];
  }

  // 获取用户增长报表
  Future<List<UserGrowthReport>> getUserGrowthReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client
        .from('user_growth_reports')
        .select('*')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date');

    return (response as List?)
        ?.map((json) => UserGrowthReport.fromJson(json))
        .toList() ?? [];
  }

  // 获取求助类型分布
  Future<List<HelpTypeStatistics>> getHelpTypeStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await client
        .from('help_type_statistics')
        .select('*')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    return (response as List?)
        ?.map((json) => HelpTypeStatistics.fromJson(json))
        .toList() ?? [];
  }
}
