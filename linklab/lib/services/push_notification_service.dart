import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/logger.dart';

/// 推送通知服務
/// 負責FCM集成、本地通知和後臺消息處理
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  SupabaseClient? _supabaseClient;
  SupabaseClient get _supabase {
    if (!Supabase.instance.isInitialized) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  // 通知點擊回調
  Function(Map<String, dynamic>)? _onNotificationTap;

  /// 初始化推送服務
  Future<void> initialize({Function(Map<String, dynamic>)? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    // 請求權限
    await _requestPermissions();

    // 初始化本地通知
    await _initLocalNotifications();

    // 設置FCM回調
    _setupFCMCallbacks();

    // 獲取並上傳FCM Token
    await _updateFCMToken();

    // 監聽Token刷新
    _fcm.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// 請求通知權限
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true, // 允許緊急通知
    );

    AppLogger.info('通知權限狀態: ${settings.authorizationStatus}');
  }

  /// 初始化本地通知
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _onNotificationTap?.call(data);
        }
      },
    );
  }

  /// 設置FCM回調
  void _setupFCMCallbacks() {
    // 前臺消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 後臺/終止狀態點擊通知
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // 獲取終止狀態的通知點擊
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationOpen(message);
      }
    });
  }

  /// 處理前臺消息
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // 根據類型顯示不同優先級通知
    final priority = data['priority'] ?? 'normal';

    if (priority == 'sos' || priority == 'high') {
      // 高優先級通知（SOS或求助）
      await _showHighPriorityNotification(
        title: notification.title ?? '新消息',
        body: notification.body ?? '',
        data: data,
      );
    } else {
      // 普通通知
      await _showLocalNotification(
        title: notification.title ?? '新消息',
        body: notification.body ?? '',
        data: data,
      );
    }
  }

  /// 顯示本地通知
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      '默認通知',
      channelDescription: '一般通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// 顯示高優先級通知（繞過勿擾模式）
  Future<void> _showHighPriorityNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'high_priority_channel',
      '高優先級通知',
      channelDescription: '求助和SOS通知',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      sound: const RawResourceAndroidNotificationSound('emergency'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'emergency.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0, // 固定ID，避免重複
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// 處理通知點擊
  void _handleNotificationOpen(RemoteMessage message) {
    _onNotificationTap?.call(message.data);
  }

  /// 獲取並更新FCM Token
  Future<void> _updateFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _onTokenRefresh(token);
      }
    } catch (e) {
      AppLogger.error('獲取 FCM Token 失敗', e);
    }
  }

  /// Token刷新回調
  Future<void> _onTokenRefresh(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_devices').upsert(
        {
          'user_id': userId,
          'fcm_token': token,
          'platform': 'flutter',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      AppLogger.error('上傳 FCM Token 失敗', e);
    }
  }

  /// 訂閱主題
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  /// 取消訂閱主題
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  /// 顯示SOS通知（最高優先級）
  Future<void> showSOSNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS緊急求助',
      channelDescription: 'SOS緊急求助通知',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.call,
      sound: const RawResourceAndroidNotificationSound('sos_alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 500, 500, 500, 500, 500, 500]),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'sos_alarm.wav',
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999, // SOS固定ID
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// 取消SOS通知
  Future<void> cancelSOSNotification() async {
    await _localNotifications.cancel(999);
  }
}

/// 後臺消息處理（頂級函數）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // 處理後臺消息
  final notification = message.notification;
  final data = message.data;

  if (notification != null) {
    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'background_channel',
      '後臺通知',
      channelDescription: '應用後臺時接收的通知',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await localNotifications.show(
      DateTime.now().millisecond,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(data),
    );
  }
}
