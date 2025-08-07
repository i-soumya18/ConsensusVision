import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/config_service.dart';

class TextExtractionService {
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/openai/';

  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Use Gemini API for text extraction on all platforms
      return await _extractTextUsingGemini(imageFile);
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  static Future<String> _extractTextUsingGemini(File imageFile) async {
    try {
      final apiKey = ConfigService.getGeminiApiKey();
      if (apiKey == null) {
        throw Exception('Gemini API key not configured');
      }

      // Read and encode image
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create request body using OpenAI-compatible format
      final requestBody = {
        'model': 'gemini-2.0-flash',
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text':
                    'Extract all text from this image. Return only the extracted text without any additional commentary or formatting. If no text is found, return "No text found".',
              },
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 2048,
        'temperature': 0.1,
      };

      final response = await http.post(
        Uri.parse('${geminiBaseUrl}chat/completions'),
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
          final content = choices[0]['message']['content'] as String?;
          return content?.trim() ?? '';
        }
      } else {
        print('Gemini API error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to extract text: ${response.statusCode}');
      }

      return '';
    } catch (e) {
      print('Error in Gemini text extraction: $e');
      throw e;
    }
  }

  static Future<String> extractTextFromMultipleImages(
    List<File> imageFiles,
  ) async {
    List<String> allTexts = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final text = await extractTextFromImage(imageFiles[i]);
      if (text.isNotEmpty) {
        allTexts.add('--- Image ${i + 1} ---\n$text');
      }
    }

    return allTexts.join('\n\n');
  }

  static void dispose() {
    // No resources to dispose when using Gemini API
  }
}
