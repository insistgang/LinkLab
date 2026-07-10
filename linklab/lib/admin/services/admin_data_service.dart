import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';

/// 运营后台数据服务
class AdminDataService extends ChangeNotifier {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  // 模拟数据存储
  final List<UserListItem> _users = [];
  final List<VerificationRequest> _verifications = [];
  final List<ReportRecord> _reports = [];
  final List<ContentItem> _contents = [];
  final List<OperationLog> _operationLogs = [];

  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 初始化演示数据
  void initializeDemoData() {
    _generateDemoUsers();
    _generateDemoVerifications();
    _generateDemoReports();
    _generateDemoContents();
  }

  /// 生成演示用户数据
  void _generateDemoUsers() {
    final roles = [
      ['seeker'],
      ['volunteer'],
      ['seeker', 'volunteer'],
    ];
    final disabilityTypes = [
      ['visual'],
      ['visual', 'hearing'],
      [],
    ];
    final statuses = ['active', 'active', 'active', 'pending_verification', 'banned'];

    for (int i = 1; i <= 50; i++) {
      _users.add(UserListItem(
        id: 'user_$i',
        phone: '138${(10000000 + i).toString().substring(1)}',
        name: '用户$i',
        roles: List<String>.from(roles[i % 3]),
        disabilityTypes: List<String>.from(disabilityTypes[i % 3]),
        status: statuses[i % 5],
        createdAt: DateTime.now().subtract(Duration(days: i * 2)),
        lastLoginAt: DateTime.now().subtract(Duration(hours: i)),
        helpRequestCount: i % 10,
        volunteerCount: i % 5,
        isDisabilityVerified: i % 3 == 0,
        isVolunteerVerified: i % 4 == 0,
      ));
    }
  }

  /// 生成演示认证数据
  void _generateDemoVerifications() {
    final types = ['disability', 'volunteer_skill'];
    final docTypes = ['身份证', '残疾证', '技能证书', '学历证明'];

    for (int i = 1; i <= 20; i++) {
      _verifications.add(VerificationRequest(
        id: 'ver_$i',
        userId: 'user_$i',
        userName: '用户$i',
        type: types[i % 2],
        status: i % 3 == 0 ? 'approved' : (i % 4 == 0 ? 'rejected' : 'pending'),
        documentType: docTypes[i % 4],
        submittedAt: DateTime.now().subtract(Duration(days: i)),
        reviewedAt: i % 3 == 0 || i % 4 == 0 ? DateTime.now().subtract(Duration(days: i ~/ 2)) : null,
        rejectionReason: i % 4 == 0 ? '证件照片不清晰' : null,
      ));
    }
  }

  /// 生成演示举报数据
  void _generateDemoReports() {
    final reasons = [
      '言语辱骂',
      '骚扰行为',
      '虚假信息',
      '不当内容',
      '恶意挂断',
    ];
    final statuses = ['pending', 'processing', 'resolved', 'dismissed'];

    for (int i = 1; i <= 30; i++) {
      _reports.add(ReportRecord(
        id: 'rep_$i',
        reporterId: 'user_${i + 10}',
        reporterName: '举报者$i',
        targetId: 'user_$i',
        targetType: i % 2 == 0 ? 'user' : 'call',
        targetName: '被举报用户$i',
        reason: reasons[i % 5],
        description: '详细描述内容...',
        status: statuses[i % 4],
        createdAt: DateTime.now().subtract(Duration(hours: i * 3)),
      ));
    }
  }

  /// 生成演示内容数据
  void _generateDemoContents() {
    for (int i = 1; i <= 25; i++) {
      _contents.add(ContentItem(
        id: 'content_$i',
        title: '精选故事 #$i：志愿者与视障用户的温暖相遇',
        content: '这是一个感人的故事...',
        type: i % 3 == 0 ? 'announcement' : 'story',
        authorId: 'user_$i',
        authorName: '作者$i',
        viewCount: i * 100,
        likeCount: i * 20,
        status: i % 4 == 0 ? 'published' : (i % 3 == 0 ? 'pending' : 'draft'),
        tags: ['温暖', '互助', '正能量'],
        createdAt: DateTime.now().subtract(Duration(days: i)),
      ));
    }
  }

