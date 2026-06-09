# Services Facades

AGENTS.md §12.2 要求：**同一業務能力只能有一個統一入口**，UI 層只依賴 facade / provider-backed controller。

## 設計原則

1. **單一入口** — 每種業務能力（AI、匹配、通話、SOS、無障礙偏好、會話）只允許通過一個 facade 暴露。
2. **屏蔽實現** — facade 內部可包裝 demo 或 real 服務，但對外接口保持穩定。
3. **歸一化輸出** — AI 相關能力統一返回 `AgentResult`，包含 intent、urgency、confidence、nextAction 等標準字段。
4. **禁止 UI 穿透** — UI 不得直接調用 `DemoAIService`、`DemoMatchingEngineService` 等具體實現。

## 當前 Facade

| Facade | 職責 | 狀態 |
|---|---|---|
| `AgentServiceFacade` | AI 意圖識別、OCR、場景描述、顏色/鈔票/藥品識別、緊急檢測 | 已創建 |
| `VolunteerMatchingFacade` | F9 志願者匹配引擎（規劃中） | 待創建 |
| `CallSessionFacade` | F11 實時語音通話（規劃中） | 待創建 |
| `SosFacade` | F13 SOS 緊急呼救（規劃中） | 待創建 |
| `AccessibilityPrefsFacade` | F36 無障礙偏好（規劃中） | 待創建 |
| `SessionFacade` | 登錄與會話管理（規劃中） | 待創建 |

## 使用方式

```dart
import 'package:linklab/services/facades/facades_exports.dart';

final agent = AgentServiceFacade();
final result = await agent.processInput(text: '幫我讀藥盒');
```

## 遷移路線圖

1. **階段一（當前）**：創建 facade 和標準模型，不修改 UI 調用。
2. **階段二**：將 UI 層 `DemoAIService` 直接調用遷移到 `AgentServiceFacade`。
3. **階段三**：其他 facade（Matching/Call/SOS）補齊，逐步收斂舊 service singleton。
