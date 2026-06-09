import 'package:freezed_annotation/freezed_annotation.dart';

part 'community_models.freezed.dart';
part 'community_models.g.dart';

/// 興趣小組模型
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

/// 小組消息模型
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

/// 地區社羣模型
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

/// 社羣活動模型
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

/// 精選故事模型
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

/// 新手訓練模型
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

/// 模擬場景模型
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

/// 內容審覈結果模型
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

/// 小組分類枚舉
class GroupCategory {
  static const String medical = 'medical';
  static const String translation = 'translation';
  static const String psychological = 'psychological';
  static const String technical = 'technical';
  static const String other = 'other';

  static const Map<String, String> labels = {
    medical: '醫療輔助組',
    translation: '外語翻譯組',
    psychological: '心理支持組',
    technical: '技術指導組',
    other: '其他',
  };

  static String getLabel(String category) {
    return labels[category] ?? '其他';
  }
}

/// 故事狀態枚舉
class StoryStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
  static const String featured = 'featured';
}

/// 訓練場景類型枚舉
class ScenarioType {
  static const String ocr = 'ocr';
  static const String sceneDescription = 'scene_description';
  static const String navigation = 'navigation';
  static const String emergency = 'emergency';

  static const Map<String, String> labels = {
    ocr: 'OCR識別場景',
    sceneDescription: '場景描述場景',
    navigation: '導航指引場景',
    emergency: '緊急情況場景',
  };

  static String getLabel(String type) {
    return labels[type] ?? '綜合場景';
  }
}
