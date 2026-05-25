import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../core/utils/logger.dart';

class EmailAuthOutcome {
  const EmailAuthOutcome({
    required this.signedIn,
    required this.message,
    this.user,
    this.session,
  });

  final bool signedIn;
  final String message;
  final User? user;
  final Session? session;
}

/// Supabase Auth facade.
///
/// Phase-2 只使用 Supabase anon/publishable key 接入登录态，不查询业务表。
class AuthService {
  AuthService({SupabaseClient? supabase}) : _supabaseClient = supabase;

  SupabaseClient? _supabaseClient;

  bool get isAvailable => AppConfig.isRealMode && AppConfig.supabaseInitialized;

  SupabaseClient get _supabase {
    if (!isAvailable) {
      throw const AuthException('当前未连接真实认证服务');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 获取当前用户
  User? get currentUser => isAvailable ? _supabase.auth.currentUser : null;

  /// 获取当前会话
  Session? get currentSession =>
      isAvailable ? _supabase.auth.currentSession : null;

  /// 是否已登录
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get onAuthStateChange {
    if (!isAvailable) {
      return const Stream<AuthState>.empty();
    }
    return _supabase.auth.onAuthStateChange;
  }

  Future<EmailAuthOutcome> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      AppLogger.info('Supabase Auth 邮箱登录成功');
      return EmailAuthOutcome(
        signedIn: response.session != null,
        message: '登录成功',
        user: response.user,
        session: response.session,
      );
    } on AuthException catch (error) {
      AppLogger.warning('Supabase Auth 邮箱登录失败', error);
      throw AuthException(_readableAuthError(error));
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 邮箱登录异常', error, stackTrace);
      throw const AuthException('登录失败，请稍后再试');
    }
  }

  Future<EmailAuthOutcome> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
      );

      if (response.session == null) {
        AppLogger.info('Supabase Auth 注册已提交，等待邮箱确认');
        return EmailAuthOutcome(
          signedIn: false,
          message: '注册邮件已发送，请先完成邮箱确认，再回到应用登录。',
          user: response.user,
          session: response.session,
        );
      }

      AppLogger.info('Supabase Auth 邮箱注册并登录成功');
      return EmailAuthOutcome(
        signedIn: true,
        message: '注册成功，已登录',
        user: response.user,
        session: response.session,
      );
    } on AuthException catch (error) {
      AppLogger.warning('Supabase Auth 邮箱注册失败', error);
      throw AuthException(_readableAuthError(error));
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 邮箱注册异常', error, stackTrace);
      throw const AuthException('注册失败，请稍后再试');
    }
  }

  /// 发送邮箱登录链接。Phase-2 先作为辅助能力保留，不依赖业务表。
  Future<void> sendEmailLoginLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: true,
      );
      AppLogger.info('Supabase Auth 邮箱登录链接已发送');
    } on AuthException catch (error) {
      AppLogger.warning('Supabase Auth 邮箱登录链接发送失败', error);
      throw AuthException(_readableAuthError(error));
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 邮箱登录链接发送异常', error, stackTrace);
      throw const AuthException('发送登录邮件失败，请稍后再试');
    }
  }

  /// 手机短信不属于 Phase-2，真实模式不接入。
  Future<void> sendPhoneOTP(String phone) async {
    if (AppConfig.isRealMode) {
      throw const AuthException('本阶段暂未接入真实短信登录，请使用邮箱登录。');
    }
    AppLogger.info('Demo 手机验证码流程保持本地模拟');
  }

  Future<AuthResponse> verifyPhoneOTP(String phone, String token) async {
    throw const AuthException('本阶段暂未接入真实短信验证。');
  }

  /// 退出登录
  Future<void> signOut() async {
    if (!isAvailable) {
      return;
    }

    try {
      await _supabase.auth.signOut();
      AppLogger.info('Supabase Auth 已退出登录');
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 退出登录失败', error, stackTrace);
      throw const AuthException('退出登录失败，请稍后再试');
    }
  }

  String _readableAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '邮箱或密码不正确，请检查后重试。';
    }
    if (message.contains('email not confirmed')) {
      return '邮箱还没有完成确认，请先打开邮件中的确认链接。';
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return '这个邮箱已经注册，请直接登录。';
    }
    if (message.contains('password')) {
      return '密码不符合要求，请至少输入 6 位。';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return '请求过于频繁，请稍后再试。';
    }
    return error.message.isEmpty ? '认证失败，请稍后再试。' : error.message;
  }
}
