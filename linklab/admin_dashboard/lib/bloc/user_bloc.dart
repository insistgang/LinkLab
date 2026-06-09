import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

// Events
abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserLoadRequested extends UserEvent {
  final int page;
  final int pageSize;
  final String? search;
  final UserStatus? status;
  final UserRole? role;
  final String? userType;

  const UserLoadRequested({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.status,
    this.role,
    this.userType,
  });

  @override
  List<Object?> get props => [page, pageSize, search, status, role, userType];
}

class UserSearchChanged extends UserEvent {
  final String search;

  const UserSearchChanged(this.search);

  @override
  List<Object?> get props => [search];
}

class UserFilterChanged extends UserEvent {
  final UserStatus? status;
  final UserRole? role;
  final String? userType;

  const UserFilterChanged({
    this.status,
    this.role,
    this.userType,
  });

  @override
  List<Object?> get props => [status, role, userType];
}

class UserBanRequested extends UserEvent {
  final String userId;
  final String? reason;

  const UserBanRequested(this.userId, {this.reason});

  @override
  List<Object?> get props => [userId, reason];
}

class UserUnbanRequested extends UserEvent {
  final String userId;

  const UserUnbanRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UserVerifyRequested extends UserEvent {
  final String userId;
  final VerificationStatus status;
  final String? reason;

  const UserVerifyRequested(this.userId, this.status, {this.reason});

  @override
  List<Object?> get props => [userId, status, reason];
}

// States
abstract class UserState extends Equatable {
  const UserState();

  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<UserModel> users;
  final int total;
  final int page;
  final int pageSize;
  final String? search;
  final UserStatus? status;
  final UserRole? role;
  final String? userType;

  const UserLoaded({
    required this.users,
    required this.total,
    required this.page,
    required this.pageSize,
    this.search,
    this.status,
    this.role,
    this.userType,
  });

  @override
  List<Object?> get props => [
        users,
        total,
        page,
        pageSize,
        search,
        status,
        role,
        userType,
      ];

  UserLoaded copyWith({
    List<UserModel>? users,
    int? total,
    int? page,
    int? pageSize,
    String? search,
    UserStatus? status,
    UserRole? role,
    String? userType,
  }) {
    return UserLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: status ?? this.status,
      role: role ?? this.role,
      userType: userType ?? this.userType,
    );
  }
}

class UserError extends UserState {
  final String message;

  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserActionSuccess extends UserState {
  final String message;

  const UserActionSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class UserBloc extends Bloc<UserEvent, UserState> {
  final SupabaseService _supabaseService;

  UserBloc({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService(),
        super(UserInitial()) {
    on<UserLoadRequested>(_onLoadRequested);
    on<UserSearchChanged>(_onSearchChanged);
    on<UserFilterChanged>(_onFilterChanged);
    on<UserBanRequested>(_onBanRequested);
    on<UserUnbanRequested>(_onUnbanRequested);
    on<UserVerifyRequested>(_onVerifyRequested);
  }

  Future<void> _onLoadRequested(
    UserLoadRequested event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final response = await _supabaseService.getUsers(
        page: event.page,
        pageSize: event.pageSize,
        search: event.search,
        status: event.status,
        role: event.role,
        userType: event.userType,
      );

      emit(UserLoaded(
        users: response.users,
        total: response.total,
        page: event.page,
        pageSize: event.pageSize,
        search: event.search,
        status: event.status,
        role: event.role,
        userType: event.userType,
      ));
    } catch (e) {
      emit(UserError('加載用戶失敗: ${e.toString()}'));
    }
  }

  Future<void> _onSearchChanged(
    UserSearchChanged event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;
      add(UserLoadRequested(
        page: 1,
        pageSize: currentState.pageSize,
        search: event.search.isEmpty ? null : event.search,
        status: currentState.status,
        role: currentState.role,
        userType: currentState.userType,
      ));
    }
  }

  Future<void> _onFilterChanged(
    UserFilterChanged event,
    Emitter<UserState> emit,
  ) async {
    if (state is UserLoaded) {
      final currentState = state as UserLoaded;
      add(UserLoadRequested(
        page: 1,
        pageSize: currentState.pageSize,
        search: currentState.search,
        status: event.status,
        role: event.role,
        userType: event.userType,
      ));
    }
  }

  Future<void> _onBanRequested(
    UserBanRequested event,
    Emitter<UserState> emit,
  ) async {
    final previousState = state;
    try {
      await _supabaseService.updateUserStatus(event.userId, UserStatus.banned);
      emit(const UserActionSuccess('用戶已封禁'));

      if (previousState is UserLoaded) {
        add(UserLoadRequested(
          page: previousState.page,
          pageSize: previousState.pageSize,
          search: previousState.search,
          status: previousState.status,
          role: previousState.role,
          userType: previousState.userType,
        ));
      }
    } catch (e) {
      emit(UserError('封禁用戶失敗: ${e.toString()}'));
    }
  }

  Future<void> _onUnbanRequested(
    UserUnbanRequested event,
    Emitter<UserState> emit,
  ) async {
    final previousState = state;
    try {
      await _supabaseService.updateUserStatus(event.userId, UserStatus.active);
      emit(const UserActionSuccess('用戶已解封'));

      if (previousState is UserLoaded) {
        add(UserLoadRequested(
          page: previousState.page,
          pageSize: previousState.pageSize,
          search: previousState.search,
          status: previousState.status,
          role: previousState.role,
          userType: previousState.userType,
        ));
      }
    } catch (e) {
      emit(UserError('解封用戶失敗: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyRequested(
    UserVerifyRequested event,
    Emitter<UserState> emit,
  ) async {
    final previousState = state;
    try {
      await _supabaseService.verifyUser(
        event.userId,
        event.status,
        reason: event.reason,
      );
      emit(const UserActionSuccess('認證審覈已更新'));

      if (previousState is UserLoaded) {
        add(UserLoadRequested(
          page: previousState.page,
          pageSize: previousState.pageSize,
          search: previousState.search,
          status: previousState.status,
          role: previousState.role,
          userType: previousState.userType,
        ));
      }
    } catch (e) {
      emit(UserError('審覈失敗: ${e.toString()}'));
    }
  }
}
