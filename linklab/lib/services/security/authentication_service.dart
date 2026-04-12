import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/auth_level_model.dart';

/// 认证服务 - 多级认证体系
class AuthenticationService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 获取用户认证状态
  Future<UserAuthStatus?> getUserAuthStatus(String userId) async {
    try {
      final response = await _supabase
          .from('user_auth_status')
          .select('*, skill_certifications(*)')
          .eq('user_id', userId)
          .single();

      return UserAuthStatus.fromJson(response);
    } catch (e) {
      AppLogger.error('获取用户认证状态失败', e);
      return null;
    }
  }

  /// 验证手机号
  Future<void> verifyPhone(String phone, String code) async {
    try {
      await _supabase.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );
      AppLogger.info('手机号验证成功: $phone');
    } catch (e) {
      AppLogger.error('手机号验证失败', e);
      rethrow;
    }
  }

  /// 提交实名认证
  Future<void> submitRealNameVerification({
    required String userId,
    required String name,
    required String idCard,
  }) async {
    try {
      // 创建认证申请
      await _supabase.from('certification_applications').insert({
        'user_id': userId,
        'auth_level': 'realName',
        'status': 'pending',
        'real_name': name,
        'id_card_number': _maskIdCard(idCard),
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // 更新用户认证状态
      await _supabase.from('user_auth_status').upsert({
        'user_id': userId,
        'real_name': name,
        'id_card_number': _maskIdCard(idCard),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('实名认证申请已提交: $userId');
    } catch (e) {
      AppLogger.error('提交实名认证失败', e);
      rethrow;
    }
  }

  /// 上传残障证明
  Future<void> uploadDisabledCertificate({
    required String userId,
    required File certificate,
  }) async {
    try {
      // 上传图片到存储
      final fileName = 'disabled_cert_$userId${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'certificates/disabled/$fileName';

      await _supabase.storage
          .from('certificates')
          .upload(filePath, certificate);

      final imageUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(filePath);

      // 创建认证申请
      await _supabase.from('certification_applications').insert({
        'user_id': userId,
        'auth_level': 'disabledCert',
        'status': 'pending',
        'certificate_image_url': imageUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // 更新用户认证状态
      await _supabase.from('user_auth_status').upsert({
        'user_id': userId,
        'disabled_cert_image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('残障证明上传成功: $userId');
    } catch (e) {
      AppLogger.error('上传残障证明失败', e);
      rethrow;
    }
  }

  /// 提交技能认证
  Future<void> submitSkillCertification({
    required String userId,
    required String skill,
    required File certificate,
    String? skillCode,
  }) async {
    try {
      // 上传证书图片
      final fileName = 'skill_cert_${userId}_${skill}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'certificates/skills/$fileName';

      await _supabase.storage
          .from('certificates')
          .upload(filePath, certificate);

      final imageUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(filePath);

      // 创建技能认证记录
      await _supabase.from('skill_certifications').insert({
        'user_id': userId,
        'skill_name': skill,
        'skill_code': skillCode,
        'certificate_image_url': imageUrl,
        'is_verified': false,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // 创建认证申请
      await _supabase.from('certification_applications').insert({
        'user_id': userId,
        'auth_level': 'skillCert',
        'skill_name': skill,
        'status': 'pending',
        'certificate_image_url': imageUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('技能认证申请已提交: $userId - $skill');
    } catch (e) {
      AppLogger.error('提交技能认证失败', e);
      rethrow;
    }
  }

  /// 获取用户的认证申请列表
  Future<List<CertificationApplication>> getUserApplications(String userId) async {
    try {
      final response = await _supabase
          .from('certification_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CertificationApplication.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取认证申请列表失败', e);
      return [];
    }
  }

  /// 检查用户是否完成基础认证
  Future<bool> isBasicVerified(String userId) async {
    final status = await getUserAuthStatus(userId);
    return status?.isBasicVerified ?? false;
  }

  /// 检查用户是否有优先认证
  Future<bool> hasPriorityCertification(String userId) async {
    final status = await getUserAuthStatus(userId);
    return status?.hasPriority ?? false;
  }

  /// 获取用户已认证的技能
  Future<List<SkillCertification>> getVerifiedSkills(String userId) async {
    try {
      final response = await _supabase
          .from('skill_certifications')
          .select()
          .eq('user_id', userId)
          .eq('is_verified', true);

      return (response as List)
          .map((json) => SkillCertification.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取认证技能失败', e);
      return [];
    }
  }

  /// 身份证脱敏
  String _maskIdCard(String idCard) {
    if (idCard.length != 18) return idCard;
    return '${idCard.substring(0, 6)}********${idCard.substring(14)}';
  }

  /// 监听认证状态变化
  Stream<UserAuthStatus?> watchUserAuthStatus(String userId) {
    return _supabase
        .from('user_auth_status')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return UserAuthStatus.fromJson(rows.first);
        });
  }
}
