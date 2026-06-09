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
    label: '演示位置：上海市靜安區附近',
    isFromRealProvider: false,
  );
}

/// 位置能力統一入口。
///
/// 精確位置只允許在匹配/SOS等用戶主動流程中獲取；權限失敗或能力關閉時，
/// 統一回退到演示座標，避免主鏈路卡死。
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
        AppLogger.warning('位置服務未開啓，使用 Demo 位置 fallback');
        return LocationSnapshot.demo;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        AppLogger.warning('位置權限被拒絕，使用 Demo 位置 fallback');
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
        label: requirePrecise ? '真實精確位置已獲取' : '真實大致位置已獲取',
        isFromRealProvider: true,
        accuracyMeters: position.accuracy,
      );
    } catch (error, stackTrace) {
      AppLogger.error('獲取位置失敗，使用 Demo 位置 fallback', error, stackTrace);
      return LocationSnapshot.demo;
    }
  }
}
