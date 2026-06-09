import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/dashboard_model.dart';
import '../services/supabase_service.dart';

// Events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {}

class DashboardRefreshRequested extends DashboardEvent {}

class DashboardLoadTrendData extends DashboardEvent {
  final DateTime startDate;
  final DateTime endDate;

  const DashboardLoadTrendData({
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object?> get props => [startDate, endDate];
}

// States
abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardMetrics metrics;
  final TrendData? trendData;
  final UserDistribution? distribution;

  const DashboardLoaded({
    required this.metrics,
    this.trendData,
    this.distribution,
  });

  @override
  List<Object?> get props => [metrics, trendData, distribution];

  DashboardLoaded copyWith({
    DashboardMetrics? metrics,
    TrendData? trendData,
    UserDistribution? distribution,
  }) {
    return DashboardLoaded(
      metrics: metrics ?? this.metrics,
      trendData: trendData ?? this.trendData,
      distribution: distribution ?? this.distribution,
    );
  }
}

class DashboardError extends DashboardState {
  final String message;

  const DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final SupabaseService _supabaseService;

  DashboardBloc({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService(),
        super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardLoadTrendData>(_onLoadTrendData);
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      final metrics = await _supabaseService.getDashboardMetrics();
      final distribution = await _supabaseService.getDistributionData();

      // 獲取最近7天趨勢數據
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 7));
      final trendData = await _supabaseService.getTrendData(
        startDate: startDate,
        endDate: endDate,
      );

      emit(DashboardLoaded(
        metrics: metrics,
        trendData: trendData,
        distribution: distribution,
      ));
    } catch (e) {
      emit(DashboardError('加載數據失敗: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        final metrics = await _supabaseService.getDashboardMetrics();
        emit(currentState.copyWith(metrics: metrics));
      } catch (e) {
        emit(DashboardError('刷新數據失敗: ${e.toString()}'));
      }
    }
  }

  Future<void> _onLoadTrendData(
    DashboardLoadTrendData event,
    Emitter<DashboardState> emit,
  ) async {
    if (state is DashboardLoaded) {
      final currentState = state as DashboardLoaded;
      try {
        final trendData = await _supabaseService.getTrendData(
          startDate: event.startDate,
          endDate: event.endDate,
        );
        emit(currentState.copyWith(trendData: trendData));
      } catch (e) {
        // 不覆蓋錯誤狀態，保持當前數據
      }
    }
  }
}
