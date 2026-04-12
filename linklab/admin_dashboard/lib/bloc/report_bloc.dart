import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import '../models/report_model.dart';
import '../services/supabase_service.dart';

// Events
abstract class ReportEvent extends Equatable {
  const ReportEvent();

  @override
  List<Object?> get props => [];
}

class ReportLoadRequested extends ReportEvent {
  final int page;
  final int pageSize;
  final ReportStatus? status;
  final ReportType? type;

  const ReportLoadRequested({
    this.page = 1,
    this.pageSize = 20,
    this.status,
    this.type,
  });

  @override
  List<Object?> get props => [page, pageSize, status, type];
}

class ReportFilterChanged extends ReportEvent {
  final ReportStatus? status;
  final ReportType? type;

  const ReportFilterChanged({
    this.status,
    this.type,
  });

  @override
  List<Object?> get props => [status, type];
}

class ReportProcessRequested extends ReportEvent {
  final String reportId;
  final ReportStatus status;
  final String result;
  final String? action;

  const ReportProcessRequested({
    required this.reportId,
    required this.status,
    required this.result,
    this.action,
  });

  @override
  List<Object?> get props => [reportId, status, result, action];
}

class ReportLoadStatistics extends ReportEvent {}

// States
abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final List<ReportModel> reports;
  final int page;
  final int pageSize;
  final bool hasMore;
  final ReportStatus? status;
  final ReportType? type;

  const ReportLoaded({
    required this.reports,
    required this.page,
    required this.pageSize,
    this.hasMore = true,
    this.status,
    this.type,
  });

  @override
  List<Object?> get props => [reports, page, pageSize, hasMore, status, type];

  ReportLoaded copyWith({
    List<ReportModel>? reports,
    int? page,
    int? pageSize,
    bool? hasMore,
    ReportStatus? status,
    ReportType? type,
  }) {
    return ReportLoaded(
      reports: reports ?? this.reports,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
      type: type ?? this.type,
    );
  }
}

class ReportStatisticsLoaded extends ReportState {
  final ReportStatistics statistics;

  const ReportStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}

class ReportActionSuccess extends ReportState {
  final String message;

  const ReportActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class ReportBloc extends Bloc<ReportEvent, ReportState> {
  final SupabaseService _supabaseService;

  ReportBloc({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService(),
        super(ReportInitial()) {
    on<ReportLoadRequested>(_onLoadRequested);
    on<ReportFilterChanged>(_onFilterChanged);
    on<ReportProcessRequested>(_onProcessRequested);
    on<ReportLoadStatistics>(_onLoadStatistics);
  }

  Future<void> _onLoadRequested(
    ReportLoadRequested event,
    Emitter<ReportState> emit,
  ) async {
    emit(ReportLoading());
    try {
      final reports = await _supabaseService.getReports(
        page: event.page,
        pageSize: event.pageSize,
        status: event.status,
        type: event.type,
      );

      emit(ReportLoaded(
        reports: reports,
        page: event.page,
        pageSize: event.pageSize,
        hasMore: reports.length == event.pageSize,
        status: event.status,
        type: event.type,
      ));
    } catch (e) {
      emit(ReportError('加载举报失败: ${e.toString()}'));
    }
  }

  Future<void> _onFilterChanged(
    ReportFilterChanged event,
    Emitter<ReportState> emit,
  ) async {
    if (state is ReportLoaded) {
      final currentState = state as ReportLoaded;
      add(ReportLoadRequested(
        page: 1,
        pageSize: currentState.pageSize,
        status: event.status,
        type: event.type,
      ));
    }
  }

  Future<void> _onProcessRequested(
    ReportProcessRequested event,
    Emitter<ReportState> emit,
  ) async {
    try {
      await _supabaseService.processReport(
        event.reportId,
        status: event.status,
        result: event.result,
        action: event.action,
      );
      emit(const ReportActionSuccess('举报处理成功'));

      // 刷新列表
      if (state is ReportLoaded) {
        final currentState = state as ReportLoaded;
        add(ReportLoadRequested(
          page: currentState.page,
          pageSize: currentState.pageSize,
          status: currentState.status,
          type: currentState.type,
        ));
      }
    } catch (e) {
      emit(ReportError('处理举报失败: ${e.toString()}'));
    }
  }

  Future<void> _onLoadStatistics(
    ReportLoadStatistics event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final statistics = await _supabaseService.getReportStatistics();
      emit(ReportStatisticsLoaded(statistics));
    } catch (e) {
      emit(ReportError('加载统计失败: ${e.toString()}'));
    }
  }
}
