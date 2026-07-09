import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/community/featured_story_service.dart';

/// 精选故事服务 Provider
final featuredStoryProvider = Provider<FeaturedStoryService>((ref) {
  return FeaturedStoryService();
});
