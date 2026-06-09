import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../models/emergency_contact_model.dart';
import '../local_storage.dart' as app_storage;

/// 緊急聯繫人服務
class EmergencyContactService {
  EmergencyContactService({
    SupabaseClient? supabase,
    app_storage.LocalStorage? storage,
  }) : _supabaseClient = supabase,
       _storage = storage ?? app_storage.LocalStorage();

  SupabaseClient? _supabaseClient;
  final app_storage.LocalStorage _storage;
  bool _localInitialized = false;

  bool get _hasSupabase {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  SupabaseClient get _supabase {
    if (!_hasSupabase) {
      throw StateError('Supabase not initialized');
    }
    _supabaseClient ??= Supabase.instance.client;
    return _supabaseClient!;
  }

  bool get _useLocalContacts => !_hasSupabase || !FeatureFlags.enableRealSMS;

  Future<void> _ensureLocalStorage() async {
    if (_localInitialized) return;
    await _storage.initialize();
    _localInitialized = true;
  }

  /// 獲取用戶的緊急聯繫人
  Future<List<EmergencyContactModel>> getContacts(String userId) async {
    if (_useLocalContacts) {
      return _getLocalContacts(userId);
    }

    try {
      final response = await _supabase
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('priority', ascending: true);

      return (response as List)
          .map(
            (json) => EmergencyContactModel.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error('獲取緊急聯繫人失敗', e);
      return [];
    }
  }

  /// 添加緊急聯繫人
  Future<EmergencyContactModel?> addContact({
    required String userId,
    required String name,
    required String phone,
    String? relationship,
    int priority = 0,
  }) async {
    final normalizedPhone = phone.replaceAll(RegExp(r'\D'), '');
    final existingContacts = await getContacts(userId);

    if (existingContacts.length >= 3) {
      throw Exception('最多隻能添加3個緊急聯繫人');
    }
    if (existingContacts.any((contact) => contact.phone == normalizedPhone)) {
      throw Exception('該聯繫人已存在');
    }

    final contact = EmergencyContactModel(
      id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      name: name.trim(),
      phone: normalizedPhone,
      relationship: relationship,
      priority: priority,
      isActive: true,
      createdAt: DateTime.now(),
    );

    try {
      if (_useLocalContacts) {
        await _saveLocalContacts([...existingContacts, contact]);
        return contact;
      }

      await _supabase.from('emergency_contacts').insert({
        'id': contact.id,
        'user_id': userId,
        'name': contact.name,
        'phone': contact.phone,
        'relationship': relationship,
        'priority': priority,
        'is_active': true,
        'created_at': contact.createdAt?.toIso8601String(),
      });

      AppLogger.info('緊急聯繫人添加成功: ${contact.id}');
      return contact;
    } catch (e) {
      AppLogger.error('添加緊急聯繫人失敗', e);
      rethrow;
    }
  }

  /// 更新緊急聯繫人
  Future<void> updateContact({
    required String contactId,
    String? name,
    String? phone,
    String? relationship,
    int? priority,
  }) async {
    try {
      if (_useLocalContacts) {
        final contacts = await _getAllLocalContacts();
        final index = contacts.indexWhere((contact) => contact.id == contactId);
        if (index == -1) {
          throw Exception('聯繫人不存在');
        }

        contacts[index] = contacts[index].copyWith(
          name: name?.trim() ?? contacts[index].name,
          phone: phone?.replaceAll(RegExp(r'\D'), '') ?? contacts[index].phone,
          relationship: relationship,
          priority: priority ?? contacts[index].priority,
        );

        await _saveLocalContacts(contacts);
        return;
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (name != null) updates['name'] = name.trim();
      if (phone != null) {
        updates['phone'] = phone.replaceAll(RegExp(r'\D'), '');
      }
      if (relationship != null) updates['relationship'] = relationship;
      if (priority != null) updates['priority'] = priority;

      await _supabase
          .from('emergency_contacts')
          .update(updates)
          .eq('id', contactId);
      AppLogger.info('緊急聯繫人更新成功: $contactId');
    } catch (e) {
      AppLogger.error('更新緊急聯繫人失敗', e);
      rethrow;
    }
  }

  /// 刪除緊急聯繫人
  Future<void> deleteContact(String contactId) async {
    try {
      if (_useLocalContacts) {
        final contacts = await _getAllLocalContacts();
        contacts.removeWhere((contact) => contact.id == contactId);
        await _saveLocalContacts(contacts);
        return;
      }

      await _supabase.from('emergency_contacts').delete().eq('id', contactId);
      AppLogger.info('緊急聯繫人刪除成功: $contactId');
    } catch (e) {
      AppLogger.error('刪除緊急聯繫人失敗', e);
      rethrow;
    }
  }

  /// 通知緊急聯繫人
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
        AppLogger.warning('用戶沒有設置緊急聯繫人: $userId');
        return;
      }

      final content =
          message ??
          '【共感LinkAble緊急求助】位置：${address ?? '未知地址'} '
              '($latitude,$longitude)';

      if (_useLocalContacts) {
        AppLogger.info('演示模式通知緊急聯繫人: ${contacts.map((c) => c.name).join('、')}');
        return;
      }

      await Future.wait(
        contacts.map(
          (contact) => _logNotification(
            userId: userId,
            contactId: contact.id,
            type: 'sms',
            content: content,
          ),
        ),
      );
      AppLogger.info('緊急聯繫人通知已記錄: ${contacts.length}人');
    } catch (e) {
      AppLogger.error('通知緊急聯繫人失敗', e);
    }
  }

  Future<int> getContactCount(String userId) async {
    final contacts = await getContacts(userId);
    return contacts.length;
  }

  Future<bool> hasEmergencyContacts(String userId) async {
    final count = await getContactCount(userId);
    return count > 0;
  }

  bool isValidPhone(String phone) {
    final regex = RegExp(r'^1[3-9]\d{9}$');
    return regex.hasMatch(phone);
  }

  List<Map<String, String>> getRelationshipOptions() {
    return const [
      {'value': 'parent', 'label': '父母'},
      {'value': 'spouse', 'label': '配偶'},
      {'value': 'child', 'label': '子女'},
      {'value': 'sibling', 'label': '兄弟姐妹'},
      {'value': 'friend', 'label': '朋友'},
      {'value': 'caregiver', 'label': '看護人'},
      {'value': 'doctor', 'label': '醫生'},
      {'value': 'other', 'label': '其他'},
    ];
  }

  Stream<List<EmergencyContactModel>> watchContacts(String userId) {
    return Stream.fromFuture(getContacts(userId));
  }

  Future<List<EmergencyContactModel>> _getLocalContacts(String userId) async {
    final contacts = await _getAllLocalContacts();
    final filtered =
        contacts
            .where((contact) => contact.userId == userId && contact.isActive)
            .toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
    return filtered;
  }

  Future<List<EmergencyContactModel>> _getAllLocalContacts() async {
    await _ensureLocalStorage();
    final rawContacts = _storage.getEmergencyContacts();
    final contacts = rawContacts
        .map(
          (json) =>
              EmergencyContactModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
    return contacts;
  }

  Future<void> _saveLocalContacts(List<EmergencyContactModel> contacts) async {
    await _ensureLocalStorage();

    final normalized = List<EmergencyContactModel>.from(contacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));

    for (var i = 0; i < normalized.length; i++) {
      normalized[i] = normalized[i].copyWith(priority: i);
    }

    await _storage.saveEmergencyContacts(
      normalized.map((item) => item.toJson()).toList(),
    );
  }

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
      AppLogger.error('記錄通知日誌失敗', e);
    }
  }
}
