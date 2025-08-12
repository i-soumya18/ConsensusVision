import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// Conditional import for Android TTS
import 'android_tts_service_stub.dart'
    if (dart.library.io) 'android_tts_service.dart';

class TextToSpeechService {
  static final TextToSpeechService _instance = TextToSpeechService._internal();
  factory TextToSpeechService() => _instance;
  TextToSpeechService._internal();

  static const MethodChannel _channel = MethodChannel('text_to_speech');

  // Android TTS service instance
  AndroidTtsService? _androidTts;

  // Initialize TTS service
  Future<void> _initializeTts() async {
    if (_androidTts == null &&
        defaultTargetPlatform == TargetPlatform.android) {
      try {
        _androidTts = AndroidTtsService();
        final success = await _androidTts!.initialize();

        if (!success) {
          _androidTts = null;
        } else if (kDebugMode) {
          print('Android TTS service initialized successfully');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing Android TTS service: $e');
        }
        _androidTts = null;
      }
    }
  }

  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isSpeaking => _isSpeaking;

  // Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // For now, we'll use a simple approach
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize TTS: $e');
      }
      _isInitialized = false;
    }
  }

  // Speak the given text using platform-specific methods
  Future<void> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (text.trim().isEmpty) return;

    try {
      // Stop any current speech
      if (_isSpeaking) {
        await stop();
      }

      _isSpeaking = true;

      // Clean the text for better speech
      final cleanText = _cleanTextForSpeech(text);

      // Use platform-specific TTS
      if (defaultTargetPlatform == TargetPlatform.android) {
        await _speakAndroid(cleanText);
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        await _speakWindows(cleanText);
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        await _speakMacOS(cleanText);
      } else {
        // Fallback: just copy to clipboard and show notification
        await _fallbackSpeak(cleanText);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to speak text: $e');
      }
    } finally {
      _isSpeaking = false;
    }
  }

  // Android-specific TTS using flutter_tts or fallback methods
  Future<void> _speakAndroid(String text) async {
    try {
      // Initialize TTS if not already done
      await _initializeTts();

      // Try using AndroidTtsService first
      if (_androidTts != null && _androidTts!.isAvailable) {
        final success = await _androidTts!.speak(text);
        if (success) {
          if (kDebugMode) {
            print('Using AndroidTtsService for Android TTS');
          }
          return;
        }
      }

      // Fallback to method channel
      final result = await _channel.invokeMethod('speak', {
        'text': text,
        'language': 'en-US',
        'speechRate': 0.5,
        'pitch': 1.0,
      });

      if (result == false) {
        throw Exception('Android TTS not available');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Android TTS failed: $e, falling back to alternative method');
      }
      // Try alternative Android TTS approach
      await _speakAndroidAlternative(text);
    }
  }

  // Alternative Android TTS implementation
  Future<void> _speakAndroidAlternative(String text) async {
    try {
      // For Android, try to use a system-level approach
      await _speakAndroidSystem(text);
    } catch (e) {
      if (kDebugMode) {
        print('Android TTS alternative failed: $e');
        print('Falling back to clipboard copy');
      }
      await _fallbackSpeak(text);
    }
  }

  // System-level Android TTS using adb/am commands
  Future<void> _speakAndroidSystem(String text) async {
    try {
      // Split long text into smaller chunks for better TTS handling
      final chunks = _splitTextIntoChunks(text, 200);

      for (final chunk in chunks) {
        // Try to use Android's TTS through shell command
        // This approach tries to trigger the accessibility TTS service
        await Process.run('sh', [
          '-c',
          'echo "$chunk" | festival --tts 2>/dev/null || echo "$chunk" | espeak 2>/dev/null || true',
        ]);

        // Add a small delay between chunks
        if (chunks.length > 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (kDebugMode) {
        print('Android TTS: Attempted system-level synthesis');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Android system TTS failed: $e');
        print(
          'Recommendation: Add flutter_tts package to pubspec.yaml for proper Android TTS',
        );
      }
      // Final fallback
      await _fallbackSpeak(text);
    }
  }

  // Split text into manageable chunks for TTS
  List<String> _splitTextIntoChunks(String text, int maxChunkSize) {
    if (text.length <= maxChunkSize) {
      return [text];
    }

    final chunks = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));

    String currentChunk = '';
    for (final sentence in sentences) {
      final trimmedSentence = sentence.trim();
      if (trimmedSentence.isEmpty) continue;

      if (currentChunk.length + trimmedSentence.length + 1 <= maxChunkSize) {
        currentChunk += (currentChunk.isEmpty ? '' : '. ') + trimmedSentence;
      } else {
        if (currentChunk.isNotEmpty) {
          chunks.add(currentChunk);
        }
        currentChunk = trimmedSentence;
      }
    }

    if (currentChunk.isNotEmpty) {
      chunks.add(currentChunk);
    }

    return chunks.isEmpty ? [text] : chunks;
  }

  // Windows-specific TTS using SAPI
  Future<void> _speakWindows(String text) async {
    try {
      // Escape text properly for PowerShell
      final escapedText = text
          .replaceAll('"', '""')
          .replaceAll("'", "''")
          .replaceAll('\n', ' ')
          .replaceAll('\r', ' ');

      // Use PowerShell with SAPI for Windows TTS
      final result = await Process.run('powershell', [
        '-WindowStyle',
        'Hidden',
        '-Command',
        '''
        try {
          Add-Type -AssemblyName System.Speech
          \$speak = New-Object System.Speech.Synthesis.SpeechSynthesizer
          \$speak.Rate = 0
          \$speak.Volume = 100
          \$speak.Speak("$escapedText")
        } catch {
          Write-Host "TTS Error: \$_"
          exit 1
        }
        ''',
      ], runInShell: false);

      if (result.exitCode != 0) {
        throw Exception('PowerShell TTS failed: ${result.stderr}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Windows TTS failed: $e');
      }
      await _fallbackSpeak(text);
    }
  }

  // macOS-specific TTS using say command
  Future<void> _speakMacOS(String text) async {
    try {
      await Process.run('say', [text]);
    } catch (e) {
      await _fallbackSpeak(text);
    }
  }

  // Fallback method - copy to clipboard with user notification
  Future<void> _fallbackSpeak(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (kDebugMode) {
        print(
          'TTS attempted but may not be audible - Message copied to clipboard for manual reading',
        );
        print(
          'Text: ${text.substring(0, text.length > 100 ? 100 : text.length)}${text.length > 100 ? '...' : ''}',
        );
        print(
          'To enable TTS: Go to Android Settings > Accessibility > Text-to-speech output',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS and clipboard fallback both failed: $e');
      }
    }
  }

  // Stop speaking
  Future<void> stop() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        // Stop AndroidTtsService if available
        if (_androidTts != null) {
          try {
            await _androidTts!.stop();
          } catch (e) {
            if (kDebugMode) {
              print('Error stopping AndroidTtsService: $e');
            }
          }
        }
        // Also try method channel as fallback
        try {
          await _channel.invokeMethod('stop');
        } catch (e) {
          if (kDebugMode) {
            print('Method channel stop failed: $e');
          }
        }
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        // Kill any running PowerShell TTS processes
        await Process.run('taskkill', ['/F', '/IM', 'powershell.exe']);
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        // Kill any running say processes
        await Process.run('killall', ['say']);
      }
      _isSpeaking = false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop TTS: $e');
      }
    }
  }

  // Clean text for better speech synthesis
  String _cleanTextForSpeech(String text) {
    // Remove markdown syntax
    String cleanText = text
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Inline code
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' code block ') // Code blocks
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'$1') // Links
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'>\s*'), '') // Blockquotes
        .replaceAll(RegExp(r'-\s*'), ' ') // List items
        .replaceAll(RegExp(r'\n+'), ' ') // Multiple newlines
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces
        .trim();

    // Replace technical terms or symbols for better pronunciation
    cleanText = cleanText
        .replaceAll('&', ' and ')
        .replaceAll('@', ' at ')
        .replaceAll('#', ' hash ')
        .replaceAll('%', ' percent ')
        .replaceAll(r'$', ' dollar ')
        .replaceAll('€', ' euro ')
        .replaceAll('£', ' pound ');

    return cleanText;
  }

  // Dispose resources
  void dispose() {
    stop();
    _isInitialized = false;
    _isSpeaking = false;
  }
}
