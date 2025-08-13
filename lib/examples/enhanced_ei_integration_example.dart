import 'package:flutter/foundation.dart';
import '../models/emotional_state.dart';
import '../services/enhanced_emotional_intelligence_service.dart';

/// Example integration showing how to use enhanced emotional intelligence
/// in the existing chat provider
class ChatProviderWithEnhancedEI {
  final EnhancedEmotionalIntelligenceService _eiService =
      EnhancedEmotionalIntelligenceService();
  bool _emotionalIntelligenceEnabled = true;

  /// Initialize emotional intelligence
  Future<void> initializeEmotionalIntelligence() async {
    try {
      await _eiService.initialize();
      if (kDebugMode) {
        print('Enhanced Emotional Intelligence initialized for chat provider');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing emotional intelligence: $e');
      }
    }
  }

  /// Process user message with enhanced emotional intelligence
  Future<Map<String, dynamic>> processUserMessageWithEI(
    String userMessage,
    String sessionId,
  ) async {
    if (!_emotionalIntelligenceEnabled) {
      return {
        'processed_message': userMessage,
        'emotional_context': null,
        'recommended_tone': null,
      };
    }

    try {
      // Process with enhanced emotional intelligence
      final emotionalResult = await _eiService.processUserMessage(
        userMessage,
        sessionId,
        additionalContext: {
          'timestamp': DateTime.now().toIso8601String(),
          'message_length': userMessage.length,
        },
      );

      if (kDebugMode) {
        print('Enhanced EI Analysis:');
        print(
          '  Sentiment: ${emotionalResult.emotionalState?.sentiment.displayName}',
        );
        print(
          '  Emotions: ${emotionalResult.emotionalState?.emotions.map((e) => e.displayName).join(", ")}',
        );
        print(
          '  Intensity: ${emotionalResult.emotionalState?.intensity.toStringAsFixed(2)}',
        );
        print(
          '  Recommended Tone: ${emotionalResult.recommendedTone?.displayName}',
        );
        print('  Processing Time: ${emotionalResult.processingTimeMs}ms');
      }

      return {
        'processed_message': userMessage,
        'emotional_context': emotionalResult.enhancedContext,
        'emotional_state': emotionalResult.emotionalState,
        'recommended_tone': emotionalResult.recommendedTone,
        'real_time_trend': emotionalResult.realTimeTrend,
        'processing_time_ms': emotionalResult.processingTimeMs,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error in enhanced emotional processing: $e');
      }

      return {
        'processed_message': userMessage,
        'emotional_context': null,
        'recommended_tone': null,
        'error': e.toString(),
      };
    }
  }

