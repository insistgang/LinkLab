import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import '../models/content_model.dart';
import '../services/supabase_service.dart';

// Events
abstract class ContentEvent extends Equatable {
  const ContentEvent();

  @override
  List<Object?> get props => [];
}

class ContentLoadStoriesRequested extends ContentEvent {
  final int page;
  final int pageSize;
  final ContentStatus? status;
  final bool? isFeatured;

  const ContentLoadStoriesRequested({
    this.page = 1,
    this.pageSize = 20,
    this.status,
    this.isFeatured,
  });

  @override
  List<Object?> get props => [page, pageSize, status, isFeatured];
}

class ContentLoadCommunityRequested extends ContentEvent {
  final int page;
  final int pageSize;
  final ContentStatus? status;

  const ContentLoadCommunityRequested({
    this.page = 1,
    this.pageSize = 20,
    this.status,
  });

  @override
  List<Object?> get props => [page, pageSize, status];
}

class ContentUpdateStoryStatus extends ContentEvent {
  final String storyId;
  final ContentStatus status;

  const ContentUpdateStoryStatus(this.storyId, this.status);

  @override
  List<Object?> get props => [storyId, status];
}

class ContentSetStoryFeatured extends ContentEvent {
  final String storyId;
  final bool isFeatured;

  const ContentSetStoryFeatured(this.storyId, this.isFeatured);

  @override
  List<Object?> get props => [storyId, isFeatured];
}

class ContentUpdateCommunityStatus extends ContentEvent {
  final String contentId;
  final ContentStatus status;

  const ContentUpdateCommunityStatus(this.contentId, this.status);

  @override
  List<Object?> get props => [contentId, status];
}

// States
abstract class ContentState extends Equatable {
  const ContentState();

  @override
  List<Object?> get props => [];
}

class ContentInitial extends ContentState {}

class ContentLoading extends ContentState {}

class ContentStoriesLoaded extends ContentState {
  final List<StoryModel> stories;
  final int page;
  final int pageSize;
  final bool hasMore;

  const ContentStoriesLoaded({
    required this.stories,
    required this.page,
    required this.pageSize,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [stories, page, pageSize, hasMore];

  ContentStoriesLoaded copyWith({
    List<StoryModel>? stories,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return ContentStoriesLoaded(
      stories: stories ?? this.stories,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ContentCommunityLoaded extends ContentState {
  final List<CommunityContentModel> contents;
  final int page;
  final int pageSize;
  final bool hasMore;

  const ContentCommunityLoaded({
    required this.contents,
    required this.page,
    required this.pageSize,
    this.hasMore = true,
  });

  @override
  List<Object?> get props => [contents, page, pageSize, hasMore];

  ContentCommunityLoaded copyWith({
    List<CommunityContentModel>? contents,
    int? page,
    int? pageSize,
    bool? hasMore,
  }) {
    return ContentCommunityLoaded(
      contents: contents ?? this.contents,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ContentError extends ContentState {
  final String message;

  const ContentError(this.message);

  @override
  List<Object?> get props => [message];
}

class ContentActionSuccess extends ContentState {
  final String message;

  const ContentActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ContentBloc extends Bloc<ContentEvent, ContentState> {
  final SupabaseService _supabaseService;

  ContentBloc({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService(),
        super(ContentInitial()) {
    on<ContentLoadStoriesRequested>(_onLoadStories);
    on<ContentLoadCommunityRequested>(_onLoadCommunity);
    on<ContentUpdateStoryStatus>(_onUpdateStoryStatus);
    on<ContentSetStoryFeatured>(_onSetStoryFeatured);
    on<ContentUpdateCommunityStatus>(_onUpdateCommunityStatus);
  }

  Future<void> _onLoadStories(
    ContentLoadStoriesRequested event,
    Emitter<ContentState> emit,
  ) async {
    emit(ContentLoading());
    try {
      final stories = await _supabaseService.getStories(
        page: event.page,
        pageSize: event.pageSize,
        status: event.status,
        isFeatured: event.isFeatured,
      );

      emit(ContentStoriesLoaded(
        stories: stories,
        page: event.page,
        pageSize: event.pageSize,
        hasMore: stories.length == event.pageSize,
      ));
    } catch (e) {
      emit(ContentError('加载故事失败: ${e.toString()}'));
    }
  }

  Future<void> _onLoadCommunity(
    ContentLoadCommunityRequested event,
    Emitter<ContentState> emit,
  ) async {
    emit(ContentLoading());
    try {
      final contents = await _supabaseService.getCommunityContent(
        page: event.page,
        pageSize: event.pageSize,
        status: event.status,
      );

      emit(ContentCommunityLoaded(
        contents: contents,
        page: event.page,
        pageSize: event.pageSize,
        hasMore: contents.length == event.pageSize,
      ));
    } catch (e) {
      emit(ContentError('加载社群内容失败: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateStoryStatus(
    ContentUpdateStoryStatus event,
    Emitter<ContentState> emit,
  ) async {
    try {
      await _supabaseService.updateStoryStatus(event.storyId, event.status);
      emit(ContentActionSuccess('故事状态已更新'));

      // 刷新列表
      if (state is ContentStoriesLoaded) {
        final currentState = state as ContentStoriesLoaded;
        add(ContentLoadStoriesRequested(
          page: currentState.page,
          pageSize: currentState.pageSize,
        ));
      }
    } catch (e) {
      emit(ContentError('更新故事状态失败: ${e.toString()}'));
    }
  }

  Future<void> _onSetStoryFeatured(
    ContentSetStoryFeatured event,
    Emitter<ContentState> emit,
  ) async {
    try {
      await _supabaseService.setStoryFeatured(event.storyId, event.isFeatured);
      emit(ContentActionSuccess(event.isFeatured ? '已设为精选' : '已取消精选'));

      // 刷新列表
      if (state is ContentStoriesLoaded) {
        final currentState = state as ContentStoriesLoaded;
        add(ContentLoadStoriesRequested(
          page: currentState.page,
          pageSize: currentState.pageSize,
        ));
      }
    } catch (e) {
      emit(ContentError('设置精选失败: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateCommunityStatus(
    ContentUpdateCommunityStatus event,
    Emitter<ContentState> emit,
  ) async {
    try {
      await _supabaseService.updateContentStatus(event.contentId, event.status);
      emit(ContentActionSuccess('内容状态已更新'));

      // 刷新列表
      if (state is ContentCommunityLoaded) {
        final currentState = state as ContentCommunityLoaded;
        add(ContentLoadCommunityRequested(
          page: currentState.page,
          pageSize: currentState.pageSize,
        ));
      }
    } catch (e) {
      emit(ContentError('更新内容状态失败: ${e.toString()}'));
    }
  }
}

