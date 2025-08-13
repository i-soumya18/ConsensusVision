import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_response.dart';
import 'connection_pool_service.dart';

/// Streaming response service for faster AI interactions
/// Provides real-time streaming of AI responses for better user experience
class StreamingResponseService {
  static final StreamingResponseService _instance =
      StreamingResponseService._internal();
  factory StreamingResponseService() => _instance;
  StreamingResponseService._internal();

  final ConnectionPoolService _connectionPool = ConnectionPoolService();
  final Map<String, StreamController<String>> _activeStreams = {};
  final Map<String, StringBuffer> _partialResponses = {};

  /// Initialize the streaming service
  Future<void> init() async {
    await _connectionPool.init();
  }

  /// Start a streaming request to Gemini API
  Stream<String> streamGeminiResponse({
    required String apiKey,
    required Map<String, dynamic> requestBody,
    String? sessionId,
    Duration timeout = const Duration(seconds: 30),
  }) async* {
    sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    final controller = StreamController<String>();
    _activeStreams[sessionId] = controller;
    _partialResponses[sessionId] = StringBuffer();

    try {
      final uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:streamGenerateContent?key=$apiKey',
      );

      // Add streaming configuration to request body
      final streamingRequestBody = {
        ...requestBody,
        'generationConfig': {
          ...(requestBody['generationConfig'] as Map<String, dynamic>? ?? {}),
          'candidateCount': 1,
        },
      };

      final request = http.Request('POST', uri)
        ..headers.addAll({
          'Content-Type': 'application/json',
          'Accept': 'text/event-stream',
        })
        ..body = jsonEncode(streamingRequestBody);

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode == 200) {
        await for (final chunk in response.stream.transform(utf8.decoder)) {
          final processedChunk = _processStreamChunk(chunk, sessionId);
          if (processedChunk.isNotEmpty) {
            controller.add(processedChunk);
            yield processedChunk;
          }
        }
      } else {
        final error = 'Streaming failed with status: ${response.statusCode}';
        controller.addError(error);
        throw Exception(error);
      }
    } catch (e) {
      controller.addError(e);
      throw e;
    } finally {
      await controller.close();
      _activeStreams.remove(sessionId);
      _partialResponses.remove(sessionId);
    }
  }

  /// Stream HuggingFace response (simulated streaming for non-streaming APIs)
  Stream<String> streamHuggingFaceResponse({
    required String apiKey,
    required String modelId,
    required Map<String, dynamic> requestBody,
    String? sessionId,
    Duration timeout = const Duration(seconds: 30),
  }) async* {
    sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final uri = Uri.parse(
        'https://api-inference.huggingface.co/models/$modelId',
      );

      final response = await _connectionPool.post(
        uri,
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
        timeout: timeout,
        priority: 8, // High priority for streaming
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String fullText = '';

        if (responseData is List && responseData.isNotEmpty) {
          fullText = responseData[0]['generated_text'] ?? '';
        } else if (responseData is Map) {
          fullText = responseData['generated_text'] ?? '';
        }

        // Simulate streaming by breaking text into chunks
        yield* _simulateStreaming(fullText, sessionId);
      } else {
        throw Exception('HuggingFace API error: ${response.statusCode}');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Create a streaming wrapper for non-streaming APIs
  Stream<String> createStreamingWrapper({
    required Future<AIResponse> Function() apiCall,
    String? sessionId,
    int chunkSize = 50,
    Duration chunkDelay = const Duration(milliseconds: 100),
  }) async* {
    sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final response = await apiCall();

      if (response.isSuccessful) {
        yield* _simulateStreaming(
          response.content,
          sessionId,
          chunkSize: chunkSize,
          delay: chunkDelay,
        );
      } else {
        throw Exception(response.error ?? 'API call failed');
      }
    } catch (e) {
      throw e;
    }
  }

  /// Stream response with typing indicator simulation
  Stream<StreamingEvent> streamWithTypingIndicator({
    required Stream<String> dataStream,
    String? sessionId,
    Duration typingDelay = const Duration(milliseconds: 50),
  }) async* {
    sessionId ??= DateTime.now().millisecondsSinceEpoch.toString();

    yield StreamingEvent.typing(sessionId);

    final buffer = StringBuffer();
    bool hasEmittedContent = false;

    try {
      await for (final chunk in dataStream) {
        if (!hasEmittedContent) {
          yield StreamingEvent.startContent(sessionId);
          hasEmittedContent = true;
        }

        buffer.write(chunk);
        yield StreamingEvent.content(sessionId, chunk, buffer.toString());

        // Add realistic typing delay
        await Future.delayed(typingDelay);
      }

      yield StreamingEvent.complete(sessionId, buffer.toString());
    } catch (e) {
      yield StreamingEvent.error(sessionId, e.toString());
    }
  }

  /// Get partial response for a session
  String getPartialResponse(String sessionId) {
    return _partialResponses[sessionId]?.toString() ?? '';
  }

  /// Stop streaming for a session
  Future<void> stopStreaming(String sessionId) async {
    final controller = _activeStreams[sessionId];
    if (controller != null) {
      await controller.close();
      _activeStreams.remove(sessionId);
      _partialResponses.remove(sessionId);
    }
  }

  /// Stop all active streams
  Future<void> stopAllStreams() async {
    final sessions = _activeStreams.keys.toList();
    for (final sessionId in sessions) {
      await stopStreaming(sessionId);
    }
  }

  /// Get streaming statistics
  Map<String, dynamic> getStreamingStats() {
    return {
      'activeStreams': _activeStreams.length,
      'partialResponses': _partialResponses.length,
      'activeSessions': _activeStreams.keys.toList(),
    };
  }

  // Private helper methods

  String _processStreamChunk(String chunk, String sessionId) {
    try {
      // Handle Server-Sent Events format
      final lines = chunk.split('\n');
      final processedContent = StringBuffer();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data.trim() == '[DONE]') {
            break;
          }

          try {
            final jsonData = jsonDecode(data);
            final candidates = jsonData['candidates'] as List?;

            if (candidates != null && candidates.isNotEmpty) {
              final candidate = candidates[0];
              final content = candidate['content'];
              final parts = content?['parts'] as List?;

              if (parts != null && parts.isNotEmpty) {
                final text = parts[0]['text'] as String?;
                if (text != null) {
                  processedContent.write(text);
                  _partialResponses[sessionId]?.write(text);
                }
              }
            }
          } catch (e) {
            // Skip invalid JSON chunks
            continue;
          }
        }
      }

      return processedContent.toString();
    } catch (e) {
      print('Error processing stream chunk: $e');
      return '';
    }
  }

  Stream<String> _simulateStreaming(
    String fullText,
    String sessionId, {
    int chunkSize = 50,
    Duration delay = const Duration(milliseconds: 100),
  }) async* {
    if (fullText.isEmpty) return;

    _partialResponses[sessionId] = StringBuffer();

    // Split text into words for more natural streaming
    final words = fullText.split(' ');
    final buffer = StringBuffer();

    for (int i = 0; i < words.length; i++) {
      buffer.write(words[i]);
      if (i < words.length - 1) buffer.write(' ');

      // Emit chunk when we reach chunk size or end of text
      if ((i + 1) % chunkSize == 0 || i == words.length - 1) {
        final chunk = buffer.toString();
        _partialResponses[sessionId]?.write(chunk);
        yield chunk;
        buffer.clear();

        if (i < words.length - 1) {
          await Future.delayed(delay);
        }
      }
    }
  }
}

