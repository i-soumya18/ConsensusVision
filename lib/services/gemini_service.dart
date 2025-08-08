import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';

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
        Uri.parse('${baseUrl}gemini-2.0-flash-exp:generateContent?key=$apiKey'),
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

      // Add enhanced text content
      final promptText = _buildEnhancedPrompt(
        query,
        extractedText,
        conversationHistory,
      );
      parts.add({'text': promptText});

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
        'generationConfig': {
          'temperature': _getContextualTemperature(conversationHistory),
          'topP': 0.95,
          'topK': 40,
          'maxOutputTokens': 2048,
        },
      };

      final response = await http.post(
        Uri.parse('${baseUrl}gemini-2.0-flash-exp:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
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
        final errorBody = response.body;
        return AIResponse.error(
          error: 'API Error (${response.statusCode}): $errorBody',
          model: modelName,
        );
      }
    } catch (e) {
      return AIResponse.error(
        error: 'Exception occurred: $e',
        model: modelName,
      );
    }
  }

  // Enhanced prompt building with context awareness
  String _buildEnhancedPrompt(
    String query,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  ) {
    String prompt = '';

    // Add system-like instructions at the beginning
    prompt +=
        '''You are an advanced AI assistant specialized in image analysis and contextual conversations. 
Always maintain awareness of conversation context and provide detailed, helpful responses.

''';

    // Add contextual awareness
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final hasImages = conversationHistory.any(
        (msg) =>
            msg['content'] is List &&
            (msg['content'] as List).any(
              (content) =>
                  content['type'] == 'image_url' ||
                  content.containsKey('inline_data'),
            ),
      );

      if (hasImages) {
        prompt += 'Building on our previous image analysis and discussion:\n\n';
      } else {
        prompt += 'Continuing our conversation:\n\n';
      }
    }

    prompt += 'Current query: $query\n\n';

    if (extractedText != null && extractedText.isNotEmpty) {
      prompt += 'Extracted text from current image(s):\n$extractedText\n\n';
    }

    prompt += '''
Please provide a comprehensive response that:
- Directly addresses the current query
- Maintains awareness of our conversation context
- Incorporates any visual information from images
- Builds upon previous discussion points when relevant
- Is detailed, accurate, and conversational
''';

    return prompt;
  }

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

  // Adjust temperature based on conversation context
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
