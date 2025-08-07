import 'dart:io';
import '../models/ai_response.dart';

abstract class AIService {
  String get modelName;
  Future<AIResponse> processQuery({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  });
  Future<bool> isAvailable();
}
