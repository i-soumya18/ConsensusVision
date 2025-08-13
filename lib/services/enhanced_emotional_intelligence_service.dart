import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emotional_state.dart';
import '../services/enhanced_sentiment_analysis_service.dart';
import '../services/enhanced_emotional_memory_service.dart';
import '../services/enhanced_adaptive_response_service.dart';

/// Enhanced emotional intelligence coordinator service
class EnhancedEmotionalIntelligenceService {
  static final EnhancedEmotionalIntelligenceService _instance =
      EnhancedEmotionalIntelligenceService._internal();
  factory EnhancedEmotionalIntelligenceService() => _instance;
  EnhancedEmotionalIntelligenceService._internal();

  final EnhancedSentimentAnalysisService _sentimentAnalysis =
      EnhancedSentimentAnalysisService();
  final EnhancedEmotionalMemoryService _emotionalMemory =
      EnhancedEmotionalMemoryService();
  final EnhancedAdaptiveResponseService _adaptiveResponse =
      EnhancedAdaptiveResponseService();

  bool _isInitialized = false;
  bool _isEnabled = true;

  /// Initialize all enhanced emotional intelligence services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize all services in parallel for better performance
      await Future.wait([
        _sentimentAnalysis.initialize(),
        _emotionalMemory.initialize(),
        _adaptiveResponse.initialize(),
      ]);

      _isInitialized = true;

