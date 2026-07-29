import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_model.freezed.dart';
part 'skill_model.g.dart';

/// 技能标签模型
@freezed
class SkillModel with _$SkillModel {
  const factory SkillModel({
    required String id,
    required String name,
    String? category,
    String? description,
    String? iconUrl,
    @Default(false) bool requiresVerification,
    @Default(false) bool isVerified,
    String? certificateUrl,
    DateTime? verifiedAt,
  }) = _SkillModel;

  factory SkillModel.fromJson(Map<String, dynamic> json) =>
      _$SkillModelFromJson(json);

  const SkillModel._();

  /// 技能图标（emoji）
  String get iconEmoji {
    switch (category) {
      case 'medical':
        return '🏥';
      case 'language':
        return '🌐';
      case 'tech':
        return '💻';
      case 'psychology':
        return '🧠';
      case 'navigation':
        return '🧭';
      case 'life':
        return '🏠';
      case 'sign_language':
        return '👋';
      default:
        return '⭐';
    }
  }
}

/// 预设技能标签定义
class SkillDefinitions {
  static const List<SkillModel> all = [
    // 医疗辅助
    SkillModel(
      id: 'medical_basic',
      name: '医疗辅助',
      category: 'medical',
      description: '基础医疗知识，可协助用药指导、健康谘询',
      requiresVerification: true,
    ),
    SkillModel(
      id: 'medical_nursing',
      name: '护理陪护',
      category: 'medical',
      description: '专业护理技能，可协助日常护理',
      requiresVerification: true,
    ),

    // 外语翻译
    SkillModel(
      id: 'lang_english',
      name: '英语翻译',
      category: 'language',
      description: '英语口译和笔译',
    ),
    SkillModel(
      id: 'lang_japanese',
      name: '日语翻译',
      category: 'language',
      description: '日语口译和笔译',
    ),
    SkillModel(
      id: 'lang_korean',
      name: '韩语翻译',
      category: 'language',
      description: '韩语口译和笔译',
    ),
    SkillModel(
      id: 'lang_french',
      name: '法语翻译',
      category: 'language',
      description: '法语口译和笔译',
    ),
    SkillModel(
      id: 'lang_german',
      name: '德语翻译',
      category: 'language',
      description: '德语口译和笔译',
    ),
    SkillModel(
      id: 'lang_spanish',
      name: '西班牙语翻译',
      category: 'language',
      description: '西班牙语口译和笔译',
    ),

    // 技术指导
    SkillModel(
      id: 'tech_mobile',
      name: '手机操作',
      category: 'tech',
      description: '协助智能手机设置、APP使用等',
    ),
    SkillModel(
      id: 'tech_computer',
      name: '电脑操作',
      category: 'tech',
      description: '协助电脑操作、软件使用等',
    ),
    SkillModel(
      id: 'tech_internet',
      name: '网络购物',
      category: 'tech',
      description: '协助网购、支付、订单查询等',
    ),

    // 心理支持
    SkillModel(
      id: 'psych_counseling',
      name: '心理谘询',
      category: 'psychology',
      description: '提供情绪疏导和心理支持',
      requiresVerification: true,
    ),
    SkillModel(
      id: 'psych_companion',
      name: '陪伴聊天',
      category: 'psychology',
      description: '提供陪伴和倾听',
    ),

    // 出行导航
    SkillModel(
      id: 'nav_outdoor',
      name: '户外导航',
      category: 'navigation',
      description: '协助路线规划、交通查询等',
    ),
    SkillModel(
      id: 'nav_transport',
      name: '交通协助',
      category: 'navigation',
      description: '协助打车、公交地铁换乘等',
    ),

    // 生活常识
    SkillModel(
      id: 'life_cooking',
      name: '烹饪指导',
      category: 'life',
      description: '提供烹饪方法和食谱指导',
    ),
    SkillModel(
      id: 'life_cleaning',
      name: '家务整理',
      category: 'life',
      description: '提供家务整理和清洁建议',
    ),
    SkillModel(
      id: 'life_shopping',
      name: '购物协助',
      category: 'life',
      description: '协助商品选择、价格比较等',
    ),

    // 手语
    SkillModel(
      id: 'sign_language',
      name: '手语翻译',
      category: 'sign_language',
      description: '手语翻译服务',
      requiresVerification: true,
    ),
  ];

  /// 按分类获取技能
  static List<SkillModel> getByCategory(String category) {
    return all.where((s) => s.category == category).toList();
  }

  /// 获取所有分类
  static List<String> get categories {
    return all.map((s) => s.category).whereType<String>().toSet().toList();
  }

  /// 根据ID获取技能
  static SkillModel? getById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取分类显示名称
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'medical':
        return '医疗辅助';
      case 'language':
        return '外语翻译';
      case 'tech':
        return '技术指导';
      case 'psychology':
        return '心理支持';
      case 'navigation':
        return '出行导航';
      case 'life':
        return '生活常识';
      case 'sign_language':
        return '手语翻译';
      default:
        return '其他';
    }
  }
}

/// 技能认证申请
@freezed
class SkillVerificationRequest with _$SkillVerificationRequest {
  const factory SkillVerificationRequest({
    required String id,
    required String volunteerId,
    required String skillId,
    String? skillName,
    String? certificateUrl,
    String? description,
    @Default('pending') String status,
    String? reviewerNote,
    DateTime? submittedAt,
    DateTime? reviewedAt,
  }) = _SkillVerificationRequest;

  factory SkillVerificationRequest.fromJson(Map<String, dynamic> json) =>
      _$SkillVerificationRequestFromJson(json);
}
