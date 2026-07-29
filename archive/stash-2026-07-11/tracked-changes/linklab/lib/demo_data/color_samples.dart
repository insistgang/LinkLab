/// 颜色识别模拟样本数据
/// 用于演示模式下的颜色识别结果
class ColorSamples {
  /// 颜色样本列表（含色盲友好描述）
  static final List<Map<String, dynamic>> samples = [
    {
      'id': 'red_shirt',
      'image': 'red_shirt.jpg',
      'color': '红色',
      'colorBlindDesc': '暖色调，类似番茄或苹果的颜色',
      'rgb': [255, 0, 0],
      'hex': '#FF0000',
      'category': '暖色',
    },
    {
      'id': 'blue_sky',
      'image': 'blue_sky.jpg',
      'color': '天蓝色',
      'colorBlindDesc': '浅冷色调，类似晴朗天空的颜色',
      'rgb': [135, 206, 235],
      'hex': '#87CEEB',
      'category': '冷色',
    },
    {
      'id': 'green_grass',
      'image': 'green_grass.jpg',
      'color': '草绿色',
      'colorBlindDesc': '冷色调，类似新鲜草地的颜色',
      'rgb': [0, 128, 0],
      'hex': '#008000',
      'category': '冷色',
    },
    {
      'id': 'yellow_banana',
      'image': 'yellow_banana.jpg',
      'color': '黄色',
      'colorBlindDesc': '明亮暖色调，类似柠檬或香蕉的颜色',
      'rgb': [255, 255, 0],
      'hex': '#FFFF00',
      'category': '暖色',
    },
    {
      'id': 'white_wall',
      'image': 'white_wall.jpg',
      'color': '白色',
      'colorBlindDesc': '很浅的色调，类似雪或纸张的颜色',
      'rgb': [255, 255, 255],
      'hex': '#FFFFFF',
      'category': '中性色',
    },
    {
      'id': 'black_shoes',
      'image': 'black_shoes.jpg',
      'color': '黑色',
      'colorBlindDesc': '很深的色调，类似夜晚或煤炭的颜色',
      'rgb': [0, 0, 0],
      'hex': '#000000',
      'category': '中性色',
    },
    {
      'id': 'navy_suit',
      'image': 'navy_suit.jpg',
      'color': '深蓝色',
      'colorBlindDesc': '深冷色调，类似深海或制服的颜色',
      'rgb': [0, 0, 128],
      'hex': '#000080',
      'category': '冷色',
    },
    {
      'id': 'brown_wood',
      'image': 'brown_wood.jpg',
      'color': '棕色',
      'colorBlindDesc': '深暖色调，类似木头或巧克力的颜色',
      'rgb': [165, 42, 42],
      'hex': '#A52A2A',
      'category': '暖色',
    },
    {
      'id': 'gray_concrete',
      'image': 'gray_concrete.jpg',
      'color': '灰色',
      'colorBlindDesc': '中等色调，类似石头或水泥的颜色',
      'rgb': [128, 128, 128],
      'hex': '#808080',
      'category': '中性色',
    },
    {
      'id': 'orange_fruit',
      'image': 'orange_fruit.jpg',
      'color': '橙色',
      'colorBlindDesc': '暖色调，类似橙子或胡萝卜的颜色',
      'rgb': [255, 165, 0],
      'hex': '#FFA500',
      'category': '暖色',
    },
    {
      'id': 'purple_flower',
      'image': 'purple_flower.jpg',
      'color': '紫色',
      'colorBlindDesc': '中性色调，类似葡萄或薰衣草的颜色',
      'rgb': [128, 0, 128],
      'hex': '#800080',
      'category': '中性色',
    },
    {
      'id': 'pink_rose',
      'image': 'pink_rose.jpg',
      'color': '粉红色',
      'colorBlindDesc': '浅暖色调，类似樱花或玫瑰的颜色',
      'rgb': [255, 192, 203],
      'hex': '#FFC0CB',
      'category': '暖色',
    },
    {
      'id': 'beige_sweater',
      'image': 'beige_sweater.jpg',
      'color': '米色',
      'colorBlindDesc': '浅暖色调，类似沙子或奶茶的颜色',
      'rgb': [245, 245, 220],
      'hex': '#F5F5DC',
      'category': '暖色',
    },
    {
      'id': 'olive_jacket',
      'image': 'olive_jacket.jpg',
      'color': '橄榄绿',
      'colorBlindDesc': '中性色调，类似橄榄或军服的颜色',
      'rgb': [128, 128, 0],
      'hex': '#808000',
      'category': '中性色',
    },
    {
      'id': 'gold_jewelry',
      'image': 'gold_jewelry.jpg',
      'color': '金色',
      'colorBlindDesc': '明亮暖色调，类似阳光或金子的颜色',
      'rgb': [255, 215, 0],
      'hex': '#FFD700',
      'category': '暖色',
    },
  ];

  /// 根据ID获取颜色样本
  static Map<String, dynamic>? getById(String id) {
    try {
      return samples.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 随机获取一个颜色样本
  static Map<String, dynamic> getRandom() {
    final index = DateTime.now().millisecond % samples.length;
    return samples[index];
  }

  /// 根据颜色类别获取样本
  static List<Map<String, dynamic>> getByCategory(String category) {
    return samples.where((s) => s['category'] == category).toList();
  }

  /// 获取暖色样本
  static List<Map<String, dynamic>> getWarmColors() {
    return getByCategory('暖色');
  }

  /// 获取冷色样本
  static List<Map<String, dynamic>> getCoolColors() {
    return getByCategory('冷色');
  }

  /// 获取中性色样本
  static List<Map<String, dynamic>> getNeutralColors() {
    return getByCategory('中性色');
  }

  /// 获取衣物颜色建议
  static String getClothingAdvice(String colorName) {
    final color = samples.firstWhere(
      (s) => s['color'] == colorName,
      orElse: () => samples[0],
    );

    final category = color['category'];
    final name = color['color'];

    switch (category) {
      case '暖色':
        return '这是$name，属于暖色调，适合搭配米色、棕色或深蓝色。';
      case '冷色':
        return '这是$name，属于冷色调，适合搭配白色、灰色或黑色。';
      case '中性色':
        return '这是$name，属于中性色，非常百搭，可以搭配各种颜色。';
      default:
        return '这是$name。';
    }
  }
}