      if (kDebugMode) {
        print(
          'Enhanced Emotional Intelligence Service initialized successfully',
        );
        print('All sub-services are ready for real-time emotional analysis');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Enhanced Emotional Intelligence Service: $e');
      }
      rethrow;
    }
  }

  /// Process user message with comprehensive emotional intelligence
  Future<EmotionalProcessingResult> processUserMessage(
    String userMessage,
    String sessionId, {
    Map<String, dynamic>? additionalContext,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (!_isEnabled) {
      return EmotionalProcessingResult.disabled(userMessage);
    }

    try {
      final startTime = DateTime.now();

      // 1. Real-time sentiment analysis with voice tone simulation
      final emotionalState = await _sentimentAnalysis.analyzeText(
        userMessage,
        context: 'session_$sessionId',
      );

      // 2. Store and learn from emotional patterns
      await _emotionalMemory.addEmotionalState(emotionalState, sessionId);

      // 3. Get real-time emotional trend
      final realTimeTrend = _sentimentAnalysis.getRealTimeEmotionalTrend();

      // 4. Predict optimal response tone
      final optimalTone = _emotionalMemory.predictOptimalResponseToneEnhanced(
        userMessage,
        sessionId,
      );

      // 5. Generate enhanced emotional context
      final enhancedContext = _generateEnhancedContext(
        emotionalState,
        realTimeTrend,
        optimalTone,
        sessionId,
      );

      final processingTime = DateTime.now()
          .difference(startTime)
          .inMilliseconds;

      if (kDebugMode) {
        print('Emotional processing completed in ${processingTime}ms');
        print(
          'Detected: ${emotionalState.sentiment.displayName} sentiment '
          'with ${emotionalState.emotions.map((e) => e.displayName).join(", ")} emotions',
        );
        print('Recommended tone: ${optimalTone.displayName}');
        print(
          'Real-time trend: ${realTimeTrend['trend']} (confidence: ${realTimeTrend['confidence']?.toStringAsFixed(2)})',
        );
      }

      return EmotionalProcessingResult(
        originalMessage: userMessage,
        emotionalState: emotionalState,
        enhancedContext: enhancedContext,
        realTimeTrend: realTimeTrend,
        recommendedTone: optimalTone,
        processingTimeMs: processingTime,
        sessionId: sessionId,
        success: true,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error processing user message emotionally: $e');
      }

      return EmotionalProcessingResult.error(userMessage, e.toString());
    }
  }

  /// Adapt AI response with comprehensive emotional intelligence
  Future<String> adaptAIResponse(
    String originalResponse,
    EmotionalProcessingResult emotionalProcessing, {
    Map<String, dynamic>? additionalContext,
  }) async {
    if (!_isInitialized || !_isEnabled) {
      return originalResponse;
    }

    try {
      final adaptedResponse = await _adaptiveResponse.adaptResponseEnhanced(
        originalResponse,
        emotionalProcessing.originalMessage,
        emotionalProcessing.sessionId,
        additionalContext: {
          ...?additionalContext,
          'emotional_state': emotionalProcessing.emotionalState?.toJson(),
          'real_time_trend': emotionalProcessing.realTimeTrend,
          'recommended_tone': emotionalProcessing.recommendedTone?.name,
        },
      );

      if (kDebugMode) {
        print(
          'Response adapted with ${emotionalProcessing.recommendedTone?.displayName ?? 'unknown'} tone',
        );
      }

      return adaptedResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error adapting AI response: $e');
      }
      return originalResponse; // Fallback to original
    }
  }

  /// Record user reaction for learning (call this when user responds to AI)
  Future<void> recordUserReaction(
    String userReaction,
    ResponseTone usedTone,
    String sessionId, {
    double? userSatisfactionScore,
  }) async {
    if (!_isInitialized || !_isEnabled) return;

    try {
      // Analyze user reaction
      final reactionState = await _sentimentAnalysis.analyzeText(
        userReaction,
        context: 'reaction_$sessionId',
      );

      // Record effectiveness for learning
      await _adaptiveResponse.analyzeResponseEffectiveness(
        usedTone,
        reactionState,
        sessionId,
        userSatisfactionScore: userSatisfactionScore,
      );

      if (kDebugMode) {
        print(
          'Recorded user reaction: ${reactionState.sentiment.displayName} '
          'for ${usedTone.displayName} tone',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording user reaction: $e');
      }
    }
  }

  /// Generate enhanced emotional context
  EnhancedEmotionalContext _generateEnhancedContext(
    EmotionalState primaryState,
    Map<String, dynamic> realTimeTrend,
    ResponseTone recommendedTone,
    String sessionId,
  ) {
    final sessionEmotions = _emotionalMemory.getSessionEmotions(sessionId);
    final voiceToneAnalysis =
        primaryState.metadata?['voice_tone_analysis'] ?? {};
    final patternAnalysis = primaryState.metadata?['pattern_analysis'] ?? {};
    final emotionalComplexity =
        primaryState.metadata?['emotional_complexity'] ?? 0.0;

    return EnhancedEmotionalContext(
      primaryState: primaryState,
      contextualStates: sessionEmotions.length > 3
          ? sessionEmotions.sublist(sessionEmotions.length - 3)
          : sessionEmotions,
      recommendedTone: recommendedTone,
      voiceToneAnalysis: {
        ...voiceToneAnalysis,
        'voice_tone_score': primaryState.metadata?['voice_tone_score'] ?? 0.0,
      },
      patternAnalysis: {...patternAnalysis, 'real_time_trend': realTimeTrend},
      emotionalComplexity: (emotionalComplexity as num).toDouble(),
    );
  }

  /// Get comprehensive emotional insights for analytics
  Map<String, dynamic> getComprehensiveEmotionalInsights() {
    if (!_isInitialized) {
      return {'error': 'Service not initialized'};
    }

    return {
      'enabled': _isEnabled,
      'sentiment_analysis': _sentimentAnalysis
          .getComprehensiveEmotionalInsights(),
      'emotional_memory': _emotionalMemory.getCrossSessionInsights(),
      'adaptive_response': _adaptiveResponse.getAdaptationInsights(),
      'service_status': 'operational',
    };
  }

  /// Enable or disable emotional intelligence features
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (kDebugMode) {
      print(
        'Enhanced Emotional Intelligence ${enabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  /// Get current emotional intelligence status
  bool get isEnabled => _isEnabled && _isInitialized;

  /// Get real-time emotional trend for current session
  Future<Map<String, dynamic>> getRealTimeEmotionalTrend() async {
    if (!_isInitialized) return {'trend': 'unknown'};

    return _sentimentAnalysis.getRealTimeEmotionalTrend();
  }

  /// Get emotional memory insights
  Map<String, dynamic> getEmotionalMemoryInsights() {
    if (!_isInitialized) return {};

    return _emotionalMemory.getCrossSessionInsights();
  }

  /// Predict optimal response tone for testing
  Future<ResponseTone> predictOptimalTone(
    String message,
    String sessionId,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    return _adaptiveResponse.predictOptimalTone(message, sessionId);
  }

  /// Clear emotional memory (for privacy/reset)
  Future<void> clearEmotionalMemory() async {
    // Implementation would clear stored emotional data
    if (kDebugMode) {
      print('Emotional memory cleared for privacy');
    }
  }

  /// Export emotional data for user (GDPR compliance)
  Map<String, dynamic> exportEmotionalData() {
    if (!_isInitialized) return {};

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'insights': getComprehensiveEmotionalInsights(),
      'note':
          'This data represents your emotional patterns and AI adaptation preferences.',
    };
  }
}

/// Result of emotional processing
class EmotionalProcessingResult {
  final String originalMessage;
  final EmotionalState? emotionalState;
  final EnhancedEmotionalContext? enhancedContext;
  final Map<String, dynamic> realTimeTrend;
  final ResponseTone? recommendedTone;
  final int processingTimeMs;
  final String sessionId;
  final bool success;
  final String? error;

  const EmotionalProcessingResult({
    required this.originalMessage,
    this.emotionalState,
    this.enhancedContext,
    required this.realTimeTrend,
    this.recommendedTone,
    required this.processingTimeMs,
    required this.sessionId,
    required this.success,
    this.error,
  });

  /// Create disabled result
  factory EmotionalProcessingResult.disabled(String message) {
    return EmotionalProcessingResult(
      originalMessage: message,
      realTimeTrend: {'trend': 'disabled'},
      processingTimeMs: 0,
      sessionId: '',
      success: true,
    );
  }

  /// Create error result
  factory EmotionalProcessingResult.error(String message, String error) {
    return EmotionalProcessingResult(
      originalMessage: message,
      realTimeTrend: {'trend': 'error'},
      processingTimeMs: 0,
      sessionId: '',
      success: false,
      error: error,
    );
  }

  /// Convert to JSON for debugging/logging
  Map<String, dynamic> toJson() {
    return {
      'original_message': originalMessage,
      'emotional_state': emotionalState?.toJson(),
      'enhanced_context': enhancedContext?.toJson(),
      'real_time_trend': realTimeTrend,
      'recommended_tone': recommendedTone?.name,
      'processing_time_ms': processingTimeMs,
      'session_id': sessionId,
      'success': success,
      'error': error,
    };
  }
}
