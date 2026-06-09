# LinkLab 運營後臺管理系統

基於 Flutter Web 開發的運營後臺管理端，爲 LinkLab 視障輔助平臺提供完整的運營管理能力。

## 功能模塊

### 1. 用戶管理
- 用戶列表（分頁、篩選、搜索）
- 用戶詳情查看
- 封禁/解封用戶
- 認證審覈（殘障證明、技能證書）
- 支持殘障用戶和志願者分類管理

### 2. 數據看板
核心指標：
- DAU/MAU（日活/月活）
- 求助響應率
- 志願者留存率
- AI解決率
- 平均通話時長
- 用戶滿意度

圖表組件：
- 折線圖（趨勢分析）
- 餅圖（分佈統計）
- 柱狀圖（對比分析）

### 3. 內容管理
- 精選故事審覈與發佈
- 故事上架/下架管理
- 精選標記設置
- 社羣內容管理
- 評論管理

### 4. 舉報處理
- 舉報列表（分頁、篩選）
- 舉報詳情查看
- 處理操作：警告/封號/刪除內容/駁回
- 舉報統計分析

### 5. 數據統計
- 日/周/月報表
- 用戶增長報表
- 求助類型分佈
- Excel導出功能

## 技術棧

- **Flutter Web** - 跨平臺Web應用框架
- **fl_chart** - 圖表組件庫
- **data_table_2** - 高性能數據表格
- **supabase_flutter** - 後端服務
- **flutter_bloc** - 狀態管理
- **go_router** - 路由管理
- **responsive_framework** - 響應式佈局

## 項目結構

```
lib/
├── bloc/                 # BLoC狀態管理
│   ├── auth_bloc.dart    # 認證狀態
│   ├── dashboard_bloc.dart # 儀表盤狀態
│   ├── user_bloc.dart    # 用戶管理狀態
│   ├── content_bloc.dart # 內容管理狀態
│   └── report_bloc.dart  # 舉報處理狀態
├── constants/            # 常量定義
│   ├── app_constants.dart
│   └── theme.dart
├── models/               # 數據模型
│   ├── user_model.dart
│   ├── dashboard_model.dart
│   ├── content_model.dart
│   ├── report_model.dart
│   └── statistics_model.dart
├── screens/              # 頁面
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── users_screen.dart
│   ├── content_screen.dart
│   ├── reports_screen.dart
│   ├── statistics_screen.dart
│   └── settings_screen.dart
├── services/             # 服務層
│   └── supabase_service.dart
├── widgets/              # 公共組件
│   ├── app_layout.dart
│   ├── sidebar.dart
│   ├── metric_card.dart
│   └── charts.dart
├── main.dart             # 入口文件
└── router.dart           # 路由配置
```

## 快速開始

### 環境要求
- Flutter SDK >= 3.11.4
- Dart SDK >= 3.0.0

### 安裝依賴

```bash
cd admin_dashboard
flutter pub get
```

### 配置Supabase

編輯 `lib/constants/app_constants.dart`：

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 運行開發服務器

```bash
flutter run -d chrome
```

### 構建生產版本

```bash
flutter build web --release
```

## 默認登錄賬號

- 郵箱: admin@linklab.com
- 密碼: admin123

## 響應式佈局

系統支持多種屏幕尺寸：
- 桌面端 (>900px)：完整側邊欄 + 數據表格
- 平板端 (600-900px)：自適應佈局
- 移動端 (<600px)：抽屜式導航 + 卡片列表

## 數據庫表結構

需要以下Supabase表：
- `users` - 用戶信息
- `stories` - 精選故事
- `community_content` - 社羣內容
- `reports` - 舉報記錄
- `daily_reports` - 日報表
- `user_growth_reports` - 用戶增長報表

## 許可證

MIT License
