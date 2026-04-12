import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import '../models/user_model.dart';

/// 认证服务
class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 获取当前用户
  User? get currentUser => _supabase.auth.currentUser;

  /// 获取当前会话
  Session? get currentSession => _supabase.auth.currentSession;

  /// 是否已登录
  bool get isAuthenticated => currentUser != null;

  /// 发送手机验证码
  Future<void> sendPhoneOTP(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
      );
      AppLogger.info('验证码已发送至: $phone');
    } catch (e) {
      AppLogger.error('发送验证码失败', e);
      rethrow;
    }
  }

  /// 验证手机验证码
  Future<AuthResponse> verifyPhoneOTP(String phone, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      AppLogger.info('验证码验证成功: $phone');
      return response;
    } catch (e) {
      AppLogger.error('验证验证码失败', e);
      rethrow;
    }
  }

  /// 获取用户资料
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      AppLogger.error('获取用户资料失败', e);
      return null;
    }
  }

  /// 更新用户资料
  Future<void> updateUserProfile(UserModel user) async {
    try {
      await _supabase
          .from('users')
          .update(user.toJson())
          .eq('id', user.id);
      AppLogger.info('用户资料更新成功: ${user.id}');
    } catch (e) {
      AppLogger.error('更新用户资料失败', e);
      rethrow;
    }
  }

  /// 创建用户资料
  Future<void> createUserProfile(UserModel user) async {
    try {
      await _supabase.from('users').insert(user.toJson());
      AppLogger.info('用户资料创建成功: ${user.id}');
    } catch (e) {
      AppLogger.error('创建用户资料失败', e);
      rethrow;
    }
  }

  /// 退出登录
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.info('用户已退出登录');
    } catch (e) {
      AppLogger.error('退出登录失败', e);
      rethrow;
    }
  }

  /// 监听认证状态变化
  Stream<AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;
}
