/// OCR模拟样本数据
/// 用于演示模式下的文字识别结果
class OcrSamples {
  /// OCR样本列表
  static final List<Map<String, dynamic>> samples = [
    {
      'id': 'medicine_1',
      'image': 'medicine_box.jpg',
      'text': '''药品名称：阿司匹林肠溶片
规格：100mg × 30片
用法用量：口服，一次1片，一日1次
适应症：预防心脑血管疾病
生产日期：2024-01-15
有效期至：2027-01-14
批准文号：国药准字H20240001''',
      'isMedicine': true,
      'urgency': 'important',
    },
    {
      'id': 'menu_1',
      'image': 'restaurant_menu.jpg',
      'text': '''今日特色菜单
宫保鸡丁 ........... 38元
鱼香肉丝 ........... 32元
麻婆豆腐 ........... 18元
清炒时蔬 ........... 16元
米饭 ............... 3元
例汤免费''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'letter_1',
      'image': 'handwritten_letter.jpg',
      'text': '''亲爱的儿子：

最近身体还好吗？
天气转凉了，记得多穿衣服。
妈妈给你寄了一些家乡的特产，
收到后记得告诉我。

爱你的妈妈
2024年4月''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'express_1',
      'image': 'express_label.jpg',
      'text': '''顺丰速运
运单号：SF1234567890123
收件人：张先生 138****8888
地址：北京市朝阳区建国路88号
物品：文件
重量：0.5kg''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'sign_1',
      'image': 'street_sign.jpg',
      'text': '''温馨提示
请勿吸烟
禁止大声喧哗
营业时间：9:00-21:00
客服电话：400-123-4567''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'medicine_2',
      'image': 'medicine_bottle.jpg',
      'text': '''维生素C片
规格：100mg × 100片
用法：一次1片，一日3次
【非处方药】OTC
生产企业：XX制药有限公司
有效期：2026-12''',
      'isMedicine': true,
      'urgency': 'important',
    },
    {
      'id': 'price_tag_1',
      'image': 'supermarket_price.jpg',
      'text': '''新鲜水果区
红富士苹果  12.8元/斤
香蕉  6.5元/斤
橙子  8.9元/斤
葡萄  15.8元/斤
会员价更优惠''',
      'isMedicine': false,
      'urgency': 'normal',
    },
    {
      'id': 'business_card_1',
      'image': 'business_card.jpg',
      'text': '''李明
高级工程师
北京科技有限公司
手机：138-0000-1234
邮箱：liming@example.com
地址：北京市海淀区中关村''',
      'isMedicine': false,
      'urgency': 'normal',
    },
  ];

  /// 根据ID获取样本
  static Map<String, dynamic>? getById(String id) {
    try {
      return samples.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 随机获取一个样本
  static Map<String, dynamic> getRandom() {
    final index = DateTime.now().millisecond % samples.length;
    return samples[index];
  }

  /// 获取药品样本（用于演示药品检测）
  static Map<String, dynamic> getMedicineSample() {
    return samples.firstWhere((s) => s['isMedicine'] == true);
  }

  /// 获取非药品样本
  static Map<String, dynamic> getNonMedicineSample() {
    return samples.firstWhere((s) => s['isMedicine'] == false);
  }
}
