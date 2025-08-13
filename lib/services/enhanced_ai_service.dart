import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/ai_response.dart';
import '../services/config_service.dart';
import '../services/response_cache_service.dart';
import '../services/connection_pool_service.dart';
import '../services/streaming_response_service.dart';
import '../services/performance_monitoring_service.dart';
import '../services/gemini_service.dart';
import '../services/huggingface_service.dart';
import '../services/model_registry_service.dart';
import '../services/ai_service.dart';

/// Enhanced AI service with performance optimizations
/// Integrates caching, connection pooling, streaming, and monitoring for faster responses
class EnhancedAIService {
  static final EnhancedAIService _instance = EnhancedAIService._internal();
  factory EnhancedAIService() => _instance;
  EnhancedAIService._internal();

  final ConnectionPoolService _connectionPool = ConnectionPoolService();
  final StreamingResponseService _streamingService = StreamingResponseService();
  final PerformanceMonitoringService _performanceService =
      PerformanceMonitoringService();

  bool _isInitialized = false;
  Map<String, AIService>? _cachedServices;

  /// Initialize all performance enhancement services
  Future<void> init() async {
    if (_isInitialized) return;

    await Future.wait([
      ResponseCacheService.init(),
      _connectionPool.init(),
      _streamingService.init(),
      _performanceService.init(),
    ]);

    // Warm up connections to common API endpoints
    await _connectionPool.warmupConnections([
      'generativelanguage.googleapis.com',
      'api-inference.huggingface.co',
    ]);

    // Pre-warm cache with common queries
    await ResponseCacheService.warmCache([
      'What do you see in this image?',
      'Describe this image',
      'Analyze this picture',
      'What is the text in this image?',
      'Explain what\'s happening here',
    ]);

    _isInitialized = true;
  }

