import '../constants/app_constants.dart';
import '../models/admin_session.dart';
import '../models/content_model.dart';
import '../models/dashboard_model.dart';
import '../models/report_model.dart';
import '../models/statistics_model.dart';
import '../models/user_model.dart';

class DemoBackend {
  DemoBackend._internal() {
    reset();
  }

  static final DemoBackend instance = DemoBackend._internal();

  AdminSession? _currentAdmin;
  late List<UserModel> _users;
  late List<StoryModel> _stories;
  late List<CommunityContentModel> _communityContent;
  late List<ReportModel> _reports;
  late List<DailyReport> _dailyReports;
  late List<UserGrowthReport> _userGrowthReports;
  late List<HelpTypeStatistics> _helpTypeStatistics;

  AdminSession? get currentAdmin => _currentAdmin;

  void reset() {
    final now = DateTime.now();
    _currentAdmin = null;
    _users = _buildUsers(now);
    _stories = _buildStories(now);
    _communityContent = _buildCommunityContent(now);
    _reports = _buildReports(now);
    _dailyReports = _buildDailyReports(now);
    _userGrowthReports = _buildUserGrowthReports(now);
    _helpTypeStatistics = _buildHelpTypeStatistics();
  }

  Future<AdminSession> signIn(String email, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    if (email != AppConstants.demoAdminEmail ||
        password != AppConstants.demoAdminPassword) {
      throw Exception('演示環境僅支持默認賬號登錄');
    }

    _currentAdmin = const AdminSession(
      id: 'demo-admin',
      email: AppConstants.demoAdminEmail,
      displayName: '演示管理員',
    );
    return _currentAdmin!;
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    _currentAdmin = null;
  }

  Future<UserListResponse> getUsers({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    String? search,
    UserStatus? status,
    UserRole? role,
    String? userType,
  }) async {
    var filtered = List<UserModel>.from(_users);
    final keyword = search?.trim().toLowerCase();

    if (keyword != null && keyword.isNotEmpty) {
      filtered = filtered.where((user) {
        return user.email.toLowerCase().contains(keyword) ||
            (user.displayName?.toLowerCase().contains(keyword) ?? false) ||
            (user.phone?.toLowerCase().contains(keyword) ?? false);
      }).toList();
    }

    if (status != null) {
      filtered = filtered.where((user) => user.status == status).toList();
    }

    if (role != null) {
      filtered = filtered.where((user) => user.role == role).toList();
    }

    if (userType == 'disabled') {
      filtered = filtered.where((user) => user.disabilityType != null).toList();
    } else if (userType == 'volunteer') {
      filtered = filtered.where((user) => user.volunteerLevel != null).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final paged = _paginate(filtered, page, pageSize);

    return UserListResponse(
      users: paged,
      total: filtered.length,
      page: page,
      pageSize: pageSize,
    );
  }

  Future<void> updateUserStatus(String userId, UserStatus status) async {
    _users = _users
        .map((user) => user.id == userId ? user.copyWith(status: status) : user)
        .toList();
  }

  Future<void> verifyUser(
    String userId,
    VerificationStatus status, {
    String? reason,
  }) async {
    _users = _users
        .map(
          (user) => user.id == userId
              ? user.copyWith(
                  verificationStatus: status,
                  metadata: {
                    ...?user.metadata,
                    ...?(reason == null
                        ? null
                        : <String, dynamic>{'verification_reason': reason}),
                  },
                )
              : user,
        )
        .toList();
  }

  Future<DashboardMetrics> getDashboardMetrics() async {
    final today = _dailyReports.last;
    final yesterday = _dailyReports[_dailyReports.length - 2];
    final latestGrowth = _userGrowthReports.last;
    final previousGrowth = _userGrowthReports[_userGrowthReports.length - 2];
    final monthlyActive =
        _dailyReports
            .map((report) => report.activeUsers)
            .reduce((a, b) => a + b) ~/
        _dailyReports.length;

    return DashboardMetrics(
      dau: today.activeUsers,
      mau: monthlyActive,
      dauChange: _percentChange(today.activeUsers, yesterday.activeUsers),
      mauChange: _percentChange(monthlyActive, monthlyActive - 186),
      responseRate: today.responseRate,
      responseRateChange: _percentChange(
        today.responseRate,
        yesterday.responseRate,
      ),
      volunteerRetention: latestGrowth.volunteerRetentionRate,
      volunteerRetentionChange: _percentChange(
        latestGrowth.volunteerRetentionRate,
        previousGrowth.volunteerRetentionRate,
      ),
      aiResolutionRate: today.aiResolutionRate,
      aiResolutionRateChange: _percentChange(
        today.aiResolutionRate,
        yesterday.aiResolutionRate,
      ),
      avgCallDuration: today.avgCallDuration,
      avgCallDurationChange: _percentChange(
        today.avgCallDuration,
        yesterday.avgCallDuration,
      ),
      satisfaction: today.satisfaction,
      satisfactionChange: _percentChange(
        today.satisfaction,
        yesterday.satisfaction,
      ),
      totalCalls: today.totalCalls,
      totalCallsChange: today.totalCalls - yesterday.totalCalls,
      newUsers: today.newUsers,
      newUsersChange: today.newUsers - yesterday.newUsers,
    );
  }

  Future<TrendData> getTrendData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final reports = _dailyReports
        .where((report) => _isWithinRange(report.date, startDate, endDate))
        .toList();

    return TrendData(
      dau: reports
          .map(
            (report) => TrendDataPoint(
              date: report.date,
              value: report.activeUsers.toDouble(),
            ),
          )
          .toList(),
      mau: reports
          .map(
            (report) => TrendDataPoint(
              date: report.date,
              value: (report.activeUsers * 4.4),
            ),
          )
          .toList(),
      calls: reports
          .map(
            (report) => TrendDataPoint(
              date: report.date,
              value: report.totalCalls.toDouble(),
            ),
          )
          .toList(),
      newUsers: reports
          .map(
            (report) => TrendDataPoint(
              date: report.date,
              value: report.newUsers.toDouble(),
            ),
          )
          .toList(),
    );
  }

