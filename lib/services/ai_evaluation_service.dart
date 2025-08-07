import 'dart:io';
import '../models/ai_response.dart';
import 'ai_service.dart';
import 'gemini_service.dart';
import 'huggingface_service.dart';
import 'text_extraction_service.dart';

class AIEvaluationService {
  final List<AIService> _aiServices = [];

  AIEvaluationService({
    required String geminiApiKey,
    required String huggingFaceApiKey,
  }) {
    _aiServices.add(GeminiService(apiKey: geminiApiKey));
    _aiServices.add(HuggingFaceService(apiKey: huggingFaceApiKey));
  }

  Future<EvaluationResult> processQueryWithEvaluation({
    required String query,
    List<File>? images,
  }) async {
    // Extract text from images if provided
    String? extractedText;
    if (images != null && images.isNotEmpty) {
      extractedText = await TextExtractionService.extractTextFromMultipleImages(
        images,
      );
    }

    // Get responses from all AI services
    final List<AIResponse> responses = [];
    final List<Future<AIResponse>> futures = [];

    for (final service in _aiServices) {
      futures.add(
        service.processQuery(
          query: query,
          images: images,
          extractedText: extractedText,
        ),
      );
    }

    final results = await Future.wait(futures);
    responses.addAll(results);

    // Filter successful responses
    final successfulResponses = responses.where((r) => r.isSuccessful).toList();

    if (successfulResponses.isEmpty) {
      // No successful responses
      return EvaluationResult(
        finalAnswer:
            'Sorry, I couldn\'t generate a response. Please try again.',
        bestResponse: responses.first,
        allResponses: responses,
        reasoning: 'All AI services failed to provide a response',
        confidence: 0.0,
      );
    }

    if (successfulResponses.length == 1) {
      // Only one successful response
      return EvaluationResult(
        finalAnswer: successfulResponses.first.content,
        bestResponse: successfulResponses.first,
        allResponses: responses,
        reasoning: 'Only one AI service provided a successful response',
        confidence: successfulResponses.first.confidence,
      );
    }

    // Multiple successful responses - evaluate and compare
    return await _evaluateResponses(successfulResponses, query, extractedText);
  }

  Future<EvaluationResult> _evaluateResponses(
    List<AIResponse> responses,
    String originalQuery,
    String? extractedText,
  ) async {
    // Check for similarity between responses
    final similarity = _calculateResponseSimilarity(responses);

    if (similarity > 0.8) {
      // Responses are very similar, choose the one with highest confidence
      final bestResponse = responses.reduce(
        (a, b) => a.confidence > b.confidence ? a : b,
      );

      return EvaluationResult(
        finalAnswer: bestResponse.content,
        bestResponse: bestResponse,
        allResponses: responses,
        reasoning:
            'Responses are highly similar (${(similarity * 100).toStringAsFixed(1)}% similarity). Selected response with highest confidence.',
        confidence: bestResponse.confidence,
      );
    }

    // Responses differ significantly - use advanced evaluation
    return await _performAdvancedEvaluation(
      responses,
      originalQuery,
      extractedText,
    );
  }

  double _calculateResponseSimilarity(List<AIResponse> responses) {
    if (responses.length < 2) return 1.0;

    final response1 = responses[0].content.toLowerCase();
    final response2 = responses[1].content.toLowerCase();

    // Simple word-based similarity (can be enhanced with more sophisticated algorithms)
    final words1 = response1.split(' ').toSet();
    final words2 = response2.split(' ').toSet();

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return union > 0 ? intersection / union : 0.0;
  }

  Future<EvaluationResult> _performAdvancedEvaluation(
    List<AIResponse> responses,
    String originalQuery,
    String? extractedText,
  ) async {
    // Create evaluation prompt for cross-validation
    final evaluationPrompt = _buildEvaluationPrompt(
      responses,
      originalQuery,
      extractedText,
    );

    // Use Gemini for evaluation (typically more reliable for analysis)
    final geminiService = _aiServices.firstWhere(
      (service) => service is GeminiService,
      orElse: () => _aiServices.first,
    );

    final evaluationResponse = await geminiService.processQuery(
      query: evaluationPrompt,
      extractedText: extractedText,
    );

    if (evaluationResponse.isSuccessful) {
      return _parseEvaluationResult(evaluationResponse, responses);
    }

    // Fallback: Use simple heuristics
    return _fallbackEvaluation(responses, originalQuery, extractedText);
  }

