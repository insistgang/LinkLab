import 'dart:convert';

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';
import '../../demo_data/volunteers.dart';
import '../../models/demo_help_request_model.dart';
import '../local_storage.dart' as app_storage;

class DemoHelpRequestService {
  DemoHelpRequestService({app_storage.LocalStorage? storage})
    : _storage = storage ?? app_storage.LocalStorage();

  final app_storage.LocalStorage _storage;
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _storage.initialize();
    _initialized = true;
  }

  Future<DemoHelpRequestModel> createRequest({
    required String seekerId,
    required String type,
    required String title,
    required String description,
    required String schedulePreference,
    required String locationMode,
    required bool accessibilityNeeded,
    String? volunteerId,
    String? volunteerName,
    String? volunteerAvatar,
    String? assignedVolunteerAccountId,
    String? status,
  }) async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoHelpRequestService.createRequest',
    )) {
      throw StateError(
        'DemoHelpRequestService.createRequest 仅在 Demo fallback 开启时可用',
      );
    }

    await _ensureInitialized();

    final matchedVolunteer = volunteerId == null
        ? null
        : getVolunteerById(volunteerId);
    final request = DemoHelpRequestModel(
      id: 'demo_help_${DateTime.now().microsecondsSinceEpoch}',
      seekerId: seekerId,
      volunteerId: volunteerId,
      volunteerName: _resolveVolunteerName(volunteerName, matchedVolunteer),
      volunteerAvatar: _resolveVolunteerAvatar(
        volunteerAvatar,
        matchedVolunteer,
      ),
      type: type,
      title: title.trim(),
      description: description.trim(),
      schedulePreference: schedulePreference.trim(),
      locationMode: locationMode,
      accessibilityNeeded: accessibilityNeeded,
      status:
          status ??
          (volunteerId == null
              ? DemoHelpRequestStatus.waitingMatch
              : DemoHelpRequestStatus.pending),
      createdAt: DateTime.now(),
      assignedVolunteerAccountId: assignedVolunteerAccountId,
    );

    final requests = await _readRequests();
    requests.insert(0, request);
    await _saveRequests(requests);
    return request;
  }

  Future<List<DemoHelpRequestModel>> getSeekerRequests(String seekerId) async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoHelpRequestService.getSeekerRequests',
    )) {
      return const [];
    }

    final requests = await _readRequests();
    return requests.where((item) => item.seekerId == seekerId).toList();
  }

  Future<List<DemoHelpRequestModel>> getVolunteerRequests(
    String volunteerAccountId, {
    bool pendingOnly = false,
  }) async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoHelpRequestService.getVolunteerRequests',
    )) {
      return const [];
    }

    final requests = await _readRequests();
    return requests.where((item) {
      final assignedToCurrent =
          item.assignedVolunteerAccountId == volunteerAccountId ||
          item.volunteerId == volunteerAccountId;
      if (!assignedToCurrent) return false;
      if (!pendingOnly) return true;
      return item.status == DemoHelpRequestStatus.waitingMatch ||
          item.status == DemoHelpRequestStatus.pending ||
          item.status == DemoHelpRequestStatus.inProgress;
    }).toList();
  }

  Future<bool> cancelRequest(
    String requestId,
    String seekerId, {
    String reason = '求助者主动取消',
  }) async {
    if (!AppConfig.shouldUseDemoFallback(
      feature: 'DemoHelpRequestService.cancelRequest',
    )) {
      return false;
    }

    await _ensureInitialized();

    try {
      final requests = await _readRequests();
      final index = requests.indexWhere(
        (item) => item.id == requestId && item.seekerId == seekerId,
      );
      if (index < 0) return false;

      requests[index] = requests[index].copyWith(
        status: DemoHelpRequestStatus.cancelled,
        cancelReason: reason,
      );
      await _saveRequests(requests);
      return true;
    } catch (e) {
      AppLogger.error('取消本地求助单失败', e);
      return false;
    }
  }

  Future<List<DemoHelpRequestModel>> _readRequests() async {
    await _ensureInitialized();

    final raw = _storage.getString(app_storage.StorageKeys.demoHelpRequests);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final requests = decoded
          .map(
            (item) => DemoHelpRequestModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      AppLogger.error('读取本地求助单失败', e);
      return [];
    }
  }

  Future<void> _saveRequests(List<DemoHelpRequestModel> requests) async {
    requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final payload = requests.map((item) => item.toJson()).toList();
    await _storage.setString(
      app_storage.StorageKeys.demoHelpRequests,
      jsonEncode(payload),
    );
  }

  String? _resolveVolunteerName(
    String? provided,
    DemoVolunteer? matchedVolunteer,
  ) {
    if (provided != null && provided.trim().isNotEmpty) {
      return provided.trim();
    }
    return matchedVolunteer?.name;
  }

  String? _resolveVolunteerAvatar(
    String? provided,
    DemoVolunteer? matchedVolunteer,
  ) {
    if (provided != null && provided.trim().isNotEmpty) {
      return provided.trim();
    }
    return matchedVolunteer?.avatar;
  }
}
