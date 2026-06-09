# Experimental Services

此目錄存放真實第三方 API 集成代碼，當前處於實驗/隔離狀態。

- AI 多模型集成：百度 OCR、訊飛語音、通義千問等
- 這些服務通過 AgentServiceFacade 統一調用，UI 層不得直接引用
- Demo 模式下自動使用本地 mock 響應
