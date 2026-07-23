# Flutter 依赖与分析范围审计

> 核对日期：2026-07-24
> 工程：`linklab/`

## 1. 本轮结果

全仓 Dart import 扫描确认以下 8 个直接依赖或生成器没有任何源码引用，已从 `pubspec.yaml` 移除：

- `riverpod_annotation`
- `json_annotation`
- `sensors_plus`
- `screen_brightness`
- `intl`
- `equatable`
- `collection`
- `riverpod_generator`

`flutter pub get` 共减少 19 个依赖包。`collection`、`equatable`、`json_annotation` 仍可能作为其他包的传递依赖存在，但不再由 LinkAble 直接声明。

## 2. 验证

依赖变更后重新执行：

| 检查 | 结果 |
|---|---|
| `flutter pub get` | 成功 |
| `flutter analyze` | No issues found |
| `flutter test --reporter compact` | 114 项全部通过 |
| `flutter build web --release` | 成功 |

Web 构建的 WASM dry-run 出现工具内部 `org-dartlang-untranslatable-uri` 非阻断异常；Flutter 继续完成 JavaScript Release 构建并生成 `build/web`。

## 3. 保留的非默认主线依赖

以下依赖不属于 Demo 主线，但仍被仓库中的 legacy / experimental 源码 import，本轮不强行删除：

| 能力 | 依赖示例 | 保留原因 |
|---|---|---|
| 真实通话 | `flutter_webrtc`、`web_socket_channel` | experimental 通话源码仍可追溯 |
| 真实推送 | `firebase_core`、`firebase_messaging`、`flutter_local_notifications` | experimental 推送服务仍在 |
| 录音与媒体 | `flutter_sound`、`audioplayers`、`camera` | 历史通话/安全模块仍引用 |
| 真实定位 | `geolocator` | experimental 匹配/SOS 仍引用 |
| 历史后台 | `fl_chart`、`data_table_2` | `lib/admin/` 历史源码仍引用 |
| 真实后端 | `supabase_flutter` | 最小 RealMode repository 需要 |

这些依赖不会因为保留在 `pubspec.yaml` 就自动进入默认导航；Flutter Release 只打包入口可达代码。后续若把对应源码整体移出主包，再单独删除依赖。

## 4. 分析范围

当前 `flutter analyze` 覆盖默认可达主线，并显式排除：

- `lib/services/experimental/**`
- 历史 admin / archive / user-center / security 页面与服务
- 旧 WebRTC、真实通话和旧状态流
- 生成文件

`flutter build web --release` 进一步证明默认入口的完整 import graph 可编译。排除项仍是技术债，不等于代码质量已验收。

## 5. 后续原则

- 新代码不得加入未实际使用的直接依赖。
- 新的默认主线代码不得放进 analyze exclude。
- legacy / experimental 只有整体归档后，才移除其专用依赖。
- 不为减小数字而一次性删除仍可追溯的实验源码。
