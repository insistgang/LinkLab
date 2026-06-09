import 'package:flutter/foundation.dart';
import '../models/admin_models.dart';

/// 運營後臺數據服務
class AdminDataService extends ChangeNotifier {
  static final AdminDataService _instance = AdminDataService._internal();
  factory AdminDataService() => _instance;
  AdminDataService._internal();

  // 模擬數據存儲
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

  /// 初始化演示數據
  void initializeDemoData() {
    _generateDemoUsers();
    _generateDemoVerifications();
    _generateDemoReports();
    _generateDemoContents();
  }

  /// 生成演示用戶數據
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
        name: '用戶$i',
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

  /// 生成演示認證數據
  void _generateDemoVerifications() {
    final types = ['disability', 'volunteer_skill'];
    final docTypes = ['身份證', '殘疾證', '技能證書', '學歷證明'];

    for (int i = 1; i <= 20; i++) {
      _verifications.add(VerificationRequest(
        id: 'ver_$i',
        userId: 'user_$i',
        userName: '用戶$i',
        type: types[i % 2],
        status: i % 3 == 0 ? 'approved' : (i % 4 == 0 ? 'rejected' : 'pending'),
        documentType: docTypes[i % 4],
        submittedAt: DateTime.now().subtract(Duration(days: i)),
        reviewedAt: i % 3 == 0 || i % 4 == 0 ? DateTime.now().subtract(Duration(days: i ~/ 2)) : null,
        rejectionReason: i % 4 == 0 ? '證件照片不清晰' : null,
      ));
    }
  }

  /// 生成演示舉報數據
  void _generateDemoReports() {
    final reasons = [
      '言語辱罵',
      '騷擾行爲',
      '虛假信息',
      '不當內容',
      '惡意掛斷',
    ];
    final statuses = ['pending', 'processing', 'resolved', 'dismissed'];

    for (int i = 1; i <= 30; i++) {
      _reports.add(ReportRecord(
        id: 'rep_$i',
        reporterId: 'user_${i + 10}',
        reporterName: '舉報者$i',
        targetId: 'user_$i',
        targetType: i % 2 == 0 ? 'user' : 'call',
        targetName: '被舉報用戶$i',
        reason: reasons[i % 5],
        description: '詳細描述內容...',
        status: statuses[i % 4],
        createdAt: DateTime.now().subtract(Duration(hours: i * 3)),
      ));
    }
  }

  /// 生成演示內容數據
  void _generateDemoContents() {
    for (int i = 1; i <= 25; i++) {
      _contents.add(ContentItem(
        id: 'content_$i',
        title: '精選故事 #$i：志願者與視障用戶的溫暖相遇',
        content: '這是一個感人的故事...',
        type: i % 3 == 0 ? 'announcement' : 'story',
        authorId: 'user_$i',
        authorName: '作者$i',
        viewCount: i * 100,
        likeCount: i * 20,
        status: i % 4 == 0 ? 'published' : (i % 3 == 0 ? 'pending' : 'draft'),
        tags: ['溫暖', '互助', '正能量'],
        createdAt: DateTime.now().subtract(Duration(days: i)),
      ));
    }
  }

  /// 獲取儀表盤統計數據
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

  /// 獲取趨勢數據
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

  /// 獲取分佈數據
  Future<List<DistributionItem>> getDistributionData(String type) async {
    await Future.delayed(const Duration(milliseconds: 300));

    switch (type) {
      case 'help_type':
        return [
          const DistributionItem(label: 'AI自動解決', value: 35, colorValue: 0xFF1565C0),
          const DistributionItem(label: '異步求助', value: 25, colorValue: 0xFF2E7D32),
          const DistributionItem(label: '實時語音', value: 30, colorValue: 0xFFFF6F00),
          const DistributionItem(label: '實時視頻', value: 10, colorValue: 0xFFD32F2F),
        ];
      case 'user_type':
        return [
          const DistributionItem(label: '視障用戶', value: 60, colorValue: 0xFF1565C0),
          const DistributionItem(label: '聽障用戶', value: 15, colorValue: 0xFF2E7D32),
          const DistributionItem(label: '志願者', value: 25, colorValue: 0xFFFF6F00),
        ];
      case 'disability_type':
        return [
          const DistributionItem(label: '全盲', value: 40, colorValue: 0xFF1565C0),
          const DistributionItem(label: '低視力', value: 35, colorValue: 0xFF2E7D32),
          const DistributionItem(label: '色盲', value: 15, colorValue: 0xFFFF6F00),
          const DistributionItem(label: '其他', value: 10, colorValue: 0xFF757575),
        ];
      default:
        return [];
    }
  }

  /// 獲取用戶列表（分頁）
  Future<PaginatedResult<UserListItem>> getUsers({
    required int page,
    required int pageSize,
    UserFilter? filter,
  }) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));

    var filteredUsers = List<UserListItem>.from(_users);

    // 應用篩選
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

  /// 獲取用戶詳情
  Future<UserListItem?> getUserDetail(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  /// 封禁/解封用戶
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

  /// 獲取認證列表
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

  /// 審覈認證
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

  /// 獲取舉報列表
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

  /// 處理舉報
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

  /// 獲取內容列表
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

  /// 發佈/下架內容
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

  /// 刪除內容
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

  /// 獲取操作日誌
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

  /// 記錄操作日誌
  void _logOperation(String operation, String targetType, String targetId, {String? details}) {
    _operationLogs.insert(0, OperationLog(
      id: 'log_${_operationLogs.length + 1}',
      adminId: 'admin',
      adminName: '管理員',
      operation: operation,
      targetType: targetType,
      targetId: targetId,
      details: details,
      createdAt: DateTime.now(),
    ));
  }

  /// 清除錯誤
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
