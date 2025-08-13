import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';
import 'config_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  GeminiService({required this.apiKey});

  @override
  String get modelName => 'Gemini 2.0 Flash';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200 ||
          response.statusCode ==
              400; // 400 is expected without proper request body
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
      // Build the request body using Gemini's format
      final List<Map<String, dynamic>> contents = [];

      // Add conversation history if provided (convert to Gemini format)
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        for (final entry in conversationHistory) {
          final role = entry['role'] as String;
          final content = entry['content'];

          String textContent = '';
          if (content is List && content.isNotEmpty) {
            final textPart = content.firstWhere(
              (c) => c['type'] == 'text',
              orElse: () => {'text': ''},
            );
            textContent = textPart['text'] as String? ?? '';
          }

          if (textContent.isNotEmpty) {
            contents.add({
              'role': role == 'user' ? 'user' : 'model',
              'parts': [
                {'text': textContent},
              ],
            });
          }
        }
      }

      // Build current message content
      final List<Map<String, dynamic>> parts = [];

      // Add current user query as simple text (context is handled by conversation history)
      String currentQuery = query;
      if (extractedText != null && extractedText.isNotEmpty) {
        currentQuery += '\n\nExtracted text from image: $extractedText';
      }
      parts.add({'text': currentQuery});

      // Add images if provided (Gemini format)
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          final mimeType = _getMimeType(image.path);
          parts.add({
            'inline_data': {'mime_type': mimeType, 'data': base64Image},
          });
        }
      }

      // Add current user message
      contents.add({'role': 'user', 'parts': parts});

      final requestBody = {
        'contents': contents,
        'generationConfig': await _getGenerationConfig(conversationHistory),
      };

      final response = await http.post(
        Uri.parse('${baseUrl}gemini-2.5-flash:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Track successful API call
        await ConfigService.incrementApiCallCount();

        final jsonResponse = jsonDecode(response.body);
        final candidates = jsonResponse['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final candidate = candidates[0];
          final content = candidate['content'];
          final parts = content['parts'] as List?;

          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'] as String?;
            final finishReason = candidate['finishReason'] as String?;

            if (text != null && text.isNotEmpty) {
              // Calculate enhanced confidence based on context and response quality
              double confidence = _calculateEnhancedConfidence(
                finishReason,
                text,
                conversationHistory,
              );

              return AIResponse.success(
                content: text,
                model: modelName,
                confidence: confidence,
                metadata: {
                  'finishReason': finishReason,
                  'usage': jsonResponse['usageMetadata'],
                },
              );
            }
          }
        }

        return AIResponse.error(
          error: 'No valid response generated',
          model: modelName,
        );
      } else {
        // Track API error
        await ConfigService.incrementApiErrorCount();

        final errorBody = response.body;
        return AIResponse.error(
          error: 'API Error (${response.statusCode}): $errorBody',
          model: modelName,
        );
      }
    } catch (e) {
      // Track API error for exceptions
      await ConfigService.incrementApiErrorCount();

      return AIResponse.error(
        error: 'Exception occurred: $e',
        model: modelName,
      );
    }
  }

  // Enhanced prompt building with context awareness
  // Get MIME type for better image handling
  String _getMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      default:
        return 'image/jpeg'; // Default fallback
    }
  }

  // Get generation config with user preferences and contextual adjustments
  Future<Map<String, dynamic>> _getGenerationConfig(
    List<Map<String, dynamic>>? conversationHistory,
  ) async {
    // Get user preferences from ConfigService
    final useAdvancedParams = ConfigService.getUseAdvancedParameters();

    if (!useAdvancedParams) {
      // Use optimal defaults when advanced parameters are disabled
      return {
        'temperature': _getContextualTemperature(conversationHistory),
        'topP': 0.9,
        'topK': 40,
        'maxOutputTokens': 2048,
      };
    }

    // Use user-configured parameters when advanced mode is enabled
    final temperature = ConfigService.getTemperature();
    final topP = ConfigService.getTopP();
    final topK = ConfigService.getTopK();
    final maxTokens = ConfigService.getMaxTokens();

    return {
      'temperature': temperature,
      'topP': topP,
      'topK': topK,
      'maxOutputTokens': maxTokens,
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
    if (conversationHistory.length > 10) {
      return 0.6; // More focused and consistent responses
    } else if (conversationHistory.length > 5) {
      return 0.65; // Slightly more focused
    }

    return 0.7; // Standard temperature
  }

  // Enhanced confidence calculation with context awareness
  double _calculateEnhancedConfidence(
    String? finishReason,
    String content,
    List<Map<String, dynamic>>? conversationHistory,
  ) {
    double confidence = 0.8; // Base confidence

    // Adjust based on finish reason
    switch (finishReason) {
      case 'stop':
        confidence = 0.9;
        break;
      case 'length':
        confidence = 0.7;
        break;
      case 'content_filter':
        confidence = 0.3;
        break;
      default:
        confidence = 0.8;
    }

    // Adjust based on content quality
    if (content.length < 10) {
      confidence *= 0.6; // Very short responses are less confident
    } else if (content.length > 100) {
      confidence *= 1.1; // Longer, detailed responses are more confident
    }

    // Boost confidence for contextual responses
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final contextualIndicators = [
        'as we discussed',
        'from the previous',
        'building on',
        'continuing from',
        'as mentioned',
        'referring to',
      ];

      final isContextual = contextualIndicators.any(
        (indicator) => content.toLowerCase().contains(indicator),
      );

      if (isContextual) {
        confidence *= 1.15; // Boost confidence for contextual responses
      }
    }

    // Check for common error indicators
    if (content.toLowerCase().contains('sorry') ||
        content.toLowerCase().contains('cannot') ||
        content.toLowerCase().contains('unable')) {
      confidence *= 0.7;
    }

    return confidence.clamp(0.0, 1.0);
  }
}
