import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'ai_service.dart';
import 'config_service.dart';

class GeminiProService implements AIService {
  final String apiKey;
  static const String baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  GeminiProService({required this.apiKey});

  @override
  String get modelName => 'Gemini 2.0 Pro';

  @override
  Future<bool> isAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('${baseUrl}gemini-2.0-pro:generateContent?key=$apiKey'),
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
          if (content is String) {
            textContent = content;
          } else if (content is List) {
            for (final part in content) {
              if (part is Map && part['text'] != null) {
                textContent += part['text'] as String;
              }
            }
          }

          if (textContent.isNotEmpty) {
            contents.add({
              'role': role == 'assistant' ? 'model' : 'user',
              'parts': [
                {'text': textContent},
              ],
            });
          }
        }
      }

      // Add current query with optional images
      final List<Map<String, dynamic>> parts = [];

      // Add system prompt if this is the first message
      String finalQuery = query;
      if (conversationHistory == null || conversationHistory.isEmpty) {
        final systemPrompt = ConfigService.getSystemPrompt();
        finalQuery = '$systemPrompt\n\nUser Query: $query';
      }

      // Add extracted text if available
      if (extractedText != null && extractedText.isNotEmpty) {
        finalQuery += '\n\nExtracted text from images: $extractedText';
      }

      parts.add({'text': finalQuery});

      // Add images if provided
      if (images != null && images.isNotEmpty) {
        for (final image in images) {
          try {
            final bytes = await image.readAsBytes();
            final base64Image = base64Encode(bytes);

            // Get file extension for MIME type
            final extension = image.path.split('.').last.toLowerCase();
            String mimeType = 'image/jpeg';
            switch (extension) {
              case 'png':
                mimeType = 'image/png';
                break;
              case 'gif':
                mimeType = 'image/gif';
                break;
              case 'webp':
                mimeType = 'image/webp';
                break;
              default:
                mimeType = 'image/jpeg';
            }

            parts.add({
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            });
          } catch (e) {
            print('Error processing image: $e');
          }
        }
      }

      contents.add({'role': 'user', 'parts': parts});

      final requestBody = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 8192,
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
        Uri.parse('${baseUrl}gemini-2.0-pro:generateContent?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['candidates'] != null &&
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          final content = data['candidates'][0]['content']['parts'][0]['text'];

          return AIResponse(
            content: content ?? 'No response generated',
            isSuccessful: true,
            model: modelName,
            confidence: 85.0,
          );
        } else {
          return AIResponse(
            content: 'No response generated from Gemini Pro',
            isSuccessful: false,
            model: modelName,
            confidence: 0.0,
            error: 'Empty response',
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        return AIResponse(
          content: 'Error: ${response.statusCode}',
          isSuccessful: false,
          model: modelName,
          confidence: 0.0,
          error: errorData['error']?['message'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      return AIResponse(
        content: 'Network error occurred',
        isSuccessful: false,
        model: modelName,
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }
}
