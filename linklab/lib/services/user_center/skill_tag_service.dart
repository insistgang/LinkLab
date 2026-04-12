import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/skill_model.dart';

/// 技能标签服务 (F19)
/// 管理志愿者的技能标签和认证
class SkillTagService {
  final SupabaseClient _supabase;

  SkillTagService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// 获取所有预设技能标签
  List<SkillModel> getAllPredefinedSkills() {
    return SkillDefinitions.all;
  }

  /// 按分类获取技能
  List<SkillModel> getSkillsByCategory(String category) {
    return SkillDefinitions.getByCategory(category);
  }

  /// 获取所有分类
  List<String> getCategories() {
    return SkillDefinitions.categories;
  }

  /// 获取志愿者的技能列表
  Future<List<SkillModel>> getVolunteerSkills(String volunteerId) async {
    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('skills')
          .eq('user_id', volunteerId)
          .single();

      final skillIds = (response['skills'] as List?)?.cast<String>() ?? [];

      // 转换为完整技能对象
      return skillIds
          .map((id) => SkillDefinitions.getById(id))
          .where((s) => s != null)
          .cast<SkillModel>()
          .toList();
    } catch (e) {
      AppLogger.error('获取志愿者技能失败', e);
      return [];
    }
  }

  /// 更新志愿者技能（仅自选标签）
  Future<bool> updateSkills(
    String volunteerId,
    List<String> skillIds,
  ) async {
    try {
      // 验证技能ID
      final validSkills = skillIds
          .where((id) {
            final skill = SkillDefinitions.getById(id);
            return skill != null && !skill.requiresVerification;
          })
          .toList();

      // 获取当前已认证的技能
      final currentResponse = await _supabase
          .from('volunteer_profiles')
          .select('skills')
          .eq('user_id', volunteerId)
          .single();

      final currentSkills = (currentResponse['skills'] as List?)?.cast<String>() ?? [];

      // 保留已认证的技能
      final verifiedSkills = currentSkills.where((id) {
        final skill = SkillDefinitions.getById(id);
        return skill?.isVerified ?? false;
      }).toList();

      // 合并技能列表
      final updatedSkills = [...verifiedSkills, ...validSkills];

      await _supabase
          .from('volunteer_profiles')
          .update({'skills': updatedSkills})
          .eq('user_id', volunteerId);

      AppLogger.info('更新志愿者技能成功: $volunteerId, 技能数: ${updatedSkills.length}');
      return true;
    } catch (e) {
      AppLogger.error('更新志愿者技能失败', e);
      return false;
    }
  }

  /// 提交技能认证申请
  Future<bool> verifySkill(
    String volunteerId,
    String skillId,
    File certificate, {
    String? description,
  }) async {
    try {
      final skill = SkillDefinitions.getById(skillId);
      if (skill == null || !skill.requiresVerification) {
        AppLogger.warning('技能不需要认证: $skillId');
        return false;
      }

      // 上传证书图片
      final fileName = 'skill_cert_${volunteerId}_${skillId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'skill_certificates/$fileName';

      await _supabase.storage
          .from('certificates')
          .upload(filePath, certificate);

      // 获取公开URL
      final certificateUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(filePath);

      // 创建认证申请
      await _supabase.from('skill_verification_requests').insert({
        'volunteer_id': volunteerId,
        'skill_id': skillId,
        'skill_name': skill.name,
        'certificate_url': certificateUrl,
        'description': description,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('提交技能认证申请: $volunteerId - $skillId');
      return true;
    } catch (e) {
      AppLogger.error('提交技能认证申请失败', e);
      return false;
    }
  }

  /// 获取认证申请状态
  Future<List<SkillVerificationRequest>> getVerificationRequests(
    String volunteerId,
  ) async {
    try {
      final response = await _supabase
          .from('skill_verification_requests')
          .select()
          .eq('volunteer_id', volunteerId)
          .order('submitted_at', ascending: false);

      return (response as List)
          .map((json) => SkillVerificationRequest.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取认证申请失败', e);
      return [];
    }
  }

  /// 获取已认证的技能
  Future<List<SkillModel>> getVerifiedSkills(String volunteerId) async {
    try {
      final response = await _supabase
          .from('volunteer_skills')
          .select('skill_id, verified_at')
          .eq('volunteer_id', volunteerId)
          .eq('is_verified', true);

      final verifiedSkillIds = (response as List)
          .map((r) => r['skill_id'] as String)
          .toList();

      return verifiedSkillIds
          .map((id) => SkillDefinitions.getById(id))
          .where((s) => s != null)
          .cast<SkillModel>()
          .map((s) => s.copyWith(isVerified: true))
          .toList();
    } catch (e) {
      AppLogger.error('获取已认证技能失败', e);
      return [];
    }
  }

  /// 检查技能是否已认证
  Future<bool> isSkillVerified(String volunteerId, String skillId) async {
    try {
      final response = await _supabase
          .from('volunteer_skills')
          .select()
          .eq('volunteer_id', volunteerId)
          .eq('skill_id', skillId)
          .eq('is_verified', true)
          .maybeSingle();

      return response != null;
    } catch (e) {
      AppLogger.error('检查技能认证状态失败', e);
      return false;
    }
  }

  /// 获取技能统计
  Future<SkillStats> getSkillStats(String volunteerId) async {
    try {
      final allSkills = await getVolunteerSkills(volunteerId);
      final verifiedSkills = await getVerifiedSkills(volunteerId);

      // 按分类统计
      final categoryCount = <String, int>{};
      for (final skill in allSkills) {
        if (skill.category != null) {
          categoryCount[skill.category!] = (categoryCount[skill.category!] ?? 0) + 1;
        }
      }

      return SkillStats(
        totalSkills: allSkills.length,
        verifiedSkills: verifiedSkills.length,
        pendingSkills: allSkills.length - verifiedSkills.length,
        categoryDistribution: categoryCount,
      );
    } catch (e) {
      AppLogger.error('获取技能统计失败', e);
      return const SkillStats();
    }
  }

  /// 搜索技能
  List<SkillModel> searchSkills(String query) {
    final allSkills = SkillDefinitions.all;
    final lowerQuery = query.toLowerCase();

    return allSkills.where((skill) {
      return skill.name.toLowerCase().contains(lowerQuery) ||
          (skill.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// 获取我的技能（别名方法，兼容UI调用）
  Future<List<SkillModel>> getMySkills(String volunteerId) async {
    return getVolunteerSkills(volunteerId);
  }

  /// 获取待认证申请（别名方法，兼容UI调用）
  Future<List<SkillVerificationRequest>> getPendingRequests(String volunteerId) async {
    final requests = await getVerificationRequests(volunteerId);
    return requests.where((r) => r.status == 'pending').toList();
  }

  /// 添加技能（别名方法，兼容UI调用）
  Future<bool> addSkill(String volunteerId, String skillId) async {
    final currentSkills = await getVolunteerSkills(volunteerId);
    final currentIds = currentSkills.map((s) => s.id).toList();
    if (!currentIds.contains(skillId)) {
      currentIds.add(skillId);
    }
    return updateSkills(volunteerId, currentIds);
  }

  /// 移除技能（别名方法，兼容UI调用）
  Future<bool> removeSkill(String volunteerId, String skillId) async {
    final currentSkills = await getVolunteerSkills(volunteerId);
    final currentIds = currentSkills.map((s) => s.id).toList();
    currentIds.remove(skillId);
    return updateSkills(volunteerId, currentIds);
  }

  /// 获取推荐技能（根据帮助历史）
  Future<List<SkillModel>> getRecommendedSkills(String volunteerId) async {
    try {
      // 获取帮助历史中的意图类型
      final response = await _supabase
          .from('help_requests')
          .select('intent')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .limit(100);

      final intents = (response as List)
          .map((r) => r['intent'] as String?)
          .where((i) => i != null)
          .cast<String>()
          .toList();

      // 根据意图推荐技能
      final recommendations = <SkillModel>[];

      // 简单的推荐逻辑
      if (intents.any((i) => i.contains('翻译') || i.contains('英文'))) {
        final skill = SkillDefinitions.getById('lang_english');
        if (skill != null) recommendations.add(skill);
      }

      if (intents.any((i) => i.contains('手机') || i.contains('电脑'))) {
        final skill = SkillDefinitions.getById('tech_mobile');
        if (skill != null) recommendations.add(skill);
      }

      if (intents.any((i) => i.contains('药') || i.contains('医院'))) {
        final skill = SkillDefinitions.getById('medical_basic');
        if (skill != null) recommendations.add(skill);
      }

      return recommendations;
    } catch (e) {
      AppLogger.error('获取推荐技能失败', e);
      return [];
    }
  }
}

/// 技能统计
class SkillStats {
  final int totalSkills;
  final int verifiedSkills;
  final int pendingSkills;
  final Map<String, int> categoryDistribution;

  const SkillStats({
    this.totalSkills = 0,
    this.verifiedSkills = 0,
    this.pendingSkills = 0,
    this.categoryDistribution = const {},
  });

  /// 认证率
  double get verificationRate {
    if (totalSkills == 0) return 0.0;
    return verifiedSkills / totalSkills;
  }
}
