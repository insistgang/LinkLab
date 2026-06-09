# LinkLab Demo Status

> 文檔口徑整理日期：2026-05-01

## 當前定位

LinkLab 當前應被標註爲 **Demo-first MVP**，不是生產級全功能平臺。競賽和對外演示只承諾一條可重複講述、可點擊閉環的本地 Demo 主線：

1. F1 AI Agent 先處理標準化求助。
2. F9 複雜需求轉志願者匹配。
3. F11 進入 Demo Call 狀態機。
4. F13 展示 Mock SOS 的誤觸撤銷、廣播和聯繫人通知狀態。
5. F33 使用演示會話和基礎偏好。
6. F36 保持無障礙優先。

默認演示不應依賴真實 API key、真實 Supabase 初始化、真實 WebRTC 建鏈、真實推送、真實短信或真實報警鏈路。

## 推薦演示路徑

**主要演示路徑是 Flutter Web / Chrome。** 現場演示、錄屏和快速驗收優先使用 Chrome，因爲它最接近當前 Demo-first 的交付目標，也能減少 Windows 桌面原生工具鏈帶來的變量。

建議命令口徑：

```powershell
cd linklab
flutter pub get
flutter run -d chrome
```

需要產物時使用 Web 構建口徑：

```powershell
cd linklab
flutter build web --release
```

本輪文檔整理沒有運行任何 Flutter 命令；上述命令是推薦複驗路徑，不是本輪執行結果。

## Windows 桌面說明

Windows 桌面不是當前首選演示路徑。若要運行或構建 Windows 桌面端，需要本機已安裝 Visual Studio 的 C++ 桌面開發工具鏈，至少包括：

- Visual Studio 2022 或兼容版本；
- `Desktop development with C++` 工作負載；
- MSVC C++ build tools；
- Windows 10/11 SDK；
- CMake / Ninja 等 Flutter Windows 構建依賴。

缺少該工具鏈時，Windows desktop build 失敗不應被解讀爲 Demo 主線不可演示；應優先切回 Web / Chrome。

## 歷史驗證口徑

倉內已有文檔對驗證結果的記錄不完全同一時間點，容易被誤讀。統一口徑如下：

| 記錄來源 | 記錄內容 | 當前解釋 |
|---|---|---|
| `README.md` / `TODO.md` 的 2026-04-17 記錄 | 曾記錄 `flutter test --tags demo` 通過，同時記錄過 `flutter analyze lib` 仍有噪音 | 這是早期收口記錄，不等同於當前複驗結果 |
| `docs/rc_acceptance_evidence.md` | 曾記錄 RC 加固後 `flutter analyze` 爲 `No issues found`，`flutter test --reporter compact` 爲 `All tests passed` / 60 tests | 可作爲較新的歷史 RC 證據，但本輪未復跑 |
| `docs/competition_mvp_delivery_plan.md` / `docs/plans/2026-04-12-prd-alignment-main-frontend.md` | 將 `flutter build web --debug` / `flutter build web --release` 作爲 Web 演示驗收或構建命令 | Web build 是推薦驗收口徑；最終交付前應重新執行並記錄時間、命令和結果 |

因此，對外表述建議使用：

> 項目歷史上已有 Flutter test / Web build 驗收口徑和 RC 證據；當前文檔整理未復跑 Flutter。交付或路演前應以 Web / Chrome 路徑重新執行 `flutter test` 和 `flutter build web`，並把最新結果補到 RC 證據文檔。

## 真實鏈路狀態

以下能力不得表述爲當前生產可用：

- **真實 WebRTC**：保留實驗實現和接入文檔；競賽默認走 Demo Call，不建立真實媒體鏈路。
- **真實 Supabase**：根目錄 `supabase/` 是 schema source of truth，但競賽 Demo 默認不依賴真實 Supabase 初始化或線上數據。
- **真實推送**：推送函數和客戶端服務屬於實驗/後續基礎設施；現場演示只展示本地 Mock 狀態。
- **真實 SOS**：當前只承諾 Mock SOS 的 10 秒誤觸撤銷、廣播狀態和聯繫人通知狀態；真實短信、真實定位、系統級觸發、110/120 或後臺喚醒未作爲生產完成項。
- **真實 AI / OCR / ASR / Vision API**：可作爲本地實驗配置，不能成爲 Demo 必需條件。

## 推薦引用順序

接手或驗收項目時，建議先讀：

1. `DEMO_STATUS.md`
2. `README.md`
3. `docs/rc_acceptance_evidence.md`
4. `docs/demo_script_3min.md`
5. `docs/competition_mvp_delivery_plan.md`
6. `TODO.md`

