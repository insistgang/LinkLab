enum DemoAiIntent {
  ocrText('ocr_text', 'OCR / 读文字'),
  sceneDescription('scene_description', '场景描述'),
  objectIdentify('object_identify', '物体识别'),
  colorRecognition('color_recognition', '颜色识别'),
  moneyRecognition('money_recognition', '钞票 / 面额识别'),
  translation('translation', '翻译 / 转译'),
  environmentDescription('environment_description', '环境描述'),
  navigation('navigation', '导航 / 找路'),
  medicationCheck('medication_check', '药品确认'),
  emergency('emergency', '紧急词检测'),
  needHuman('need_human', '转人工'),
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
