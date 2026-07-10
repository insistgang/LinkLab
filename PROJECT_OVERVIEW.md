# LinkLab 項目總覽

更新時間：2026-06-09

## 項目定位

LinkLab / LinkAble 是一個 Flutter 無障礙互助平臺 Demo，核心定位是“AI 先處理 + 志願者兜底”。當前更偏競賽演示版和 Web-first Demo。

## 核心功能

- AI Agent 智能對話
- 志願者匹配
- Demo 語音通話
- SOS Mock 流程
- 登錄與無障礙偏好
- 全局無障礙約束

## 技術棧

- Flutter / Dart
- Riverpod
- Supabase 配置和 legacy 目錄
- Web / Chrome 主要演示路徑
- Android / iOS / desktop 宿主目錄

## 主要目錄

| 目錄 | 內容 |
|---|---|
| `linklab/` | 主 Flutter 應用。 |
| `linklab/admin_dashboard/` | Flutter 管理後臺。 |
| `docs/` | 競賽、驗收和演示文檔。 |
| `prd-analysis/` | PRD 拆解。 |
| `LinkAble/` | 早期設計和材料。 |
| `pic/`, `icos/` | 圖標與設計素材。 |
| `dist/` | 本地交付成品；已被 Git 忽略。 |

## 維護重點

- 當前 Git 狀態 clean。
- 保持 Demo-first 邊界，不要把真實 WebRTC、真實推送、真實 Supabase 和生產 SOS 鏈路混入默認演示主線。
- UI 修改後建議跑 `flutter analyze`、相關 widget test，並用瀏覽器檢查截圖。

