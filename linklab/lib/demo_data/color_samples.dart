/// 顏色識別模擬樣本數據
/// 用於演示模式下的顏色識別結果
class ColorSamples {
  /// 顏色樣本列表（含色盲友好描述）
  static final List<Map<String, dynamic>> samples = [
    {
      'id': 'red_shirt',
      'image': 'red_shirt.jpg',
      'color': '紅色',
      'colorBlindDesc': '暖色調，類似番茄或蘋果的顏色',
      'rgb': [255, 0, 0],
      'hex': '#FF0000',
      'category': '暖色',
    },
    {
      'id': 'blue_sky',
      'image': 'blue_sky.jpg',
      'color': '天藍色',
      'colorBlindDesc': '淺冷色調，類似晴朗天空的顏色',
      'rgb': [135, 206, 235],
      'hex': '#87CEEB',
      'category': '冷色',
    },
    {
      'id': 'green_grass',
      'image': 'green_grass.jpg',
      'color': '草綠色',
      'colorBlindDesc': '冷色調，類似新鮮草地的顏色',
      'rgb': [0, 128, 0],
      'hex': '#008000',
      'category': '冷色',
    },
    {
      'id': 'yellow_banana',
      'image': 'yellow_banana.jpg',
      'color': '黃色',
      'colorBlindDesc': '明亮暖色調，類似檸檬或香蕉的顏色',
      'rgb': [255, 255, 0],
      'hex': '#FFFF00',
      'category': '暖色',
    },
    {
      'id': 'white_wall',
      'image': 'white_wall.jpg',
      'color': '白色',
      'colorBlindDesc': '很淺的色調，類似雪或紙張的顏色',
      'rgb': [255, 255, 255],
      'hex': '#FFFFFF',
      'category': '中性色',
    },
    {
      'id': 'black_shoes',
      'image': 'black_shoes.jpg',
      'color': '黑色',
      'colorBlindDesc': '很深的色調，類似夜晚或煤炭的顏色',
      'rgb': [0, 0, 0],
      'hex': '#000000',
      'category': '中性色',
    },
    {
      'id': 'navy_suit',
      'image': 'navy_suit.jpg',
      'color': '深藍色',
      'colorBlindDesc': '深冷色調，類似深海或制服的顏色',
      'rgb': [0, 0, 128],
      'hex': '#000080',
      'category': '冷色',
    },
    {
      'id': 'brown_wood',
      'image': 'brown_wood.jpg',
      'color': '棕色',
      'colorBlindDesc': '深暖色調，類似木頭或巧克力的顏色',
      'rgb': [165, 42, 42],
      'hex': '#A52A2A',
      'category': '暖色',
    },
    {
      'id': 'gray_concrete',
      'image': 'gray_concrete.jpg',
      'color': '灰色',
      'colorBlindDesc': '中等色調，類似石頭或水泥的顏色',
      'rgb': [128, 128, 128],
      'hex': '#808080',
      'category': '中性色',
    },
    {
      'id': 'orange_fruit',
      'image': 'orange_fruit.jpg',
      'color': '橙色',
      'colorBlindDesc': '暖色調，類似橙子或胡蘿蔔的顏色',
      'rgb': [255, 165, 0],
      'hex': '#FFA500',
      'category': '暖色',
    },
    {
      'id': 'purple_flower',
      'image': 'purple_flower.jpg',
      'color': '紫色',
      'colorBlindDesc': '中性色調，類似葡萄或薰衣草的顏色',
      'rgb': [128, 0, 128],
      'hex': '#800080',
      'category': '中性色',
    },
    {
      'id': 'pink_rose',
      'image': 'pink_rose.jpg',
      'color': '粉紅色',
      'colorBlindDesc': '淺暖色調，類似櫻花或玫瑰的顏色',
      'rgb': [255, 192, 203],
      'hex': '#FFC0CB',
      'category': '暖色',
    },
    {
      'id': 'beige_sweater',
      'image': 'beige_sweater.jpg',
      'color': '米色',
      'colorBlindDesc': '淺暖色調，類似沙子或奶茶的顏色',
      'rgb': [245, 245, 220],
      'hex': '#F5F5DC',
      'category': '暖色',
    },
    {
      'id': 'olive_jacket',
      'image': 'olive_jacket.jpg',
      'color': '橄欖綠',
      'colorBlindDesc': '中性色調，類似橄欖或軍服的顏色',
      'rgb': [128, 128, 0],
      'hex': '#808000',
      'category': '中性色',
    },
    {
      'id': 'gold_jewelry',
      'image': 'gold_jewelry.jpg',
      'color': '金色',
      'colorBlindDesc': '明亮暖色調，類似陽光或金子的顏色',
      'rgb': [255, 215, 0],
      'hex': '#FFD700',
      'category': '暖色',
    },
  ];

  /// 根據ID獲取顏色樣本
  static Map<String, dynamic>? getById(String id) {
    try {
      return samples.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 隨機獲取一個顏色樣本
  static Map<String, dynamic> getRandom() {
    final index = DateTime.now().millisecond % samples.length;
    return samples[index];
  }

  /// 根據顏色類別獲取樣本
  static List<Map<String, dynamic>> getByCategory(String category) {
    return samples.where((s) => s['category'] == category).toList();
  }

  /// 獲取暖色樣本
  static List<Map<String, dynamic>> getWarmColors() {
    return getByCategory('暖色');
  }

  /// 獲取冷色樣本
  static List<Map<String, dynamic>> getCoolColors() {
    return getByCategory('冷色');
  }

  /// 獲取中性色樣本
  static List<Map<String, dynamic>> getNeutralColors() {
    return getByCategory('中性色');
  }

  /// 獲取衣物顏色建議
  static String getClothingAdvice(String colorName) {
    final color = samples.firstWhere(
      (s) => s['color'] == colorName,
      orElse: () => samples[0],
    );

    final category = color['category'];
    final name = color['color'];

    switch (category) {
      case '暖色':
        return '這是$name，屬於暖色調，適合搭配米色、棕色或深藍色。';
      case '冷色':
        return '這是$name，屬於冷色調，適合搭配白色、灰色或黑色。';
      case '中性色':
        return '這是$name，屬於中性色，非常百搭，可以搭配各種顏色。';
      default:
        return '這是$name。';
    }
  }
}
