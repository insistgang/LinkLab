// Facades 統一導出
// AGENTS.md §12.2：UI 層只允許通過 facade 調用業務服務。
// 禁止 UI 直接依賴 demo / real 兩套實現。
export 'agent_result.dart';
export 'agent_service_facade.dart';
export 'call_session_facade.dart';
export 'sos_facade.dart';
export 'volunteer_matching_facade.dart';
