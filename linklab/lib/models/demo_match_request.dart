class DemoMatchRequest {
  const DemoMatchRequest({
    required this.requestId,
    required this.queryText,
    required this.requestType,
    required this.urgencyLevel,
    this.preferredSkills = const [],
    this.isSos = false,
  });

  final String requestId;
  final String queryText;
  final String requestType;
  final String urgencyLevel;
  final List<String> preferredSkills;
  final bool isSos;

  DemoMatchRequest copyWith({
    String? requestId,
    String? queryText,
    String? requestType,
    String? urgencyLevel,
    List<String>? preferredSkills,
    bool? isSos,
  }) {
    return DemoMatchRequest(
      requestId: requestId ?? this.requestId,
      queryText: queryText ?? this.queryText,
      requestType: requestType ?? this.requestType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      preferredSkills: preferredSkills ?? this.preferredSkills,
      isSos: isSos ?? this.isSos,
    );
  }
}
