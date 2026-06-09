/// 場景描述模擬樣本數據
/// 用於演示模式下的環境描述結果
class SceneSamples {
  /// 室內場景樣本
  static final List<Map<String, dynamic>> indoorScenes = [
    {
      'id': 'living_room',
      'image': 'living_room.jpg',
      'description': '這是一個客廳場景。前方約2米處有一張棕色皮質沙發，右側約1.5米處有一扇窗戶，左側有一扇白色的門。中間有約1.5米寬的通道可以通行。地面鋪着淺色地毯，整體環境整潔。',
      'objects': [
        {'name': '沙發', 'direction': '前方', 'distance': 2.0},
        {'name': '窗戶', 'direction': '右側', 'distance': 1.5},
        {'name': '門', 'direction': '左側', 'distance': 1.0},
      ],
      'safetyNotes': ['地面平整，可以安全通行'],
    },
    {
      'id': 'bedroom',
      'image': 'bedroom.jpg',
      'description': '這是一個臥室場景。前方約1.5米處有一張大牀，牀上鋪着藍色的牀單。右側約2米處有一個衣櫃，左側約1米處有一扇窗戶。牀邊有約1米寬的通道可以繞行。',
      'objects': [
        {'name': '牀', 'direction': '前方', 'distance': 1.5},
        {'name': '衣櫃', 'direction': '右側', 'distance': 2.0},
        {'name': '窗戶', 'direction': '左側', 'distance': 1.0},
      ],
      'safetyNotes': ['牀邊通道較窄，請注意'],
    },
    {
      'id': 'kitchen',
      'image': 'kitchen.jpg',
      'description': '這是一個廚房場景。前方約2米處是竈臺和水槽，右側約1米處是冰箱，左側是操作檯面。中間有約1.2米寬的通道可以通行。地面是防滑瓷磚。',
      'objects': [
        {'name': '竈臺', 'direction': '前方', 'distance': 2.0},
        {'name': '冰箱', 'direction': '右側', 'distance': 1.0},
        {'name': '操作檯', 'direction': '左側', 'distance': 0.8},
      ],
      'safetyNotes': ['廚房地面可能有水漬，請小心行走'],
    },
    {
      'id': 'corridor',
      'image': 'corridor.jpg',
      'description': '這是一個走廊場景。前方約3米處有拐角，右側約1米處有一把椅子，左側牆壁平整。走廊寬度約1.5米，可以順暢通行。盡頭有一盞燈亮着。',
      'objects': [
        {'name': '拐角', 'direction': '前方', 'distance': 3.0},
        {'name': '椅子', 'direction': '右側', 'distance': 1.0},
        {'name': '牆壁', 'direction': '左側', 'distance': 0.5},
      ],
      'safetyNotes': ['前方拐角處請注意', '右側有椅子，注意避讓'],
    },
    {
      'id': 'office',
      'image': 'office.jpg',
      'description': '這是一個辦公室場景。前方約2米處有一張辦公桌，桌上有電腦和文件。右側約1.5米處有一把辦公椅，左側是文件櫃。中間有約1.5米寬的通道。',
      'objects': [
        {'name': '辦公桌', 'direction': '前方', 'distance': 2.0},
        {'name': '辦公椅', 'direction': '右側', 'distance': 1.5},
        {'name': '文件櫃', 'direction': '左側', 'distance': 1.0},
      ],
      'safetyNotes': ['地面平整'],
    },
  ];

  /// 室外場景樣本
  static final List<Map<String, dynamic>> outdoorScenes = [
    {
      'id': 'street_crossing',
      'image': 'street_crossing.jpg',
      'description': '這是一個街道場景。前方約5米處有斑馬線，右側是人行道，左側有樹木和花壇。天氣晴朗，光線充足。前方約10米處有一個紅綠燈。',
      'objects': [
        {'name': '斑馬線', 'direction': '前方', 'distance': 5.0},
        {'name': '人行道', 'direction': '右側', 'distance': 0.5},
        {'name': '樹木', 'direction': '左側', 'distance': 1.0},
        {'name': '紅綠燈', 'direction': '前方', 'distance': 10.0},
      ],
      'safetyNotes': ['過馬路前請確認紅綠燈狀態'],
    },
    {
      'id': 'park',
      'image': 'park.jpg',
      'description': '這是一個公園場景。前方約3米處有一條石板路，右側約2米處有長椅，左側是草坪和樹木。環境安靜，空氣清新。',
      'objects': [
        {'name': '石板路', 'direction': '前方', 'distance': 3.0},
        {'name': '長椅', 'direction': '右側', 'distance': 2.0},
        {'name': '草坪', 'direction': '左側', 'distance': 1.5},
      ],
      'safetyNotes': ['石板路可能有縫隙，請注意腳下'],
    },
    {
      'id': 'bus_stop',
      'image': 'bus_stop.jpg',
      'description': '這是一個公交站臺場景。前方約1米處是公交站牌，右側約0.5米處是候車座椅，左側是馬路。站牌上顯示有多條公交線路。',
      'objects': [
        {'name': '站牌', 'direction': '前方', 'distance': 1.0},
        {'name': '座椅', 'direction': '右側', 'distance': 0.5},
        {'name': '馬路', 'direction': '左側', 'distance': 2.0},
      ],
      'safetyNotes': ['注意左側來往車輛'],
    },
    {
      'id': 'shopping_mall',
      'image': 'shopping_mall.jpg',
      'description': '這是一個商場入口場景。前方約2米處是自動門，右側是電梯入口，左側是服務檯。地面是大理石材質，比較光滑。',
      'objects': [
        {'name': '自動門', 'direction': '前方', 'distance': 2.0},
        {'name': '電梯', 'direction': '右側', 'distance': 1.5},
        {'name': '服務檯', 'direction': '左側', 'distance': 1.0},
      ],
      'safetyNotes': ['地面較光滑，請小心行走', '自動門開關時請注意'],
    },
  ];

  /// 獲取所有場景
  static List<Map<String, dynamic>> get allScenes => [...indoorScenes, ...outdoorScenes];

  /// 根據ID獲取場景
  static Map<String, dynamic>? getById(String id) {
    try {
      return allScenes.firstWhere((s) => s['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 隨機獲取一個場景
  static Map<String, dynamic> getRandom() {
    final index = DateTime.now().millisecond % allScenes.length;
    return allScenes[index];
  }

  /// 隨機獲取室內場景
  static Map<String, dynamic> getRandomIndoor() {
    final index = DateTime.now().millisecond % indoorScenes.length;
    return indoorScenes[index];
  }

  /// 隨機獲取室外場景
  static Map<String, dynamic> getRandomOutdoor() {
    final index = DateTime.now().millisecond % outdoorScenes.length;
    return outdoorScenes[index];
  }
}
