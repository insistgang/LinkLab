import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/help_request_model.dart';
import '../services/security/emergency_contact_service.dart';
import '../services/security/safety_settings_service.dart';
import '../services/user_center/help_archive_service.dart';
import 'user_session_provider.dart';

/// 首頁數據聚合模型
class HomeScreenData {
  const HomeScreenData({
    required this.recentHistory,
    required this.safetySettings,
    required this.emergencyContactCount,
  });

  final List<HelpRequestModel> recentHistory;
  final SafetySettings safetySettings;
  final int emergencyContactCount;
}

/// 首頁數據 Provider
/// 聚合最近求助記錄、安全設置、緊急聯繫人數量
final homeDataProvider = FutureProvider<HomeScreenData>((ref) async {
  final userId = ref.watch(currentUserIdProvider);

  final helpArchiveService = HelpArchiveService();
  final safetySettingsService = SafetySettingsService();
  final emergencyContactService = EmergencyContactService();

  final results = await Future.wait<dynamic>([
    helpArchiveService.getHelpHistory(userId, limit: 3),
    safetySettingsService.getSettings(userId),
    emergencyContactService.getContactCount(userId),
  ]);

  return HomeScreenData(
    recentHistory: results[0] as List<HelpRequestModel>,
    safetySettings: results[1] as SafetySettings,
    emergencyContactCount: results[2] as int,
  );
});
