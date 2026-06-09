/// 志願者模擬樣本數據
/// 用於演示模式下的志願者匹配結果
class VolunteerSamples {
  /// 演示用志願者列表
  static final List<Map<String, dynamic>> volunteers = [
    {
      'id': 'vol_001',
      'name': '小李',
      'level': '燈塔',
      'levelDesc': '燈塔志願者 - 資深志願者',
      'avatar': 'avatar_1.jpg',
      'distance': 1.2,
      'distanceText': '1.2公里',
      'rating': 4.9,
      'helpCount': 156,
      'specialties': ['日常陪伴', '購物協助', '出行引導'],
      'tags': ['耐心', '熱情', '專業'],
      'responseTime': '平均30秒響應',
      'bio': '我是一名退休教師，有5年志願服務經驗，很高興能幫助您。',
      'languages': ['普通話', '英語'],
      'available': true,
    },
    {
      'id': 'vol_002',
      'name': '張醫生',
      'level': '星辰',
      'levelDesc': '星辰志願者 - 醫療背景',
      'avatar': 'avatar_2.jpg',
      'distance': 2.5,
      'distanceText': '2.5公里',
      'rating': 5.0,
      'helpCount': 89,
      'specialties': ['醫療諮詢', '藥品識別', '健康管理'],
      'tags': ['醫療專業', '細心', '可靠'],
      'responseTime': '平均45秒響應',
      'bio': '我是某醫院退休醫生，擅長醫療諮詢和藥品識別。',
      'languages': ['普通話'],
      'available': true,
    },
    {
      'id': 'vol_003',
      'name': '王阿姨',
      'level': '螢火',
      'levelDesc': '螢火志願者 - 新晉志願者',
      'avatar': 'avatar_3.jpg',
      'distance': 0.8,
      'distanceText': '800米',
      'rating': 4.8,
      'helpCount': 23,
      'specialties': ['情感陪伴', '聊天解悶', '生活協助'],
      'tags': ['親切', '溫暖', '好溝通'],
      'responseTime': '平均20秒響應',
      'bio': '我是一名全職媽媽，希望用我的愛心幫助更多需要幫助的人。',
      'languages': ['普通話', '粵語'],
      'available': true,
    },
    {
      'id': 'vol_004',
      'name': '陳師傅',
      'level': '燈塔',
      'levelDesc': '燈塔志願者 - 資深志願者',
      'avatar': 'avatar_4.jpg',
      'distance': 3.1,
      'distanceText': '3.1公里',
      'rating': 4.9,
      'helpCount': 234,
      'specialties': ['技術協助', '設備使用', '導航引導'],
      'tags': ['技術達人', '耐心', '經驗豐富'],
      'responseTime': '平均35秒響應',
      'bio': '我是一名工程師，擅長幫助解決各種技術問題。',
      'languages': ['普通話', '英語'],
      'available': true,
    },
    {
      'id': 'vol_005',
      'name': '劉老師',
      'level': '星辰',
      'levelDesc': '星辰志願者 - 教育背景',
      'avatar': 'avatar_5.jpg',
      'distance': 1.8,
      'distanceText': '1.8公里',
      'rating': 4.9,
      'helpCount': 112,
      'specialties': ['閱讀協助', '文字識別', '學習輔導'],
      'tags': ['知識淵博', '溫和', '有條理'],
      'responseTime': '平均25秒響應',
      'bio': '我是一名退休語文教師，熱愛閱讀和分享知識。',
      'languages': ['普通話'],
      'available': true,
    },
    {
      'id': 'vol_006',
      'name': '趙大哥',
      'level': '螢火',
      'levelDesc': '螢火志願者 - 新晉志願者',
      'avatar': 'avatar_6.jpg',
      'distance': 0.5,
      'distanceText': '500米',
      'rating': 4.7,
      'helpCount': 12,
      'specialties': ['出行協助', '體力協助', '搬運幫助'],
      'tags': ['強壯', '熱心', '行動力強'],
      'responseTime': '平均15秒響應',
      'bio': '我是一名健身教練，希望能用我的體力幫助需要的人。',
      'languages': ['普通話'],
      'available': true,
    },
  ];

  /// 獲取所有志願者
  static List<Map<String, dynamic>> get all => volunteers;

  /// 根據ID獲取志願者
  static Map<String, dynamic>? getById(String id) {
    try {
      return volunteers.firstWhere((v) => v['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 獲取默認演示志願者（總是返回小李）
  static Map<String, dynamic> getDefaultVolunteer() {
    return volunteers[0]; // 小李
  }

  /// 獲取醫療背景志願者（用於藥品/醫療場景）
  static Map<String, dynamic> getMedicalVolunteer() {
    return volunteers.firstWhere(
      (v) => (v['specialties'] as List).contains('醫療諮詢'),
      orElse: () => volunteers[0],
    );
  }

  /// 獲取最近的志願者
  static Map<String, dynamic> getNearestVolunteer() {
    final sorted = List<Map<String, dynamic>>.from(volunteers)
      ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return sorted.first;
  }

  /// 隨機獲取一個志願者
  static Map<String, dynamic> getRandomVolunteer() {
    final index = DateTime.now().millisecond % volunteers.length;
    return volunteers[index];
  }

  /// 根據專長篩選志願者
  static List<Map<String, dynamic>> getBySpecialty(String specialty) {
    return volunteers.where((v) =>
        (v['specialties'] as List).contains(specialty)).toList();
  }

  /// 獲取志願者等級說明
  static String getLevelDescription(String level) {
    switch (level) {
      case '燈塔':
        return '燈塔志願者 - 資深志願者，服務時長超過100小時';
      case '星辰':
        return '星辰志願者 - 專業背景志願者，具備特定專業技能';
      case '螢火':
        return '螢火志願者 - 新晉志願者，充滿熱情和愛心';
      default:
        return '普通志願者';
    }
  }

  /// 模擬匹配結果（演示用）
  static Map<String, dynamic> getMockMatchResult({
    String? requestType,
    String? preferredVolunteerId,
  }) {
    // 根據請求類型選擇最合適的志願者
    Map<String, dynamic> matchedVolunteer;

    if (requestType == 'medical' || requestType == 'medicine') {
      matchedVolunteer = getMedicalVolunteer();
    } else if (preferredVolunteerId != null) {
      matchedVolunteer = getById(preferredVolunteerId) ?? getDefaultVolunteer();
    } else {
      matchedVolunteer = getDefaultVolunteer();
    }

    // 模擬匹配延遲
    final estimatedWaitTime = matchedVolunteer['responseTime'];
    final matchConfidence = 0.85 + (DateTime.now().millisecond % 15) / 100;

    return {
      'success': true,
      'matchId': 'match_${DateTime.now().millisecondsSinceEpoch}',
      'volunteer': matchedVolunteer,
      'estimatedWaitTime': estimatedWaitTime,
      'matchConfidence': matchConfidence,
      'message': '已爲您匹配到志願者${matchedVolunteer['name']}，正在等待響應...',
    };
  }

  /// 模擬匹配等待隊列（演示用）
  static Map<String, dynamic> getMockQueueStatus() {
    final queuePosition = 1;
    final estimatedWaitSeconds = 5 + DateTime.now().second % 10;

    return {
      'inQueue': true,
      'queuePosition': queuePosition,
      'estimatedWaitSeconds': estimatedWaitSeconds,
      'message': '您當前排在第$queuePosition位，預計等待$estimatedWaitSeconds秒',
    };
  }
}
