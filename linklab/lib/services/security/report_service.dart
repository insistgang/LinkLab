import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/report_model.dart';
import 'credit_score_service.dart';
import 'blacklist_service.dart';

/// 举报服务
class ReportService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  CreditScoreService? _creditScoreServiceInstance;
  CreditScoreService get _creditScoreService {
    _creditScoreServiceInstance ??= CreditScoreService();
    return _creditScoreServiceInstance!;
  }

  BlacklistService? _blacklistServiceInstance;
  BlacklistService get _blacklistService {
    _blacklistServiceInstance ??= BlacklistService();
    return _blacklistServiceInstance!;
  }

  /// 提交举报
  Future<Report?> submitReport({
    required String reporterId,
    required String reportedId,
    required ReportReason reason,
    String? description,
    List<File>? evidenceFiles,
    String? callId,
    String? helpRequestId,
  }) async {
    try {
      // 检查是否重复举报
      final existingReport = await _getExistingReport(
        reporterId,
        reportedId,
        callId,
      );
      if (existingReport != null) {
        AppLogger.warning('已经举报过此用户');
        return existingReport;
      }

      // 上传证据图片
      final evidenceUrls = <String>[];
      if (evidenceFiles != null && evidenceFiles.isNotEmpty) {
        for (final file in evidenceFiles) {
          final fileName =
              'evidence_${DateTime.now().millisecondsSinceEpoch}_${evidenceUrls.length}.jpg';
          final filePath = 'reports/$fileName';

          await _supabase.storage.from('evidence').upload(filePath, file);

          final url = _supabase.storage.from('evidence').getPublicUrl(filePath);
          evidenceUrls.add(url);
        }
      }

      final report = Report(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        reporterId: reporterId,
        reportedId: reportedId,
        reason: reason.name,
        description: description,
        evidenceUrls: evidenceUrls,
        callId: callId,
        helpRequestId: helpRequestId,
        status: ReportStatus.pending,
        submittedAt: DateTime.now(),
      );

      // 保存举报记录
      await _supabase.from('reports').insert({
        'id': report.id,
        'reporter_id': reporterId,
        'reported_id': reportedId,
        'reason': reason.name,
        'description': description,
        'evidence_urls': evidenceUrls,
        'call_id': callId,
        'help_request_id': helpRequestId,
        'status': 'pending',
        'submitted_at': report.submittedAt?.toIso8601String(),
      });

      // 临时冻结双方匹配（24小时）
      await _temporaryFreeze(reporterId, reportedId);

      // 更新举报统计
      await _updateReportStatistics(reportedId);

      AppLogger.info('举报提交成功: ${report.id}');
      return report;
    } catch (e) {
      AppLogger.error('提交举报失败', e);
      rethrow;
    }
  }

  /// 处理举报
  Future<void> processReport({
    required String reportId,
    required ReportDecision decision,
    String? reviewNote,
    String? reviewerId,
  }) async {
    try {
      final report = await getReport(reportId);
      if (report == null) {
        throw Exception('举报记录不存在');
      }

      // 更新举报状态
      await _supabase.from('reports').update({
        'status': 'resolved',
        'decision': decision.name,
        'review_note': reviewNote,
        'reviewer_id': reviewerId,
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', reportId);

      if (decision == ReportDecision.valid) {
        // 举报成立，处理被举报人
        await _handleValidReport(report);
      } else {
        // 举报不成立，恢复匹配
        await _unfreezeUser(report.reporterId);
        await _unfreezeUser(report.reportedId);
      }

      AppLogger.info('举报处理完成: $reportId, 结果: ${decision.name}');
    } catch (e) {
      AppLogger.error('处理举报失败', e);
      rethrow;
    }
  }

  /// 获取举报详情
  Future<Report?> getReport(String reportId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('id', reportId)
          .single();

      return Report.fromJson(response);
    } catch (e) {
      AppLogger.error('获取举报详情失败', e);
      return null;
    }
  }

  /// 获取用户收到的举报
  Future<List<Report>> getUserReports(
    String userId, {
    ReportStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('reports')
          .select()
          .eq('reported_id', userId);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Report.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取用户举报失败', e);
      return [];
    }
  }

  /// 获取待处理举报列表（用于管理后台）
  Future<List<Report>> getPendingReports({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('reports')
          .select()
          .eq('status', 'pending')
          .order('submitted_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Report.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取待处理举报失败', e);
      return [];
    }
  }

  /// 获取举报统计
  Future<ReportStatistics> getReportStatistics(String userId) async {
    try {
      final response = await _supabase
          .from('reports')
          .select('status, decision')
          .eq('reported_id', userId);

      int total = 0;
      int valid = 0;
      int invalid = 0;
      int pending = 0;

      for (final record in response) {
        total++;
        final status = record['status'] as String;
        final decision = record['decision'] as String?;

        if (status == 'pending') {
          pending++;
        } else if (decision == 'valid') {
          valid++;
        } else if (decision == 'invalid') {
          invalid++;
        }
      }

      return ReportStatistics(
        userId: userId,
        totalReportsReceived: total,
        validReports: valid,
        invalidReports: invalid,
        pendingReports: pending,
      );
    } catch (e) {
      AppLogger.error('获取举报统计失败', e);
      return ReportStatistics(
        userId: userId,
        totalReportsReceived: 0,
        validReports: 0,
        invalidReports: 0,
        pendingReports: 0,
      );
    }
  }

  /// 检查是否存在重复举报
  Future<Report?> _getExistingReport(
    String reporterId,
    String reportedId,
    String? callId,
  ) async {
    try {
      var query = _supabase
          .from('reports')
          .select()
          .eq('reporter_id', reporterId)
          .eq('reported_id', reportedId);

      if (callId != null) {
        query = query.eq('call_id', callId);
      }

      final response = await query.maybeSingle();

      if (response == null) return null;
      return Report.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 临时冻结用户匹配
  Future<void> _temporaryFreeze(String reporterId, String reportedId) async {
    final freezeUntil = DateTime.now().add(const Duration(hours: 24));

    await _supabase.from('user_restrictions').upsert([
      {
        'user_id': reporterId,
        'type': 'temporary_freeze',
        'reason': '举报处理中',
        'expires_at': freezeUntil.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
      {
        'user_id': reportedId,
        'type': 'temporary_freeze',
        'reason': '被举报，处理中',
        'expires_at': freezeUntil.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      },
    ]);

    AppLogger.info('临时冻结用户匹配: $reporterId, $reportedId');
  }

  /// 解冻用户
  Future<void> _unfreezeUser(String userId) async {
    await _supabase
        .from('user_restrictions')
        .delete()
        .eq('user_id', userId)
        .eq('type', 'temporary_freeze');

    AppLogger.info('解冻用户: $userId');
  }

  /// 处理举报成立
  Future<void> _handleValidReport(Report report) async {
    // 扣除信用分
    await _creditScoreService.processValidReport(report.reportedId);

    // 获取用户被举报统计
    final stats = await getReportStatistics(report.reportedId);

    // 根据被举报次数决定处罚
    if (stats.validReports >= 5) {
      // 多次违规，永久封号
      await _blacklistService.addToBlacklist(
        userId: report.reportedId,
        level: BlacklistLevel.user,
        reason: '多次违规被举报',
      );
    } else if (stats.validReports >= 3) {
      // 严重违规，封号30天
      await _blacklistService.addToBlacklist(
        userId: report.reportedId,
        level: BlacklistLevel.user,
        reason: '多次违规被举报',
        duration: const Duration(days: 30),
      );
    } else if (stats.validReports >= 1) {
      // 首次违规，警告+封号7天
      await _blacklistService.addToBlacklist(
        userId: report.reportedId,
        level: BlacklistLevel.user,
        reason: '违规被举报',
        duration: const Duration(days: 7),
      );
    }

    // 解冻举报人
    await _unfreezeUser(report.reporterId);
  }

  /// 更新举报统计
  Future<void> _updateReportStatistics(String userId) async {
    try {
      final stats = await getReportStatistics(userId);

      await _supabase.from('report_statistics').upsert({
        'user_id': userId,
        'total_reports_received': stats.totalReportsReceived,
        'valid_reports': stats.validReports,
        'invalid_reports': stats.invalidReports,
        'pending_reports': stats.pendingReports,
        'last_report_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('更新举报统计失败', e);
    }
  }

  /// 检查用户是否被限制匹配
  Future<bool> isUserRestricted(String userId) async {
    try {
      final response = await _supabase
          .from('user_restrictions')
          .select()
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// 获取用户限制信息
  Future<Map<String, dynamic>?> getUserRestriction(String userId) async {
    try {
      final response = await _supabase
          .from('user_restrictions')
          .select()
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}
