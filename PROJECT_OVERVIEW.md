# LinkLab 项目总览

更新时间：2026-06-09

## 项目定位

LinkLab / LinkAble 是一个 Flutter 无障碍互助平台 Demo，核心定位是“AI 先处理 + 志愿者兜底”。当前更偏竞赛演示版和 Web-first Demo。

## 核心功能

- AI Agent 智能对话
- 志愿者匹配
- Demo 语音通话
- SOS Mock 流程
- 登录与无障碍偏好
- 全局无障碍约束

## 技术栈

- Flutter / Dart
- Riverpod
- Supabase 配置和 legacy 目录
- Web / Chrome 主要演示路径
- Android / iOS / desktop 宿主目录

## 主要目录

| 目录 | 内容 |
|---|---|
| `linklab/` | 主 Flutter 应用。 |
| `linklab/admin_dashboard/` | Flutter 管理后台。 |
| `docs/` | 竞赛、验收和演示文档。 |
| `prd-analysis/` | PRD 拆解。 |
| `LinkAble/` | 早期设计和材料。 |
| `视频/`, `pic/`, `icos/` | 演示资产和图标素材。 |

## 维护重点

- 当前 Git 状态 clean。
- 保持 Demo-first 边界，不要把真实 WebRTC、真实推送、真实 Supabase 和生产 SOS 链路混入默认演示主线。
- UI 修改后建议跑 `flutter analyze`、相关 widget test，并用浏览器检查截图。

