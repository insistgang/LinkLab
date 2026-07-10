import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'app_session_provider.dart';

/// 当前用户ID Provider
/// 优先从 Riverpod appSessionProvider 获取当前用户ID，fallback 到 demo user id
final currentUserIdProvider = Provider<String>((ref) {
  final session = ref.watch(appSessionProvider);
  return session.userProfile?.id ?? 'demo-user-id';
});

/// 当前用户 Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  final session = ref.watch(appSessionProvider);
  return session.userProfile;
});
