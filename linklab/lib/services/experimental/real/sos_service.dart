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

/// SOS 緊急服務
/// 負責處理SOS觸發、廣播和升級策略
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

  // 狀態
  bool _isSOSActive = false;
  String? _currentSOSId;
  Timer? _escalationTimer;
  int _escalationLevel = 0;

  // SOS狀態流
  final _sosStateController = StreamController<SOSState>.broadcast();
  Stream<SOSState> get sosStateStream => _sosStateController.stream;

  bool get isSOSActive => _isSOSActive;
  String? get currentSOSId => _currentSOSId;

  // 電源鍵監聽
  DateTime? _lastPowerKeyTime;
  int _powerKeyCount = 0;
  static const int _powerKeyTriggerCount = 3;
  static const int _powerKeyTimeWindowMs = 3000;

  /// 初始化SOS服務
  void initialize() {
    // 監聽電源鍵（僅Android，需原生代碼配合）
    // 這裏提供方法供原生代碼調用
  }

  /// 處理電源鍵事件
  /// 由原生代碼調用
  Future<void> handlePowerKeyEvent() async {
    final now = DateTime.now();

    if (_lastPowerKeyTime == null ||
        now.difference(_lastPowerKeyTime!).inMilliseconds > _powerKeyTimeWindowMs) {
      // 重置計數
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

  /// 觸發SOS
  ///
  /// [method] 觸發方式: voice, powerButton, longPress, manual
  Future<void> triggerSOS(SOSTriggerMethod method) async {
    if (_isSOSActive) {
      AppLogger.warning('SOS 已在進行中，忽略重複觸發');
      return;
    }

    _isSOSActive = true;
    _escalationLevel = 0;
    _updateSOSState(SOSState.triggering);

    try {
      // 1. 獲取位置
      _updateSOSState(SOSState.gettingLocation);
      final position = await _getCurrentLocation();

      // 2. 震動反饋
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500]);
      }

      // 3. 創建SOS記錄
      final sosId = await _createSOSRecord(method, position);
      _currentSOSId = sosId;

      // 4. 廣播推送
      _updateSOSState(SOSState.broadcasting);
      await _broadcastSOS(sosId, position);

      // 5. 通知緊急聯繫人
      await _notifyEmergencyContacts(position);

      // 6. 啓動升級定時器
      _startEscalationTimer(sosId, position);

      _updateSOSState(SOSState.waitingResponse);

      // 7. 訂閱響應
      _subscribeToSOSResponse(sosId);
    } catch (e) {
      AppLogger.error('SOS 觸發失敗', e);
      _updateSOSState(SOSState.error);
      _isSOSActive = false;
    }
  }

  /// 獲取當前位置
  Future<Position> _getCurrentLocation() async {
    // 檢查權限
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('位置權限被拒絕');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('位置權限被永久拒絕');
    }

    // 獲取高精度位置
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// 創建SOS記錄
  Future<String> _createSOSRecord(SOSTriggerMethod method, Position position) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('用戶未登錄');

    final response = await _supabase.from('help_requests').insert({
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
    }).select('id').single();

    final record = Map<String, dynamic>.from(response as Map);
    return record['id'].toString();
  }

  /// 廣播SOS
  Future<void> _broadcastSOS(String sosId, Position position) async {
    try {
      final seekerId = _supabase.auth.currentUser?.id;
      await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'type': 'sos_broadcast',
          'seekerId': seekerId,
          'helpRequestId': sosId,
          'sosId': sosId,
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
          },
          'radius': 5, // 5km
          'priority': 'critical',
        }),
      );

      // 顯示本地SOS通知
      await _pushService.showSOSNotification(
        title: 'SOS緊急求助已發送',
        body: '正在向周圍志願者發送求助信號...',
        data: {'sos_id': sosId, 'type': 'sos'},
      );
    } catch (e) {
      AppLogger.error('SOS 廣播失敗', e);
    }
  }

  /// 通知緊急聯繫人
  Future<void> _notifyEmergencyContacts(Position position) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 獲取緊急聯繫人
      final contacts = await _supabase
          .from('emergency_contacts')
          .select('*')
          .eq('user_id', userId);

      if (contacts.isEmpty) return;

      final contactRecords = (contacts as List)
          .map((c) => Map<String, dynamic>.from(c as Map))
          .toList();

      // 發送短信通知（通過Edge Function）
      final locationUrl =
          'https://maps.google.com/?q=${position.latitude},${position.longitude}';

      await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'type': 'emergency_sms',
          'contacts': contactRecords.map((c) => c['phone']?.toString()).toList(),
          'message': '【共感LinkAble緊急求助】您的親友觸發了SOS求助，'
              '位置: $locationUrl，請儘快聯繫確認安全。',
        }),
      );
    } catch (e) {
      AppLogger.error('通知緊急聯繫人失敗', e);
    }
  }

  /// 啓動升級定時器
  void _startEscalationTimer(String sosId, Position position) {
    _escalationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      _escalationLevel++;

      switch (_escalationLevel) {
        case 1: // 5分鐘
          await _escalateToCityWide(sosId, position);
          break;
        case 2: // 10分鐘
          await _forceNotifyContacts(sosId, position);
          break;
        case 3: // 15分鐘
          await _escalateToManual(sosId);
          timer.cancel();
          break;
      }

      await _updateSOSMetadata(
        sosId,
        {'escalationLevel': _escalationLevel},
      );
    });
  }

  /// 升級至全城廣播
  Future<void> _escalateToCityWide(String sosId, Position position) async {
    _updateSOSState(SOSState.escalating);

    try {
      await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
        },
        body: jsonEncode({
          'type': 'sos_escalation',
          'sosId': sosId,
          'level': 1,
          'message': 'SOS求助5分鐘無響應，擴大至全城志願者',
        }),
      );
    } catch (e) {
      AppLogger.error('SOS 升級廣播失敗', e);
    }
  }

  /// 強制通知緊急聯繫人
  Future<void> _forceNotifyContacts(String sosId, Position position) async {
    final locationUrl =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';

    await http.post(
      Uri.parse('${AppConstants.supabaseUrl}/functions/v1/push-notifier'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken ?? ''}',
      },
      body: jsonEncode({
        'type': 'emergency_call',
        'message': '【緊急】SOS求助10分鐘無響應，位置: $locationUrl，'
            '請立即聯繫或報警！',
      }),
    );
  }

  /// 升級至人工介入
  Future<void> _escalateToManual(String sosId) async {
    await _supabase.from('help_requests').update({
      'status': 'expired',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', sosId);

    await _updateSOSMetadata(
      sosId,
      {'requiresManualIntervention': true},
    );

    _updateSOSState(SOSState.manualIntervention);
  }

  /// 訂閱SOS響應
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
            final newRecord = Map<String, dynamic>.from(payload.newRecord as Map);
            if (newRecord['type']?.toString() != 'sos') {
              return;
            }
            final status = newRecord['status']?.toString();

            if (status == 'connected') {
              // 有志願者響應
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

  /// 連接到志願者
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
      await _supabase.from('help_requests').update({
        'status': 'cancelled',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', currentSOSId);
    }

    await _clearLocalSOSState(SOSState.cancelled);
  }

  /// 解決SOS
  Future<void> resolveSOS() async {
    _escalationTimer?.cancel();

    final currentSOSId = _currentSOSId;
    if (currentSOSId != null) {
      await _supabase.from('help_requests').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', currentSOSId);
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
      AppLogger.error('更新 SOS 元數據失敗', e);
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

  /// 更新SOS狀態
  void _updateSOSState(SOSState state) {
    _sosStateController.add(state);
  }

  /// 釋放資源
  void dispose() {
    _escalationTimer?.cancel();
    _sosStateController.close();
  }
}

/// SOS觸發方式
enum SOSTriggerMethod {
  voice,        // 語音觸發
  powerButton,  // 電源鍵3次
  longPress,    // 長按3秒
  manual,       // 手動觸發
}

/// SOS狀態
enum SOSState {
  idle,                // 空閒
  triggering,          // 觸發中
  gettingLocation,     // 獲取位置中
  broadcasting,        // 廣播中
  waitingResponse,     // 等待響應
  escalating,          // 升級中
  responded,           // 已響應
  connected,           // 已連接
  manualIntervention,  // 人工介入
  cancelled,           // 已取消
  resolved,            // 已解決
  error,               // 錯誤
}
