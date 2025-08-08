import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';
import 'config_service.dart';

class HuggingFaceService implements AIService {
  final String apiKey;
  final String modelId;
  static const String baseUrl = 'https://api-inference.huggingface.co';

  HuggingFaceService({
    required this.apiKey,
    this.modelId = 'microsoft/DialoGPT-large', // Default conversational model
  });

  @override
  String get modelName => 'HuggingFace $modelId';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/models/$modelId'),
        headers: {'Authorization': 'Bearer $apiKey'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AIResponse> processQuery({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    try {
      // For text-based models, we'll use an enhanced conversational approach
      final response = await _processTextQuery(
        query,
        extractedText,
        conversationHistory,
      );

      if (response.isSuccessful) {
        return response;
      }

      // Fallback to different models if the primary fails
      return await _tryAlternativeModels(query, extractedText);
    } catch (e) {
      return AIResponse.error(
        error: 'Exception occurred: $e',
        model: modelName,
      );
    }
  }

  Future<AIResponse> _processTextQuery(
    String query,
    String? extractedText, [
    List<Map<String, dynamic>>? conversationHistory,
  ]) async {
    try {
      String prompt = _buildEnhancedPrompt(
        query,
        extractedText,
        conversationHistory,
      );

      final requestBody = {
        'inputs': prompt,
        'parameters': await _getGenerationParameters(conversationHistory),
        'options': {'wait_for_model': true},
      };

      final response = await http.post(
        Uri.parse('$baseUrl/models/$modelId'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse is List && jsonResponse.isNotEmpty) {
          final generatedText = jsonResponse[0]['generated_text'] as String?;

          if (generatedText != null && generatedText.isNotEmpty) {
            return AIResponse.success(
              content: generatedText,
              model: modelName,
              confidence: _calculateEnhancedConfidence(
                generatedText,
                conversationHistory,
              ),
              metadata: {
                'model_id': modelId,
                'response_length': generatedText.length,
                'has_conversation_context':
                    conversationHistory?.isNotEmpty ?? false,
              },
            );
          }
        }
      }

      return AIResponse.error(
        error:
            'Invalid response format or empty content. Status: ${response.statusCode}',
        model: modelName,
      );
    } catch (e) {
      return AIResponse.error(
        error: 'Exception in text processing: $e',
        model: modelName,
      );
    }
  }

  // Enhanced prompt building with conversation context
  String _buildEnhancedPrompt(
    String query,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  ) {
    String prompt = '';

    // Add conversation context if available
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      prompt += 'Previous conversation context:\n';

      // Include last few exchanges for context
      final recentHistory = conversationHistory.length > 4
          ? conversationHistory.sublist(conversationHistory.length - 4)
          : conversationHistory;

      for (final exchange in recentHistory) {
        final role = exchange['role'] as String;
        final content = exchange['content'];

        if (content is List && content.isNotEmpty) {
          final textContent =
              content.firstWhere(
                    (c) => c['type'] == 'text',
                    orElse: () => {'text': ''},
                  )['text']
                  as String;

          if (textContent.isNotEmpty) {
            prompt +=
                '${role == 'user' ? 'Human' : 'Assistant'}: ${textContent.trim()}\n';
          }
        }
      }
      prompt += '\n';
    }

    if (extractedText != null && extractedText.isNotEmpty) {
      prompt += 'Context from image text: $extractedText\n\n';
    }

    prompt += 'Human: $query\n\nAssistant: ';

    return prompt;
  }

  // Get generation parameters with user preferences and contextual adjustments
  Future<Map<String, dynamic>> _getGenerationParameters(
    List<Map<String, dynamic>>? conversationHistory,
  ) async {
    // Get user preferences from ConfigService
    final useAdvancedParams = await ConfigService.getUseAdvancedParameters();

    if (!useAdvancedParams) {
      // Use optimal defaults when advanced parameters are disabled
      return {
        'max_length': 1000,
        'temperature': _getContextualTemperature(conversationHistory),
        'top_p': 0.9,
        'do_sample': true,
        'return_full_text': false,
        'repetition_penalty': 1.2, // Reduce repetition in conversations
      };
    }

    // Use user-configured parameters when advanced mode is enabled
    final temperature = await ConfigService.getTemperature();
    final topP = await ConfigService.getTopP();
    final maxTokens = await ConfigService.getMaxTokens();

    return {
      'max_length': maxTokens,
      'temperature': temperature,
      'top_p': topP,
      'do_sample': true,
      'return_full_text': false,
      'repetition_penalty': 1.2, // Keep this for better conversation quality
    };
  }

  // Adjust temperature based on conversation context (used when advanced params are off)
  double _getContextualTemperature(
    List<Map<String, dynamic>>? conversationHistory,
  ) {
    if (conversationHistory == null || conversationHistory.isEmpty) {
      return 0.7; // Standard temperature for new conversations
    }

    // Lower temperature for longer conversations to maintain consistency
    if (conversationHistory.length > 8) {
      return 0.6; // More focused responses for long conversations
    } else if (conversationHistory.length > 4) {
      return 0.65; // Slightly more focused
    }

    return 0.7; // Standard temperature
  }

  // Enhanced confidence calculation
  double _calculateEnhancedConfidence(
    String content,
    List<Map<String, dynamic>>? conversationHistory,
  ) {
    double confidence = 0.8; // Base confidence for HuggingFace

    // Adjust based on content quality
    if (content.length < 10) {
      confidence *= 0.6; // Very short responses are less confident
    } else if (content.length > 50) {
      confidence *= 1.1; // Longer responses are generally better
    }

    // Boost confidence if response shows contextual awareness
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final contextualIndicators = [
        'as mentioned',
        'previously',
        'earlier',
        'continuing',
        'building on',
        'regarding',
        'about that',
      ];

      final isContextual = contextualIndicators.any(
        (indicator) => content.toLowerCase().contains(indicator),
      );

      if (isContextual) {
        confidence *= 1.1; // Boost for contextual responses
      }
    }

    // Reduce confidence for error indicators
    if (content.toLowerCase().contains('sorry') ||
        content.toLowerCase().contains('cannot') ||
        content.toLowerCase().contains('unable') ||
        content.toLowerCase().contains('don\'t know')) {
      confidence *= 0.7;
    }

    return confidence.clamp(0.0, 1.0);
  }

  Future<AIResponse> _tryAlternativeModels(
    String query,
    String? extractedText,
  ) async {
    final alternativeModels = [
      'facebook/blenderbot-400M-distill',
      'microsoft/DialoGPT-medium',
      'gpt2',
    ];

    for (final model in alternativeModels) {
      try {
        final service = HuggingFaceService(apiKey: apiKey, modelId: model);
        final response = await service._processTextQuery(query, extractedText);

        if (response.isSuccessful) {
          return response.copyWith(model: 'HuggingFace $model (fallback)');
        }
      } catch (e) {
        continue; // Try next model
      }
    }

    return AIResponse.error(
      error: 'All alternative models failed',
      model: modelName,
    );
  }
}

extension AIResponseExtension on AIResponse {
  AIResponse copyWith({
    String? content,
    String? model,
    double? confidence,
    bool? isSuccessful,
    String? error,
    Map<String, dynamic>? metadata,
  }) {
    return AIResponse(
      content: content ?? this.content,
      model: model ?? this.model,
      confidence: confidence ?? this.confidence,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      error: error ?? this.error,
      metadata: metadata ?? this.metadata,
    );
  }
}
