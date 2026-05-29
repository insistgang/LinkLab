import 'package:geolocator/geolocator.dart';

import '../../config/app_config.dart';
import '../../core/utils/logger.dart';

class LocationSnapshot {
  const LocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.precision,
    required this.label,
    required this.isFromRealProvider,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final String precision;
  final String label;
  final bool isFromRealProvider;
  final double? accuracyMeters;

  Map<String, double> toLatLngMap() => {'lat': latitude, 'lng': longitude};

  static const demo = LocationSnapshot(
    latitude: 31.2304,
    longitude: 121.4737,
    precision: 'district',
    label: '演示位置：上海市静安区附近',
    isFromRealProvider: false,
  );
}

/// 位置能力统一入口。
///
/// 精确位置只允许在匹配/SOS等用户主动流程中获取；权限失败或能力关闭时，
/// 统一回退到演示坐标，避免主链路卡死。
class LocationFacade {
  const LocationFacade();

  Future<LocationSnapshot> getAssistiveLocation({
    bool requirePrecise = false,
  }) async {
    if (!FeatureFlags.enableLocationService) {
      return LocationSnapshot.demo;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('位置服务未开启，使用 Demo 位置 fallback');
        return LocationSnapshot.demo;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('位置权限被拒绝，使用 Demo 位置 fallback');
        return LocationSnapshot.demo;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: requirePrecise
              ? LocationAccuracy.high
              : LocationAccuracy.medium,
        ),
      ).timeout(const Duration(seconds: 8));

      return LocationSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        precision: requirePrecise ? 'exact' : 'district',
        label: requirePrecise ? '真实精确位置已获取' : '真实大致位置已获取',
        isFromRealProvider: true,
        accuracyMeters: position.accuracy,
      );
    } catch (error, stackTrace) {
      AppLogger.error('获取位置失败，使用 Demo 位置 fallback', error, stackTrace);
      return LocationSnapshot.demo;
    }
  }
}
