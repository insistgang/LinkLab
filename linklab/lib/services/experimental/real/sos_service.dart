import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vibration/vibration.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';
import '../../push_notification_service.dart';
import 'webrtc_service.dart';

/// SOS 紧急服务
/// 负责处理SOS触发、广播和升级策略
class SOSService {
  static final SOSService _instance = SOSService._internal();
  factory SOSService() => _instance;
  SOSService._internal();

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  PushNotificationService? _pushServiceInstance;
  PushNotificationService get _pushService {
    _pushServiceInstance ??= PushNotificationService();
    return _pushServiceInstance!;
  }

  WebRTCService? _webRTCServiceInstance;
  WebRTCService get _webRTCService {
    _webRTCServiceInstance ??= WebRTCService();
    return _webRTCServiceInstance!;
  }

  // 状态
  bool _isSOSActive = false;
  String? _currentSOSId;
  Timer? _escalationTimer;
  int _escalationLevel = 0;

  // SOS状态流
  final _sosStateController = StreamController<SOSState>.broadcast();
  Stream<SOSState> get sosStateStream => _sosStateController.stream;

  bool get isSOSActive => _isSOSActive;
  String? get currentSOSId => _currentSOSId;

  // 电源键监听
  DateTime? _lastPowerKeyTime;
  int _powerKeyCount = 0;
  static const int _powerKeyTriggerCount = 3;
  static const int _powerKeyTimeWindowMs = 3000;

  /// 初始化SOS服务
  void initialize() {
    // 监听电源键（仅Android，需原生代码配合）
    // 这里提供方法供原生代码调用
  }

  /// 处理电源键事件
  /// 由原生代码调用
  Future<void> handlePowerKeyEvent() async {
    final now = DateTime.now();

    if (_lastPowerKeyTime == null ||
        now.difference(_lastPowerKeyTime!).inMilliseconds >
            _powerKeyTimeWindowMs) {
      // 重置计数
      _powerKeyCount = 1;
    } else {
      _powerKeyCount++;
    }

    _lastPowerKeyTime = now;

    if (_powerKeyCount >= _powerKeyTriggerCount) {
      _powerKeyCount = 0;
      await triggerSOS(SOSTriggerMethod.powerButton);
    }
  }

