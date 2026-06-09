import 'package:freezed_annotation/freezed_annotation.dart';

part 'skill_model.freezed.dart';
part 'skill_model.g.dart';

/// 技能標籤模型
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

  /// 技能圖標（emoji）
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

/// 預設技能標籤定義
class SkillDefinitions {
  static const List<SkillModel> all = [
    // 醫療輔助
    SkillModel(
      id: 'medical_basic',
      name: '醫療輔助',
      category: 'medical',
      description: '基礎醫療知識，可協助用藥指導、健康諮詢',
      requiresVerification: true,
    ),
    SkillModel(
      id: 'medical_nursing',
      name: '護理陪護',
      category: 'medical',
      description: '專業護理技能，可協助日常護理',
      requiresVerification: true,
    ),

    // 外語翻譯
    SkillModel(
      id: 'lang_english',
      name: '英語翻譯',
      category: 'language',
      description: '英語口譯和筆譯',
    ),
    SkillModel(
      id: 'lang_japanese',
      name: '日語翻譯',
      category: 'language',
      description: '日語口譯和筆譯',
    ),
    SkillModel(
      id: 'lang_korean',
      name: '韓語翻譯',
      category: 'language',
      description: '韓語口譯和筆譯',
    ),
    SkillModel(
      id: 'lang_french',
      name: '法語翻譯',
      category: 'language',
      description: '法語口譯和筆譯',
    ),
    SkillModel(
      id: 'lang_german',
      name: '德語翻譯',
      category: 'language',
      description: '德語口譯和筆譯',
    ),
    SkillModel(
      id: 'lang_spanish',
      name: '西班牙語翻譯',
      category: 'language',
      description: '西班牙語口譯和筆譯',
    ),

    // 技術指導
    SkillModel(
      id: 'tech_mobile',
      name: '手機操作',
      category: 'tech',
      description: '協助智能手機設置、APP使用等',
    ),
    SkillModel(
      id: 'tech_computer',
      name: '電腦操作',
      category: 'tech',
      description: '協助電腦操作、軟件使用等',
    ),
    SkillModel(
      id: 'tech_internet',
      name: '網絡購物',
      category: 'tech',
      description: '協助網購、支付、訂單查詢等',
    ),

    // 心理支持
    SkillModel(
      id: 'psych_counseling',
      name: '心理諮詢',
      category: 'psychology',
      description: '提供情緒疏導和心理支持',
      requiresVerification: true,
    ),
    SkillModel(
      id: 'psych_companion',
      name: '陪伴聊天',
      category: 'psychology',
      description: '提供陪伴和傾聽',
    ),

    // 出行導航
    SkillModel(
      id: 'nav_outdoor',
      name: '戶外導航',
      category: 'navigation',
      description: '協助路線規劃、交通查詢等',
    ),
    SkillModel(
      id: 'nav_transport',
      name: '交通協助',
      category: 'navigation',
      description: '協助打車、公交地鐵換乘等',
    ),

    // 生活常識
    SkillModel(
      id: 'life_cooking',
      name: '烹飪指導',
      category: 'life',
      description: '提供烹飪方法和食譜指導',
    ),
    SkillModel(
      id: 'life_cleaning',
      name: '家務整理',
      category: 'life',
      description: '提供家務整理和清潔建議',
    ),
    SkillModel(
      id: 'life_shopping',
      name: '購物協助',
      category: 'life',
      description: '協助商品選擇、價格比較等',
    ),

    // 手語
    SkillModel(
      id: 'sign_language',
      name: '手語翻譯',
      category: 'sign_language',
      description: '手語翻譯服務',
      requiresVerification: true,
    ),
  ];

  /// 按分類獲取技能
  static List<SkillModel> getByCategory(String category) {
    return all.where((s) => s.category == category).toList();
  }

  /// 獲取所有分類
  static List<String> get categories {
    return all.map((s) => s.category).whereType<String>().toSet().toList();
  }

  /// 根據ID獲取技能
  static SkillModel? getById(String id) {
    try {
      return all.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 獲取分類顯示名稱
  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'medical':
        return '醫療輔助';
      case 'language':
        return '外語翻譯';
      case 'tech':
        return '技術指導';
      case 'psychology':
        return '心理支持';
      case 'navigation':
        return '出行導航';
      case 'life':
        return '生活常識';
      case 'sign_language':
        return '手語翻譯';
      default:
        return '其他';
    }
  }
}

/// 技能認證申請
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
