enum DemoAiIntent {
  ocrText('ocr_text', 'OCR / 讀文字'),
  sceneDescription('scene_description', '場景描述'),
  objectIdentify('object_identify', '物體識別'),
  colorRecognition('color_recognition', '顏色識別'),
  moneyRecognition('money_recognition', '鈔票 / 面額識別'),
  translation('translation', '翻譯 / 轉譯'),
  environmentDescription('environment_description', '環境描述'),
  navigation('navigation', '導航 / 找路'),
  medicationCheck('medication_check', '藥品確認'),
  emergency('emergency', '緊急詞檢測'),
  needHuman('need_human', '轉人工'),
  fallback('fallback', '兜底回答');

  const DemoAiIntent(this.wireName, this.label);

  final String wireName;
  final String label;

  static DemoAiIntent fromWireName(String? value) {
    for (final intent in values) {
      if (intent.wireName == value) {
        return intent;
      }
    }
    return DemoAiIntent.fallback;
  }
}
