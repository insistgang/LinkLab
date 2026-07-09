import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/facades/call_session_facade.dart';
import '../services/facades/sos_facade.dart';
import '../services/facades/volunteer_matching_facade.dart';

/// 志愿者匹配 Facade Provider
///
/// AGENTS.md §12.2：UI 层只允许通过此 provider 获取匹配能力。
final volunteerMatchingFacadeProvider = Provider<VolunteerMatchingFacade>(
  (ref) => VolunteerMatchingFacade(),
);

/// 通话 Facade Provider
///
/// AGENTS.md §12.2：UI 层只允许通过此 provider 获取通话能力。
final callSessionFacadeProvider = Provider<CallSessionFacade>(
  (ref) => CallSessionFacade(),
);

/// SOS 紧急呼救 Facade Provider
///
/// AGENTS.md §12.2：UI 层只允许通过此 provider 获取 SOS 能力。
final sosFacadeProvider = Provider<SosFacade>(
  (ref) => SosFacade(),
);
