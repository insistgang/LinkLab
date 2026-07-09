enum HelpRequestStatus {
  created('created', '等待中'),
  aiProcessing('ai_processing', 'AI正在分析'),
  aiResolved('ai_resolved', 'AI已解决'),
  matching('matching', '匹配中'),
  connected('connected', '志愿者已接通'),
  expired('expired', '已超时'),
  cancelled('cancelled', '已取消'),
  completed('completed', '已完成');

  const HelpRequestStatus(this.wireName, this.label);

  final String wireName;
  final String label;

  static HelpRequestStatus fromWireName(String? value) {
    for (final status in values) {
      if (status.wireName == value) {
        return status;
      }
    }
    return HelpRequestStatus.created;
  }

  bool get isTerminal =>
      this == aiResolved ||
      this == expired ||
      this == cancelled ||
      this == completed;

  bool get isActive =>
      this == created ||
      this == aiProcessing ||
      this == matching ||
      this == connected;

  bool canTransitionTo(HelpRequestStatus next) {
    if (this == next) {
      return true;
    }

    return switch (this) {
      HelpRequestStatus.created =>
        next == HelpRequestStatus.aiProcessing ||
            next == HelpRequestStatus.cancelled,
      HelpRequestStatus.aiProcessing =>
        next == HelpRequestStatus.aiResolved ||
            next == HelpRequestStatus.matching ||
            next == HelpRequestStatus.cancelled,
      HelpRequestStatus.aiResolved => false,
      HelpRequestStatus.matching =>
        next == HelpRequestStatus.connected ||
            next == HelpRequestStatus.expired ||
            next == HelpRequestStatus.cancelled,
      HelpRequestStatus.connected =>
        next == HelpRequestStatus.completed ||
            next == HelpRequestStatus.matching ||
            next == HelpRequestStatus.cancelled,
      HelpRequestStatus.expired => false,
      HelpRequestStatus.cancelled => false,
      HelpRequestStatus.completed => false,
    };
  }
}
