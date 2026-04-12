import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/logger.dart';
import '../../models/emergency_contact_model.dart';
import '../push_notification_service.dart';

/// 紧急联系人服务
class EmergencyContactService {
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

  /// 获取用户的紧急联系人
  Future<List<EmergencyContactModel>> getContacts(String userId) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('priority', ascending: true);

      return (response as List)
          .map((json) => EmergencyContactModel.fromJson(json))
          .toList();
    } catch (e) {
      AppLogger.error('获取紧急联系人失败', e);
      return [];
    }
  }

  /// 添加紧急联系人
  Future<EmergencyContactModel?> addContact({
    required String userId,
    required String name,
    required String phone,
    String? relationship,
    int priority = 0,
  }) async {
    try {
      // 检查是否已达到上限
      final existingContacts = await getContacts(userId);
      if (existingContacts.length >= 3) {
        throw Exception('最多只能添加3个紧急联系人');
      }

      // 检查手机号是否已存在
      final existing = existingContacts.where((c) => c.phone == phone).toList();
      if (existing.isNotEmpty) {
        throw Exception('该联系人已存在');
      }

      final contact = EmergencyContactModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name,
        phone: phone,
        relationship: relationship,
        priority: priority,
        isActive: true,
        createdAt: DateTime.now(),
      );

      await _supabase.from('emergency_contacts').insert({
        'id': contact.id,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'priority': priority,
        'is_active': true,
        'created_at': contact.createdAt?.toIso8601String(),
      });

      AppLogger.info('紧急联系人添加成功: ${contact.id}');
      return contact;
    } catch (e) {
      AppLogger.error('添加紧急联系人失败', e);
      rethrow;
    }
  }

  /// 更新紧急联系人
  Future<void> updateContact({
    required String contactId,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (relationship != null) updates['relationship'] = relationship;
      if (priority != null) updates['priority'] = priority;

      await _supabase
          .from('emergency_contacts')
          .update(updates)
          .eq('id', contactId);

      AppLogger.info('紧急联系人更新成功: $contactId');
    } catch (e) {
      AppLogger.error('更新紧急联系人失败', e);
      rethrow;
    }
  }

  /// 删除紧急联系人
  Future<void> deleteContact(String contactId) async {
    try {
      await _supabase
          .from('emergency_contacts')
          .delete()
          .eq('id', contactId);

      AppLogger.info('紧急联系人删除成功: $contactId');
    } catch (e) {
      AppLogger.error('删除紧急联系人失败', e);
      rethrow;
    }
  }

  /// 通知紧急联系人
  Future<void> notifyEmergencyContacts({
    required String userId,
    required double latitude,
    required double longitude,
    String? address,
    String? message,
  }) async {
    try {
      final contacts = await getContacts(userId);
      if (contacts.isEmpty) {
        AppLogger.warning('用户没有设置紧急联系人: $userId');
        return;
      }

      // 获取用户信息
      final userResponse = await _supabase
          .from('users')
          .select('name, phone')
          .eq('id', userId)
          .single();

      final userName = userResponse['name'] ?? '您的亲友';

      // 构建位置链接
      final locationUrl =
          'https://maps.google.com/?q=$latitude,$longitude';

      // 构建通知内容
      final notificationTitle = '紧急求助通知';
      final notificationBody =
          '$userName 触发了SOS紧急求助，当前位置：${address ?? '未知地址'}';

      // 构建短信内容
      final smsMessage = message ??
          '【共感LinkAble紧急求助】\n'
          '$userName 触发了SOS紧急求助。\n'
          '当前位置：${address ?? '未知地址'}\n'
          '地图链接：$locationUrl\n'
          '请尽快联系确认安全！';

      // 并行通知所有联系人
      final futures = <Future>[];

      for (final contact in contacts) {
        // 发送Push通知（如果用户有安装App并绑定）
        futures.add(_sendPushNotification(
          contact: contact,
          title: notificationTitle,
          body: notificationBody,
          data: {
            'type': 'sos',
            'user_id': userId,
            'latitude': latitude,
            'longitude': longitude,
          },
        ));

        // 记录通知日志
        futures.add(_logNotification(
          userId: userId,
          contactId: contact.id,
          type: 'sms',
          content: smsMessage,
        ));
      }

      await Future.wait(futures);

      AppLogger.info('紧急联系人通知已发送: ${contacts.length}人');
    } catch (e) {
      AppLogger.error('通知紧急联系人失败', e);
    }
  }

  /// 发送Push通知
  Future<void> _sendPushNotification({
    required EmergencyContactModel contact,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 检查联系人是否有绑定设备
      final deviceResponse = await _supabase
          .from('user_devices')
          .select('fcm_token')
          .eq('phone', contact.phone)
          .maybeSingle();

      if (deviceResponse == null || deviceResponse['fcm_token'] == null) {
        return;
      }

      final fcmToken = deviceResponse['fcm_token'] as String;

      // 发送推送
      await _pushService.sendNotification(
        token: fcmToken,
        title: title,
        body: body,
        data: data,
      );
    } catch (e) {
      AppLogger.error('发送Push通知失败', e);
    }
  }

  /// 记录通知日志
  Future<void> _logNotification({
    required String userId,
    required String contactId,
    required String type,
    required String content,
  }) async {
    try {
      await _supabase.from('emergency_notifications').insert({
        'user_id': userId,
        'contact_id': contactId,
        'type': type,
        'content': content,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('记录通知日志失败', e);
    }
  }

  /// 检查联系人数量
  Future<int> getContactCount(String userId) async {
    try {
      final response = await _supabase
          .from('emergency_contacts')
          .count()
          .eq('user_id', userId)
          .eq('is_active', true);

      return response;
    } catch (e) {
      AppLogger.error('获取联系人数量失败', e);
      return 0;
    }
  }

  /// 检查是否已设置紧急联系人
  Future<bool> hasEmergencyContacts(String userId) async {
    final count = await getContactCount(userId);
    return count > 0;
  }

  /// 验证手机号格式
  bool isValidPhone(String phone) {
    // 中国大陆手机号验证
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(phone);
  }

  /// 获取关系选项
  List<Map<String, String>> getRelationshipOptions() {
    return [
      {'value': 'parent', 'label': '父母'},
      {'value': 'spouse', 'label': '配偶'},
      {'value': 'child', 'label': '子女'},
      {'value': 'sibling', 'label': '兄弟姐妹'},
      {'value': 'friend', 'label': '朋友'},
      {'value': 'caregiver', 'label': '看护人'},
      {'value': 'doctor', 'label': '医生'},
      {'value': 'other', 'label': '其他'},
    ];
  }

  /// 监听紧急联系人变化
  Stream<List<EmergencyContactModel>> watchContacts(String userId) {
    return _supabase
        .from('emergency_contacts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('is_active', true)
        .map((rows) => rows
            .map((json) => EmergencyContactModel.fromJson(json))
            .toList());
  }
}
