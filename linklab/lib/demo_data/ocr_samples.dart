/// OCR模擬樣本數據
/// 用於演示模式下的文字識別結果
class OcrSamples {
  /// OCR樣本列表
  static final List<Map<String, dynamic>> samples = [
    {
      'id': 'medicine_1',
      'image': 'medicine_box.jpg',
      'text': '''藥品名稱：阿司匹林腸溶片
規格：100mg × 30片
用法用量：口服，一次1片，一日1次
適應症：預防心腦血管疾病
生產日期：2024-01-15
有效期至：2027-01-14
批准文號：國藥準字H20240001''',
      'isMedicine': true,
      'urgency': 'important',
    },
    {
      'id': 'menu_1',
      'image': 'restaurant_menu.jpg',
      'text': '''今日特色菜單
宮保雞丁 ........... 38元
魚香肉絲 ........... 32元
麻婆豆腐 ........... 18元
清炒時蔬 ........... 16元
米飯 ............... 3元
例湯免費''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'letter_1',
      'image': 'handwritten_letter.jpg',
      'text': '''親愛的兒子：

最近身體還好嗎？
天氣轉涼了，記得多穿衣服。
媽媽給你寄了一些家鄉的特產，
收到後記得告訴我。

愛你的媽媽
2024年4月''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'express_1',
      'image': 'express_label.jpg',
      'text': '''順豐速運
運單號：SF1234567890123
收件人：張先生 138****8888
地址：北京市朝陽區建國路88號
物品：文件
重量：0.5kg''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'sign_1',
      'image': 'street_sign.jpg',
      'text': '''溫馨提示
請勿吸菸
禁止大聲喧譁
營業時間：9:00-21:00
客服電話：400-123-4567''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'medicine_2',
      'image': 'medicine_bottle.jpg',
      'text': '''維生素C片
規格：100mg × 100片
用法：一次1片，一日3次
【非處方藥】OTC
生產企業：XX製藥有限公司
有效期：2026-12''',
      'isMedicine': true,
      'urgency': 'important',
    },
    {
      'id': 'price_tag_1',
      'image': 'supermarket_price.jpg',
      'text': '''新鮮水果區
紅富士蘋果  12.8元/斤
香蕉  6.5元/斤
橙子  8.9元/斤
葡萄  15.8元/斤
會員價更優惠''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'business_card_1',
      'image': 'business_card.jpg',
      'text': '''李明
高級工程師
北京科技有限公司
手機：138-0000-1234
郵箱：liming@example.com
地址：北京市海淀區中關村''',
      'isMedicine': false,
      'urgency': 'normal',
    },
  ];

  /// 根據ID獲取樣本
  static Map<String, dynamic>? getById(String id) {
    try {
      return samples.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 隨機獲取一個樣本
  static Map<String, dynamic> getRandom() {
    final index = DateTime.now().millisecond % samples.length;
    return samples[index];
  }

  /// 獲取藥品樣本（用於演示藥品檢測）
  static Map<String, dynamic> getMedicineSample() {
    return samples.firstWhere((s) => s['isMedicine'] == true);
  }

  /// 獲取非藥品樣本
  static Map<String, dynamic> getNonMedicineSample() {
    return samples.firstWhere((s) => s['isMedicine'] == false);
  }
}
