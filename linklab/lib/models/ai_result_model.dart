/// AI 服務通用結果模型
class AIResult {
  final bool success;
  final String text;
  final Map<String, dynamic>? data;
  final String? error;

  AIResult({required this.success, required this.text, this.data, this.error});

  factory AIResult.success(String text, {Map<String, dynamic>? data}) {
    return AIResult(success: true, text: text, data: data);
  }

  factory AIResult.error(String errorMessage) {
    return AIResult(success: false, text: '', error: errorMessage);
  }
}
