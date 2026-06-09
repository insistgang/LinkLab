import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class RealDatabaseException implements Exception {
  const RealDatabaseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class RealProfile {
  const RealProfile({
    required this.id,
    required this.displayName,
    required this.role,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String displayName;
  final String role;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RealProfile.fromJson(Map<String, dynamic> json) {
    return RealProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      role: _normalizeRole(json['role']?.toString()),
      phone: json['phone']?.toString(),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  String get effectiveDisplayName {
    final trimmed = displayName.trim();
    return trimmed.isEmpty ? 'LinkAble用戶' : trimmed;
  }
}

class RealHelpRequest {
  const RealHelpRequest({
    required this.id,
    required this.seekerId,
    required this.title,
    required this.description,
    required this.status,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String seekerId;
  final String title;
  final String description;
  final String status;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RealHelpRequest.fromJson(Map<String, dynamic> json) {
    return RealHelpRequest(
      id: json['id']?.toString() ?? '',
      seekerId: json['seeker_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'created',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class RealVolunteerProfile {
  const RealVolunteerProfile({
    required this.id,
    required this.userId,
    required this.serviceRadiusM,
    required this.isAvailable,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final int serviceRadiusM;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory RealVolunteerProfile.fromJson(Map<String, dynamic> json) {
    return RealVolunteerProfile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      serviceRadiusM: _parseInt(json['service_radius_m']) ?? 3000,
      isAvailable: json['is_available'] == true,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

class RealHomeSummary {
  const RealHomeSummary({
    required this.profile,
    required this.helpRequests,
    required this.volunteerProfile,
  });

  factory RealHomeSummary.empty() {
    return const RealHomeSummary(
      profile: null,
      helpRequests: [],
      volunteerProfile: null,
    );
  }

  final RealProfile? profile;
  final List<RealHelpRequest> helpRequests;
  final RealVolunteerProfile? volunteerProfile;

  int get helpRequestCount => helpRequests.length;
  bool get hasVolunteerProfile => volunteerProfile != null;
}

class RealDatabaseRepository {
  const RealDatabaseRepository({SupabaseClient? client}) : _client = client;

  final SupabaseClient? _client;

  bool get isAvailable => _resolveClient() != null;

  Future<RealProfile?> fetchCurrentProfile() async {
    final client = _requireClient();
    final userId = _requireCurrentUserId(client);
    final row = await client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return RealProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<RealProfile> ensureCurrentProfile({
    required String fallbackDisplayName,
    String role = 'seeker',
    String? phone,
  }) async {
    final existing = await fetchCurrentProfile();
    if (existing != null) return existing;

    return upsertCurrentProfile(
      displayName: fallbackDisplayName,
      role: role,
      phone: phone,
    );
  }

  Future<RealProfile> upsertCurrentProfile({
    required String displayName,
    String role = 'seeker',
    String? phone,
  }) async {
    final client = _requireClient();
    final userId = _requireCurrentUserId(client);
    final row = await client
        .from('profiles')
        .upsert({
          'id': userId,
          'display_name': displayName.trim(),
          'role': _normalizeRole(role),
          'phone': _blankToNull(phone),
        }, onConflict: 'id')
        .select()
        .single();
    return RealProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<RealHelpRequest> createHelpRequest({
    required String title,
    required String description,
    double? latitude,
    double? longitude,
  }) async {
    final client = _requireClient();
    final userId = _requireCurrentUserId(client);
    await ensureCurrentProfile(fallbackDisplayName: 'LinkAble用戶');

    final payload = <String, dynamic>{
      'seeker_id': userId,
      'title': title.trim(),
      'description': description.trim(),
      'status': 'created',
      ...?latitude == null ? null : {'latitude': latitude},
      ...?longitude == null ? null : {'longitude': longitude},
    };

    final row = await client
        .from('help_requests')
        .insert(payload)
        .select()
        .single();
    return RealHelpRequest.fromJson(Map<String, dynamic>.from(row));
  }

  Future<List<RealHelpRequest>> listMyHelpRequests({int limit = 20}) async {
    final client = _requireClient();
    final userId = _requireCurrentUserId(client);
    final rows = await client
        .from('help_requests')
        .select()
        .eq('seeker_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((row) => RealHelpRequest.fromJson(_mapFromRow(row)))
        .toList();
  }

  Future<RealVolunteerProfile?> fetchMyVolunteerProfile() async {
    final client = _requireClient();
    final userId = _requireCurrentUserId(client);
    final row = await client
        .from('volunteer_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (row == null) return null;
    return RealVolunteerProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<RealVolunteerProfile> upsertVolunteerProfile({
    required int serviceRadiusM,
    required bool isAvailable,
  }) async {
    final client = _requireClient();
    final userId = _requireCurrentUserId(client);
    final profile = await fetchCurrentProfile();
    if (profile == null || profile.role != 'volunteer') {
      await upsertCurrentProfile(
        displayName: profile?.effectiveDisplayName ?? 'LinkAble志願者',
        role: 'volunteer',
        phone: profile?.phone,
      );
    }

    final row = await client
        .from('volunteer_profiles')
        .upsert({
          'user_id': userId,
          'service_radius_m': serviceRadiusM,
          'is_available': isAvailable,
        }, onConflict: 'user_id')
        .select()
        .single();
    return RealVolunteerProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<RealHomeSummary> fetchHomeSummary({int helpLimit = 5}) async {
    final client = _resolveClient();
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return RealHomeSummary.empty();
    }

    final profile = await fetchCurrentProfile();
    final helpRequests = await listMyHelpRequests(limit: helpLimit);
    final volunteerProfile = await fetchMyVolunteerProfile();
    return RealHomeSummary(
      profile: profile,
      helpRequests: helpRequests,
      volunteerProfile: volunteerProfile,
    );
  }

  SupabaseClient _requireClient() {
    final client = _resolveClient();
    if (client == null) {
      throw const RealDatabaseException('真實數據庫服務不可用，已保留 DemoMode fallback。');
    }
    return client;
  }

  SupabaseClient? _resolveClient() {
    if (_client != null) return _client;
    if (!FeatureFlags.enableDatabaseSync) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  String _requireCurrentUserId(SupabaseClient client) {
    final userId = client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const RealDatabaseException('請先登錄後再使用真實數據庫功能。');
    }
    return userId;
  }
}

String _normalizeRole(String? role) {
  return switch (role) {
    'volunteer' => 'volunteer',
    'admin' => 'admin',
    _ => 'seeker',
  };
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

double? _parseDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

Map<String, dynamic> _mapFromRow(dynamic row) {
  return Map<String, dynamic>.from(row as Map);
}
