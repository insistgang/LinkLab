class DemoVolunteer {
  const DemoVolunteer({
    required this.id,
    required this.nickname,
    required this.avatarLabel,
    required this.distanceMeters,
    required this.skills,
    required this.reputationScore,
    required this.isOnline,
    required this.helpCount,
    required this.estimatedResponseSeconds,
    this.preferredScenarios = const [],
    this.languageTags = const [],
  });

  final String id;
  final String nickname;
  final String avatarLabel;
  final int distanceMeters;
  final List<String> skills;
  final double reputationScore;
  final bool isOnline;
  final int helpCount;
  final int estimatedResponseSeconds;
  final List<String> preferredScenarios;
  final List<String> languageTags;

  factory DemoVolunteer.fromJson(Map<String, dynamic> json) {
    return DemoVolunteer(
      id: _stringValue(json, 'id'),
      nickname: _stringValue(json, 'nickname', fallback: '演示志願者'),
      avatarLabel: _stringValue(json, 'avatarLabel', fallback: '志'),
      distanceMeters: _intValue(json, 'distanceMeters', fallback: 9999),
      skills: _stringList(json['skills']),
      reputationScore: _doubleValue(json, 'reputationScore', fallback: 0.8),
      isOnline: _boolValue(json, 'isOnline'),
      helpCount: _intValue(json, 'helpCount'),
      estimatedResponseSeconds: _intValue(
        json,
        'estimatedResponseSeconds',
        fallback: 30,
      ),
      preferredScenarios: _stringList(json['preferredScenarios']),
      languageTags: _stringList(json['languageTags']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'nickname': nickname,
      'avatarLabel': avatarLabel,
      'distanceMeters': distanceMeters,
      'skills': skills,
      'reputationScore': reputationScore,
      'isOnline': isOnline,
      'helpCount': helpCount,
      'estimatedResponseSeconds': estimatedResponseSeconds,
      'preferredScenarios': preferredScenarios,
      'languageTags': languageTags,
    };
  }

  static String _stringValue(
    Map<String, dynamic> json,
    String key, {
    String fallback = '',
  }) {
    final value = json[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : fallback;
  }

  static int _intValue(
    Map<String, dynamic> json,
    String key, {
    int fallback = 0,
  }) {
    final value = json[key];
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _doubleValue(
    Map<String, dynamic> json,
    String key, {
    double fallback = 0,
  }) {
    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _boolValue(Map<String, dynamic> json, String key) {
    final value = json[key];
    return value is bool ? value : false;
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) {
      return const [];
    }
    return List<String>.unmodifiable(raw.whereType<String>());
  }
}
