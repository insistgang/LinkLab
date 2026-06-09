import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'app_session_provider.dart';

/// 當前用戶ID Provider
/// 優先從 Riverpod appSessionProvider 獲取當前用戶ID，fallback 到 demo user id
final currentUserIdProvider = Provider<String>((ref) {
  final session = ref.watch(appSessionProvider);
  return session.userProfile?.id ?? 'demo-user-id';
});

/// 當前用戶 Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final session = ref.watch(appSessionProvider);
  return session.userProfile;
});
