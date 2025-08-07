class AIResponse {
  final String content;
  final String model;
  final double confidence;
  final bool isSuccessful;
  final String? error;
  final Map<String, dynamic>? metadata;

  const AIResponse({
    required this.content,
    required this.model,
    required this.confidence,
    required this.isSuccessful,
    this.error,
    this.metadata,
  });

  factory AIResponse.success({
    required String content,
    required String model,
    required double confidence,
    Map<String, dynamic>? metadata,
  }) {
    return AIResponse(
      content: content,
      model: model,
      confidence: confidence,
      isSuccessful: true,
      metadata: metadata,
    );
  }

  factory AIResponse.error({required String error, required String model}) {
    return AIResponse(
      content: '',
      model: model,
      confidence: 0.0,
      isSuccessful: false,
      error: error,
    );
  }
}

class EvaluationResult {
  final String finalAnswer;
  final AIResponse bestResponse;
  final List<AIResponse> allResponses;
  final String reasoning;
  final double confidence;

  const EvaluationResult({
    required this.finalAnswer,
    required this.bestResponse,
    required this.allResponses,
    required this.reasoning,
    required this.confidence,
  });
}