/// Streaming event types for enhanced UI feedback
class StreamingEvent {
  final String sessionId;
  final StreamingEventType type;
  final String content;
  final String? fullContent;
  final String? error;

  const StreamingEvent._({
    required this.sessionId,
    required this.type,
    this.content = '',
    this.fullContent,
    this.error,
  });

  factory StreamingEvent.typing(String sessionId) =>
      StreamingEvent._(sessionId: sessionId, type: StreamingEventType.typing);

  factory StreamingEvent.startContent(String sessionId) => StreamingEvent._(
    sessionId: sessionId,
    type: StreamingEventType.startContent,
  );

  factory StreamingEvent.content(
    String sessionId,
    String chunk,
    String fullContent,
  ) => StreamingEvent._(
    sessionId: sessionId,
    type: StreamingEventType.content,
    content: chunk,
    fullContent: fullContent,
  );

  factory StreamingEvent.complete(String sessionId, String fullContent) =>
      StreamingEvent._(
        sessionId: sessionId,
        type: StreamingEventType.complete,
        fullContent: fullContent,
      );

  factory StreamingEvent.error(String sessionId, String error) =>
      StreamingEvent._(
        sessionId: sessionId,
        type: StreamingEventType.error,
        error: error,
      );

  bool get isTyping => type == StreamingEventType.typing;
  bool get isContent => type == StreamingEventType.content;
  bool get isComplete => type == StreamingEventType.complete;
  bool get isError => type == StreamingEventType.error;
}

enum StreamingEventType { typing, startContent, content, complete, error }
