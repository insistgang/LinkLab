/// 志愿者模拟样本数据
/// 用于演示模式下的志愿者匹配结果
class VolunteerSamples {
  /// 演示用志愿者列表
  static final List<Map<String, dynamic>> volunteers = [
    {
      'id': 'vol_001',
      'name': '小李',
      'level': '灯塔',
      'levelDesc': '灯塔志愿者 - 资深志愿者',
      'avatar': 'avatar_1.jpg',
      'distance': 1.2,
      'distanceText': '1.2公里',
      'rating': 4.9,
      'helpCount': 156,
      'specialties': ['日常陪伴', '购物协助', '出行引导'],
      'tags': ['耐心', '热情', '专业'],
      'responseTime': '平均30秒响应',
      'bio': '我是一名退休教师，有5年志愿服务经验，很高兴能帮助您。',
      'languages': ['普通话', '英语'],
      'available': true,
    },
    {
      'id': 'vol_002',
      'name': '张医生',
      'level': '星辰',
      'levelDesc': '星辰志愿者 - 医疗背景',
      'avatar': 'avatar_2.jpg',
      'distance': 2.5,
      'distanceText': '2.5公里',
      'rating': 5.0,
      'helpCount': 89,
      'specialties': ['医疗咨询', '药品识别', '健康管理'],
      'tags': ['医疗专业', '细心', '可靠'],
      'responseTime': '平均45秒响应',
      'bio': '我是某医院退休医生，擅长医疗咨询和药品识别。',
      'languages': ['普通话'],
      'available': true,
    },
    {
      'id': 'vol_003',
      'name': '王阿姨',
      'level': '萤火',
      'levelDesc': '萤火志愿者 - 新晋志愿者',
      'avatar': 'avatar_3.jpg',
      'distance': 0.8,
      'distanceText': '800米',
      'rating': 4.8,
      'helpCount': 23,
      'specialties': ['情感陪伴', '聊天解闷', '生活协助'],
      'tags': ['亲切', '温暖', '好沟通'],
      'responseTime': '平均20秒响应',
      'bio': '我是一名全职妈妈，希望用我的爱心帮助更多需要帮助的人。',
      'languages': ['普通话', '粤语'],
      'available': true,
    },
    {
      'id': 'vol_004',
      'name': '陈师傅',
      'level': '灯塔',
      'levelDesc': '灯塔志愿者 - 资深志愿者',
      'avatar': 'avatar_4.jpg',
      'distance': 3.1,
      'distanceText': '3.1公里',
      'rating': 4.9,
      'helpCount': 234,
      'specialties': ['技术协助', '设备使用', '导航引导'],
      'tags': ['技术达人', '耐心', '经验丰富'],
      'responseTime': '平均35秒响应',
      'bio': '我是一名工程师，擅长帮助解决各种技术问题。',
      'languages': ['普通话', '英语'],
      'available': true,
    },
    {
      'id': 'vol_005',
      'name': '刘老师',
      'level': '星辰',
      'levelDesc': '星辰志愿者 - 教育背景',
      'avatar': 'avatar_5.jpg',
      'distance': 1.8,
      'distanceText': '1.8公里',
      'rating': 4.9,
      'helpCount': 112,
      'specialties': ['阅读协助', '文字识别', '学习辅导'],
      'tags': ['知识渊博', '温和', '有条理'],
      'responseTime': '平均25秒响应',
      'bio': '我是一名退休语文教师，热爱阅读和分享知识。',
      'languages': ['普通话'],
      'available': true,
    },
    {
      'id': 'vol_006',
      'name': '赵大哥',
      'level': '萤火',
      'levelDesc': '萤火志愿者 - 新晋志愿者',
      'avatar': 'avatar_6.jpg',
      'distance': 0.5,
      'distanceText': '500米',
      'rating': 4.7,
      'helpCount': 12,
      'specialties': ['出行协助', '体力协助', '搬运帮助'],
      'tags': ['强壮', '热心', '行动力强'],
      'responseTime': '平均15秒响应',
      'bio': '我是一名健身教练，希望能用我的体力帮助需要的人。',
      'languages': ['普通话'],
      'available': true,
    },
  ];

  /// 获取所有志愿者
  static List<Map<String, dynamic>> get all => volunteers;

  /// 根据ID获取志愿者
  static Map<String, dynamic>? getById(String id) {
    try {
      return volunteers.firstWhere((v) => v['id'] == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取默认演示志愿者（总是返回小李）
  static Map<String, dynamic> getDefaultVolunteer() {
    return volunteers[0]; // 小李
  }

  /// 获取医疗背景志愿者（用于药品/医疗场景）
  static Map<String, dynamic> getMedicalVolunteer() {
    return volunteers.firstWhere(
      (v) => (v['specialties'] as List).contains('医疗咨询'),
      orElse: () => volunteers[0],
    );
  }

  /// 获取最近的志愿者
  static Map<String, dynamic> getNearestVolunteer() {
    final sorted = List<Map<String, dynamic>>.from(volunteers)
      ..sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
    return sorted.first;
  }

  /// 随机获取一个志愿者
  static Map<String, dynamic> getRandomVolunteer() {
    final index = DateTime.now().millisecond % volunteers.length;
    return volunteers[index];
  }

  /// 根据专长筛选志愿者
  static List<Map<String, dynamic>> getBySpecialty(String specialty) {
    return volunteers.where((v) =>
        (v['specialties'] as List).contains(specialty)).toList();
  }

  /// 获取志愿者等级说明
  static String getLevelDescription(String level) {
    switch (level) {
      case '灯塔':
        return '灯塔志愿者 - 资深志愿者，服务时长超过100小时';
      case '星辰':
        return '星辰志愿者 - 专业背景志愿者，具备特定专业技能';
      case '萤火':
        return '萤火志愿者 - 新晋志愿者，充满热情和爱心';
      default:
        return '普通志愿者';
    }
  }

  /// 模拟匹配结果（演示用）
  static Map<String, dynamic> getMockMatchResult({
    String? requestType,
    String? preferredVolunteerId,
  }) {
    // 根据请求类型选择最合适的志愿者
    Map<String, dynamic> matchedVolunteer;

    if (requestType == 'medical' || requestType == 'medicine') {
      matchedVolunteer = getMedicalVolunteer();
    } else if (preferredVolunteerId != null) {
      matchedVolunteer = getById(preferredVolunteerId) ?? getDefaultVolunteer();
    } else {
      matchedVolunteer = getDefaultVolunteer();
    }

    // 模拟匹配延迟
    final estimatedWaitTime = matchedVolunteer['responseTime'];
    final matchConfidence = 0.85 + (DateTime.now().millisecond % 15) / 100;

    return {
      'success': true,
      'matchId': 'match_${DateTime.now().millisecondsSinceEpoch}',
      'volunteer': matchedVolunteer,
      'estimatedWaitTime': estimatedWaitTime,
      'matchConfidence': matchConfidence,
      'message': '已为您匹配到志愿者${matchedVolunteer['name']}，正在等待响应...',
    };
  }

  /// 模拟匹配等待队列（演示用）
  static Map<String, dynamic> getMockQueueStatus() {
    final queuePosition = 1;
    final estimatedWaitSeconds = 5 + DateTime.now().second % 10;

    return {
      'inQueue': true,
      'queuePosition': queuePosition,
      'estimatedWaitSeconds': estimatedWaitSeconds,
      'message': '您当前排在第$queuePosition位，预计等待${estimatedWaitSeconds}秒',
    };
  }
}
