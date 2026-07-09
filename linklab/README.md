# 共感LinkAble - AI无障碍互助平台

[![Flutter Version](https://img.shields.io/badge/Flutter-3.11+-blue.svg)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

> 一个专为视障人士设计的智能互助平台，结合AI识别与志愿者实时协助，让科技更有温度。
> 当前状态：Demo-first MVP。Web / Chrome 是首选演示路径；真实 WebRTC、真实 Supabase、真实推送和生产级 SOS 仍是实验或后续能力，不作为当前生产完成项。

## 项目简介

共感LinkAble是一款面向视障人士的AI无障碍互助应用。当前仓库优先服务竞赛 Demo：通过本地 AI 场景、Demo 通话状态机和志愿者兜底流程，帮助视障用户完成可演示的求助闭环。当AI无法准确识别或用户需要进一步帮助时，可进入志愿者匹配和 Demo Call 演示。

## 当前 Demo 与 PRD 对齐范围

当前仓库中的 `linklab` 主前端已经打通以下演示闭环：

- 首次启动、登录、onboarding 与本地会话恢复
- 无障碍偏好设置的保存、再次编辑与全局生效
- 首页主求助入口、最近帮助记录、精选故事内容展示
- AI 助手 Tab：文字识别、场景描述、颜色识别、紧急识别的预设场景与对话演示
- 演示版实时通话结束后可提交评价，并回流到帮助档案与常用志愿者
- 个人中心与求助者中心的数据联动
- 紧急联系人、位置共享设置与 SOS 演示阶段状态
- 异步留言求助：提交留言、写入帮助档案、在求助者中心回看进度
- 在未初始化 Supabase 时，帮助档案、精选故事、异步留言与安全设置的本地降级展示

当前仍未完成、但在 PRD 中明确存在的能力包括：

- 真实手机号认证与正式用户体系
- 稳定的实时匹配、WebRTC 通话与生产级状态同步
- 真实定位权限、短信/Push 通知、生产级 SOS 升级链路
- 推送通知、内容审核后台与更完整的志愿者运营能力

因此，当前版本更适合做 Web / Chrome 主前端产品演示，而不是生产环境部署。

## 功能特性

### AI智能识别
- **OCR文字识别** - 识别药品说明书、菜单、路牌等文字信息
- **场景描述** - 拍照描述周围环境，辅助导航
- **颜色识别** - 识别衣物、物品颜色
- **智能对话** - 语音交互，自然语言理解

### 志愿者匹配
- **智能匹配** - 根据用户需求匹配最合适的志愿者
- **Demo通话** - 基于本地状态机展示连接、接通、结束与评价；真实 WebRTC 仍是实验链路
- **异步留言** - 非紧急问题先留言，稍后由志愿者回覆
- **志愿者等级** - 灯塔、星辰、暖阳、微光、烛光五级认证体系

### SOS紧急求助
- **快速触发** - 长按3秒启动紧急求助
- **Mock SOS展示** - 竞赛 Demo 展示误触撤销、模拟广播和联系人通知状态
- **阶段状态反馈** - 展示位置同步、联系人通知、志愿者广播与响应进度；真实短信、真实推送、系统级触发和报警联通未生产化

### 无障碍设计
- **WCAG 2.1 AAA标准** - 高对比度配色，对比度>=7:1
- **全语音交互** - 支持语音输入和TTS语音播报
- **大触摸目标** - 最小48dp触摸区域
- **动态字体缩放** - 支持0.8x-2.0x字体缩放

## 安装说明

### 环境要求
- Flutter SDK >= 3.11.4
- Dart SDK >= 3.0.0
- Chrome（首选演示路径）
- Android SDK 或 Xcode (iOS) 可用于移动端验证
- Windows 桌面端需要 Visual Studio C++ 桌面开发工具链，非首选演示路径

### 安装步骤

```bash
# 1. 克隆项目
git clone <repository-url>
cd linklab

# 2. 安装依赖
flutter pub get

# 3. 运行代码生成 (用于生成freezed模型)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行应用（首选 Web / Chrome）
flutter run -d chrome
```

### 配置Supabase（实验真实链路，非 Demo 必需）

竞赛 Demo 默认不需要真实 Supabase。只有在本地实验真实链路时，才配置以下信息。

1. 在 `lib/config/app_config.dart` 中配置Supabase信息：
```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

2. 如需实验推送通知，配置Firebase并下载 `google-services.json` (Android) 或 `GoogleService-Info.plist` (iOS)。真实推送不属于当前 Demo 验收依赖。

## 项目结构

```
lib/
├── app.dart                    # 应用根组件
├── main.dart                   # 应用入口
├── config/
│   └── app_config.dart         # 应用配置（模式切换、网络配置）
├── core/
│   ├── constants/              # 常量定义
│   ├── theme/
│   │   └── app_theme.dart      # 主题配置（WCAG AAA标准）
│   └── utils/                  # 工具类
├── models/                     # 数据模型（User、HelpRequest等）
├── screens/                    # 页面
│   ├── auth/                   # 认证相关（登录、注册、 onboarding）
│   ├── home/                   # 首页、AI对话、社区、个人中心
│   └── call/                   # 通话相关（匹配、通话、评价、SOS）
├── services/                   # 服务层
│   ├── ai/                     # AI相关服务（OCR、场景识别、语音）
│   ├── demo/                   # 演示模式服务
│   ├── auth_service.dart       # 认证服务
│   ├── matching_service.dart   # 志愿者匹配服务
│   ├── webrtc_service.dart     # WebRTC通话服务
│   └── sos_service.dart        # SOS紧急求助服务
├── widgets/
│   └── accessible/             # 无障碍组件库
├── demo_data/                  # 演示数据
└── demo_flow/                  # 演示流程控制
```

## 演示模式

应用默认运行在演示模式，使用模拟数据，无需后端服务即可体验完整功能。

### 切换模式

真实模式仅用于本地实验，不用于竞赛 Demo。当前 Demo-first 口径下，不建议现场切换到真实模式。

在 `lib/config/app_config.dart` 中修改：

```dart
// 切换到真实模式
AppConfig.setRealMode();

// 切换到演示模式
AppConfig.setDemoMode();
```

或在 `lib/demo_config.dart` 中修改：

```dart
static bool isDemoMode = false;  // 关闭演示模式
```

### 演示场景

演示模式包含以下预设场景：

| 场景 | 描述 | 需要匹配 |
|------|------|----------|
| 药品识别 | 拍照识别药品说明书，AI建议转人工确认 | 是 |
| 菜单识别 | 识别餐厅菜单，AI直接读出菜品 | 否 |
| 场景描述 | 描述周围环境辅助导航 | 否 |
| 颜色识别 | 识别物体颜色 | 否 |
| SOS紧急求助 | 紧急情况下快速求助 | 是 |

### 演示配置

```dart
// lib/demo_config.dart

// 模拟延迟时间（秒）
static int mockDelaySeconds = 2;

// 匹配等待时间（秒）
static int matchingWaitSeconds = 4;

// 通话自动结束时间（秒）
static int callAutoEndSeconds = 30;

// 是否显示演示模式指示器
static bool showDemoIndicator = true;
```

## 无障碍特性

### WCAG 2.1 AAA 合规

- **色彩对比度** - 文字与背景对比度 >= 7:1
- **触摸目标** - 最小48dp，重要按钮56dp-120dp
- **字体大小** - 支持14sp-48sp，可动态缩放

### Semantics支持

所有自定义组件均实现了Semantics：

```dart
Semantics(
  button: true,
  label: '连接志愿者按钮，双击开始匹配',
  child: AccessibleButton(
    onTap: _startMatching,
    child: Text('连接志愿者'),
  ),
)
```

### 语音与震动反馈

- **TTS语音播报** - 所有操作均有语音提示
- **震动反馈** - 按钮点击、匹配成功、通话状态变化
- **音效提示** - 匹配成功、通话连接等关键节点

## 技术栈

| 技术 | 用途 |
|------|------|
| **Flutter** | 跨平台UI框架 |
| **Riverpod** | 状态管理 |
| **Supabase** | 后端服务（数据库、认证、实时通信） |
| **WebRTC** | 实验性真实通话；竞赛默认使用 Demo Call |
| **Firebase** | 实验性推送通知；竞赛默认不依赖 |
| **flutter_tts** | 文字转语音 |
| **speech_to_text** | 语音识别 |
| **camera** | 相机访问 |
| **image_picker** | 图片选择 |

## 开发指南

### 代码生成

项目使用 `freezed` 和 `json_serializable` 进行模型代码生成：

```bash
# 生成代码
flutter pub run build_runner build

# 持续监听生成
flutter pub run build_runner watch

# 删除冲突输出
flutter pub run build_runner build --delete-conflicting-outputs
```

### 无障碍测试

1. 开启设备屏幕阅读器（TalkBack/VoiceOver）
2. 使用无障碍扫描工具检查对比度
3. 验证所有交互元素都有语义标签

## 截图

> TODO: 添加应用截图

## 贡献指南

欢迎提交Issue和Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

## 许可证

[MIT](LICENSE) License

---

**共感LinkAble** - 让科技温暖每一双眼睛