  String _buildEvaluationPrompt(
    List<AIResponse> responses,
    String originalQuery,
    String? extractedText,
  ) {
    String prompt =
        '''
You are an AI evaluator. Your task is to analyze multiple AI responses to a user query and determine which one is most accurate and helpful.

Original Query: "$originalQuery"
''';

    if (extractedText != null && extractedText.isNotEmpty) {
      prompt += '\nExtracted Text Context: "$extractedText"';
    }

    prompt += '\n\nAI Responses to evaluate:\n';

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      prompt +=
          '\nResponse ${i + 1} (${response.model}):\n${response.content}\n';
    }

    prompt += '''

Please evaluate these responses based on:
1. Accuracy and factual correctness
2. Relevance to the query
3. Completeness of the answer
4. Clarity and helpfulness
5. Use of provided context (if any)

Respond in this exact format:
BEST_RESPONSE: [number 1, 2, etc.]
CONFIDENCE: [0.0 to 1.0]
REASONING: [brief explanation]
FINAL_ANSWER: [the best response content or an improved version]
''';

    return prompt;
  }

  EvaluationResult _parseEvaluationResult(
    AIResponse evaluationResponse,
    List<AIResponse> originalResponses,
  ) {
    final content = evaluationResponse.content;

    try {
      final bestResponseMatch = RegExp(
        r'BEST_RESPONSE:\s*(\d+)',
      ).firstMatch(content);
      final confidenceMatch = RegExp(
        r'CONFIDENCE:\s*([\d.]+)',
      ).firstMatch(content);
      final reasoningMatch = RegExp(
        r'REASONING:\s*(.+?)(?=FINAL_ANSWER:|$)',
        dotAll: true,
      ).firstMatch(content);
      final finalAnswerMatch = RegExp(
        r'FINAL_ANSWER:\s*(.+)',
        dotAll: true,
      ).firstMatch(content);

      if (bestResponseMatch != null) {
        final responseIndex = int.parse(bestResponseMatch.group(1)!) - 1;
        if (responseIndex >= 0 && responseIndex < originalResponses.length) {
          final bestResponse = originalResponses[responseIndex];
          final confidence = confidenceMatch != null
              ? double.tryParse(confidenceMatch.group(1)!) ??
                    bestResponse.confidence
              : bestResponse.confidence;

          final reasoning =
              reasoningMatch?.group(1)?.trim() ?? 'AI evaluation completed';
          final finalAnswer =
              finalAnswerMatch?.group(1)?.trim() ?? bestResponse.content;

          return EvaluationResult(
            finalAnswer: finalAnswer,
            bestResponse: bestResponse,
            allResponses: originalResponses,
            reasoning: reasoning,
            confidence: confidence.clamp(0.0, 1.0),
          );
        }
      }
    } catch (e) {
      print('Error parsing evaluation result: $e');
    }

    // Fallback if parsing fails
    return _fallbackEvaluation(originalResponses, '', '');
  }

  EvaluationResult _fallbackEvaluation(
    List<AIResponse> responses,
    String originalQuery,
    String? extractedText,
  ) {
    // Simple fallback: choose response with highest confidence
    final bestResponse = responses.reduce(
      (a, b) => a.confidence > b.confidence ? a : b,
    );

    return EvaluationResult(
      finalAnswer: bestResponse.content,
      bestResponse: bestResponse,
      allResponses: responses,
      reasoning:
          'Used fallback evaluation: selected response with highest confidence',
      confidence:
          bestResponse.confidence * 0.8, // Reduce confidence due to fallback
    );
  }
}
