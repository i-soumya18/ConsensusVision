import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';

class GeminiService implements AIService {
  final String apiKey;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta';

  GeminiService({required this.apiKey});

  @override
  String get modelName => 'Gemini Pro Vision';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/models'),
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
      final List<Map<String, dynamic>> parts = [];

      // Add text query
      parts.add({'text': _buildPrompt(query, extractedText)});

      // Add images if provided
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          final bytes = await image.readAsBytes();
          final base64Image = base64Encode(bytes);
          parts.add({
            'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
          });
        }
      }

      final requestBody = {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      final response = await http.post(
        Uri.parse(
          '$baseUrl/models/gemini-pro-vision:generateContent?key=$apiKey',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final candidates = jsonResponse['candidates'] as List?;

        if (candidates != null && candidates.isNotEmpty) {
          final content =
              candidates[0]['content']['parts'][0]['text'] as String;
          final safetyRatings = candidates[0]['safetyRatings'] as List?;

          // Calculate confidence based on safety ratings and finish reason
          double confidence = _calculateConfidence(candidates[0]);

          return AIResponse.success(
            content: content,
            model: modelName,
            confidence: confidence,
            metadata: {
              'safetyRatings': safetyRatings,
              'finishReason': candidates[0]['finishReason'],
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
        return AIResponse.error(
          error: errorBody['error']['message'] ?? 'Unknown error occurred',
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

  double _calculateConfidence(Map<String, dynamic> candidate) {
    final finishReason = candidate['finishReason'] as String?;
    final safetyRatings = candidate['safetyRatings'] as List?;

    double confidence = 0.8; // Base confidence

    // Adjust based on finish reason
    switch (finishReason) {
      case 'STOP':
        confidence = 0.9;
        break;
      case 'MAX_TOKENS':
        confidence = 0.7;
        break;
      case 'SAFETY':
        confidence = 0.3;
        break;
      case 'RECITATION':
        confidence = 0.5;
        break;
    }

    // Adjust based on safety ratings
    if (safetyRatings != null) {
      for (final rating in safetyRatings) {
        final probability = rating['probability'] as String?;
        if (probability == 'HIGH' || probability == 'MEDIUM') {
          confidence *= 0.8;
        }
      }
    }

    return confidence.clamp(0.0, 1.0);
  }
}
