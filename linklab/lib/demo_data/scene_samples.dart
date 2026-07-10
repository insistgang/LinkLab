/// 场景描述模拟样本数据
/// 用于演示模式下的环境描述结果
class SceneSamples {
  /// 室内场景样本
  static final List<Map<String, dynamic>> indoorScenes = [
    {
      'id': 'living_room',
      'image': 'living_room.jpg',
      'description': '这是一个客厅场景。前方约2米处有一张棕色皮质沙发，右侧约1.5米处有一扇窗户，左侧有一扇白色的门。中间有约1.5米宽的通道可以通行。地面铺着浅色地毯，整体环境整洁。',
      'objects': [
        {'name': '沙发', 'direction': '前方', 'distance': 2.0},
        {'name': '窗户', 'direction': '右侧', 'distance': 1.5},
        {'name': '门', 'direction': '左侧', 'distance': 1.0},
      ],
      'safetyNotes': ['地面平整，可以安全通行'],
    },
    {
      'id': 'bedroom',
      'image': 'bedroom.jpg',
      'description': '这是一个卧室场景。前方约1.5米处有一张大床，床上铺着蓝色的床单。右侧约2米处有一个衣柜，左侧约1米处有一扇窗户。床边有约1米宽的通道可以绕行。',
      'objects': [
        {'name': '床', 'direction': '前方', 'distance': 1.5},
        {'name': '衣柜', 'direction': '右侧', 'distance': 2.0},
        {'name': '窗户', 'direction': '左侧', 'distance': 1.0},
      ],
      'safetyNotes': ['床边通道较窄，请注意'],
    },
    {
      'id': 'kitchen',
      'image': 'kitchen.jpg',
      'description': '这是一个厨房场景。前方约2米处是灶台和水槽，右侧约1米处是冰箱，左侧是操作台面。中间有约1.2米宽的通道可以通行。地面是防滑瓷砖。',
      'objects': [
        {'name': '灶台', 'direction': '前方', 'distance': 2.0},
        {'name': '冰箱', 'direction': '右侧', 'distance': 1.0},
        {'name': '操作台', 'direction': '左侧', 'distance': 0.8},
      ],
      'safetyNotes': ['厨房地面可能有水渍，请小心行走'],
    },
    {
      'id': 'corridor',
      'image': 'corridor.jpg',
      'description': '这是一个走廊场景。前方约3米处有拐角，右侧约1米处有一把椅子，左侧墙壁平整。走廊宽度约1.5米，可以顺畅通行。尽头有一盏灯亮着。',
      'objects': [
        {'name': '拐角', 'direction': '前方', 'distance': 3.0},
        {'name': '椅子', 'direction': '右侧', 'distance': 1.0},
        {'name': '墙壁', 'direction': '左侧', 'distance': 0.5},
      ],
      'safetyNotes': ['前方拐角处请注意', '右侧有椅子，注意避让'],
    },
    {
      'id': 'office',
      'image': 'office.jpg',
      'description': '这是一个办公室场景。前方约2米处有一张办公桌，桌上有电脑和文件。右侧约1.5米处有一把办公椅，左侧是文件柜。中间有约1.5米宽的通道。',
      'objects': [
        {'name': '办公桌', 'direction': '前方', 'distance': 2.0},
        {'name': '办公椅', 'direction': '右侧', 'distance': 1.5},
        {'name': '文件柜', 'direction': '左侧', 'distance': 1.0},
      ],
      'safetyNotes': ['地面平整'],
    },
  ];

  /// 室外场景样本
  static final List<Map<String, dynamic>> outdoorScenes = [
    {
      'id': 'street_crossing',
      'image': 'street_crossing.jpg',
      'description': '这是一个街道场景。前方约5米处有斑马线，右侧是人行道，左侧有树木和花坛。天气晴朗，光线充足。前方约10米处有一个红绿灯。',
      'objects': [
        {'name': '斑马线', 'direction': '前方', 'distance': 5.0},
        {'name': '人行道', 'direction': '右侧', 'distance': 0.5},
        {'name': '树木', 'direction': '左侧', 'distance': 1.0},
        {'name': '红绿灯', 'direction': '前方', 'distance': 10.0},
      ],
      'safetyNotes': ['过马路前请确认红绿灯状态'],
    },
    {
      'id': 'park',
      'image': 'park.jpg',
      'description': '这是一个公园场景。前方约3米处有一条石板路，右侧约2米处有长椅，左侧是草坪和树木。环境安静，空气清新。',
      'objects': [
        {'name': '石板路', 'direction': '前方', 'distance': 3.0},
        {'name': '长椅', 'direction': '右侧', 'distance': 2.0},
        {'name': '草坪', 'direction': '左侧', 'distance': 1.5},
      ],
      'safetyNotes': ['石板路可能有缝隙，请注意脚下'],
    },
    {
      'id': 'bus_stop',
      'image': 'bus_stop.jpg',
      'description': '这是一个公交站台场景。前方约1米处是公交站牌，右侧约0.5米处是候车座椅，左侧是马路。站牌上显示有多条公交线路。',
      'objects': [
        {'name': '站牌', 'direction': '前方', 'distance': 1.0},
        {'name': '座椅', 'direction': '右侧', 'distance': 0.5},
        {'name': '马路', 'direction': '左侧', 'distance': 2.0},
      ],
      'safetyNotes': ['注意左侧来往车辆'],
    },
    {
      'id': 'shopping_mall',
      'image': 'shopping_mall.jpg',
      'description': '这是一个商场入口场景。前方约2米处是自动门，右侧是电梯入口，左侧是服务台。地面是大理石材质，比较光滑。',
      'objects': [
        {'name': '自动门', 'direction': '前方', 'distance': 2.0},
        {'name': '电梯', 'direction': '右侧', 'distance': 1.5},
        {'name': '服务台', 'direction': '左侧', 'distance': 1.0},
      ],
      'safetyNotes': ['地面较光滑，请小心行走', '自动门开关时请注意'],
    },
  ];

  /// 获取所有场景
  static List<Map<String, dynamic>> get allScenes => [...indoorScenes, ...outdoorScenes];

  /// 根据ID获取场景
  static Map<String, dynamic>? getById(String id) {
    try {
      return allScenes.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 随机获取一个场景
  static Map<String, dynamic> getRandom() {
    final index = DateTime.now().millisecond % allScenes.length;
    return allScenes[index];
  }

  /// 随机获取室内场景
  static Map<String, dynamic> getRandomIndoor() {
    final index = DateTime.now().millisecond % indoorScenes.length;
    return indoorScenes[index];
  }

  /// 随机获取室外场景
  static Map<String, dynamic> getRandomOutdoor() {
    final index = DateTime.now().millisecond % outdoorScenes.length;
    return outdoorScenes[index];
  }
}
