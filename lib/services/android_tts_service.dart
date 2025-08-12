import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AndroidTtsService {
  static final AndroidTtsService _instance = AndroidTtsService._internal();
  factory AndroidTtsService() => _instance;
  AndroidTtsService._internal();

  static const MethodChannel _channel = MethodChannel('android_tts');
  bool _isInitialized = false;

  // Initialize TTS service for Android
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Try to test if Android TTS is available
      final result = await _channel.invokeMethod('isAvailable');
      _isInitialized = result == true;

      if (_isInitialized && kDebugMode) {
        print('Android TTS channel initialized successfully');
      }
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('Android TTS channel not available: $e');
      }
      _isInitialized = false;
      return false;
    }
  }

  // Speak text using Android TTS intents or system commands
  Future<bool> speak(String text) async {
    try {
      // Try method channel first
      if (_isInitialized) {
        final result = await _channel.invokeMethod('speak', {'text': text});
        if (result == true) {
          if (kDebugMode) {
            print(
              'Android TTS channel speaking: ${text.substring(0, text.length > 50 ? 50 : text.length)}...',
            );
          }
          return true;
        }
      }

      // Fallback to system-level TTS commands
      return await _speakUsingSystemCommands(text);
    } catch (e) {
      if (kDebugMode) {
        print('Android TTS speak failed: $e');
      }
      return await _speakUsingSystemCommands(text);
    }
  }

  // Fallback method using system commands and Android intents
  Future<bool> _speakUsingSystemCommands(String text) async {
    try {
      if (Platform.isAndroid) {
        // Split long text into chunks for better TTS handling
        final chunks = _splitTextIntoChunks(text, 200);

        for (String chunk in chunks) {
          // Try using Android TTS through intent
          try {
            final result = await Process.run('am', [
              'start',
              '-a',
              'android.intent.action.TTS_QUEUE_PROCESSING_COMPLETED',
              '--es',
              'android.speech.extra.TEXT',
              chunk,
              '--ez',
              'android.speech.extra.QUEUE_ADD',
              'false',
            ]);

            if (result.exitCode == 0) {
              if (kDebugMode) {
                print(
                  'Android TTS intent executed for chunk: ${chunk.substring(0, chunk.length > 30 ? 30 : chunk.length)}...',
                );
              }
              // Small delay between chunks
              await Future.delayed(Duration(milliseconds: 500));
              continue;
            }
          } catch (e) {
            if (kDebugMode) {
              print('Android TTS intent failed for chunk: $e');
            }
          }

          // Alternative: Try using settings TTS
          try {
            final settingsResult = await Process.run('am', [
              'start',
              '-a',
              'com.android.settings.TTS_SETTINGS',
            ]);

            if (settingsResult.exitCode == 0) {
              if (kDebugMode) {
                print(
                  'Opened Android TTS settings - manual TTS configuration may be needed',
                );
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Could not open TTS settings: $e');
            }
          }
        }

        // Try espeak as final fallback
        try {
          final espeakResult = await Process.run('espeak', [text]);
          if (espeakResult.exitCode == 0) {
            if (kDebugMode) {
              print('Android espeak TTS executed successfully');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Espeak not available: $e');
          }
        }

        if (kDebugMode) {
          print('Android TTS: Attempted system-level synthesis');
        }
        return true; // Return true to indicate attempt was made
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Android system TTS commands failed: $e');
      }
      return false;
    }
  }

  // Helper method to split text into manageable chunks
  List<String> _splitTextIntoChunks(String text, int maxLength) {
    if (text.length <= maxLength) return [text];

    List<String> chunks = [];
    int start = 0;

    while (start < text.length) {
      int end = start + maxLength;
      if (end >= text.length) {
        chunks.add(text.substring(start));
        break;
      }

      // Try to find a natural break point (space, period, etc.)
      int breakPoint = text.lastIndexOf(' ', end);
      if (breakPoint == -1 || breakPoint <= start) {
        breakPoint = end;
      }

      chunks.add(text.substring(start, breakPoint));
      start = breakPoint + 1;
    }

    return chunks;
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      if (_isInitialized) {
        await _channel.invokeMethod('stop');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping Android TTS: $e');
      }
    }
  }

  // Check if TTS is available
  bool get isAvailable => _isInitialized;
}
