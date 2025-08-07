import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';

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
  }) async {
    try {
      // For text-based models, we'll use a conversational approach
      final response = await _processTextQuery(query, extractedText);

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
    String? extractedText,
  ) async {
    try {
      String prompt = _buildPrompt(query, extractedText);

      final requestBody = {
        'inputs': prompt,
        'parameters': {
          'max_length': 1000,
          'temperature': 0.7,
          'top_p': 0.9,
          'do_sample': true,
          'return_full_text': false,
        },
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
              confidence: 0.8,
              metadata: {
                'model_id': modelId,
                'response_length': generatedText.length,
              },
            );
          }
        }

        return AIResponse.error(
          error: 'No valid response generated',
          model: modelName,
        );
      } else {
        final errorBody = response.body;
        return AIResponse.error(
          error: 'HTTP ${response.statusCode}: $errorBody',
          model: modelName,
        );
      }
    } catch (e) {
      return AIResponse.error(
        error: 'Exception in text processing: $e',
        model: modelName,
      );
    }
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

  String _buildPrompt(String query, String? extractedText) {
    String prompt = '';

    if (extractedText != null && extractedText.isNotEmpty) {
      prompt += 'Context from image text: $extractedText\n\n';
    }

    prompt += 'Human: $query\n\nAssistant: ';

    return prompt;
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
