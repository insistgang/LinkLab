import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 推送通知服务
/// 负责FCM集成、本地通知和后台消息处理
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

  // 通知点击回调
  Function(Map<String, dynamic>)? _onNotificationTap;

  /// 初始化推送服务
  Future<void> initialize({Function(Map<String, dynamic>)? onNotificationTap}) async {
    _onNotificationTap = onNotificationTap;

    // 请求权限
    await _requestPermissions();

    // 初始化本地通知
    await _initLocalNotifications();

    // 设置FCM回调
    _setupFCMCallbacks();

    // 获取并上传FCM Token
    await _updateFCMToken();

    // 监听Token刷新
    _fcm.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// 请求通知权限
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true, // 允许紧急通知
    );

    print('通知权限状态: ${settings.authorizationStatus}');
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

  /// 设置FCM回调
  void _setupFCMCallbacks() {
    // 前台消息
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 后台/终止状态点击通知
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpen);

    // 获取终止状态的通知点击
    _fcm.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationOpen(message);
      }
    });
  }

  /// 处理前台消息
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    if (notification == null) return;

    // 根据类型显示不同优先级通知
    final priority = data['priority'] ?? 'normal';

    if (priority == 'sos' || priority == 'high') {
      // 高优先级通知（SOS或求助）
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

  /// 显示本地通知
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      '默认通知',
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

  /// 显示高优先级通知（绕过勿扰模式）
  Future<void> _showHighPriorityNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_priority_channel',
      '高优先级通知',
      channelDescription: '求助和SOS通知',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      sound: RawResourceAndroidNotificationSound('emergency'),
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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0, // 固定ID，避免重复
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// 处理通知点击
  void _handleNotificationOpen(RemoteMessage message) {
    _onNotificationTap?.call(message.data);
  }

  /// 获取并更新FCM Token
  Future<void> _updateFCMToken() async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _onTokenRefresh(token);
      }
    } catch (e) {
      print('获取FCM Token失败: $e');
    }
  }

  /// Token刷新回调
  Future<void> _onTokenRefresh(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.from('user_devices').upsert({
        'user_id': userId,
        'fcm_token': token,
        'platform': 'flutter',
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('上传FCM Token失败: $e');
    }
  }

  /// 订阅主题
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
  }

  /// 取消订阅主题
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  /// 显示SOS通知（最高优先级）
  Future<void> showSOSNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'sos_channel',
      'SOS紧急求助',
      channelDescription: 'SOS紧急求助通知',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      ongoing: true,
      autoCancel: false,
      category: AndroidNotificationCategory.call,
      sound: RawResourceAndroidNotificationSound('sos_alarm'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 500, 500, 500, 500, 500, 500]),
      ledColor: Color.fromARGB(255, 255, 0, 0),
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

    const details = NotificationDetails(
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

/// 后台消息处理（顶级函数）
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  // 处理后台消息
  final notification = message.notification;
  final data = message.data;

  if (notification != null) {
    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'background_channel',
      '后台通知',
      channelDescription: '应用后台时接收的通知',
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
