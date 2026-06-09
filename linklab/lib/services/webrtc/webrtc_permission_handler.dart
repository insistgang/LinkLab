import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// WebRTC權限處理結果
enum PermissionResult {
  granted,      // 已授權
  denied,       // 被拒絕
  permanentlyDenied, // 永久拒絕
  restricted,   // 受限（iOS家長控制等）
}

/// WebRTC權限處理器
/// 處理WebRTC所需的各種權限申請
class WebRTCPermissionHandler {
  /// 檢查麥克風權限
  static Future<PermissionResult> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return _convertStatus(status);
  }

  /// 請求麥克風權限
  static Future<PermissionResult> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return _convertStatus(status);
  }

  /// 檢查並請求麥克風權限
  static Future<PermissionResult> ensureMicrophonePermission() async {
    var result = await checkMicrophonePermission();
    if (result == PermissionResult.denied) {
      result = await requestMicrophonePermission();
    }
    return result;
  }

  /// 檢查存儲權限（用於錄音保存）
  static Future<PermissionResult> checkStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 使用新的權限模型
      if (await _isAndroid13OrHigher()) {
        final audioStatus = await Permission.audio.status;
        return _convertStatus(audioStatus);
      } else {
        final storageStatus = await Permission.storage.status;
        return _convertStatus(storageStatus);
      }
    }
    // iOS不需要顯式存儲權限
    return PermissionResult.granted;
  }

  /// 請求存儲權限
  static Future<PermissionResult> requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.audio.request();
        return _convertStatus(status);
      } else {
        final status = await Permission.storage.request();
        return _convertStatus(status);
      }
    }
    return PermissionResult.granted;
  }

  /// 檢查並請求存儲權限
  static Future<PermissionResult> ensureStoragePermission() async {
    var result = await checkStoragePermission();
    if (result == PermissionResult.denied) {
      result = await requestStoragePermission();
    }
    return result;
  }

  /// 檢查所有WebRTC所需權限
  static Future<Map<String, PermissionResult>> checkAllPermissions() async {
    return {
      'microphone': await checkMicrophonePermission(),
      'storage': await checkStoragePermission(),
    };
  }

  /// 請求所有WebRTC所需權限
  static Future<Map<String, PermissionResult>> requestAllPermissions() async {
    return {
      'microphone': await requestMicrophonePermission(),
      'storage': await requestStoragePermission(),
    };
  }

  /// 確保所有權限已獲取
  static Future<bool> ensureAllPermissions() async {
    final results = await requestAllPermissions();
    return results.values.every((result) =>
        result == PermissionResult.granted || result == PermissionResult.restricted);
  }

  /// 檢查是否爲Android 13或更高版本
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    // 簡化檢查，實際應該使用device_info_plus獲取SDK版本
    return false;
  }

  /// 轉換PermissionStatus爲PermissionResult
  static PermissionResult _convertStatus(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return PermissionResult.granted;
      case PermissionStatus.denied:
        return PermissionResult.denied;
      case PermissionStatus.permanentlyDenied:
        return PermissionResult.permanentlyDenied;
      case PermissionStatus.restricted:
        return PermissionResult.restricted;
      case PermissionStatus.limited:
        return PermissionResult.granted; // 有限權限也算已授權
      case PermissionStatus.provisional:
        return PermissionResult.granted;
      default:
        return PermissionResult.denied;
    }
  }

  /// 打開應用設置頁面
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// 顯示權限被拒絕的對話框
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String permissionName,
    required VoidCallback onOpenSettings,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('需要$permissionName權限'),
        content: Text(
          '共感LinkAble需要$permissionName權限才能進行語音通話。請在設置中開啓權限。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onOpenSettings();
            },
            child: const Text('去設置'),
          ),
        ],
      ),
    );
  }

  /// 顯示權限說明對話框（首次請求前）
  static Future<bool> showPermissionRationaleDialog(
    BuildContext context, {
    required String permissionName,
    required String rationale,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('申請$permissionName權限'),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('拒絕'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('同意'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// 權限檢查工具類
class PermissionChecker {
  /// 檢查麥克風權限並處理
  static Future<bool> checkMicrophone(BuildContext context) async {
    final result = await WebRTCPermissionHandler.ensureMicrophonePermission();

    switch (result) {
      case PermissionResult.granted:
      case PermissionResult.restricted:
        return true;

      case PermissionResult.denied:
        if (context.mounted) {
          final shouldRequest = await WebRTCPermissionHandler.showPermissionRationaleDialog(
            context,
            permissionName: '麥克風',
            rationale: '共感LinkAble需要麥克風權限來進行語音通話，幫助視障人士與志願者進行實時交流。',
          );
          if (shouldRequest) {
            final newResult = await WebRTCPermissionHandler.requestMicrophonePermission();
            return newResult == PermissionResult.granted;
          }
        }
        return false;

      case PermissionResult.permanentlyDenied:
        if (context.mounted) {
          await WebRTCPermissionHandler.showPermissionDeniedDialog(
            context,
            permissionName: '麥克風',
            onOpenSettings: () => WebRTCPermissionHandler.openAppSettings(),
          );
        }
        return false;
    }
  }
}