  /// 触发SOS
  ///
  /// [method] 触发方式: voice, powerButton, longPress, manual
  Future<void> triggerSOS(SOSTriggerMethod method) async {
    if (_isSOSActive) {
      AppLogger.warning('SOS 已在进行中，忽略重复触发');
      return;
    }

    _isSOSActive = true;
    _escalationLevel = 0;
    _updateSOSState(SOSState.triggering);

    try {
      // 1. 获取位置
      _updateSOSState(SOSState.gettingLocation);
      final position = await _getCurrentLocation();

      // 2. 震动反馈
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      }

      // 3. 创建SOS记录
      final sosId = await _createSOSRecord(method, position);
      _currentSOSId = sosId;

      // 4. 广播推送
      _updateSOSState(SOSState.broadcasting);
      await _broadcastSOS(sosId, position);

      // 5. 通知紧急联系人
      await _notifyEmergencyContacts(sosId, position);

      // 6. 启动升级定时器
      _startEscalationTimer(sosId, position);

      _updateSOSState(SOSState.waitingResponse);

      // 7. 订阅响应
      _subscribeToSOSResponse(sosId);
    } catch (e) {
      AppLogger.error('SOS 触发失败', e);
      _updateSOSState(SOSState.error);
      _isSOSActive = false;
    }
  }

  /// 获取当前位置
  Future<Position> _getCurrentLocation() async {
    // 检查权限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('位置权限被拒绝');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('位置权限被永久拒绝');
    }

    // 获取高精度位置
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// 创建SOS记录
  Future<String> _createSOSRecord(
    SOSTriggerMethod method,
    Position position,
  ) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('用户未登录');

    final response = await _supabase
        .from('help_requests')
        .insert({
          'seeker_id': userId,
          'type': 'sos',
          'intent': 'sos_${method.name}',
          'urgency': 'emergency',
          'status': 'matching',
          'help_type': 'sos',
          'latitude': position.latitude,
          'longitude': position.longitude,
          'ai_response': {
            'triggerMethod': method.name,
            'locationAccuracy': position.accuracy,
            'escalationLevel': 0,
          },
        })
        .select('id')
        .single();

    final record = Map<String, dynamic>.from(response as Map);
    return record['id'].toString();
  }

  /// 广播SOS
  Future<void> _broadcastSOS(String sosId, Position position) async {
    try {
      final seekerId = _supabase.auth.currentUser?.id;
      await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'type': 'sos_broadcast',
          'seekerId': seekerId,
          'helpRequestId': sosId,
          'sosId': sosId,
          'location': {'lat': position.latitude, 'lng': position.longitude},
          'radius': 5, // 5km
          'priority': 'critical',
        }),
      );

      // 显示本地SOS通知
      await _pushService.showSOSNotification(
        title: 'SOS紧急求助已发送',
        body: '正在向周围志愿者发送求助信号...',
        data: {'sos_id': sosId, 'type': 'sos'},
      );
    } catch (e) {
      AppLogger.error('SOS 广播失败', e);
    }
  }

  /// 通知紧急联系人
  Future<void> _notifyEmergencyContacts(String sosId, Position position) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 获取紧急联系人
      final contacts = await _supabase
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', userId);

      if (contacts.isEmpty) return;

      final contactRecords = (contacts as List)
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();

      // 发送短信通知（通过Edge Function）
      final locationUrl =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'type': 'emergency_sms',
          'sosId': sosId,
          'contacts': contactRecords
              .map((c) => c['phone']?.toString())
              .toList(),
          'message':
              '【共感LinkAble紧急求助】您的亲友触发了SOS求助，'
              '位置: $locationUrl，请尽快联系确认安全。',
        }),
      );
    } catch (e) {
      AppLogger.error('通知紧急联系人失败', e);
    }
  }

  /// 启动升级定时器
  void _startEscalationTimer(String sosId, Position position) {
    _escalationTimer = Timer.periodic(const Duration(minutes: 5), (
      timer,
    ) async {
      _escalationLevel++;

      switch (_escalationLevel) {
        case 1: // 5分钟
          await _escalateToCityWide(sosId, position);
          break;
        case 2: // 10分钟
          await _forceNotifyContacts(sosId, position);
          break;
        case 3: // 15分钟
          await _escalateToManual(sosId);
          timer.cancel();
          break;
      }

      await _updateSOSMetadata(sosId, {'escalationLevel': _escalationLevel});
    });
  }

  /// 升级至全城广播
  Future<void> _escalateToCityWide(String sosId, Position position) async {
    _updateSOSState(SOSState.escalating);

    try {
      await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'type': 'sos_escalation',
          'sosId': sosId,
          'level': 1,
          'message': 'SOS求助5分钟无响应，扩大至全城志愿者',
        }),
      );
    } catch (e) {
      AppLogger.error('SOS 升级广播失败', e);
    }
  }

  /// 强制通知紧急联系人
  Future<void> _forceNotifyContacts(String sosId, Position position) async {
    final locationUrl =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';

    await http.post(
      Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
      },
      body: jsonEncode({
        'type': 'emergency_call',
        'sosId': sosId,
        'message':
            '【紧急】SOS求助10分钟无响应，位置: $locationUrl，'
            '请立即联系或报警！',
      }),
    );
  }

  /// 升级至人工介入
  Future<void> _escalateToManual(String sosId) async {
    await _supabase
        .from('help_requests')
        .update({
          'status': 'expired',
          'completed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sosId);

    await _updateSOSMetadata(sosId, {'requiresManualIntervention': true});

    _updateSOSState(SOSState.manualIntervention);
  }

  /// 订阅SOS响应
  void _subscribeToSOSResponse(String sosId) {
    _supabase
        .channel('sos:$sosId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'help_requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: sosId,
          ),
          callback: (payload) async {
            final newRecord = Map<String, dynamic>.from(
              payload.newRecord as Map,
            );
            if (newRecord['type']?.toString() != 'sos') {
              return;
            }
            final status = newRecord['status']?.toString();

            if (status == 'connected') {
              // 有志愿者响应
              _escalationTimer?.cancel();
              _updateSOSState(SOSState.responded);

              final volunteerId = newRecord['volunteer_id']?.toString();
              if (volunteerId != null) {
                await _connectToVolunteer(sosId, volunteerId);
              }
            } else if (status == 'completed') {
              await _clearLocalSOSState(SOSState.resolved);
            } else if (status == 'cancelled' || status == 'expired') {
              await _clearLocalSOSState(SOSState.cancelled);
            }
          },
        )
        .subscribe();
  }

  /// 连接到志愿者
  Future<void> _connectToVolunteer(String sosId, String volunteerId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    // 初始化WebRTC
    await _webRTCService.initializeCallAsSeeker(
      seekerId: userId,
      helpRequestId: sosId,
    );

    _updateSOSState(SOSState.connected);
  }

  /// 取消SOS
  Future<void> cancelSOS() async {
    _escalationTimer?.cancel();

    final currentSOSId = _currentSOSId;
    if (currentSOSId != null) {
      await _supabase
          .from('help_requests')
          .update({
            'status': 'cancelled',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentSOSId);
    }

    await _clearLocalSOSState(SOSState.cancelled);
  }

  /// 解决SOS
  Future<void> resolveSOS() async {
    _escalationTimer?.cancel();

    final currentSOSId = _currentSOSId;
    if (currentSOSId != null) {
      await _supabase
          .from('help_requests')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', currentSOSId);
    }

    await _clearLocalSOSState(SOSState.resolved);
  }

  Future<void> _updateSOSMetadata(
    String helpRequestId,
    Map<String, dynamic> delta,
  ) async {
    try {
      final response = await _supabase
          .from('help_requests')
          .select('ai_response')
          .eq('id', helpRequestId)
          .maybeSingle();

      final current = response == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(
              response['ai_response'] as Map? ?? <String, dynamic>{},
            );
      current.addAll(delta);

      await _supabase
          .from('help_requests')
          .update({'ai_response': current})
          .eq('id', helpRequestId);
    } catch (e) {
      AppLogger.error('更新 SOS 元数据失败', e);
    }
  }

  Future<void> _clearLocalSOSState(SOSState terminalState) async {
    _escalationTimer?.cancel();
    await _pushService.cancelSOSNotification();
    _isSOSActive = false;
    _currentSOSId = null;
    _escalationLevel = 0;
    _updateSOSState(terminalState);
  }

  /// 更新SOS状态
  void _updateSOSState(SOSState state) {
    _sosStateController.add(state);
  }

  /// 释放资源
  void dispose() {
    _escalationTimer?.cancel();
    _sosStateController.close();
  }
}

/// SOS触发方式
enum SOSTriggerMethod {
  voice, // 语音触发
  powerButton, // 电源键3次
  longPress, // 长按3秒
  manual, // 手动触发
}

/// SOS状态
enum SOSState {
  idle, // 空闲
  triggering, // 触发中
  gettingLocation, // 获取位置中
  broadcasting, // 广播中
  waitingResponse, // 等待响应
  escalating, // 升级中
  responded, // 已响应
  connected, // 已连接
  manualIntervention, // 人工介入
  cancelled, // 已取消
  resolved, // 已解决
  error, // 错误
}
