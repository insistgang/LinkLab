# Experimental Services

此目录存放真实第三方 API 集成代码，当前处于实验/隔离状态。

- AI 多模型集成：百度 OCR、讯飞语音、通义千问等
- 这些服务通过 AgentServiceFacade 统一调用，UI 层不得直接引用
- Demo 模式下自动使用本地 mock 响应
