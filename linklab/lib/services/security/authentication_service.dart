import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/security/auth_level_model.dart';

/// 認證服務 - 多級認證體系
class AuthenticationService {
  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 獲取用戶認證狀態
  Future<UserAuthStatus?> getUserAuthStatus(String userId) async {
    try {
      final response = await _supabase
          .from('user_auth_status')
          .select('*, skill_certifications(*)')
          .eq('user_id', userId)
          .single();

      return UserAuthStatus.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      AppLogger.error('獲取用戶認證狀態失敗', e);
      return null;
    }
  }

  /// 驗證手機號
  Future<void> verifyPhone(String phone, String code) async {
    try {
      await _supabase.auth.verifyOTP(
        phone: phone,
        token: code,
        type: OtpType.sms,
      );
      AppLogger.info('手機號驗證成功: $phone');
    } catch (e) {
      AppLogger.error('手機號驗證失敗', e);
      rethrow;
    }
  }

  /// 提交實名認證
  Future<void> submitRealNameVerification({
    required String userId,
    required String name,
    required String idCard,
  }) async {
    try {
      // 創建認證申請
      await _supabase.from('certification_applications').insert({
        'user_id': userId,
        'auth_level': 'realName',
        'status': 'pending',
        'real_name': name,
        'id_card_number': _maskIdCard(idCard),
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // 更新用戶認證狀態
      await _supabase.from('user_auth_status').upsert({
        'user_id': userId,
        'real_name': name,
        'id_card_number': _maskIdCard(idCard),
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('實名認證申請已提交: $userId');
    } catch (e) {
      AppLogger.error('提交實名認證失敗', e);
      rethrow;
    }
  }

  /// 上傳殘障證明
  Future<void> uploadDisabledCertificate({
    required String userId,
    required File certificate,
  }) async {
    try {
      // 上傳圖片到存儲
      final fileName = 'disabled_cert_$userId${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'certificates/disabled/$fileName';

      await _supabase.storage
          .from('certificates')
          .upload(filePath, certificate);

      final imageUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(filePath);

      // 創建認證申請
      await _supabase.from('certification_applications').insert({
        'user_id': userId,
        'auth_level': 'disabledCert',
        'status': 'pending',
        'certificate_image_url': imageUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // 更新用戶認證狀態
      await _supabase.from('user_auth_status').upsert({
        'user_id': userId,
        'disabled_cert_image_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('殘障證明上傳成功: $userId');
    } catch (e) {
      AppLogger.error('上傳殘障證明失敗', e);
      rethrow;
    }
  }

  /// 提交技能認證
  Future<void> submitSkillCertification({
    required String userId,
    required String skill,
    required File certificate,
    String? skillCode,
  }) async {
    try {
      // 上傳證書圖片
      final fileName = 'skill_cert_${userId}_${skill}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'certificates/skills/$fileName';

      await _supabase.storage
          .from('certificates')
          .upload(filePath, certificate);

      final imageUrl = _supabase.storage
          .from('certificates')
          .getPublicUrl(filePath);

      // 創建技能認證記錄
      await _supabase.from('skill_certifications').insert({
        'user_id': userId,
        'skill_name': skill,
        'skill_code': skillCode,
        'certificate_image_url': imageUrl,
        'is_verified': false,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      // 創建認證申請
      await _supabase.from('certification_applications').insert({
        'user_id': userId,
        'auth_level': 'skillCert',
        'skill_name': skill,
        'status': 'pending',
        'certificate_image_url': imageUrl,
        'submitted_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('技能認證申請已提交: $userId - $skill');
    } catch (e) {
      AppLogger.error('提交技能認證失敗', e);
      rethrow;
    }
  }

  /// 獲取用戶的認證申請列表
  Future<List<CertificationApplication>> getUserApplications(String userId) async {
    try {
      final response = await _supabase
          .from('certification_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => CertificationApplication.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取認證申請列表失敗', e);
      return [];
    }
  }

  /// 檢查用戶是否完成基礎認證
  Future<bool> isBasicVerified(String userId) async {
    final status = await getUserAuthStatus(userId);
    return status?.isBasicVerified ?? false;
  }

  /// 檢查用戶是否有優先認證
  Future<bool> hasPriorityCertification(String userId) async {
    final status = await getUserAuthStatus(userId);
    return status?.hasPriority ?? false;
  }

  /// 獲取用戶已認證的技能
  Future<List<SkillCertification>> getVerifiedSkills(String userId) async {
    try {
      final response = await _supabase
          .from('skill_certifications')
          .select()
          .eq('user_id', userId)
          .eq('is_verified', true);

      return (response as List<dynamic>)
          .map((json) => SkillCertification.fromJson(Map<String, dynamic>.from(json as Map)))
          .toList();
    } catch (e) {
      AppLogger.error('獲取認證技能失敗', e);
      return [];
    }
  }

  /// 身份證脫敏
  String _maskIdCard(String idCard) {
    if (idCard.length != 18) return idCard;
    return '${idCard.substring(0, 6)}********${idCard.substring(14)}';
  }

  /// 監聽認證狀態變化
  Stream<UserAuthStatus?> watchUserAuthStatus(String userId) {
    return _supabase
        .from('user_auth_status')
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((rows) {
          if (rows.isEmpty) return null;
          return UserAuthStatus.fromJson(Map<String, dynamic>.from(rows.first as Map));
        });
  }
}
