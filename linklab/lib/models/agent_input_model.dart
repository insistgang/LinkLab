/// 用戶無障礙偏好
class AccessibilityPrefs {
  final bool screenReader;
  final bool largeText;
  final bool highContrast;
  final bool voiceOutput;

  const AccessibilityPrefs({
    this.screenReader = false,
    this.largeText = false,
    this.highContrast = false,
    this.voiceOutput = false,
  });

  Map<String, dynamic> toJson() => {
        'screen_reader': screenReader,
        'large_text': largeText,
        'high_contrast': highContrast,
        'voice_output': voiceOutput,
      };

  factory AccessibilityPrefs.fromJson(Map<String, dynamic> json) {
    return AccessibilityPrefs(
      screenReader: json['screen_reader'] as bool? ?? false,
      largeText: json['large_text'] as bool? ?? false,
      highContrast: json['high_contrast'] as bool? ?? false,
      voiceOutput: json['voice_output'] as bool? ?? false,
    );
  }
}

/// 位置信息
class LocationInfo {
  final double lat;
  final double lng;
  final String precision; // city | district | exact

  const LocationInfo({
    required this.lat,
    required this.lng,
    this.precision = 'exact',
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'precision': precision,
      };

  factory LocationInfo.fromJson(Map<String, dynamic> json) {
    return LocationInfo(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      precision: json['precision'] as String? ?? 'exact',
    );
  }
}

/// Agent 標準化輸入模型
/// 符合 AGENTS.md §5.3 要求
class AgentInput {
  final String requestId;
  final String userId;
  final String inputType; // text | voice | image | location | mixed
  final String? text;
  final String? imageUri;
  final LocationInfo? location;
  final AccessibilityPrefs accessibilityPrefs;
  final String networkStatus; // online | weak | offline
  final bool demoMode;

  const AgentInput({
    required this.requestId,
    required this.userId,
    required this.inputType,
    this.text,
    this.imageUri,
    this.location,
    this.accessibilityPrefs = const AccessibilityPrefs(),
    this.networkStatus = 'online',
    this.demoMode = true,
  });

  Map<String, dynamic> toJson() => {
        'request_id': requestId,
        'user_id': userId,
        'input_type': inputType,
        'text': text,
        'image_uri': imageUri,
        'location': location?.toJson(),
        'accessibility_prefs': accessibilityPrefs.toJson(),
        'network_status': networkStatus,
        'demo_mode': demoMode,
      };

  factory AgentInput.fromJson(Map<String, dynamic> json) {
    return AgentInput(
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      inputType: json['input_type'] as String,
      text: json['text'] as String?,
      imageUri: json['image_uri'] as String?,
      location: json['location'] != null
          ? LocationInfo.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      accessibilityPrefs: json['accessibility_prefs'] != null
          ? AccessibilityPrefs.fromJson(
              json['accessibility_prefs'] as Map<String, dynamic>)
          : const AccessibilityPrefs(),
      networkStatus: json['network_status'] as String? ?? 'online',
      demoMode: json['demo_mode'] as bool? ?? true,
    );
  }
}
