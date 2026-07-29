# LinkLab 运营后台管理系统

基于 Flutter Web 开发的运营后台管理端，为 LinkLab 视障辅助平台提供完整的运营管理能力。

## 功能模块

### 1. 用户管理
- 用户列表（分页、筛选、搜索）
- 用户详情查看
- 封禁/解封用户
- 认证审核（残障证明、技能证书）
- 支持残障用户和志愿者分类管理

### 2. 数据看板
核心指标：
- DAU/MAU（日活/月活）
- 求助响应率
- 志愿者留存率
- AI解决率
- 平均通话时长
- 用户满意度

图表组件：
- 折线图（趋势分析）
- 饼图（分布统计）
- 柱状图（对比分析）

### 3. 内容管理
- 精选故事审核与发布
- 故事上架/下架管理
- 精选标记设置
- 社群内容管理
- 评论管理

### 4. 举报处理
- 举报列表（分页、筛选）
- 举报详情查看
- 处理操作：警告/封号/删除内容/驳回
- 举报统计分析

### 5. 数据统计
- 日/周/月报表
- 用户增长报表
- 求助类型分布
- Excel导出功能

## 技术栈

- **Flutter Web** - 跨平台Web应用框架
- **fl_chart** - 图表组件库
- **data_table_2** - 高性能数据表格
- **supabase_flutter** - 后端服务
- **flutter_bloc** - 状态管理
- **go_router** - 路由管理
- **responsive_framework** - 响应式布局

## 项目结构

```
lib/
├── bloc/                 # BLoC状态管理
│   ├── auth_bloc.dart    # 认证状态
│   ├── dashboard_bloc.dart # 仪表盘状态
│   ├── user_bloc.dart    # 用户管理状态
│   ├── content_bloc.dart # 内容管理状态
│   └── report_bloc.dart  # 举报处理状态
├── constants/            # 常量定义
│   ├── app_constants.dart
│   └── theme.dart
├── models/               # 数据模型
│   ├── user_model.dart
│   ├── dashboard_model.dart
│   ├── content_model.dart
│   ├── report_model.dart
│   └── statistics_model.dart
├── screens/              # 页面
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── users_screen.dart
│   ├── content_screen.dart
│   ├── reports_screen.dart
│   ├── statistics_screen.dart
│   └── settings_screen.dart
├── services/             # 服务层
│   └── supabase_service.dart
├── widgets/              # 公共组件
│   ├── app_layout.dart
│   ├── sidebar.dart
│   ├── metric_card.dart
│   └── charts.dart
├── main.dart             # 入口文件
└── router.dart           # 路由配置
```

## 快速开始

### 环境要求
- Flutter SDK >= 3.11.4
- Dart SDK >= 3.0.0

### 安装依赖

```bash
cd admin_dashboard
flutter pub get
```

### 配置Supabase

编辑 `lib/constants/app_constants.dart`：

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

### 运行开发服务器

```bash
flutter run -d chrome
```

### 构建生产版本

```bash
flutter build web --release
```

## 默认登录账号

- 邮箱: admin@linklab.com
- 密码: admin123

## 响应式布局

系统支持多种屏幕尺寸：
- 桌面端 (>900px)：完整侧边栏 + 数据表格
- 平板端 (600-900px)：自适应布局
- 移动端 (<600px)：抽屉式导航 + 卡片列表

## 数据库表结构

需要以下Supabase表：
- `users` - 用户信息
- `stories` - 精选故事
- `community_content` - 社群内容
- `reports` - 举报记录
- `daily_reports` - 日报表
- `user_growth_reports` - 用户增长报表

## 许可证

MIT License
