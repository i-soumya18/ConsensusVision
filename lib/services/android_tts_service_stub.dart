import 'package:flutter/foundation.dart';

// Stub implementation for non-Android platforms
class AndroidTtsService {
  static final AndroidTtsService _instance = AndroidTtsService._internal();
  factory AndroidTtsService() => _instance;
  AndroidTtsService._internal();

  // Initialize TTS service (stub)
  Future<bool> initialize() async {
    if (kDebugMode) {
      print('AndroidTtsService stub - not available on this platform');
    }
    return false;
  }

  // Speak text (stub)
  Future<bool> speak(String text) async {
    if (kDebugMode) {
      print('AndroidTtsService stub - speak not available on this platform');
    }
    return false;
  }

  // Stop speaking (stub)
  Future<void> stop() async {
    if (kDebugMode) {
      print('AndroidTtsService stub - stop not available on this platform');
    }
  }

  // Check if TTS is available (always false for stub)
  bool get isAvailable => false;
}
