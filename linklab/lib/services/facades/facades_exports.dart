// Facades 统一导出
// AGENTS.md §12.2：UI 层只允许通过 facade 调用业务服务。
// 禁止 UI 直接依赖 demo / real 两套实现。
export 'agent_result.dart';
export 'agent_service_facade.dart';
export 'call_session_facade.dart';
export 'sos_facade.dart';
export 'volunteer_matching_facade.dart';
