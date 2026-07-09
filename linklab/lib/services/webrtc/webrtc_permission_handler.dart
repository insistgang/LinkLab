import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// WebRTC权限处理结果
enum PermissionResult {
  granted,      // 已授权
  denied,       // 被拒绝
  permanentlyDenied, // 永久拒绝
  restricted,   // 受限（iOS家长控制等）
}

/// WebRTC权限处理器
/// 处理WebRTC所需的各种权限申请
class WebRTCPermissionHandler {
  /// 检查麦克风权限
  static Future<PermissionResult> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return _convertStatus(status);
  }

  /// 请求麦克风权限
  static Future<PermissionResult> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return _convertStatus(status);
  }

  /// 检查并请求麦克风权限
  static Future<PermissionResult> ensureMicrophonePermission() async {
    var result = await checkMicrophonePermission();
    if (result == PermissionResult.denied) {
      result = await requestMicrophonePermission();
    }
    return result;
  }

  /// 检查存储权限（用于录音保存）
  static Future<PermissionResult> checkStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 使用新的权限模型
      if (await _isAndroid13OrHigher()) {
        final audioStatus = await Permission.audio.status;
        return _convertStatus(audioStatus);
      } else {
        final storageStatus = await Permission.storage.status;
        return _convertStatus(storageStatus);
      }
    }
    // iOS不需要显式存储权限
    return PermissionResult.granted;
  }

  /// 请求存储权限
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

  /// 检查并请求存储权限
  static Future<PermissionResult> ensureStoragePermission() async {
    var result = await checkStoragePermission();
    if (result == PermissionResult.denied) {
      result = await requestStoragePermission();
    }
    return result;
  }

  /// 检查所有WebRTC所需权限
  static Future<Map<String, PermissionResult>> checkAllPermissions() async {
    return {
      'microphone': await checkMicrophonePermission(),
      'storage': await checkStoragePermission(),
    };
  }

  /// 请求所有WebRTC所需权限
  static Future<Map<String, PermissionResult>> requestAllPermissions() async {
    return {
      'microphone': await requestMicrophonePermission(),
      'storage': await requestStoragePermission(),
    };
  }

  /// 确保所有权限已获取
  static Future<bool> ensureAllPermissions() async {
    final results = await requestAllPermissions();
    return results.values.every((result) =>
        result == PermissionResult.granted || result == PermissionResult.restricted);
  }

  /// 检查是否为Android 13或更高版本
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;
    // 简化检查，实际应该使用device_info_plus获取SDK版本
    return false;
  }

  /// 转换PermissionStatus为PermissionResult
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
        return PermissionResult.granted; // 有限权限也算已授权
      case PermissionStatus.provisional:
        return PermissionResult.granted;
      default:
        return PermissionResult.denied;
    }
  }

  /// 打开应用设置页面
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  /// 显示权限被拒绝的对话框
  static Future<void> showPermissionDeniedDialog(
    BuildContext context, {
    required String permissionName,
    required VoidCallback onOpenSettings,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('需要$permissionName权限'),
        content: Text(
          '共感LinkAble需要$permissionName权限才能进行语音通话。请在设置中开启权限。',
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
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 显示权限说明对话框（首次请求前）
  static Future<bool> showPermissionRationaleDialog(
    BuildContext context, {
    required String permissionName,
    required String rationale,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('申请$permissionName权限'),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('拒绝'),
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

/// 权限检查工具类
class PermissionChecker {
  /// 检查麦克风权限并处理
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
            permissionName: '麦克风',
            rationale: '共感LinkAble需要麦克风权限来进行语音通话，帮助视障人士与志愿者进行实时交流。',
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
            permissionName: '麦克风',
            onOpenSettings: () => WebRTCPermissionHandler.openAppSettings(),
          );
        }
        return false;
    }
  }
}
