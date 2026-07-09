# LinkAble 真实 AI 安全集成指南

## 当前发布策略

客户端发布包只运行安全的 Demo fallback，不保存、读取或打包第三方 AI 密钥。
百度 OCR、通义千问、科大讯飞、MiniMax、智谱等服务如需接入，必须由受控服务端代理调用。

禁止采用以下方式：

- 在 Dart、JavaScript、Android 或 iOS 源码中填写密钥。
- 把 `.env`、`api_config.dart` 或其他密钥文件声明为 Flutter asset。
- 从客户端安全存储读取第三方服务端密钥后直接调用供应商接口。
- 在 Web 构建参数中注入可被浏览器下载的服务端密钥。

即使文件没有提交到 Git，写入客户端后仍会出现在 Web、APK 或 IPA 的编译产物中。

## 推荐架构

```text
LinkAble 客户端
    │ 用户身份令牌、任务数据
    ▼
LinkAble 服务端代理 / Edge Function
    │ 服务端保存的供应商密钥
    ├── OCR 服务
    ├── 视觉模型
    ├── ASR / TTS
    └── 翻译服务
```

客户端只知道 LinkAble 自己的代理地址。服务端负责：

- 安全保存和轮换供应商密钥。
- 校验用户身份、请求大小和内容类型。
- 限流、配额、超时、重试与审计。
- 删除不必要的图片、音频和日志。
- 将供应商响应转换为项目统一的数据结构。

## 建议接口

```http
POST /v1/ai/vision
Authorization: Bearer <用户短期令牌>
Content-Type: multipart/form-data

mode=ocr|color|scene
image=<文件>
```

```json
{
  "success": true,
  "text": "识别结果",
  "confidence": 0.93,
  "requestId": "..."
}
```

语音能力可按相同方式拆分为 `/v1/ai/asr` 和 `/v1/ai/tts`。服务端不得把上游密钥、原始错误栈或供应商内部响应直接返回客户端。

## 本地与 CI

`lib/config/api_config.dart` 是已跟踪的无密钥兼容配置，所有密钥字段保持为空且不可写。
CI 会执行以下检查：

```bash
flutter analyze
flutter test
flutter build web --release --base-href /LinkLab/
```

发布前还应确认：

1. `pubspec.yaml` 没有 `.env` 资源。
2. Git 差异中没有真实令牌或私钥。
3. Release 产物中没有供应商密钥。
4. 未配置代理时稳定回退到 Demo 模式。

## 移动端权限

- 相机：拍照进行文字、颜色和环境识别，以及通话预览。
- 相册：选择需要识别的图片。
- 麦克风与语音识别：语音求助、语音转文字和通话协助。

权限被拒绝或插件不可用时，客户端必须显示可理解的错误提示，并允许用户继续使用文字输入。