  /// Adapt AI response using enhanced emotional intelligence
  Future<String> adaptAIResponseWithEI(
    String originalResponse,
    Map<String, dynamic> emotionalProcessingResult,
    String sessionId,
  ) async {
    if (!_emotionalIntelligenceEnabled ||
        emotionalProcessingResult['emotional_context'] == null) {
      return originalResponse;
    }

    try {
      // Create processing result for adaptation
      final processingResult = EmotionalProcessingResult(
        originalMessage: '', // Not needed for adaptation
        emotionalState:
            emotionalProcessingResult['emotional_state'] as EmotionalState?,
        enhancedContext:
            emotionalProcessingResult['emotional_context']
                as EnhancedEmotionalContext?,
        realTimeTrend:
            emotionalProcessingResult['real_time_trend']
                as Map<String, dynamic>? ??
            {},
        recommendedTone:
            emotionalProcessingResult['recommended_tone'] as ResponseTone?,
        processingTimeMs:
            emotionalProcessingResult['processing_time_ms'] as int? ?? 0,
        sessionId: sessionId,
        success: true,
      );

      // Adapt response with enhanced emotional intelligence
      final adaptedResponse = await _eiService.adaptAIResponse(
        originalResponse,
        processingResult,
        additionalContext: {
          'response_type': 'chat_message',
          'original_length': originalResponse.length,
        },
      );

      if (kDebugMode) {
        print('Response Adaptation:');
        print('  Original: "$originalResponse"');
        print('  Adapted: "$adaptedResponse"');
        print(
          '  Used Tone: ${processingResult.recommendedTone?.displayName ?? 'None'}',
        );
      }

      return adaptedResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error in enhanced response adaptation: $e');
      }
      return originalResponse; // Fallback to original
    }
  }

  /// Record user reaction for learning (call when user responds to AI)
  Future<void> recordUserReactionForLearning(
    String userReaction,
    ResponseTone? usedTone,
    String sessionId, {
    double? userSatisfactionScore,
  }) async {
    if (!_emotionalIntelligenceEnabled || usedTone == null) return;

    try {
      await _eiService.recordUserReaction(
        userReaction,
        usedTone,
        sessionId,
        userSatisfactionScore: userSatisfactionScore,
      );

      if (kDebugMode) {
        print('Recorded user reaction for learning: ${usedTone.displayName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error recording user reaction: $e');
      }
    }
  }

  /// Get emotional insights for display in UI
  Map<String, dynamic> getEmotionalInsights() {
    if (!_emotionalIntelligenceEnabled) {
      return {'enabled': false};
    }

    return _eiService.getComprehensiveEmotionalInsights();
  }

  /// Get real-time emotional trend for current session
  Future<Map<String, dynamic>> getCurrentEmotionalTrend() async {
    if (!_emotionalIntelligenceEnabled) {
      return {'trend': 'disabled'};
    }

    return await _eiService.getRealTimeEmotionalTrend();
  }

  /// Toggle emotional intelligence features
  void setEmotionalIntelligenceEnabled(bool enabled) {
    _emotionalIntelligenceEnabled = enabled;
    _eiService.setEnabled(enabled);

    if (kDebugMode) {
      print(
        'Enhanced Emotional Intelligence ${enabled ? 'enabled' : 'disabled'}',
      );
    }
  }

  /// Get emotional intelligence status
  bool get isEmotionalIntelligenceEnabled =>
      _emotionalIntelligenceEnabled && _eiService.isEnabled;

  /// Example of complete message processing flow
  Future<Map<String, dynamic>> processCompleteMessageFlow(
    String userMessage,
    String sessionId,
    String originalAIResponse,
  ) async {
    // 1. Process user message with emotional intelligence
    final emotionalProcessing = await processUserMessageWithEI(
      userMessage,
      sessionId,
    );

    // 2. Adapt AI response based on emotional context
    final adaptedResponse = await adaptAIResponseWithEI(
      originalAIResponse,
      emotionalProcessing,
      sessionId,
    );

    // 3. Get current emotional trend for UI display
    final emotionalTrend = await getCurrentEmotionalTrend();

    return {
      'user_message': userMessage,
      'original_ai_response': originalAIResponse,
      'adapted_ai_response': adaptedResponse,
      'emotional_processing': emotionalProcessing,
      'emotional_trend': emotionalTrend,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Export emotional data for user (GDPR compliance)
  Map<String, dynamic> exportUserEmotionalData() {
    return _eiService.exportEmotionalData();
  }

  /// Clear emotional memory for privacy
  Future<void> clearEmotionalMemory() async {
    await _eiService.clearEmotionalMemory();
  }
}

/// Example usage in a chat screen widget
class ChatScreenEIExample {
  final ChatProviderWithEnhancedEI _chatProvider = ChatProviderWithEnhancedEI();

  Future<void> initializeChat() async {
    await _chatProvider.initializeEmotionalIntelligence();
  }

  Future<void> handleUserMessage(String userMessage, String sessionId) async {
    // Process complete flow
    final result = await _chatProvider.processCompleteMessageFlow(
      userMessage,
      sessionId,
      "Here's how I can help you with that.", // Original AI response
    );

    // Display adapted response to user
    final adaptedResponse = result['adapted_ai_response'] as String;

    // Get emotional context for UI indicators
    final emotionalProcessing =
        result['emotional_processing'] as Map<String, dynamic>;
    final emotionalState =
        emotionalProcessing['emotional_state'] as EmotionalState?;
    final recommendedTone =
        emotionalProcessing['recommended_tone'] as ResponseTone?;

    // Update UI with emotional intelligence indicators
    if (emotionalState != null) {
      _showEmotionalIndicators(
        sentiment: emotionalState.sentiment,
        emotions: emotionalState.emotions,
        intensity: emotionalState.intensity,
        recommendedTone: recommendedTone,
      );
    }

    // Display the adapted response
    _displayAIMessage(adaptedResponse);
  }

  void _showEmotionalIndicators({
    required SentimentType sentiment,
    required List<EmotionType> emotions,
    required double intensity,
    ResponseTone? recommendedTone,
  }) {
    // Example UI indicators
    print('🎭 Emotional Intelligence Active');
    print('😊 Sentiment: ${sentiment.displayName}');
    print('💭 Emotions: ${emotions.map((e) => e.displayName).join(", ")}');
    print('⚡ Intensity: ${(intensity * 100).round()}%');
    if (recommendedTone != null) {
      print('🎯 AI Tone: ${recommendedTone.displayName}');
    }
  }

  void _displayAIMessage(String message) {
    print('🤖 AI: $message');
  }

  Future<void> handleUserReaction(
    String reaction,
    ResponseTone? usedTone,
    String sessionId,
  ) async {
    // Record for learning
    await _chatProvider.recordUserReactionForLearning(
      reaction,
      usedTone,
      sessionId,
      userSatisfactionScore: 0.8, // Could be from explicit feedback
    );
  }
}
