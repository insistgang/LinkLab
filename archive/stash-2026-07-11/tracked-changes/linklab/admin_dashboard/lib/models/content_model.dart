import '../constants/app_constants.dart';

// 精选故事模型
class StoryModel {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String? coverImage;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final ContentStatus status;
  final DateTime createdAt;
  final DateTime? publishedAt;
  final int viewCount;
  final int likeCount;
  final List<String>? tags;
  final bool isFeatured;

  StoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    this.coverImage,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.status = ContentStatus.draft,
    required this.createdAt,
    this.publishedAt,
    this.viewCount = 0,
    this.likeCount = 0,
    this.tags,
    this.isFeatured = false,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    return StoryModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      summary: json['summary'] ?? '',
      coverImage: json['cover_image'],
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      authorAvatar: json['author_avatar'],
      status: ContentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContentStatus.draft,
      ),
      createdAt: DateTime.parse(json['created_at']),
      publishedAt: json['published_at'] != null
          ? DateTime.parse(json['published_at'])
          : null,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      isFeatured: json['is_featured'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'summary': summary,
      'cover_image': coverImage,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'published_at': publishedAt?.toIso8601String(),
      'view_count': viewCount,
      'like_count': likeCount,
      'tags': tags,
      'is_featured': isFeatured,
    };
  }

  String get statusText {
    switch (status) {
      case ContentStatus.draft:
        return '草稿';
      case ContentStatus.published:
        return '已发布';
      case ContentStatus.archived:
        return '已下架';
    }
  }
}

// 社群内容模型
class CommunityContentModel {
  final String id;
  final String content;
  final String? imageUrl;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String groupId;
  final String groupName;
  final ContentStatus status;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool isPinned;

  CommunityContentModel({
    required this.id,
    required this.content,
    this.imageUrl,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.groupId,
    required this.groupName,
    this.status = ContentStatus.published,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isPinned = false,
  });

  factory CommunityContentModel.fromJson(Map<String, dynamic> json) {
    return CommunityContentModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      authorAvatar: json['author_avatar'],
      groupId: json['group_id'] ?? '',
      groupName: json['group_name'] ?? '',
      status: ContentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ContentStatus.published,
      ),
      createdAt: DateTime.parse(json['created_at']),
      likeCount: json['like_count'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
      isPinned: json['is_pinned'] ?? false,
    );
  }
}

// 评论模型
class CommentModel {
  final String id;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String targetId; // 故事ID或内容ID
  final String targetType; // 'story' 或 'community'
  final DateTime createdAt;
  final bool isReported;
  final int reportCount;

  CommentModel({
    required this.id,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.targetId,
    required this.targetType,
    required this.createdAt,
    this.isReported = false,
    this.reportCount = 0,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      authorId: json['author_id'] ?? '',
      authorName: json['author_name'] ?? '',
      authorAvatar: json['author_avatar'],
      targetId: json['target_id'] ?? '',
      targetType: json['target_type'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
      isReported: json['is_reported'] ?? false,
      reportCount: json['report_count'] ?? 0,
    );
  }
}
