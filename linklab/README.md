# 共感LinkAble - AI無障礙互助平臺

[![Flutter Version](https://img.shields.io/badge/Flutter-3.11+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> 一個專爲視障人士設計的智能互助平臺，結合AI識別與志願者實時協助，讓科技更有溫度。
> 當前狀態：Demo-first MVP。Web / Chrome 是首選演示路徑；真實 WebRTC、真實 Supabase、真實推送和生產級 SOS 仍是實驗或後續能力，不作爲當前生產完成項。

## 項目簡介

共感LinkAble是一款面向視障人士的AI無障礙互助應用。當前倉庫優先服務競賽 Demo：通過本地 AI 場景、Demo 通話狀態機和志願者兜底流程，幫助視障用戶完成可演示的求助閉環。當AI無法準確識別或用戶需要進一步幫助時，可進入志願者匹配和 Demo Call 演示。

## 當前 Demo 與 PRD 對齊範圍

當前倉庫中的 `linklab` 主前端已經打通以下演示閉環：

- 首次啓動、登錄、onboarding 與本地會話恢復
- 無障礙偏好設置的保存、再次編輯與全局生效
- 首頁主求助入口、最近幫助記錄、精選故事內容展示
- AI 助手 Tab：文字識別、場景描述、顏色識別、緊急識別的預設場景與對話演示
- 演示版實時通話結束後可提交評價，並回流到幫助檔案與常用志願者
- 個人中心與求助者中心的數據聯動
- 緊急聯繫人、位置共享設置與 SOS 演示階段狀態
- 異步留言求助：提交留言、寫入幫助檔案、在求助者中心回看進度
- 在未初始化 Supabase 時，幫助檔案、精選故事、異步留言與安全設置的本地降級展示

當前仍未完成、但在 PRD 中明確存在的能力包括：

- 真實手機號認證與正式用戶體系
- 穩定的實時匹配、WebRTC 通話與生產級狀態同步
- 真實定位權限、短信/Push 通知、生產級 SOS 升級鏈路
- 推送通知、內容審覈後臺與更完整的志願者運營能力

因此，當前版本更適合做 Web / Chrome 主前端產品演示，而不是生產環境部署。

## 功能特性

### AI智能識別
- **OCR文字識別** - 識別藥品說明書、菜單、路牌等文字信息
- **場景描述** - 拍照描述周圍環境，輔助導航
- **顏色識別** - 識別衣物、物品顏色
- **智能對話** - 語音交互，自然語言理解

### 志願者匹配
- **智能匹配** - 根據用戶需求匹配最合適的志願者
- **Demo通話** - 基於本地狀態機展示連接、接通、結束與評價；真實 WebRTC 仍是實驗鏈路
- **異步留言** - 非緊急問題先留言，稍後由志願者回覆
- **志願者等級** - 燈塔、星辰、暖陽、微光、燭光五級認證體系

### SOS緊急求助
- **快速觸發** - 長按3秒啓動緊急求助
- **Mock SOS展示** - 競賽 Demo 展示誤觸撤銷、模擬廣播和聯繫人通知狀態
- **階段狀態反饋** - 展示位置同步、聯繫人通知、志願者廣播與響應進度；真實短信、真實推送、系統級觸發和報警聯通未生產化

### 無障礙設計
- **WCAG 2.1 AAA標準** - 高對比度配色，對比度>=7:1
- **全語音交互** - 支持語音輸入和TTS語音播報
- **大觸摸目標** - 最小48dp觸摸區域
- **動態字體縮放** - 支持0.8x-2.0x字體縮放

## 安裝說明

### 環境要求
- Flutter SDK >= 3.11.4
- Dart SDK >= 3.0.0
- Chrome（首選演示路徑）
- Android SDK 或 Xcode (iOS) 可用於移動端驗證
- Windows 桌面端需要 Visual Studio C++ 桌面開發工具鏈，非首選演示路徑

### 安裝步驟

```bash
# 1. 克隆項目
git clone <repository-url>
cd linklab

# 2. 安裝依賴
flutter pub get

# 3. 運行代碼生成 (用於生成freezed模型)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 運行應用（首選 Web / Chrome）
flutter run -d chrome
```

### 配置Supabase（實驗真實鏈路，非 Demo 必需）

競賽 Demo 默認不需要真實 Supabase。只有在本地實驗真實鏈路時，才配置以下信息。

1. 在 `lib/config/app_config.dart` 中配置Supabase信息：
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

2. 如需實驗推送通知，配置Firebase並下載 `google-services.json` (Android) 或 `GoogleService-Info.plist` (iOS)。真實推送不屬於當前 Demo 驗收依賴。

## 項目結構

```
lib/
├── app.dart                    # 應用根組件
├── main.dart                   # 應用入口
├── config/
│   └── app_config.dart         # 應用配置（模式切換、網絡配置）
├── core/
│   ├── constants/              # 常量定義
│   ├── theme/
│   │   └── app_theme.dart      # 主題配置（WCAG AAA標準）
│   └── utils/                  # 工具類
├── models/                     # 數據模型（User、HelpRequest等）
├── screens/                    # 頁面
│   ├── auth/                   # 認證相關（登錄、註冊、 onboarding）
│   ├── home/                   # 首頁、AI對話、社區、個人中心
│   └── call/                   # 通話相關（匹配、通話、評價、SOS）
├── services/                   # 服務層
│   ├── ai/                     # AI相關服務（OCR、場景識別、語音）
│   ├── demo/                   # 演示模式服務
│   ├── auth_service.dart       # 認證服務
│   ├── matching_service.dart   # 志願者匹配服務
│   ├── webrtc_service.dart     # WebRTC通話服務
│   └── sos_service.dart        # SOS緊急求助服務
├── widgets/
│   └── accessible/             # 無障礙組件庫
├── demo_data/                  # 演示數據
└── demo_flow/                  # 演示流程控制
```

## 演示模式

應用默認運行在演示模式，使用模擬數據，無需後端服務即可體驗完整功能。

### 切換模式

真實模式僅用於本地實驗，不用於競賽 Demo。當前 Demo-first 口徑下，不建議現場切換到真實模式。

在 `lib/config/app_config.dart` 中修改：

```dart
// 切換到真實模式
AppConfig.setRealMode();

// 切換到演示模式
AppConfig.setDemoMode();
```

或在 `lib/demo_config.dart` 中修改：

```dart
static bool isDemoMode = false;  // 關閉演示模式
```

### 演示場景

演示模式包含以下預設場景：

| 場景 | 描述 | 需要匹配 |
|------|------|----------|
| 藥品識別 | 拍照識別藥品說明書，AI建議轉人工確認 | 是 |
| 菜單識別 | 識別餐廳菜單，AI直接讀出菜品 | 否 |
| 場景描述 | 描述周圍環境輔助導航 | 否 |
| 顏色識別 | 識別物體顏色 | 否 |
| SOS緊急求助 | 緊急情況下快速求助 | 是 |

### 演示配置

```dart
// lib/demo_config.dart

// 模擬延遲時間（秒）
static int mockDelaySeconds = 2;

// 匹配等待時間（秒）
static int matchingWaitSeconds = 4;

// 通話自動結束時間（秒）
static int callAutoEndSeconds = 30;

// 是否顯示演示模式指示器
static bool showDemoIndicator = true;
```

## 無障礙特性

### WCAG 2.1 AAA 合規

- **色彩對比度** - 文字與背景對比度 >= 7:1
- **觸摸目標** - 最小48dp，重要按鈕56dp-120dp
- **字體大小** - 支持14sp-48sp，可動態縮放

### Semantics支持

所有自定義組件均實現了Semantics：

```dart
Semantics(
  button: true,
  label: '連接志願者按鈕，雙擊開始匹配',
  child: AccessibleButton(
    onTap: _startMatching,
    child: Text('連接志願者'),
  ),
)
```

### 語音與震動反饋

- **TTS語音播報** - 所有操作均有語音提示
- **震動反饋** - 按鈕點擊、匹配成功、通話狀態變化
- **音效提示** - 匹配成功、通話連接等關鍵節點

## 技術棧

| 技術 | 用途 |
|------|------|
| **Flutter** | 跨平臺UI框架 |
| **Riverpod** | 狀態管理 |
| **Supabase** | 後端服務（數據庫、認證、實時通信） |
| **WebRTC** | 實驗性真實通話；競賽默認使用 Demo Call |
| **Firebase** | 實驗性推送通知；競賽默認不依賴 |
| **flutter_tts** | 文字轉語音 |
| **speech_to_text** | 語音識別 |
| **camera** | 相機訪問 |
| **image_picker** | 圖片選擇 |

## 開發指南

### 代碼生成

項目使用 `freezed` 和 `json_serializable` 進行模型代碼生成：

```bash
# 生成代碼
flutter pub run build_runner build

# 持續監聽生成
flutter pub run build_runner watch

# 刪除衝突輸出
flutter pub run build_runner build --delete-conflicting-outputs
```

### 無障礙測試

1. 開啓設備屏幕閱讀器（TalkBack/VoiceOver）
2. 使用無障礙掃描工具檢查對比度
3. 驗證所有交互元素都有語義標籤

## 截圖

> TODO: 添加應用截圖

## 貢獻指南

歡迎提交Issue和Pull Request！

1. Fork 本倉庫
2. 創建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打開 Pull Request

## 許可證

[MIT](LICENSE) License

---

**共感LinkAble** - 讓科技溫暖每一雙眼睛
