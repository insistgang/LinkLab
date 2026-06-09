import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/logger.dart';
import '../../models/skill_model.dart';
import 'volunteer_demo_store.dart';

/// 技能標籤服務 (F19)
/// 管理志願者的技能標籤和認證
class SkillTagService {
  SkillTagService({
    SupabaseClient? supabase,
    VolunteerDemoStore? demoStore,
  })  : _supabaseClient = supabase,
        _demoStore = demoStore ?? VolunteerDemoStore();

  SupabaseClient? _supabaseClient;
  final VolunteerDemoStore _demoStore;

  bool get _hasSupabase => Supabase.instance.isInitialized;

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 獲取所有預設技能標籤
  List<SkillModel> getAllPredefinedSkills() {
    return SkillDefinitions.all;
  }

  /// 按分類獲取技能
  List<SkillModel> getSkillsByCategory(String category) {
    return SkillDefinitions.getByCategory(category);
  }

  /// 獲取所有分類
  List<String> getCategories() {
    return SkillDefinitions.categories;
  }

  /// 獲取志願者的技能列表
  Future<List<SkillModel>> getVolunteerSkills(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        return await _demoStore.getSkills(volunteerId);
      } catch (e) {
        AppLogger.error('獲取本地志願者技能失敗', e);
        return [];
      }
    }

    try {
      final response = await _supabase
          .from('volunteer_profiles')
          .select('skills')
          .eq('user_id', volunteerId)
          .single();

      final skillIds = (response['skills'] as List?)?.cast<String>() ?? [];

      // 轉換爲完整技能對象
      return skillIds
          .map((id) => SkillDefinitions.getById(id))
          .where((s) => s != null)
          .cast<SkillModel>()
          .toList();
    } catch (e) {
      AppLogger.error('獲取志願者技能失敗', e);
      return [];
    }
  }

  /// 更新志願者技能（僅自選標籤）
  Future<bool> updateSkills(
    String volunteerId,
    List<String> skillIds,
  ) async {
    if (!_hasSupabase) {
      try {
        final currentSkills = await _demoStore.getSkills(volunteerId);
        final updatedSkills = <SkillModel>[];

        for (final skillId in skillIds.toSet()) {
          final definition = SkillDefinitions.getById(skillId);
          if (definition == null) continue;

          final existing = currentSkills.where((item) => item.id == skillId).toList();
          if (existing.isNotEmpty) {
            updatedSkills.add(existing.first);
            continue;
          }

          if (definition.requiresVerification) {
            continue;
          }

          updatedSkills.add(definition.copyWith(isVerified: true));
        }

        for (final skill in currentSkills) {
          if (skill.requiresVerification && skill.isVerified) {
            final exists = updatedSkills.any((item) => item.id == skill.id);
            if (!exists) {
              updatedSkills.add(skill);
            }
          }
        }

        await _demoStore.saveSkills(volunteerId, updatedSkills);
        return true;
      } catch (e) {
        AppLogger.error('更新本地志願者技能失敗', e);
        return false;
      }
    }

    try {
      // 驗證技能ID
      final validSkills = skillIds
          .where((id) {
            final skill = SkillDefinitions.getById(id);
            return skill != null && !skill.requiresVerification;
          })
          .toList();

      // 獲取當前已認證的技能
      final currentResponse = await _supabase
          .from('volunteer_profiles')
          .select('skills')
          .eq('user_id', volunteerId)
          .single();

      final currentSkills = (currentResponse['skills'] as List?)?.cast<String>() ?? [];

      // 保留已認證的技能
      final verifiedSkills = currentSkills.where((id) {
        final skill = SkillDefinitions.getById(id);
        return skill?.isVerified ?? false;
      }).toList();

      // 合併技能列表
      final updatedSkills = [...verifiedSkills, ...validSkills];

      await _supabase
          .from('volunteer_profiles')
          .update({'skills': updatedSkills})
          .eq('user_id', volunteerId);

      AppLogger.info('更新志願者技能成功: $volunteerId, 技能數: ${updatedSkills.length}');
      return true;
    } catch (e) {
      AppLogger.error('更新志願者技能失敗', e);
      return false;
    }
  }

  /// 提交技能認證申請
  Future<bool> verifySkill(
    String volunteerId,
    String skillId,
    File certificate, {
    String? description,
  }) async {
    if (!_hasSupabase) {
      return submitVerificationRequest(
        volunteerId,
        skillId,
        description: description,
      );
    }

    try {
      final skill = SkillDefinitions.getById(skillId);
      if (skill == null || !skill.requiresVerification) {
        AppLogger.warning('技能不需要認證: $skillId');
        return false;
      }

      // 上傳證書圖片
      final fileName = 'skill_cert_${volunteerId}_${skillId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'skill_certificates/$fileName';

      await _supabase.storage
          .from('certificates')
          .upload(filePath, certificate);

      // 獲取公開URL
      final certificateUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(filePath);

      // 創建認證申請
      await _supabase.from('skill_verification_requests').insert({
        'volunteer_id': volunteerId,
        'skill_id': skillId,
        'skill_name': skill.name,
        'certificate_url': certificateUrl,
        'description': description,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('提交技能認證申請: $volunteerId - $skillId');
      return true;
    } catch (e) {
      AppLogger.error('提交技能認證申請失敗', e);
      return false;
    }
  }

  /// 獲取認證申請狀態
  Future<List<SkillVerificationRequest>> getVerificationRequests(
    String volunteerId,
  ) async {
    if (!_hasSupabase) {
      try {
        return await _demoStore.getSkillRequests(volunteerId);
      } catch (e) {
        AppLogger.error('獲取本地認證申請失敗', e);
        return [];
      }
    }

    try {
      final response = await _supabase
          .from('skill_verification_requests')
          .select()
          .eq('volunteer_id', volunteerId)
          .order('submitted_at', ascending: false);

      return (response as List)
          .map(
            (json) => SkillVerificationRequest.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('獲取認證申請失敗', e);
      return [];
    }
  }

  /// 獲取已認證的技能
  Future<List<SkillModel>> getVerifiedSkills(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final skills = await _demoStore.getSkills(volunteerId);
        return skills.where((item) => item.isVerified).toList();
      } catch (e) {
        AppLogger.error('獲取本地已認證技能失敗', e);
        return [];
      }
    }

    try {
      final response = await _supabase
          .from('volunteer_skills')
          .select('skill_id, verified_at')
          .eq('volunteer_id', volunteerId)
          .eq('is_verified', true);

      final verifiedSkillIds = (response as List)
          .map((r) {
            final item = Map<String, dynamic>.from(r as Map);
            return item['skill_id']?.toString();
          })
          .whereType<String>()
          .toList();

      return verifiedSkillIds
          .map((id) => SkillDefinitions.getById(id))
          .where((s) => s != null)
          .cast<SkillModel>()
          .map((s) => s.copyWith(isVerified: true))
          .toList();
    } catch (e) {
      AppLogger.error('獲取已認證技能失敗', e);
      return [];
    }
  }

  /// 檢查技能是否已認證
  Future<bool> isSkillVerified(String volunteerId, String skillId) async {
    if (!_hasSupabase) {
      final skills = await _demoStore.getSkills(volunteerId);
      return skills.any((item) => item.id == skillId && item.isVerified);
    }

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
      AppLogger.error('檢查技能認證狀態失敗', e);
      return false;
    }
  }

  /// 獲取技能統計
  Future<SkillStats> getSkillStats(String volunteerId) async {
    try {
      final allSkills = await getVolunteerSkills(volunteerId);
      final verifiedSkills = await getVerifiedSkills(volunteerId);

      // 按分類統計
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
      AppLogger.error('獲取技能統計失敗', e);
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

  /// 獲取我的技能（別名方法，兼容UI調用）
  Future<List<SkillModel>> getMySkills(String volunteerId) async {
    return getVolunteerSkills(volunteerId);
  }

  /// 獲取待認證申請（別名方法，兼容UI調用）
  Future<List<SkillVerificationRequest>> getPendingRequests(String volunteerId) async {
    final requests = await getVerificationRequests(volunteerId);
    return requests.where((r) => r.status == 'pending').toList();
  }

  /// 添加技能（別名方法，兼容UI調用）
  Future<bool> addSkill(String volunteerId, String skillId) async {
    final currentSkills = await getVolunteerSkills(volunteerId);
    final currentIds = currentSkills.map((s) => s.id).toList();
    if (!currentIds.contains(skillId)) {
      currentIds.add(skillId);
    }
    return updateSkills(volunteerId, currentIds);
  }

  /// 移除技能（別名方法，兼容UI調用）
  Future<bool> removeSkill(String volunteerId, String skillId) async {
    final currentSkills = await getVolunteerSkills(volunteerId);
    final currentIds = currentSkills.map((s) => s.id).toList();
    currentIds.remove(skillId);
    return updateSkills(volunteerId, currentIds);
  }

  /// 獲取推薦技能（根據幫助歷史）
  Future<List<SkillModel>> getRecommendedSkills(String volunteerId) async {
    if (!_hasSupabase) {
      try {
        final currentSkillIds = (await _demoStore.getSkills(volunteerId))
            .map((item) => item.id)
            .toSet();
        return SkillDefinitions.all
            .where((item) => !currentSkillIds.contains(item.id))
            .take(3)
            .toList();
      } catch (e) {
        AppLogger.error('獲取本地推薦技能失敗', e);
        return [];
      }
    }

    try {
      // 獲取幫助歷史中的意圖類型
      final response = await _supabase
          .from('help_requests')
          .select('intent')
          .eq('volunteer_id', volunteerId)
          .eq('status', 'completed')
          .limit(100);

      final intents = (response as List)
          .map((r) {
            final item = Map<String, dynamic>.from(r as Map);
            return item['intent']?.toString();
          })
          .where((i) => i != null)
          .cast<String>()
          .toList();

      // 根據意圖推薦技能
      final recommendations = <SkillModel>[];

      // 簡單的推薦邏輯
      if (intents.any((i) => i.contains('翻譯') || i.contains('英文'))) {
        final skill = SkillDefinitions.getById('lang_english');
        if (skill != null) recommendations.add(skill);
      }

      if (intents.any((i) => i.contains('手機') || i.contains('電腦'))) {
        final skill = SkillDefinitions.getById('tech_mobile');
        if (skill != null) recommendations.add(skill);
      }

      if (intents.any((i) => i.contains('藥') || i.contains('醫院'))) {
        final skill = SkillDefinitions.getById('medical_basic');
        if (skill != null) recommendations.add(skill);
      }

      return recommendations;
    } catch (e) {
      AppLogger.error('獲取推薦技能失敗', e);
      return [];
    }
  }

  /// 提交技能認證申請
  Future<bool> submitVerificationRequest(
    String volunteerId,
    String skillId, {
    String? description,
  }) async {
    final skill = SkillDefinitions.getById(skillId);
    if (skill == null || !skill.requiresVerification) {
      return false;
    }

    if (!_hasSupabase) {
      try {
        final requests = await _demoStore.getSkillRequests(volunteerId);
        final existsPending = requests.any(
          (item) => item.skillId == skillId && item.status == 'pending',
        );
        if (existsPending) {
          return false;
        }

        requests.insert(
          0,
          SkillVerificationRequest(
            id: 'skill_request_${DateTime.now().microsecondsSinceEpoch}',
            volunteerId: volunteerId,
            skillId: skillId,
            skillName: skill.name,
            description: description,
            status: 'pending',
            submittedAt: DateTime.now(),
          ),
        );
        await _demoStore.saveSkillRequests(volunteerId, requests);
        return true;
      } catch (e) {
        AppLogger.error('提交本地技能認證申請失敗', e);
        return false;
      }
    }

    try {
      await _supabase.from('skill_verification_requests').insert({
        'volunteer_id': volunteerId,
        'skill_id': skillId,
        'skill_name': skill.name,
        'description': description,
        'status': 'pending',
        'submitted_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      AppLogger.error('提交技能認證申請失敗', e);
      return false;
    }
  }
}

/// 技能統計
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

  /// 認證率
  double get verificationRate {
    if (totalSkills == 0) return 0.0;
    return verifiedSkills / totalSkills;
  }
}
