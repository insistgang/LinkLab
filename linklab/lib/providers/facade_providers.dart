import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/facades/call_session_facade.dart';
import '../services/facades/sos_facade.dart';
import '../services/facades/volunteer_matching_facade.dart';

/// 志願者匹配 Facade Provider
///
/// AGENTS.md §12.2：UI 層只允許通過此 provider 獲取匹配能力。
final volunteerMatchingFacadeProvider = Provider<VolunteerMatchingFacade>(
  (ref) => VolunteerMatchingFacade(),
);

/// 通話 Facade Provider
///
/// AGENTS.md §12.2：UI 層只允許通過此 provider 獲取通話能力。
final callSessionFacadeProvider = Provider<CallSessionFacade>(
  (ref) => CallSessionFacade(),
);

/// SOS 緊急呼救 Facade Provider
///
/// AGENTS.md §12.2：UI 層只允許通過此 provider 獲取 SOS 能力。
final sosFacadeProvider = Provider<SosFacade>(
  (ref) => SosFacade(),
);
