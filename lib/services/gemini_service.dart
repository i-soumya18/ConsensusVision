import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai/';

  GeminiService({required this.apiKey});

  @override
  String get modelName => 'Gemini 2.0 Flash';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}models'),
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
      // Build content array for OpenAI-compatible format
      final List<Map<String, dynamic>> content = [];

      // Add text content
      content.add({'type': 'text', 'text': _buildPrompt(query, extractedText)});

      // Add images if provided
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          content.add({
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
          });
        }
      }

      final requestBody = {
        'model': 'gemini-2.0-flash',
        'messages': [
          {'role': 'user', 'content': content},
        ],
        'max_tokens': 2048,
        'temperature': 0.7,
      };

      final response = await http.post(
        Uri.parse('${baseUrl}chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final choices = jsonResponse['choices'] as List?;

        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0];
          final message = choice['message'];
          final content = message['content'] as String;
          final finishReason = choice['finish_reason'] as String?;

          // Calculate confidence based on finish reason and response quality
          double confidence = _calculateConfidence(finishReason, content);

          return AIResponse.success(
            content: content,
            model: modelName,
            confidence: confidence,
            metadata: {
              'finishReason': finishReason,
              'usage': jsonResponse['usage'],
            },
          );
        } else {
          return AIResponse.error(
            error: 'No valid response generated',
            model: modelName,
          );
        }
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage =
            errorBody['error']?['message'] ?? 'Unknown error occurred';
        return AIResponse.error(
          error: 'API Error (${response.statusCode}): $errorMessage',
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

  String _buildPrompt(String query, String? extractedText) {
    String prompt = 'User query: $query\n\n';

    if (extractedText != null && extractedText.isNotEmpty) {
      prompt += 'Extracted text from image(s):\n$extractedText\n\n';
    }

    prompt += '''
Please analyze the provided content and answer the user's query accurately. 
If images are provided, analyze them carefully and incorporate visual information into your response.
Be comprehensive, accurate, and helpful in your response.
''';

    return prompt;
  }

  double _calculateConfidence(String? finishReason, String content) {
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

    // Adjust based on content quality (simple heuristics)
    if (content.length < 10) {
      confidence *= 0.6; // Very short responses are less confident
    } else if (content.length > 100) {
      confidence *= 1.1; // Longer, detailed responses are more confident
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
