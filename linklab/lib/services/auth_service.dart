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
/// Phase-2 只使用 Supabase anon/publishable key 接入登錄態，不查詢業務表。
class AuthService {
  AuthService({SupabaseClient? supabase}) : _supabaseClient = supabase;

  SupabaseClient? _supabaseClient;

  bool get isAvailable => AppConfig.isRealMode && AppConfig.supabaseInitialized;

  SupabaseClient get _supabase {
    if (!isAvailable) {
      throw const AuthException('當前未連接真實認證服務');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  /// 獲取當前用戶
  User? get currentUser => isAvailable ? _supabase.auth.currentUser : null;

  /// 獲取當前會話
  Session? get currentSession =>
      isAvailable ? _supabase.auth.currentSession : null;

  /// 是否已登錄
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
      AppLogger.info('Supabase Auth 郵箱登錄成功');
      return EmailAuthOutcome(
        signedIn: response.session != null,
        message: '登錄成功',
        user: response.user,
        session: response.session,
      );
    } on AuthException catch (error) {
      AppLogger.warning('Supabase Auth 郵箱登錄失敗', error);
      throw AuthException(_readableAuthError(error));
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 郵箱登錄異常', error, stackTrace);
      throw const AuthException('登錄失敗，請稍後再試');
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
        AppLogger.info('Supabase Auth 註冊已提交，等待郵箱確認');
        return EmailAuthOutcome(
          signedIn: false,
          message: '註冊郵件已發送，請先完成郵箱確認，再回到應用登錄。',
          user: response.user,
          session: response.session,
        );
      }

      AppLogger.info('Supabase Auth 郵箱註冊並登錄成功');
      return EmailAuthOutcome(
        signedIn: true,
        message: '註冊成功，已登錄',
        user: response.user,
        session: response.session,
      );
    } on AuthException catch (error) {
      AppLogger.warning('Supabase Auth 郵箱註冊失敗', error);
      throw AuthException(_readableAuthError(error));
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 郵箱註冊異常', error, stackTrace);
      throw const AuthException('註冊失敗，請稍後再試');
    }
  }

  /// 發送郵箱登錄鏈接。Phase-2 先作爲輔助能力保留，不依賴業務表。
  Future<void> sendEmailLoginLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email.trim(),
        shouldCreateUser: true,
      );
      AppLogger.info('Supabase Auth 郵箱登錄鏈接已發送');
    } on AuthException catch (error) {
      AppLogger.warning('Supabase Auth 郵箱登錄鏈接發送失敗', error);
      throw AuthException(_readableAuthError(error));
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 郵箱登錄鏈接發送異常', error, stackTrace);
      throw const AuthException('發送登錄郵件失敗，請稍後再試');
    }
  }

  /// 手機短信不屬於 Phase-2，真實模式不接入。
  Future<void> sendPhoneOTP(String phone) async {
    if (AppConfig.isRealMode) {
      throw const AuthException('本階段暫未接入真實短信登錄，請使用郵箱登錄。');
    }
    AppLogger.info('Demo 手機驗證碼流程保持本地模擬');
  }

  Future<AuthResponse> verifyPhoneOTP(String phone, String token) async {
    throw const AuthException('本階段暫未接入真實短信驗證。');
  }

  /// 退出登錄
  Future<void> signOut() async {
    if (!isAvailable) {
      return;
    }

    try {
      await _supabase.auth.signOut();
      AppLogger.info('Supabase Auth 已退出登錄');
    } catch (error, stackTrace) {
      AppLogger.error('Supabase Auth 退出登錄失敗', error, stackTrace);
      throw const AuthException('退出登錄失敗，請稍後再試');
    }
  }

  String _readableAuthError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return '郵箱或密碼不正確，請檢查後重試。';
    }
    if (message.contains('email not confirmed')) {
      return '郵箱還沒有完成確認，請先打開郵件中的確認鏈接。';
    }
    if (message.contains('user already registered') ||
        message.contains('already registered')) {
      return '這個郵箱已經註冊，請直接登錄。';
    }
    if (message.contains('password')) {
      return '密碼不符合要求，請至少輸入 6 位。';
    }
    if (message.contains('rate limit') || message.contains('too many')) {
      return '請求過於頻繁，請稍後再試。';
    }
    return error.message.isEmpty ? '認證失敗，請稍後再試。' : error.message;
  }
}
