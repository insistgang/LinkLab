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
  final ReportStatistics? statistics;

  const ReportLoaded({
    required this.reports,
    required this.page,
    required this.pageSize,
    this.hasMore = true,
    this.status,
    this.type,
    this.statistics,
  });

  @override
  List<Object?> get props => [
        reports,
        page,
        pageSize,
        hasMore,
        status,
        type,
        statistics,
      ];

  ReportLoaded copyWith({
    List<ReportModel>? reports,
    int? page,
    int? pageSize,
    bool? hasMore,
    ReportStatus? status,
    ReportType? type,
    ReportStatistics? statistics,
  }) {
    return ReportLoaded(
      reports: reports ?? this.reports,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      hasMore: hasMore ?? this.hasMore,
      status: status ?? this.status,
      type: type ?? this.type,
      statistics: statistics ?? this.statistics,
    );
  }
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
    final previousState = state is ReportLoaded ? state as ReportLoaded : null;
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
        statistics: previousState?.statistics,
      ));
    } catch (e) {
      emit(ReportError('加載舉報失敗: ${e.toString()}'));
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
    final previousState = state;
    try {
      await _supabaseService.processReport(
        event.reportId,
        status: event.status,
        result: event.result,
        action: event.action,
      );
      emit(const ReportActionSuccess('舉報處理成功'));

      if (previousState is ReportLoaded) {
        add(ReportLoadRequested(
          page: previousState.page,
          pageSize: previousState.pageSize,
          status: previousState.status,
          type: previousState.type,
        ));
        add(ReportLoadStatistics());
      }
    } catch (e) {
      emit(ReportError('處理舉報失敗: ${e.toString()}'));
    }
  }

  Future<void> _onLoadStatistics(
    ReportLoadStatistics event,
    Emitter<ReportState> emit,
  ) async {
    try {
      final statistics = await _supabaseService.getReportStatistics();
      if (state is ReportLoaded) {
        emit((state as ReportLoaded).copyWith(statistics: statistics));
      } else {
        emit(ReportLoaded(
          reports: const [],
          page: 1,
          pageSize: AppConstants.defaultPageSize,
          hasMore: false,
          statistics: statistics,
        ));
      }
    } catch (e) {
      emit(ReportError('加載統計失敗: ${e.toString()}'));
    }
  }
}