  Future<UserDistribution> getDistributionData() async {
    final disabledUsers = _users.where((user) => user.disabilityType != null);
    final volunteers = _users.where((user) => user.volunteerLevel != null);
    final disabilityBuckets = <String, double>{};
    final skillBuckets = <String, double>{};
    final regionBuckets = <String, double>{};

    for (final user in disabledUsers) {
      disabilityBuckets.update(
        user.disabilityType ?? '未標註',
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    for (final user in volunteers) {
      for (final skill in user.skills ?? const <String>[]) {
        skillBuckets.update(skill, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    for (final user in _users) {
      final region = user.metadata?['region'] as String? ?? '未分區';
      regionBuckets.update(region, (value) => value + 1, ifAbsent: () => 1);
    }

    return UserDistribution(
      userType: [
        DistributionData(name: '殘障用戶', value: disabledUsers.length.toDouble()),
        DistributionData(name: '志願者', value: volunteers.length.toDouble()),
      ],
      disabilityType: disabilityBuckets.entries
          .map((entry) => DistributionData(name: entry.key, value: entry.value))
          .toList(),
      skillDistribution: skillBuckets.entries
          .map((entry) => DistributionData(name: entry.key, value: entry.value))
          .toList(),
      regionDistribution: regionBuckets.entries
          .map((entry) => DistributionData(name: entry.key, value: entry.value))
          .toList(),
    );
  }

  Future<List<StoryModel>> getStories({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    ContentStatus? status,
    bool? isFeatured,
  }) async {
    var filtered = List<StoryModel>.from(_stories);

    if (status != null) {
      filtered = filtered.where((story) => story.status == status).toList();
    }

    if (isFeatured != null) {
      filtered = filtered
          .where((story) => story.isFeatured == isFeatured)
          .toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _paginate(filtered, page, pageSize);
  }

  Future<void> updateStoryStatus(String storyId, ContentStatus status) async {
    _stories = _stories.map((story) {
      if (story.id != storyId) {
        return story;
      }
      return StoryModel(
        id: story.id,
        title: story.title,
        content: story.content,
        summary: story.summary,
        coverImage: story.coverImage,
        authorId: story.authorId,
        authorName: story.authorName,
        authorAvatar: story.authorAvatar,
        status: status,
        createdAt: story.createdAt,
        publishedAt: status == ContentStatus.published
            ? DateTime.now()
            : story.publishedAt,
        viewCount: story.viewCount,
        likeCount: story.likeCount,
        tags: story.tags,
        isFeatured: story.isFeatured,
      );
    }).toList();
  }

  Future<void> setStoryFeatured(String storyId, bool isFeatured) async {
    _stories = _stories.map((story) {
      if (story.id != storyId) {
        return story;
      }
      return StoryModel(
        id: story.id,
        title: story.title,
        content: story.content,
        summary: story.summary,
        coverImage: story.coverImage,
        authorId: story.authorId,
        authorName: story.authorName,
        authorAvatar: story.authorAvatar,
        status: story.status,
        createdAt: story.createdAt,
        publishedAt: story.publishedAt,
        viewCount: story.viewCount,
        likeCount: story.likeCount,
        tags: story.tags,
        isFeatured: isFeatured,
      );
    }).toList();
  }

  Future<List<CommunityContentModel>> getCommunityContent({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    ContentStatus? status,
    String? groupId,
  }) async {
    var filtered = List<CommunityContentModel>.from(_communityContent);

    if (status != null) {
      filtered = filtered.where((content) => content.status == status).toList();
    }

    if (groupId != null) {
      filtered = filtered
          .where((content) => content.groupId == groupId)
          .toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _paginate(filtered, page, pageSize);
  }

  Future<void> updateContentStatus(
    String contentId,
    ContentStatus status,
  ) async {
    _communityContent = _communityContent.map((content) {
      if (content.id != contentId) {
        return content;
      }
      return CommunityContentModel(
        id: content.id,
        content: content.content,
        imageUrl: content.imageUrl,
        authorId: content.authorId,
        authorName: content.authorName,
        authorAvatar: content.authorAvatar,
        groupId: content.groupId,
        groupName: content.groupName,
        status: status,
        createdAt: content.createdAt,
        likeCount: content.likeCount,
        commentCount: content.commentCount,
        isPinned: content.isPinned,
      );
    }).toList();
  }

  Future<List<ReportModel>> getReports({
    int page = 1,
    int pageSize = AppConstants.defaultPageSize,
    ReportStatus? status,
    ReportType? type,
  }) async {
    var filtered = List<ReportModel>.from(_reports);

    if (status != null) {
      filtered = filtered.where((report) => report.status == status).toList();
    }

    if (type != null) {
      filtered = filtered.where((report) => report.type == type).toList();
    }

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _paginate(filtered, page, pageSize);
  }

  Future<void> processReport(
    String reportId, {
    required ReportStatus status,
    required String result,
    String? action,
  }) async {
    _reports = _reports.map((report) {
      if (report.id != reportId) {
        return report;
      }
      return ReportModel(
        id: report.id,
        type: report.type,
        reason: report.reason,
        description: report.description,
        reporterId: report.reporterId,
        reporterName: report.reporterName,
        targetId: report.targetId,
        targetType: report.targetType,
        targetContent: report.targetContent,
        targetUserId: report.targetUserId,
        targetUserName: report.targetUserName,
        status: status,
        createdAt: report.createdAt,
        processedAt: DateTime.now(),
        processedBy: _currentAdmin?.id,
        processorName: _currentAdmin?.displayName,
        result: result,
        action: action,
      );
    }).toList();
  }

  Future<ReportStatistics> getReportStatistics() async {
    final counts = <ReportType, int>{
      for (final type in ReportType.values) type: 0,
    };

    for (final report in _reports) {
      counts.update(report.type, (value) => value + 1);
    }

    return ReportStatistics(
      totalReports: _reports.length,
      pendingReports: _reports
          .where((report) => report.status == ReportStatus.pending)
          .length,
      processingReports: _reports
          .where((report) => report.status == ReportStatus.processing)
          .length,
      resolvedReports: _reports
          .where((report) => report.status == ReportStatus.resolved)
          .length,
      dismissedReports: _reports
          .where((report) => report.status == ReportStatus.dismissed)
          .length,
      avgProcessTime: 3.6,
      typeDistribution: counts.entries
          .map((entry) => ReportTypeCount(type: entry.key, count: entry.value))
          .toList(),
    );
  }

  Future<List<DailyReport>> getDailyReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _dailyReports
        .where((report) => _isWithinRange(report.date, startDate, endDate))
        .toList();
  }

  Future<List<UserGrowthReport>> getUserGrowthReports({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _userGrowthReports
        .where((report) => _isWithinRange(report.date, startDate, endDate))
        .toList();
  }

  Future<List<HelpTypeStatistics>> getHelpTypeStatistics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (_helpTypeStatistics.isEmpty) {
      return const <HelpTypeStatistics>[];
    }
    return List<HelpTypeStatistics>.from(_helpTypeStatistics);
  }

  List<T> _paginate<T>(List<T> items, int page, int pageSize) {
    final start = (page - 1) * pageSize;
    if (start >= items.length || start < 0) {
      return <T>[];
    }
    final end = (start + pageSize).clamp(0, items.length);
    return items.sublist(start, end);
  }

  bool _isWithinRange(DateTime date, DateTime start, DateTime end) {
    final current = DateTime(date.year, date.month, date.day);
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    return !current.isBefore(startDate) && !current.isAfter(endDate);
  }

  double _percentChange(num current, num previous) {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }

  List<UserModel> _buildUsers(DateTime now) {
    return [
      UserModel(
        id: 'user-001',
        email: 'lin.xia@linklab.demo',
        phone: '13800000001',
        displayName: '林夏',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 90)),
        lastSignInAt: now.subtract(const Duration(hours: 2)),
        metadata: const {'region': '上海'},
        disabilityType: '視力障礙',
        disabilityDescription: '低視力，需要日常識別協助',
        verificationStatus: VerificationStatus.approved,
      ),
      UserModel(
        id: 'user-002',
        email: 'zhou.mo@linklab.demo',
        phone: '13800000002',
        displayName: '周默',
        role: UserRole.operator,
        status: UserStatus.pending,
        createdAt: now.subtract(const Duration(days: 61)),
        lastSignInAt: now.subtract(const Duration(days: 1)),
        metadata: const {'region': '北京'},
        disabilityType: '視力障礙',
        disabilityDescription: '需要陌生場景導航幫助',
        verificationStatus: VerificationStatus.pending,
      ),
      UserModel(
        id: 'user-003',
        email: 'wu.qing@linklab.demo',
        phone: '13800000003',
        displayName: '吳晴',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 42)),
        lastSignInAt: now.subtract(const Duration(hours: 10)),
        metadata: const {'region': '杭州'},
        disabilityType: '視力障礙',
        disabilityDescription: '藥品說明與標籤識別需求高',
        verificationStatus: VerificationStatus.approved,
      ),
      UserModel(
        id: 'vol-001',
        email: 'chen.yu@linklab.demo',
        phone: '13800000011',
        displayName: '陳雨',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 130)),
        lastSignInAt: now.subtract(const Duration(minutes: 35)),
        metadata: const {'region': '上海'},
        volunteerLevel: '燈塔',
        volunteerPoints: 1580,
        skills: const ['生活協助', '導盲', '情緒陪伴'],
        rating: 4.9,
        totalCalls: 226,
        totalHelpMinutes: 1540,
      ),
      UserModel(
        id: 'vol-002',
        email: 'sun.jie@linklab.demo',
        phone: '13800000012',
        displayName: '孫潔',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 118)),
        lastSignInAt: now.subtract(const Duration(hours: 4)),
        metadata: const {'region': '廣州'},
        volunteerLevel: '星辰',
        volunteerPoints: 1210,
        skills: const ['手語', '生活協助'],
        rating: 4.8,
        totalCalls: 174,
        totalHelpMinutes: 1290,
      ),
      UserModel(
        id: 'vol-003',
        email: 'tang.lin@linklab.demo',
        phone: '13800000013',
        displayName: '唐琳',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 84)),
        lastSignInAt: now.subtract(const Duration(days: 2)),
        metadata: const {'region': '深圳'},
        volunteerLevel: '暖陽',
        volunteerPoints: 860,
        skills: const ['導盲', '應急陪護'],
        rating: 4.7,
        totalCalls: 121,
        totalHelpMinutes: 890,
      ),
      UserModel(
        id: 'vol-004',
        email: 'gao.yi@linklab.demo',
        phone: '13800000014',
        displayName: '高奕',
        role: UserRole.operator,
        status: UserStatus.banned,
        createdAt: now.subtract(const Duration(days: 53)),
        lastSignInAt: now.subtract(const Duration(days: 9)),
        metadata: const {'region': '成都'},
        volunteerLevel: '微光',
        volunteerPoints: 320,
        skills: const ['生活協助'],
        rating: 3.9,
        totalCalls: 34,
        totalHelpMinutes: 210,
      ),
      UserModel(
        id: 'admin-001',
        email: AppConstants.demoAdminEmail,
        phone: '13800000999',
        displayName: '演示管理員',
        role: UserRole.admin,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 200)),
        lastSignInAt: now.subtract(const Duration(minutes: 5)),
        metadata: const {'region': '上海'},
      ),
    ];
  }

  List<StoryModel> _buildStories(DateTime now) {
    return [
      StoryModel(
        id: 'story-001',
        title: '夜間回家路上的那通電話',
        content: '在志願者遠程協助下，用戶順利完成夜間返家路線確認。',
        summary: '真實志願者協助案例，展示夜間導航與情緒安撫能力。',
        authorId: 'user-001',
        authorName: '林夏',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 12)),
        publishedAt: now.subtract(const Duration(days: 11)),
        viewCount: 428,
        likeCount: 86,
        tags: const ['真實案例', '夜間協助'],
        isFeatured: true,
      ),
      StoryModel(
        id: 'story-002',
        title: 'AI先識別，人工再確認的藥盒閱讀流程',
        content: '結合 OCR 與人工確認，將高風險場景控制在可解釋範圍內。',
        summary: '展示 AI 與人工協作的典型閉環。',
        authorId: 'user-003',
        authorName: '吳晴',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 9)),
        publishedAt: now.subtract(const Duration(days: 8)),
        viewCount: 317,
        likeCount: 63,
        tags: const ['藥品識別', 'AI協同'],
        isFeatured: false,
      ),
      StoryModel(
        id: 'story-003',
        title: '新手村陪練計劃一週覆盤',
        content: '圍繞首次通話、常見誤區與志願者反饋進行內容覆盤。',
        summary: '適合運營團隊展示內容扶持策略。',
        authorId: 'vol-002',
        authorName: '孫潔',
        status: ContentStatus.draft,
        createdAt: now.subtract(const Duration(days: 5)),
        viewCount: 105,
        likeCount: 17,
        tags: const ['社區運營', '陪練'],
        isFeatured: false,
      ),
      StoryModel(
        id: 'story-004',
        title: '城市地鐵換乘中的臨時志願協助',
        content: '通過附近志願者匹配，幫助用戶完成高峯時段換乘。',
        summary: '體現平臺的時效性與地理分發能力。',
        authorId: 'vol-003',
        authorName: '唐琳',
        status: ContentStatus.archived,
        createdAt: now.subtract(const Duration(days: 18)),
        publishedAt: now.subtract(const Duration(days: 17)),
        viewCount: 512,
        likeCount: 91,
        tags: const ['地鐵換乘', '志願匹配'],
        isFeatured: true,
      ),
    ];
  }

  List<CommunityContentModel> _buildCommunityContent(DateTime now) {
    return [
      CommunityContentModel(
        id: 'community-001',
        content: '本週五晚 8 點開展新手志願者語音陪練，歡迎報名。',
        authorId: 'vol-001',
        authorName: '陳雨',
        groupId: 'group-001',
        groupName: '志願者訓練營',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 3)),
        likeCount: 39,
        commentCount: 12,
        isPinned: true,
      ),
      CommunityContentModel(
        id: 'community-002',
        content: '求推薦適合低視力用戶的廚房標籤工具。',
        authorId: 'user-001',
        authorName: '林夏',
        groupId: 'group-002',
        groupName: '生活技巧分享',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 2)),
        likeCount: 26,
        commentCount: 8,
      ),
      CommunityContentModel(
        id: 'community-003',
        content: '地鐵換乘時如果網絡較弱，建議優先使用文字化地點描述模板。',
        authorId: 'vol-002',
        authorName: '孫潔',
        groupId: 'group-001',
        groupName: '志願者訓練營',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 1)),
        likeCount: 21,
        commentCount: 4,
      ),
      CommunityContentModel(
        id: 'community-004',
        content: '測試帖：這裏是待審覈內容示例。',
        authorId: 'user-002',
        authorName: '周默',
        groupId: 'group-003',
        groupName: '互助廣場',
        status: ContentStatus.draft,
        createdAt: now.subtract(const Duration(hours: 20)),
        likeCount: 2,
        commentCount: 0,
      ),
    ];
  }

  List<ReportModel> _buildReports(DateTime now) {
    return [
      ReportModel(
        id: 'report-001',
        type: ReportType.harassment,
        reason: '通話中語言不當',
        description: '用戶反饋志願者在通話中多次打斷並出現情緒化表達。',
        reporterId: 'user-001',
        reporterName: '林夏',
        targetId: 'vol-004',
        targetType: 'user',
        targetUserId: 'vol-004',
        targetUserName: '高奕',
        status: ReportStatus.pending,
        createdAt: now.subtract(const Duration(hours: 14)),
      ),
      ReportModel(
        id: 'report-002',
        type: ReportType.spam,
        reason: '重複灌水',
        reporterId: 'vol-001',
        reporterName: '陳雨',
        targetId: 'community-004',
        targetType: 'community',
        targetContent: '測試帖：這裏是待審覈內容示例。',
        targetUserId: 'user-002',
        targetUserName: '周默',
        status: ReportStatus.processing,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        processedAt: now.subtract(const Duration(hours: 10)),
        processedBy: 'demo-admin',
        processorName: '演示管理員',
        result: '已通知運營複覈內容語境',
        action: 'warn',
      ),
      ReportModel(
        id: 'report-003',
        type: ReportType.inappropriate,
        reason: '圖片內容不適',
        reporterId: 'user-003',
        reporterName: '吳晴',
        targetId: 'story-004',
        targetType: 'story',
        targetContent: '城市地鐵換乘中的臨時志願協助',
        targetUserId: 'vol-003',
        targetUserName: '唐琳',
        status: ReportStatus.resolved,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        processedAt: now.subtract(const Duration(days: 1, hours: 12)),
        processedBy: 'demo-admin',
        processorName: '演示管理員',
        result: '內容已下架並通知作者修改封面素材',
        action: 'delete',
      ),
      ReportModel(
        id: 'report-004',
        type: ReportType.fraud,
        reason: '疑似誘導私下轉賬',
        description: '舉報人稱在羣內被引導離開平臺交易。',
        reporterId: 'user-002',
        reporterName: '周默',
        targetId: 'user-888',
        targetType: 'user',
        targetUserId: 'user-888',
        targetUserName: '匿名用戶',
        status: ReportStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 4)),
        processedAt: now.subtract(const Duration(days: 3, hours: 6)),
        processedBy: 'demo-admin',
        processorName: '演示管理員',
        result: '覈查後未發現站內證據，建議持續觀察',
        action: 'dismiss',
      ),
    ];
  }

  List<DailyReport> _buildDailyReports(DateTime now) {
    return List<DailyReport>.generate(30, (index) {
      final dayOffset = 29 - index;
      final baseActive = 860 + index * 11;
      final totalCalls = 220 + index * 4 + (index % 5) * 6;
      final helpRequests = 150 + index * 3;
      final helpResponses = helpRequests - 18 + (index % 4) * 2;
      return DailyReport(
        date: DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: dayOffset)),
        newUsers: 18 + (index % 7),
        activeUsers: baseActive,
        totalCalls: totalCalls,
        avgCallDuration: 11.8 + (index % 4) * 0.3,
        satisfaction: 4.4 + (index % 5) * 0.06,
        helpRequests: helpRequests,
        helpResponses: helpResponses,
        responseRate: (helpResponses / helpRequests) * 100,
        aiCalls: 72 + index * 2,
        aiResolutionRate: 43 + (index % 6) * 1.3,
      );
    });
  }

  List<UserGrowthReport> _buildUserGrowthReports(DateTime now) {
    return List<UserGrowthReport>.generate(30, (index) {
      final dayOffset = 29 - index;
      return UserGrowthReport(
        date: DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: dayOffset)),
        newDisabledUsers: 4 + (index % 4),
        newVolunteerUsers: 3 + (index % 3),
        totalDisabledUsers: 430 + index * 5,
        totalVolunteerUsers: 286 + index * 4,
        activeDisabledUsers: 300 + index * 4,
        activeVolunteerUsers: 210 + index * 3,
        volunteerRetentionRate: 76 + (index % 5) * 1.1,
      );
    });
  }

  List<HelpTypeStatistics> _buildHelpTypeStatistics() {
    return [
      HelpTypeStatistics(
        type: '藥品識別',
        count: 142,
        percentage: 29.8,
        avgResponseTime: 28.0,
        avgDuration: 7.2,
        satisfaction: 4.7,
      ),
      HelpTypeStatistics(
        type: '場景描述',
        count: 118,
        percentage: 24.7,
        avgResponseTime: 24.0,
        avgDuration: 6.5,
        satisfaction: 4.6,
      ),
      HelpTypeStatistics(
        type: '緊急求助',
        count: 64,
        percentage: 13.4,
        avgResponseTime: 12.0,
        avgDuration: 9.4,
        satisfaction: 4.8,
      ),
      HelpTypeStatistics(
        type: '菜單識別',
        count: 96,
        percentage: 20.1,
        avgResponseTime: 18.0,
        avgDuration: 5.1,
        satisfaction: 4.5,
      ),
      HelpTypeStatistics(
        type: '其他',
        count: 57,
        percentage: 12.0,
        avgResponseTime: 31.0,
        avgDuration: 8.0,
        satisfaction: 4.3,
      ),
    ];
  }
}
