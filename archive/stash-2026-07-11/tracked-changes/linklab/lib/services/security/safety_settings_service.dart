import 'dart:convert';

import '../../core/utils/logger.dart';
import '../local_storage.dart';

class SafetySettings {
  const SafetySettings({
    this.autoShareLocation = true,
    this.usePreciseLocation = true,
    this.shareWithEmergencyContacts = true,
    this.enableVoiceTrigger = true,
    this.updatedAt,
  });

  final bool autoShareLocation;
  final bool usePreciseLocation;
  final bool shareWithEmergencyContacts;
  final bool enableVoiceTrigger;
  final DateTime? updatedAt;

  bool get isReady => autoShareLocation && enableVoiceTrigger;

  String get locationModeLabel {
    if (!autoShareLocation) {
      return '位置共享已关闭';
    }

    return usePreciseLocation ? '精确位置' : '大致位置';
  }

  SafetySettings copyWith({
    bool? autoShareLocation,
    bool? usePreciseLocation,
    bool? shareWithEmergencyContacts,
    bool? enableVoiceTrigger,
    DateTime? updatedAt,
  }) {
    return SafetySettings(
      autoShareLocation: autoShareLocation ?? this.autoShareLocation,
      usePreciseLocation: usePreciseLocation ?? this.usePreciseLocation,
      shareWithEmergencyContacts:
          shareWithEmergencyContacts ?? this.shareWithEmergencyContacts,
      enableVoiceTrigger: enableVoiceTrigger ?? this.enableVoiceTrigger,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoShareLocation': autoShareLocation,
      'usePreciseLocation': usePreciseLocation,
      'shareWithEmergencyContacts': shareWithEmergencyContacts,
      'enableVoiceTrigger': enableVoiceTrigger,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SafetySettings.fromJson(Map<String, dynamic> json) {
    return SafetySettings(
      autoShareLocation: json['autoShareLocation'] as bool? ?? true,
      usePreciseLocation: json['usePreciseLocation'] as bool? ?? true,
      shareWithEmergencyContacts:
          json['shareWithEmergencyContacts'] as bool? ?? true,
      enableVoiceTrigger: json['enableVoiceTrigger'] as bool? ?? true,
      updatedAt: json['updatedAt'] is String
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }
}

class SafetySettingsService {
  SafetySettingsService({
    LocalStorage? storage,
  }) : _storage = storage ?? LocalStorage();

  final LocalStorage _storage;
  bool _localInitialized = false;

  Future<void> _ensureStorage() async {
    if (_localInitialized) return;
    await _storage.initialize();
    _localInitialized = true;
  }

  Future<SafetySettings> getSettings(String userId) async {
    await _ensureStorage();

    final raw = _storage.getString(StorageKeys.safetySettings(userId));
    if (raw == null || raw.isEmpty) {
      return const SafetySettings();
    }

    try {
      return SafetySettings.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      AppLogger.error('读取安全设置失败', e);
      return const SafetySettings();
    }
  }

  Future<SafetySettings> saveSettings(
    String userId,
    SafetySettings settings,
  ) async {
    await _ensureStorage();

    final normalized = settings.copyWith(updatedAt: DateTime.now());
    await _storage.setString(
      StorageKeys.safetySettings(userId),
      jsonEncode(normalized.toJson()),
    );
    AppLogger.info('安全设置已保存: $userId');
    return normalized;
  }
}
