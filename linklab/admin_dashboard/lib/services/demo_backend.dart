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
      throw Exception('演示环境仅支持默认账号登录');
    }

    _currentAdmin = const AdminSession(
      id: 'demo-admin',
      email: AppConstants.demoAdminEmail,
      displayName: '演示管理员',
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
        user.disabilityType ?? '未标注',
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
      final region = user.metadata?['region'] as String? ?? '未分区';
      regionBuckets.update(region, (value) => value + 1, ifAbsent: () => 1);
    }

    return UserDistribution(
      userType: [
        DistributionData(name: '残障用户', value: disabledUsers.length.toDouble()),
        DistributionData(name: '志愿者', value: volunteers.length.toDouble()),
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
        disabilityType: '视力障碍',
        disabilityDescription: '低视力，需要日常识别协助',
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
        disabilityType: '视力障碍',
        disabilityDescription: '需要陌生场景导航帮助',
        verificationStatus: VerificationStatus.pending,
      ),
      UserModel(
        id: 'user-003',
        email: 'wu.qing@linklab.demo',
        phone: '13800000003',
        displayName: '吴晴',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 42)),
        lastSignInAt: now.subtract(const Duration(hours: 10)),
        metadata: const {'region': '杭州'},
        disabilityType: '视力障碍',
        disabilityDescription: '药品说明与标签识别需求高',
        verificationStatus: VerificationStatus.approved,
      ),
      UserModel(
        id: 'vol-001',
        email: 'chen.yu@linklab.demo',
        phone: '13800000011',
        displayName: '陈雨',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 130)),
        lastSignInAt: now.subtract(const Duration(minutes: 35)),
        metadata: const {'region': '上海'},
        volunteerLevel: '灯塔',
        volunteerPoints: 1580,
        skills: const ['生活协助', '导盲', '情绪陪伴'],
        rating: 4.9,
        totalCalls: 226,
        totalHelpMinutes: 1540,
      ),
      UserModel(
        id: 'vol-002',
        email: 'sun.jie@linklab.demo',
        phone: '13800000012',
        displayName: '孙洁',
        role: UserRole.operator,
        status: UserStatus.active,
        createdAt: now.subtract(const Duration(days: 118)),
        lastSignInAt: now.subtract(const Duration(hours: 4)),
        metadata: const {'region': '广州'},
        volunteerLevel: '星辰',
        volunteerPoints: 1210,
        skills: const ['手语', '生活协助'],
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
        volunteerLevel: '暖阳',
        volunteerPoints: 860,
        skills: const ['导盲', '应急陪护'],
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
        skills: const ['生活协助'],
        rating: 3.9,
        totalCalls: 34,
        totalHelpMinutes: 210,
      ),
      UserModel(
        id: 'admin-001',
        email: AppConstants.demoAdminEmail,
        phone: '13800000999',
        displayName: '演示管理员',
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
        title: '夜间回家路上的那通电话',
        content: '在志愿者远程协助下，用户顺利完成夜间返家路线确认。',
        summary: '真实志愿者协助案例，展示夜间导航与情绪安抚能力。',
        authorId: 'user-001',
        authorName: '林夏',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 12)),
        publishedAt: now.subtract(const Duration(days: 11)),
        viewCount: 428,
        likeCount: 86,
        tags: const ['真实案例', '夜间协助'],
        isFeatured: true,
      ),
      StoryModel(
        id: 'story-002',
        title: 'AI先识别，人工再确认的药盒阅读流程',
        content: '结合 OCR 与人工确认，将高风险场景控制在可解释范围内。',
        summary: '展示 AI 与人工协作的典型闭环。',
        authorId: 'user-003',
        authorName: '吴晴',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 9)),
        publishedAt: now.subtract(const Duration(days: 8)),
        viewCount: 317,
        likeCount: 63,
        tags: const ['药品识别', 'AI协同'],
        isFeatured: false,
      ),
      StoryModel(
        id: 'story-003',
        title: '新手村陪练计划一周覆盘',
        content: '围绕首次通话、常见误区与志愿者反馈进行内容覆盘。',
        summary: '适合运营团队展示内容扶持策略。',
        authorId: 'vol-002',
        authorName: '孙洁',
        status: ContentStatus.draft,
        createdAt: now.subtract(const Duration(days: 5)),
        viewCount: 105,
        likeCount: 17,
        tags: const ['社区运营', '陪练'],
        isFeatured: false,
      ),
      StoryModel(
        id: 'story-004',
        title: '城市地铁换乘中的临时志愿协助',
        content: '通过附近志愿者匹配，帮助用户完成高峰时段换乘。',
        summary: '体现平台的时效性与地理分发能力。',
        authorId: 'vol-003',
        authorName: '唐琳',
        status: ContentStatus.archived,
        createdAt: now.subtract(const Duration(days: 18)),
        publishedAt: now.subtract(const Duration(days: 17)),
        viewCount: 512,
        likeCount: 91,
        tags: const ['地铁换乘', '志愿匹配'],
        isFeatured: true,
      ),
    ];
  }

  List<CommunityContentModel> _buildCommunityContent(DateTime now) {
    return [
      CommunityContentModel(
        id: 'community-001',
        content: '本周五晚 8 点开展新手志愿者语音陪练，欢迎报名。',
        authorId: 'vol-001',
        authorName: '陈雨',
        groupId: 'group-001',
        groupName: '志愿者训练营',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 3)),
        likeCount: 39,
        commentCount: 12,
        isPinned: true,
      ),
      CommunityContentModel(
        id: 'community-002',
        content: '求推荐适合低视力用户的厨房标签工具。',
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
        content: '地铁换乘时如果网络较弱，建议优先使用文字化地点描述模板。',
        authorId: 'vol-002',
        authorName: '孙洁',
        groupId: 'group-001',
        groupName: '志愿者训练营',
        status: ContentStatus.published,
        createdAt: now.subtract(const Duration(days: 1)),
        likeCount: 21,
        commentCount: 4,
      ),
      CommunityContentModel(
        id: 'community-004',
        content: '测试帖：这里是待审核内容示例。',
        authorId: 'user-002',
        authorName: '周默',
        groupId: 'group-003',
        groupName: '互助广场',
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
        reason: '通话中语言不当',
        description: '用户反馈志愿者在通话中多次打断并出现情绪化表达。',
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
        reason: '重复灌水',
        reporterId: 'vol-001',
        reporterName: '陈雨',
        targetId: 'community-004',
        targetType: 'community',
        targetContent: '测试帖：这里是待审核内容示例。',
        targetUserId: 'user-002',
        targetUserName: '周默',
        status: ReportStatus.processing,
        createdAt: now.subtract(const Duration(days: 1, hours: 4)),
        processedAt: now.subtract(const Duration(hours: 10)),
        processedBy: 'demo-admin',
        processorName: '演示管理员',
        result: '已通知运营复核内容语境',
        action: 'warn',
      ),
      ReportModel(
        id: 'report-003',
        type: ReportType.inappropriate,
        reason: '图片内容不适',
        reporterId: 'user-003',
        reporterName: '吴晴',
        targetId: 'story-004',
        targetType: 'story',
        targetContent: '城市地铁换乘中的临时志愿协助',
        targetUserId: 'vol-003',
        targetUserName: '唐琳',
        status: ReportStatus.resolved,
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        processedAt: now.subtract(const Duration(days: 1, hours: 12)),
        processedBy: 'demo-admin',
        processorName: '演示管理员',
        result: '内容已下架并通知作者修改封面素材',
        action: 'delete',
      ),
      ReportModel(
        id: 'report-004',
        type: ReportType.fraud,
        reason: '疑似诱导私下转账',
        description: '举报人称在群内被引导离开平台交易。',
        reporterId: 'user-002',
        reporterName: '周默',
        targetId: 'user-888',
        targetType: 'user',
        targetUserId: 'user-888',
        targetUserName: '匿名用户',
        status: ReportStatus.dismissed,
        createdAt: now.subtract(const Duration(days: 4)),
        processedAt: now.subtract(const Duration(days: 3, hours: 6)),
        processedBy: 'demo-admin',
        processorName: '演示管理员',
        result: '核查后未发现站内证据，建议持续观察',
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
        type: '药品识别',
        count: 142,
        percentage: 29.8,
        avgResponseTime: 28.0,
        avgDuration: 7.2,
        satisfaction: 4.7,
      ),
      HelpTypeStatistics(
        type: '场景描述',
        count: 118,
        percentage: 24.7,
        avgResponseTime: 24.0,
        avgDuration: 6.5,
        satisfaction: 4.6,
      ),
      HelpTypeStatistics(
        type: '紧急求助',
        count: 64,
        percentage: 13.4,
        avgResponseTime: 12.0,
        avgDuration: 9.4,
        satisfaction: 4.8,
      ),
      HelpTypeStatistics(
        type: '菜单识别',
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