  /// 获取仪表盘统计数据
  Future<DashboardStats> getDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final stats = DashboardStats(
      totalUsers: _users.length,
      newUsersToday: 5,
      dau: 120,
      mau: 850,
      dauGrowthRate: 0.12,
      mauGrowthRate: 0.08,
      totalHelpRequests: 1250,
      helpRequestsToday: 45,
      responseRate: 0.92,
      aiResolutionRate: 0.35,
      avgCallDuration: 8.5,
      satisfactionRate: 4.6,
      volunteerRetentionRate: 0.78,
      pendingReports: _reports.where((r) => r.status == 'pending').length,
      pendingVerifications: _verifications.where((v) => v.status == 'pending').length,
    );

    _isLoading = false;
    notifyListeners();

    return stats;
  }

  /// 获取趋势数据
  Future<List<TrendDataPoint>> getTrendData(String metric, int days) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final List<TrendDataPoint> data = [];
    for (int i = days; i >= 0; i--) {
      data.add(TrendDataPoint(
        date: DateTime.now().subtract(Duration(days: i)),
        value: 50 + (i * 2) + (i % 7) * 10,
        secondaryValue: 30 + (i * 1) + (i % 5) * 5,
      ));
    }
    return data;
  }

  /// 获取分布数据
  Future<List<DistributionItem>> getDistributionData(String type) async {
    await Future.delayed(const Duration(milliseconds: 300));

    switch (type) {
      case 'help_type':
        return [
          const DistributionItem(label: 'AI自动解决', value: 35, colorValue: 0xFF1565C0),
          const DistributionItem(label: '异步求助', value: 25, colorValue: 0xFF2E7D32),
          const DistributionItem(label: '实时语音', value: 30, colorValue: 0xFFFF6F00),
          const DistributionItem(label: '实时视频', value: 10, colorValue: 0xFFD32F2F),
        ];
      case 'user_type':
        return [
          const DistributionItem(label: '视障用户', value: 60, colorValue: 0xFF1565C0),
          const DistributionItem(label: '听障用户', value: 15, colorValue: 0xFF2E7D32),
          const DistributionItem(label: '志愿者', value: 25, colorValue: 0xFFFF6F00),
        ];
      case 'disability_type':
        return [
          const DistributionItem(label: '全盲', value: 40, colorValue: 0xFF1565C0),
          const DistributionItem(label: '低视力', value: 35, colorValue: 0xFF2E7D32),
          const DistributionItem(label: '色盲', value: 15, colorValue: 0xFFFF6F00),
          const DistributionItem(label: '其他', value: 10, colorValue: 0xFF757575),
        ];
      default:
        return [];
    }
  }

  /// 获取用户列表（分页）
  Future<PaginatedResult<UserListItem>> getUsers({
    required int page,
    required int pageSize,
    UserFilter? filter,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    var filteredUsers = List<UserListItem>.from(_users);

    // 应用筛选
    if (filter != null) {
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        filteredUsers = filteredUsers.where((u) =>
          u.name?.toLowerCase().contains(query) == true ||
          u.phone.contains(query) ||
          u.id.toLowerCase().contains(query)
        ).toList();
      }

      if (filter.roles != null && filter.roles!.isNotEmpty) {
        filteredUsers = filteredUsers.where((u) =>
          u.roles.any((r) => filter.roles!.contains(r))
        ).toList();
      }

      if (filter.status != null) {
        filteredUsers = filteredUsers.where((u) => u.status == filter.status).toList();
      }
    }

    final totalCount = filteredUsers.length;
    final totalPages = (totalCount / pageSize).ceil();

    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    final items = filteredUsers.sublist(
      startIndex,
      endIndex,
    );

    _isLoading = false;
    notifyListeners();

    return PaginatedResult(
      items: items,
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  /// 获取用户详情
  Future<UserListItem?> getUserDetail(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// 封禁/解封用户
  Future<bool> toggleUserBan(String userId, bool ban) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _users.indexWhere((u) => u.id == userId);
    if (index >= 0) {
      final user = _users[index];
      _users[index] = user.copyWith(status: ban ? 'banned' : 'active');
      _logOperation(ban ? 'ban_user' : 'unban_user', 'user', userId);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 获取认证列表
  Future<PaginatedResult<VerificationRequest>> getVerifications({
    required int page,
    required int pageSize,
    String? status,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<VerificationRequest>.from(_verifications);
    if (status != null) {
      filtered = filtered.where((v) => v.status == status).toList();
    }

    final totalCount = filtered.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = ((page - 1) * pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    _isLoading = false;
    notifyListeners();

    return PaginatedResult(
      items: filtered.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  /// 审核认证
  Future<bool> reviewVerification(String verificationId, bool approved, {String? reason}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _verifications.indexWhere((v) => v.id == verificationId);
    if (index >= 0) {
      final ver = _verifications[index];
      _verifications[index] = ver.copyWith(
        status: approved ? 'approved' : 'rejected',
        rejectionReason: reason,
        reviewedAt: DateTime.now(),
        reviewedBy: 'admin',
      );
      _logOperation(approved ? 'approve_verification' : 'reject_verification', 'verification', verificationId);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 获取举报列表
  Future<PaginatedResult<ReportRecord>> getReports({
    required int page,
    required int pageSize,
    String? status,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<ReportRecord>.from(_reports);
    if (status != null) {
      filtered = filtered.where((r) => r.status == status).toList();
    }

    final totalCount = filtered.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = ((page - 1) * pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    _isLoading = false;
    notifyListeners();

    return PaginatedResult(
      items: filtered.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  /// 处理举报
  Future<bool> handleReport(String reportId, String action, {String? resolution}) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index >= 0) {
      final report = _reports[index];
      _reports[index] = report.copyWith(
        status: 'resolved',
        action: action,
        resolution: resolution,
        resolvedAt: DateTime.now(),
        resolvedBy: 'admin',
      );
      _logOperation('handle_report', 'report', reportId, details: 'action: $action');
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 获取内容列表
  Future<PaginatedResult<ContentItem>> getContents({
    required int page,
    required int pageSize,
    String? status,
    String? type,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    var filtered = List<ContentItem>.from(_contents);
    if (status != null) {
      filtered = filtered.where((c) => c.status == status).toList();
    }
    if (type != null) {
      filtered = filtered.where((c) => c.type == type).toList();
    }

    final totalCount = filtered.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = ((page - 1) * pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    _isLoading = false;
    notifyListeners();

    return PaginatedResult(
      items: filtered.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  /// 发布/下架内容
  Future<bool> toggleContentStatus(String contentId, bool publish) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    final index = _contents.indexWhere((c) => c.id == contentId);
    if (index >= 0) {
      final content = _contents[index];
      _contents[index] = content.copyWith(
        status: publish ? 'published' : 'archived',
        publishedAt: publish ? DateTime.now() : null,
      );
      _logOperation(publish ? 'publish_content' : 'archive_content', 'content', contentId);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// 删除内容
  Future<bool> deleteContent(String contentId) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    _contents.removeWhere((c) => c.id == contentId);
    _logOperation('delete_content', 'content', contentId);

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// 获取操作日志
  Future<PaginatedResult<OperationLog>> getOperationLogs({
    required int page,
    required int pageSize,
  }) async {
    final totalCount = _operationLogs.length;
    final totalPages = (totalCount / pageSize).ceil();
    final startIndex = ((page - 1) * pageSize).clamp(0, totalCount);
    final endIndex = (startIndex + pageSize).clamp(0, totalCount);

    return PaginatedResult(
      items: _operationLogs.sublist(startIndex, endIndex),
      totalCount: totalCount,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
    );
  }

  /// 记录操作日志
  void _logOperation(String operation, String targetType, String targetId, {String? details}) {
    _operationLogs.insert(0, OperationLog(
      id: 'log_${_operationLogs.length + 1}',
      adminId: 'admin',
      adminName: '管理员',
      operation: operation,
      targetType: targetType,
      targetId: targetId,
      details: details,
      createdAt: DateTime.now(),
    ));
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