  /// Process query with all performance optimizations
  Future<AIResponse> processQuery({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
    bool enableCaching = true,
    bool enableStreaming = false,
    String? preferredModel,
    int priority = 5,
  }) async {
    await init();

    final sessionId = _performanceService.startSession(
      operation: 'ai_query',
      model: preferredModel,
      metadata: {
        'query_length': query.length,
        'has_images': images?.isNotEmpty ?? false,
        'has_extracted_text': extractedText?.isNotEmpty ?? false,
        'conversation_length': conversationHistory?.length ?? 0,
        'caching_enabled': enableCaching,
        'streaming_enabled': enableStreaming,
      },
    );

    try {
      // Try cache first if enabled
      if (enableCaching) {
        final cachedResponse = await ResponseCacheService.getCachedResponse(
          query: query,
          images: images,
          extractedText: extractedText,
        );

        if (cachedResponse != null) {
          await _performanceService.endSession(
            sessionId,
            success: true,
            additionalMetadata: {'source': 'cache'},
          );

          _performanceService.recordCacheHit(
            'ai_query',
            const Duration(milliseconds: 1500), // Estimated time saved
          );

          return cachedResponse;
        }
      }

      // Process with streaming if enabled
      if (enableStreaming) {
        return _processStreamingQuery(
          sessionId: sessionId,
          query: query,
          images: images,
          extractedText: extractedText,
          conversationHistory: conversationHistory,
          preferredModel: preferredModel,
          priority: priority,
        );
      }

      // Regular processing with optimizations
      return _processRegularQuery(
        sessionId: sessionId,
        query: query,
        images: images,
        extractedText: extractedText,
        conversationHistory: conversationHistory,
        preferredModel: preferredModel,
        enableCaching: enableCaching,
        priority: priority,
      );
    } catch (e) {
      await _performanceService.endSession(
        sessionId,
        success: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Process query with streaming response
  Stream<String> processStreamingQuery({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
    String? preferredModel,
    int priority = 5,
  }) async* {
    await init();

    final model = preferredModel ?? ConfigService.getSelectedModel();
    final service = await _getAIService(model);

    if (service is GeminiService) {
      // Use native Gemini streaming
      final requestBody = await _buildGeminiRequestBody(
        query: query,
        images: images,
        extractedText: extractedText,
        conversationHistory: conversationHistory,
      );

      yield* _streamingService.streamGeminiResponse(
        apiKey: ConfigService.getGeminiApiKey()!,
        requestBody: requestBody,
      );
    } else {
      // Use simulated streaming for other services
      yield* _streamingService.createStreamingWrapper(
        apiCall: () => service.processQuery(
          query: query,
          images: images,
          extractedText: extractedText,
          conversationHistory: conversationHistory,
        ),
      );
    }
  }

  /// Get enhanced AI service with connection pooling
  Future<AIService> getEnhancedAIService(String modelName) async {
    await init();

    _cachedServices ??= <String, AIService>{};

    if (_cachedServices!.containsKey(modelName)) {
      return _cachedServices![modelName]!;
    }

    final service = await _getAIService(modelName);

    // Enhance the service with connection pooling
    if (service is GeminiService) {
      _cachedServices![modelName] = EnhancedGeminiService(
        originalService: service,
        connectionPool: _connectionPool,
      );
    } else if (service is HuggingFaceService) {
      _cachedServices![modelName] = EnhancedHuggingFaceService(
        originalService: service,
        connectionPool: _connectionPool,
      );
    } else {
      _cachedServices![modelName] = service;
    }

    return _cachedServices![modelName]!;
  }

  /// Get performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    return {
      'cache': await ResponseCacheService.getCacheStatistics(),
      'connections': _connectionPool.getStatistics(),
      'streaming': _streamingService.getStreamingStats(),
      'monitoring': _performanceService.getCurrentStats(),
    };
  }

  /// Get performance trends
  Future<Map<String, dynamic>> getPerformanceTrends({
    Duration period = const Duration(hours: 24),
  }) async {
    final trends = await _performanceService.getPerformanceTrends(
      period: period,
    );
    final report = _performanceService.generateReport(period: period);

    return {
      'trends': trends,
      'report': report,
      'alerts': _performanceService.getActiveAlerts(),
    };
  }

  /// Clear all caches and reset connections
  Future<void> clearCachesAndReset() async {
    await Future.wait([
      ResponseCacheService.clearAllCache(),
      _connectionPool.clearConnections(),
      _streamingService.stopAllStreams(),
    ]);

    _cachedServices?.clear();
  }

  /// Dispose and cleanup
  Future<void> dispose() async {
    await Future.wait([
      _connectionPool.clearConnections(),
      _streamingService.stopAllStreams(),
      _performanceService.dispose(),
    ]);

    _isInitialized = false;
    _cachedServices?.clear();
  }

  // Private helper methods

  Future<AIResponse> _processStreamingQuery({
    required String sessionId,
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
    String? preferredModel,
    required int priority,
  }) async {
    final buffer = StringBuffer();

    await for (final chunk in processStreamingQuery(
      query: query,
      images: images,
      extractedText: extractedText,
      conversationHistory: conversationHistory,
      preferredModel: preferredModel,
      priority: priority,
    )) {
      buffer.write(chunk);
    }

    final response = AIResponse.success(
      content: buffer.toString(),
      model: preferredModel ?? 'Streaming',
      confidence: 0.85,
      metadata: {'streaming': true},
    );

    await _performanceService.endSession(
      sessionId,
      success: true,
      additionalMetadata: {'source': 'streaming'},
    );

    return response;
  }

  Future<AIResponse> _processRegularQuery({
    required String sessionId,
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
    String? preferredModel,
    required bool enableCaching,
    required int priority,
  }) async {
    final model = preferredModel ?? ConfigService.getSelectedModel();
    final service = await getEnhancedAIService(model);

    final response = await service.processQuery(
      query: query,
      images: images,
      extractedText: extractedText,
      conversationHistory: conversationHistory,
    );

    // Cache successful responses
    if (enableCaching && response.isSuccessful) {
      await ResponseCacheService.cacheResponse(
        query: query,
        response: response,
        images: images,
        extractedText: extractedText,
        highPriority: priority >= 8,
      );
    }

    await _performanceService.endSession(
      sessionId,
      success: response.isSuccessful,
      error: response.error,
      additionalMetadata: {
        'source': 'ai_service',
        'model': response.model,
        'confidence': response.confidence,
      },
    );

    return response;
  }

  Future<AIService> _getAIService(String modelName) async {
    final geminiKey = ConfigService.getGeminiApiKey();
    final huggingFaceKey = ConfigService.getHuggingFaceApiKey();

    if (modelName == 'Auto') {
      // For auto-selection, prefer Gemini if available, fallback to HuggingFace
      if (geminiKey != null) {
        return GeminiService(apiKey: geminiKey);
      } else if (huggingFaceKey != null) {
        return HuggingFaceService(apiKey: huggingFaceKey);
      } else {
        throw Exception('No API keys available');
      }
    }

    final service = ModelRegistryService.createServiceForModel(
      modelName,
      geminiApiKey: geminiKey,
      huggingFaceApiKey: huggingFaceKey,
    );

    if (service == null) {
      throw Exception('Unable to create service for model: $modelName');
    }

    return service;
  }

  Future<Map<String, dynamic>> _buildGeminiRequestBody({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    // Build Gemini-compatible request body
    final contents = <Map<String, dynamic>>[];

    // Add conversation history
    if (conversationHistory != null) {
      for (final entry in conversationHistory) {
        contents.add({
          'role': entry['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': entry['content']},
          ],
        });
      }
    }

    // Add current query
    final parts = <Map<String, dynamic>>[];

    String fullQuery = query;
    if (extractedText != null && extractedText.isNotEmpty) {
      fullQuery += '\n\nExtracted text: $extractedText';
    }

    parts.add({'text': fullQuery});

    // Add images if provided
    if (images != null) {
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final base64Data = base64Encode(bytes);
        parts.add({
          'inline_data': {'mime_type': 'image/jpeg', 'data': base64Data},
        });
      }
    }

    contents.add({'role': 'user', 'parts': parts});

    return {
      'contents': contents,
      'generationConfig': {
        'temperature': ConfigService.getTemperature(),
        'topK': ConfigService.getTopK(),
        'topP': ConfigService.getTopP(),
        'maxOutputTokens': ConfigService.getMaxTokens(),
      },
    };
  }
}

