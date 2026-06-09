import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/community/featured_story_service.dart';

/// 精選故事服務 Provider
final featuredStoryProvider = Provider<FeaturedStoryService>((ref) {
  return FeaturedStoryService();
});
