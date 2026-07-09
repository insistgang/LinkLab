import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_models.freezed.dart';
part 'community_models.g.dart';

/// 兴趣小组模型
@freezed
class InterestGroup with _$InterestGroup {
  const factory InterestGroup({
    required String id,
    required String name,
    required String description,
    required String category,
    String? iconUrl,
    @Default(0) int memberCount,
    @Default(0) int postCount,
    @Default(false) bool isJoined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _InterestGroup;

  factory InterestGroup.fromJson(Map<String, dynamic> json) =>
      _$InterestGroupFromJson(json);
}

/// 小组消息模型
@freezed
class GroupMessage with _$GroupMessage {
  const factory GroupMessage({
    required String id,
    required String groupId,
    required String userId,
    required String content,
    String? userName,
    String? userAvatar,
    @Default([]) List<String> attachments,
    @Default(0) int likeCount,
    @Default(false) bool isLiked,
    DateTime? createdAt,
  }) = _GroupMessage;

  factory GroupMessage.fromJson(Map<String, dynamic> json) =>
      _$GroupMessageFromJson(json);
}

/// 地区社群模型
@freezed
class RegionalCommunity with _$RegionalCommunity {
  const factory RegionalCommunity({
    required String id,
    required String city,
    required String province,
    String? description,
    double? latitude,
    double? longitude,
    @Default(0) int memberCount,
    @Default(0) int eventCount,
    @Default(false) bool isJoined,
    String? coverImage,
    DateTime? createdAt,
  }) = _RegionalCommunity;

  factory RegionalCommunity.fromJson(Map<String, dynamic> json) =>
      _$RegionalCommunityFromJson(json);
}

/// 社群活动模型
@freezed
class CommunityEvent with _$CommunityEvent {
  const factory CommunityEvent({
    required String id,
    required String communityId,
    required String title,
    String? description,
    required DateTime startTime,
    DateTime? endTime,
    String? location,
    double? latitude,
    double? longitude,
    @Default(0) int participantCount,
    @Default(0) int maxParticipants,
    String? coverImage,
    @Default('upcoming') String status,
    DateTime? createdAt,
  }) = _CommunityEvent;

  factory CommunityEvent.fromJson(Map<String, dynamic> json) =>
      _$CommunityEventFromJson(json);
}

/// 精选故事模型
@freezed
class FeaturedStory with _$FeaturedStory {
  const factory FeaturedStory({
    required String id,
    required String title,
    required String content,
    String? summary,
    String? coverImage,
    @Default('anonymous') String authorType,
    String? authorName,
    String? authorAvatar,
    @Default(0) int likeCount,
    @Default(0) int readCount,
    @Default(false) bool isLiked,
    @Default('pending') String status,
    DateTime? featuredDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _FeaturedStory;

  factory FeaturedStory.fromJson(Map<String, dynamic> json) =>
      _$FeaturedStoryFromJson(json);
}

/// 新手训练模型
@freezed
class NewbieTraining with _$NewbieTraining {
  const factory NewbieTraining({
    required String id,
    required String volunteerId,
    @Default(0) int completedScenarios,
    @Default(3) int totalScenarios,
    @Default(false) bool isGraduated,
    String? mentorId,
    String? mentorName,
    DateTime? startedAt,
    DateTime? graduatedAt,
    DateTime? updatedAt,
  }) = _NewbieTraining;

  factory NewbieTraining.fromJson(Map<String, dynamic> json) =>
      _$NewbieTrainingFromJson(json);
}

/// 模拟场景模型
@freezed
class TrainingScenario with _$TrainingScenario {
  const factory TrainingScenario({
    required String id,
    required String title,
    required String description,
    required String type,
    String? imageUrl,
    String? audioUrl,
    @Default([]) List<String> hints,
    @Default([]) List<String> expectedActions,
    @Default(false) bool isCompleted,
    DateTime? completedAt,
  }) = _TrainingScenario;

  factory TrainingScenario.fromJson(Map<String, dynamic> json) =>
      _$TrainingScenarioFromJson(json);
}

/// 内容审核结果模型
@freezed
class ModerationResult with _$ModerationResult {
  const factory ModerationResult({
    required bool isApproved,
    required double confidence,
    String? category,
    String? reason,
    @Default([]) List<String> flaggedKeywords,
  }) = _ModerationResult;

  factory ModerationResult.fromJson(Map<String, dynamic> json) =>
      _$ModerationResultFromJson(json);
}

/// 小组分类枚举
class GroupCategory {
  static const String medical = 'medical';
  static const String translation = 'translation';
  static const String psychological = 'psychological';
  static const String technical = 'technical';
  static const String other = 'other';

  static const Map<String, String> labels = {
    medical: '医疗辅助组',
    translation: '外语翻译组',
    psychological: '心理支持组',
    technical: '技术指导组',
    other: '其他',
  };

  static String getLabel(String category) {
    return labels[category] ?? '其他';
  }
}

/// 故事状态枚举
class StoryStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String featured = 'featured';
}

/// 训练场景类型枚举
class ScenarioType {
  static const String ocr = 'ocr';
  static const String sceneDescription = 'scene_description';
  static const String navigation = 'navigation';
  static const String emergency = 'emergency';

  static const Map<String, String> labels = {
    ocr: 'OCR识别场景',
    sceneDescription: '场景描述场景',
    navigation: '导航指引场景',
    emergency: '紧急情况场景',
  };

  static String getLabel(String type) {
    return labels[type] ?? '综合场景';
  }
}
