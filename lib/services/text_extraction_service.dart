import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/config_service.dart';

class TextExtractionService {
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';

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

      // Create request body using Gemini's native format
      final requestBody = {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {
                'text':
                    'Extract all text from this image. Return only the extracted text without any additional commentary or formatting. If no text is found, return "No text found".',
              },
              {
                'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
              },
            ],
          },
        ],
        'generationConfig': {'temperature': 0.1, 'maxOutputTokens': 2048},
      };

      final response = await http.post(
        Uri.parse(
          '${geminiBaseUrl}gemini-2.0-flash-exp:generateContent?key=$apiKey',
        ),
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
            return text?.trim() ?? '';
          }
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
