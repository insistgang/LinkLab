# Services Facades

AGENTS.md §12.2 要求：**同一业务能力只能有一个统一入口**，UI 层只依赖 facade / provider-backed controller。

## 设计原则

1. **单一入口** — 每种业务能力（AI、匹配、通话、SOS、无障碍偏好、会话）只允许通过一个 facade 暴露。
2. **屏蔽实现** — facade 内部可包装 demo 或 real 服务，但对外接口保持稳定。
3. **归一化输出** — AI 相关能力统一返回 `AgentResult`，包含 intent、urgency、confidence、nextAction 等标准字段。
4. **禁止 UI 穿透** — UI 不得直接调用 `DemoAIService`、`DemoMatchingEngineService` 等具体实现。

## 当前 Facade

| Facade | 职责 | 状态 |
|---|---|---|
| `AgentServiceFacade` | AI 意图识别、OCR、场景描述、颜色/钞票/药品识别、紧急检测 | 已创建 |
| `VolunteerMatchingFacade` | F9 志愿者匹配引擎（规划中） | 待创建 |
| `CallSessionFacade` | F11 实时语音通话（规划中） | 待创建 |
| `SosFacade` | F13 SOS 紧急呼救（规划中） | 待创建 |
| `AccessibilityPrefsFacade` | F36 无障碍偏好（规划中） | 待创建 |
| `SessionFacade` | 登录与会话管理（规划中） | 待创建 |

## 使用方式

```dart
import 'package:linklab/services/facades/facades_exports.dart';

final agent = AgentServiceFacade();
final result = await agent.processInput(text: '帮我读药盒');
```

## 迁移路线图

1. **阶段一（当前）**：创建 facade 和标准模型，不修改 UI 调用。
2. **阶段二**：将 UI 层 `DemoAIService` 直接调用迁移到 `AgentServiceFacade`。
3. **阶段三**：其他 facade（Matching/Call/SOS）补齐，逐步收敛旧 service singleton。
