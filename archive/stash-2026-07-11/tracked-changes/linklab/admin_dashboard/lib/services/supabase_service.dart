import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/app_constants.dart';
import '../models/admin_session.dart';
import '../models/content_model.dart';
import '../models/dashboard_model.dart';
import '../models/report_model.dart';
import '../models/statistics_model.dart';
import '../models/user_model.dart';
import 'demo_backend.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  static final DemoBackend _demoBackend = DemoBackend.instance;

  factory SupabaseService() => _instance;

  SupabaseService._internal();

  bool get isDemoMode => AppConstants.isDemoMode;

  SupabaseClient get client {
    if (isDemoMode) {
      throw StateError('Demo mode does not initialize a Supabase client.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (AppConstants.isDemoMode) {
      _demoBackend.reset();
      return;
    }

    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  AdminSession? get currentAdmin {
    if (isDemoMode) {
      return _demoBackend.currentAdmin;
    }

    final user = client.auth.currentUser;
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AdminSession(
      id: user.id,
      email: user.email ?? AppConstants.demoAdminEmail,
      displayName: metadata['display_name'] as String? ?? '管理员',
    );
  }

  bool get isAuthenticated => currentAdmin != null;

  Future<AdminSession> signIn(String email, String password) async {
    if (isDemoMode) {
      return _demoBackend.signIn(email, password);
    }

    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw StateError('登录失败');
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    return AdminSession(
      id: user.id,
      email: user.email ?? email,
      displayName: metadata['display_name'] as String? ?? '管理员',
    );
  }

  Future<void> signOut() async {
    if (isDemoMode) {
      await _demoBackend.signOut();
      return;
    }

    await client.auth.signOut();
  }

  Future<UserListResponse> getUsers({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? search,
    UserStatus? status,
    UserRole? role,
    String? userType,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getUsers(
        page: page,
        pageSize: pageSize,
        search: search,
        status: status,
        role: role,
        userType: userType,
      );
    }

    var query = client.from('users').select('*');

    if (search != null && search.isNotEmpty) {
      query = query.or(
        'email.ilike.%$search%,display_name.ilike.%$search%,phone.ilike.%$search%',
      );
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
            .toList() ??
        <UserModel>[];

    return UserListResponse(
      users: users,
      total: users.length + (page * pageSize),
      page: page,
      pageSize: pageSize,
    );
  }

  Future<UserModel?> getUserById(String userId) async {
    if (isDemoMode) {
      final response = await _demoBackend.getUsers(pageSize: 100);
      try {
        return response.users.firstWhere((user) => user.id == userId);
      } catch (_) {
        return null;
      }
    }

    try {
      final response =
          await client.from('users').select('*').eq('id', userId).single();
      return UserModel.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    if (isDemoMode) {
      await _demoBackend.updateUserStatus(userId, status);
      return;
    }

    await client.from('users').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<void> verifyUser(
    String userId,
    VerificationStatus status, {
    String? reason,
  }) async {
    if (isDemoMode) {
      await _demoBackend.verifyUser(userId, status, reason: reason);
      return;
    }

    await client.from('users').update({
      'verification_status': status.name,
      'verification_reason': reason,
      'verified_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  Future<DashboardMetrics> getDashboardMetrics() async {
    if (isDemoMode) {
      return _demoBackend.getDashboardMetrics();
    }

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

  Future<TrendData> getTrendData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getTrendData(
        startDate: startDate,
        endDate: endDate,
      );
    }

    final now = DateTime.now();
    return TrendData(
      dau: List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return TrendDataPoint(
          date: date,
          value: 1000 + (index * 50) + (index % 3) * 100,
        );
      }),
      mau: List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return TrendDataPoint(
          date: date,
          value: 5000 + (index * 100) + (index % 3) * 200,
        );
      }),
      calls: List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return TrendDataPoint(
          date: date,
          value: 400 + (index * 20) + (index % 3) * 50,
        );
      }),
      newUsers: List.generate(7, (index) {
        final date = now.subtract(Duration(days: 6 - index));
        return TrendDataPoint(
          date: date,
          value: 50 + (index * 5) + (index % 3) * 10,
        );
      }),
    );
  }

  Future<UserDistribution> getDistributionData() async {
    if (isDemoMode) {
      return _demoBackend.getDistributionData();
    }

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

  Future<List<StoryModel>> getStories({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    ContentStatus? status,
    bool? isFeatured,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getStories(
        page: page,
        pageSize: pageSize,
        status: status,
        isFeatured: isFeatured,
      );
    }

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
            .toList() ??
        <StoryModel>[];
  }

  Future<void> updateStoryStatus(String storyId, ContentStatus status) async {
    if (isDemoMode) {
      await _demoBackend.updateStoryStatus(storyId, status);
      return;
    }

    await client.from('stories').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
      if (status == ContentStatus.published)
        'published_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<void> setStoryFeatured(String storyId, bool isFeatured) async {
    if (isDemoMode) {
      await _demoBackend.setStoryFeatured(storyId, isFeatured);
      return;
    }

    await client.from('stories').update({
      'is_featured': isFeatured,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', storyId);
  }

  Future<List<CommunityContentModel>> getCommunityContent({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    ContentStatus? status,
    String? groupId,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getCommunityContent(
        page: page,
        pageSize: pageSize,
        status: status,
        groupId: groupId,
      );
    }

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
            .toList() ??
        <CommunityContentModel>[];
  }

  Future<void> updateContentStatus(
    String contentId,
    ContentStatus status,
  ) async {
    if (isDemoMode) {
      await _demoBackend.updateContentStatus(contentId, status);
      return;
    }

    await client.from('community_content').update({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', contentId);
  }

  Future<List<ReportModel>> getReports({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    ReportStatus? status,
    ReportType? type,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getReports(
        page: page,
        pageSize: pageSize,
        status: status,
        type: type,
      );
    }

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
            .toList() ??
        <ReportModel>[];
  }

  Future<void> processReport(
    String reportId, {
    required ReportStatus status,
    required String result,
    String? action,
  }) async {
    if (isDemoMode) {
      await _demoBackend.processReport(
        reportId,
        status: status,
        result: result,
        action: action,
      );
      return;
    }

    await client.from('reports').update({
      'status': status.name,
      'result': result,
      'action': action,
      'processed_at': DateTime.now().toIso8601String(),
      'processed_by': currentAdmin?.id,
    }).eq('id', reportId);
  }

  Future<ReportStatistics> getReportStatistics() async {
    if (isDemoMode) {
      return _demoBackend.getReportStatistics();
    }

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

  Future<List<DailyReport>> getDailyReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getDailyReports(
        startDate: startDate,
        endDate: endDate,
      );
    }

    final response = await client
        .from('daily_reports')
        .select('*')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date');

    return (response as List?)
            ?.map((json) => DailyReport.fromJson(json))
            .toList() ??
        <DailyReport>[];
  }

  Future<List<UserGrowthReport>> getUserGrowthReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getUserGrowthReports(
        startDate: startDate,
        endDate: endDate,
      );
    }

    final response = await client
        .from('user_growth_reports')
        .select('*')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String())
        .order('date');

    return (response as List?)
            ?.map((json) => UserGrowthReport.fromJson(json))
            .toList() ??
        <UserGrowthReport>[];
  }

  Future<List<HelpTypeStatistics>> getHelpTypeStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (isDemoMode) {
      return _demoBackend.getHelpTypeStatistics(
        startDate: startDate,
        endDate: endDate,
      );
    }

    final response = await client
        .from('help_type_statistics')
        .select('*')
        .gte('date', startDate.toIso8601String())
        .lte('date', endDate.toIso8601String());

    return (response as List?)
            ?.map((json) => HelpTypeStatistics.fromJson(json))
            .toList() ??
        <HelpTypeStatistics>[];
  }
}
