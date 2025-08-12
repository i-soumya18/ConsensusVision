import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emotional_state.dart';
import '../services/emotional_memory_service.dart';
import '../services/sentiment_analysis_service.dart';

class AdaptiveResponseService {
  static final AdaptiveResponseService _instance =
      AdaptiveResponseService._internal();
  factory AdaptiveResponseService() => _instance;
  AdaptiveResponseService._internal();

  final EmotionalMemoryService _emotionalMemory = EmotionalMemoryService();
  final SentimentAnalysisService _sentimentAnalysis =
      SentimentAnalysisService();

  bool _isInitialized = false;

  /// Initialize the adaptive response service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _emotionalMemory.initialize();
      await _sentimentAnalysis.initialize();
      _isInitialized = true;

      if (kDebugMode) {
        print('Adaptive Response Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Adaptive Response Service: $e');
      }
    }
  }

  /// Adapt AI response based on user's emotional state
  Future<String> adaptResponse(
    String originalResponse,
    String userMessage,
    String sessionId,
  ) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Analyze user's emotional state
      final emotionalState = await _sentimentAnalysis.analyzeText(
        userMessage,
        context: 'session_$sessionId',
      );

      // Store emotional state
      await _emotionalMemory.addEmotionalState(emotionalState, sessionId);

      // Determine optimal response tone
      final optimalTone = _emotionalMemory.predictOptimalResponseTone(
        userMessage,
        sessionId,
      );

      // Adapt the response
      final adaptedResponse = _adaptResponseWithTone(
        originalResponse,
        optimalTone,
        emotionalState,
      );

      return adaptedResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Error adapting response: $e');
      }
      return originalResponse; // Fallback to original
    }
  }

  /// Adapt response with specific tone and emotional context
  String _adaptResponseWithTone(
    String originalResponse,
    ResponseTone tone,
    EmotionalState userState,
  ) {
    // Apply tone-specific modifications
    String adaptedResponse = originalResponse;

    // Add appropriate opening based on tone and emotional state
    final opening = _getContextualOpening(tone, userState);
    if (opening.isNotEmpty) {
      adaptedResponse = '$opening $adaptedResponse';
    }

    // Modify language intensity and style
    adaptedResponse = _adjustLanguageStyle(adaptedResponse, tone, userState);

    // Add appropriate closing/encouragement
    final closing = _getContextualClosing(tone, userState);
    if (closing.isNotEmpty) {
      adaptedResponse = '$adaptedResponse $closing';
    }

    return adaptedResponse.trim();
  }

  /// Get contextual opening based on emotional state
  String _getContextualOpening(ResponseTone tone, EmotionalState userState) {
    final hasNegativeEmotions = userState.emotions.any((e) => !e.isPositive);
    final intensity = userState.intensity;

    switch (tone) {
      case ResponseTone.supportive:
        if (hasNegativeEmotions && intensity > 0.7) {
          return "I understand this can be frustrating.";
        } else if (hasNegativeEmotions) {
          return "I'm here to help you work through this.";
        }
        return "Let me help you with that.";

      case ResponseTone.encouraging:
        if (userState.emotions.contains(EmotionType.confusion)) {
          return "You're asking great questions!";
        }
        return "You're on the right track!";

      case ResponseTone.celebratory:
        if (userState.emotions.any(
          (e) => [EmotionType.joy, EmotionType.satisfaction].contains(e),
        )) {
          return "Fantastic! 🎉";
        }
        return "Excellent work!";

      case ResponseTone.reassuring:
        if (hasNegativeEmotions) {
          return "Don't worry, this is completely normal.";
        }
        return "You're doing fine.";

      case ResponseTone.patient:
        if (userState.emotions.contains(EmotionType.frustration)) {
          return "Let's take this step by step.";
        }
        return "Let me explain this clearly.";

      case ResponseTone.empathetic:
        if (intensity > 0.6) {
          return "I can sense you're having a tough time with this.";
        }
        return "I understand how you're feeling.";

      default:
        return "";
    }
  }

  /// Adjust language style based on tone and emotional state
  String _adjustLanguageStyle(
    String response,
    ResponseTone tone,
    EmotionalState userState,
  ) {
    String adjusted = response;

    switch (tone) {
      case ResponseTone.supportive:
        // Make language more gentle and reassuring
        adjusted = adjusted.replaceAll(RegExp(r'\bshould\b'), 'might want to');
        adjusted = adjusted.replaceAll(RegExp(r'\bmust\b'), 'can');
        adjusted = adjusted.replaceAll(RegExp(r'\bwill\b'), 'should');
        break;

      case ResponseTone.encouraging:
        // Add positive reinforcement
        if (!adjusted.contains('great') && !adjusted.contains('excellent')) {
          adjusted = adjusted.replaceFirst('.', ' - great question!');
        }
        break;

      case ResponseTone.celebratory:
        // Add enthusiasm markers
        if (!adjusted.contains('!')) {
          adjusted = adjusted.replaceAll('.', '!');
        }
        break;

      case ResponseTone.patient:
        // Make explanations more detailed and gentle
        adjusted = adjusted.replaceAll(
          RegExp(r'\bQuickly,\b'),
          'Take your time, and',
        );
        adjusted = adjusted.replaceAll(RegExp(r'\bSimply\b'), 'Carefully');
        break;

      case ResponseTone.gentle:
        // Soften imperative language
        adjusted = adjusted.replaceAll(RegExp(r'\bDo\b'), 'You might try');
        adjusted = adjusted.replaceAll(RegExp(r'\bUse\b'), 'Consider using');
        break;

      default:
        break;
    }

    return adjusted;
  }

  /// Get contextual closing based on emotional state
  String _getContextualClosing(ResponseTone tone, EmotionalState userState) {
    final hasNegativeEmotions = userState.emotions.any((e) => !e.isPositive);

    switch (tone) {
      case ResponseTone.supportive:
        if (hasNegativeEmotions) {
          return "Feel free to ask if you need any clarification - I'm here to help! 😊";
        }
        return "Let me know if you need any help with this!";

      case ResponseTone.encouraging:
        return "Keep up the great work! You've got this! 💪";

      case ResponseTone.celebratory:
        return "Way to go! 🌟";

      case ResponseTone.reassuring:
        return "Take your time, and don't hesitate to ask questions.";

      case ResponseTone.patient:
        return "Remember, there's no rush - we can go through this as many times as you need.";

      case ResponseTone.empathetic:
        if (userState.intensity > 0.6) {
          return "I'm here to support you through this. 💙";
        }
        return "You're doing better than you think!";

      default:
        return "Is there anything else I can help you with?";
    }
  }

  /// Generate proactive emotional support messages
  String generateProactiveSupport(String sessionId) {
    final sessionEmotions = _emotionalMemory.getSessionEmotions(sessionId);
    final trend = _emotionalMemory.getRecentTrend();

    if (sessionEmotions.length >= 3) {
      final recentNegative = sessionEmotions
          .take(3)
          .where((e) => e.sentiment.score < 0)
          .length;

      if (recentNegative >= 2) {
        return "I notice you might be having some challenges. Would you like me to try explaining this differently or break it down into smaller steps? 🤗";
      }
    }

    if (trend == EmotionalTrend.declining) {
      return "Hey, just want to remind you that learning new things can be challenging, and that's completely normal! You're doing great by asking questions. 🌟";
    }

    return "";
  }

  /// Check if emotional intervention is needed
  bool shouldProvideEmotionalSupport(String sessionId) {
    final sessionEmotions = _emotionalMemory.getSessionEmotions(sessionId);

    if (sessionEmotions.length < 2) return false;

    // Check for sustained frustration
    final recentStates = sessionEmotions.take(3).toList();
    final frustrationCount = recentStates
        .where((state) => state.emotions.contains(EmotionType.frustration))
        .length;

    return frustrationCount >= 2;
  }

  /// Get emotional context summary for debugging/analytics
  Map<String, dynamic> getEmotionalContext(String sessionId) {
    final sessionEmotions = _emotionalMemory.getSessionEmotions(sessionId);
    final profile = _emotionalMemory.currentProfile;

    return {
      'session_emotion_count': sessionEmotions.length,
      'current_trend': _emotionalMemory.getRecentTrend().displayName,
      'dominant_emotions': _emotionalMemory.getDominantEmotions(),
      'needs_support': shouldProvideEmotionalSupport(sessionId),
      'average_intensity': profile?.averageIntensity ?? 0.0,
      'last_emotions': sessionEmotions.isNotEmpty
          ? sessionEmotions.last.emotions.map((e) => e.displayName).toList()
          : [],
    };
  }
}