/// Enhanced Gemini service with connection pooling
class EnhancedGeminiService implements AIService {
  final GeminiService originalService;
  final ConnectionPoolService connectionPool;

  EnhancedGeminiService({
    required this.originalService,
    required this.connectionPool,
  });

  @override
  String get modelName => originalService.modelName;

  @override
  Future<bool> isAvailable() => originalService.isAvailable();

  @override
  Future<AIResponse> processQuery({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    // Use the original service for now - connection pooling integration
    // would require modifying the HTTP client usage in the original service
    return originalService.processQuery(
      query: query,
      images: images,
      extractedText: extractedText,
      conversationHistory: conversationHistory,
    );
  }
}

/// Enhanced HuggingFace service with connection pooling
class EnhancedHuggingFaceService implements AIService {
  final HuggingFaceService originalService;
  final ConnectionPoolService connectionPool;

  EnhancedHuggingFaceService({
    required this.originalService,
    required this.connectionPool,
  });

  @override
  String get modelName => originalService.modelName;

  @override
  Future<bool> isAvailable() => originalService.isAvailable();

  @override
  Future<AIResponse> processQuery({
    required String query,
    List<File>? images,
    String? extractedText,
    List<Map<String, dynamic>>? conversationHistory,
  }) async {
    // Use the original service for now - connection pooling integration
    // would require modifying the HTTP client usage in the original service
    return originalService.processQuery(
      query: query,
      images: images,
      extractedText: extractedText,
      conversationHistory: conversationHistory,
    );
  }
}
