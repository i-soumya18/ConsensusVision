import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emotional_state.dart';
import '../services/enhanced_emotional_memory_service.dart';
import '../services/enhanced_sentiment_analysis_service.dart';

/// Enhanced adaptive response service with advanced emotional intelligence
class EnhancedAdaptiveResponseService {
  static final EnhancedAdaptiveResponseService _instance =
      EnhancedAdaptiveResponseService._internal();
  factory EnhancedAdaptiveResponseService() => _instance;
  EnhancedAdaptiveResponseService._internal();

  final EnhancedEmotionalMemoryService _emotionalMemory =
      EnhancedEmotionalMemoryService();
  final EnhancedSentimentAnalysisService _sentimentAnalysis =
      EnhancedSentimentAnalysisService();

  bool _isInitialized = false;
  ResponseTone? _lastUsedTone;

  // Advanced response templates with emotional intelligence
  final Map<ResponseTone, Map<String, dynamic>> _responseTemplates = {
    ResponseTone.supportive: {
      'openings': [
        "I understand this can be frustrating.",
        "Let me help you work through this.",
        "I can see you're having difficulty with this.",
        "Don't worry, we'll figure this out together.",
      ],
      'language_style': 'empathetic',
      'formality': 'casual',
      'encouragement_level': 'high',
    },
    ResponseTone.celebratory: {
      'openings': [
        "That's fantastic!",
        "Excellent work!",
        "You've got it!",
        "Perfect! Well done!",
      ],
      'language_style': 'enthusiastic',
      'formality': 'casual',
      'encouragement_level': 'very_high',
    },
    ResponseTone.reassuring: {
      'openings': [
        "It's completely normal to feel this way.",
        "Take your time, there's no rush.",
        "This is a common concern.",
        "You're on the right track.",
      ],
      'language_style': 'calm',
      'formality': 'gentle',
      'encouragement_level': 'medium',
    },
    ResponseTone.patient: {
      'openings': [
        "Let me explain this step by step.",
        "No problem at all, let's break this down.",
        "I'm here to help, take your time.",
        "Let's go through this carefully.",
      ],
      'language_style': 'methodical',
      'formality': 'professional',
      'encouragement_level': 'medium',
    },
    ResponseTone.empathetic: {
      'openings': [
        "I can imagine how that feels.",
        "That sounds really challenging.",
        "I hear the concern in your message.",
        "Your feelings about this are completely valid.",
      ],
      'language_style': 'understanding',
      'formality': 'personal',
      'encouragement_level': 'high',
    },
    ResponseTone.encouraging: {
      'openings': [
        "You're making great progress!",
        "Keep going, you're doing well!",
        "You're closer than you think!",
        "I believe you can do this!",
      ],
      'language_style': 'motivational',
      'formality': 'casual',
      'encouragement_level': 'very_high',
    },
    ResponseTone.professional: {
      'openings': [
        "I'll help you with that.",
        "Here's what you need to do:",
        "Let me provide you with the information.",
        "I can assist you with this request.",
      ],
      'language_style': 'formal',
      'formality': 'professional',
      'encouragement_level': 'low',
    },
    ResponseTone.gentle: {
      'openings': [
        "Let's take this slowly.",
        "It's okay to feel overwhelmed.",
        "We can work through this gently.",
        "There's no pressure here.",
      ],
      'language_style': 'soft',
      'formality': 'personal',
      'encouragement_level': 'medium',
    },
    ResponseTone.enthusiastic: {
      'openings': [
        "This is exciting!",
        "I love helping with this!",
        "Great question!",
        "This is going to be fun!",
      ],
      'language_style': 'energetic',
      'formality': 'casual',
      'encouragement_level': 'very_high',
    },
    ResponseTone.casual: {
      'openings': ["Sure thing!", "No worries!", "Absolutely!", "Of course!"],
      'language_style': 'relaxed',
      'formality': 'informal',
      'encouragement_level': 'low',
    },
  };

  // Emotional context adjustments
  final Map<EmotionType, Map<String, String>> _emotionalAdjustments = {
    EmotionType.frustration: {
      'tone_modifier': 'extra_patient',
      'pace': 'slower',
      'validation': 'acknowledge_difficulty',
    },
    EmotionType.confusion: {
      'tone_modifier': 'clarifying',
      'pace': 'step_by_step',
      'validation': 'normalize_confusion',
    },
    EmotionType.anxiety: {
      'tone_modifier': 'calming',
      'pace': 'gentle',
      'validation': 'provide_reassurance',
    },
    EmotionType.excitement: {
      'tone_modifier': 'match_energy',
      'pace': 'maintain_momentum',
      'validation': 'celebrate_enthusiasm',
    },
    EmotionType.satisfaction: {
      'tone_modifier': 'celebratory',
      'pace': 'build_on_success',
      'validation': 'acknowledge_achievement',
    },
  };

  /// Initialize the enhanced adaptive response service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _emotionalMemory.initialize();
      await _sentimentAnalysis.initialize();
      _isInitialized = true;

      if (kDebugMode) {
        print('Enhanced Adaptive Response Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Enhanced Adaptive Response Service: $e');
      }
    }
  }

  /// Enhanced response adaptation with real-time sentiment analysis
  Future<String> adaptResponseEnhanced(
    String originalResponse,
    String userMessage,
    String sessionId, {
    Map<String, dynamic>? additionalContext,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Analyze user's emotional state with enhanced service
      final emotionalState = await _sentimentAnalysis.analyzeText(
        userMessage,
        context: 'session_$sessionId',
      );

      // Store emotional state in enhanced memory
      await _emotionalMemory.addEmotionalState(emotionalState, sessionId);

      // Get real-time emotional trend
      final realTimeTrend = _sentimentAnalysis.getRealTimeEmotionalTrend();

      // Determine optimal response tone with enhanced prediction
      final optimalTone = _emotionalMemory.predictOptimalResponseToneEnhanced(
        userMessage,
        sessionId,
        previousResponseTone: _lastUsedTone?.name,
      );

      // Apply advanced response adaptation
      final adaptedResponse = _adaptResponseWithAdvancedTone(
        originalResponse,
        optimalTone,
        emotionalState,
        realTimeTrend,
        additionalContext,
      );

      // Record effectiveness for learning
      await _recordResponseForLearning(optimalTone, emotionalState, sessionId);

      _lastUsedTone = optimalTone;

      if (kDebugMode) {
        print(
          'Enhanced adaptation: ${optimalTone.displayName} tone applied '
          'based on ${emotionalState.sentiment.displayName} sentiment '
          'with ${realTimeTrend['trend']} trend',
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

  /// Advanced response adaptation with comprehensive emotional intelligence
  String _adaptResponseWithAdvancedTone(
    String originalResponse,
    ResponseTone tone,
    EmotionalState userState,
    Map<String, dynamic> realTimeTrend,
    Map<String, dynamic>? additionalContext,
  ) {
    String adaptedResponse = originalResponse;

    // 1. Apply contextual opening
    final opening = _getAdvancedContextualOpening(
      tone,
      userState,
      realTimeTrend,
    );
    if (opening.isNotEmpty) {
      adaptedResponse = '$opening $adaptedResponse';
    }

    // 2. Adjust language style based on emotional state
    adaptedResponse = _adjustLanguageStyleAdvanced(
      adaptedResponse,
      tone,
      userState,
    );

    // 3. Apply emotional-specific modifications
    adaptedResponse = _applyEmotionalAdjustments(adaptedResponse, userState);

    // 4. Handle escalation patterns
    if (realTimeTrend['trend'] == 'escalating') {
      adaptedResponse = _applyDeEscalationTechniques(
        adaptedResponse,
        userState,
      );
    }

    // 5. Add appropriate closing with emotional intelligence
    final closing = _getAdvancedContextualClosing(
      tone,
      userState,
      realTimeTrend,
    );
    if (closing.isNotEmpty) {
      adaptedResponse = '$adaptedResponse $closing';
    }

    // 6. Apply real-time sentiment adjustments
    adaptedResponse = _applyRealTimeSentimentAdjustments(
      adaptedResponse,
      realTimeTrend,
    );

    return adaptedResponse;
  }

  /// Get advanced contextual opening with real-time awareness
  String _getAdvancedContextualOpening(
    ResponseTone tone,
    EmotionalState userState,
    Map<String, dynamic> realTimeTrend,
  ) {
    final template = _responseTemplates[tone];
    if (template == null) return '';

    final openings = template['openings'] as List<String>;

    // Select opening based on emotional state and trends
    if (realTimeTrend['trend'] == 'escalating' && userState.intensity > 0.7) {
      // High intensity escalation - use calming opening
      return _selectCalmingOpening(openings);
    } else if (userState.emotions.contains(EmotionType.frustration)) {
      // Frustrated user - use validating opening
      return _selectValidatingOpening(openings);
    } else if (userState.emotions.contains(EmotionType.satisfaction)) {
      // Satisfied user - use celebratory opening
      return _selectCelebratoryOpening(openings);
    }

    // Default selection based on tone
    return openings.isNotEmpty ? openings[0] : '';
  }

  /// Select calming opening for high-intensity situations
  String _selectCalmingOpening(List<String> openings) {
    final calmingPhrases = [
      "I understand this can be frustrating.",
      "Let's take this slowly.",
      "It's okay to feel overwhelmed.",
      "Take your time, there's no rush.",
    ];

    for (final phrase in calmingPhrases) {
      if (openings.contains(phrase)) return phrase;
    }

    return openings.isNotEmpty ? openings[0] : '';
  }

  /// Select validating opening for frustrated users
  String _selectValidatingOpening(List<String> openings) {
    final validatingPhrases = [
      "I understand this can be frustrating.",
      "I can see you're having difficulty with this.",
      "That sounds really challenging.",
      "Your feelings about this are completely valid.",
    ];

    for (final phrase in validatingPhrases) {
      if (openings.contains(phrase)) return phrase;
    }

    return openings.isNotEmpty ? openings[0] : '';
  }

  /// Select celebratory opening for satisfied users
  String _selectCelebratoryOpening(List<String> openings) {
    final celebratoryPhrases = [
      "That's fantastic!",
      "Excellent work!",
      "You've got it!",
      "Perfect! Well done!",
    ];

    for (final phrase in celebratoryPhrases) {
      if (openings.contains(phrase)) return phrase;
    }

    return openings.isNotEmpty ? openings[0] : '';
  }

  /// Advanced language style adjustment
  String _adjustLanguageStyleAdvanced(
    String response,
    ResponseTone tone,
    EmotionalState userState,
  ) {
    final template = _responseTemplates[tone];
    if (template == null) return response;

    final languageStyle = template['language_style'] as String;
    final formality = template['formality'] as String;

    // Adjust based on emotional intensity
    if (userState.intensity > 0.8) {
      // High intensity - use simpler, clearer language
      response = _simplifyLanguage(response);
    }

    // Adjust based on specific emotions
    if (userState.emotions.contains(EmotionType.confusion)) {
      response = _addClarifyingElements(response);
    } else if (userState.emotions.contains(EmotionType.anxiety)) {
      response = _addReassuranceElements(response);
    }

    // Apply formality adjustments
    response = _adjustFormality(response, formality, userState);

    return response;
  }

  /// Simplify language for high-intensity emotional states
  String _simplifyLanguage(String response) {
    // Replace complex words with simpler alternatives
    final simplifications = {
      'utilize': 'use',
      'implement': 'do',
      'consequently': 'so',
      'nevertheless': 'but',
      'furthermore': 'also',
    };

    String simplified = response;
    simplifications.forEach((complex, simple) {
      simplified = simplified.replaceAll(
        RegExp(complex, caseSensitive: false),
        simple,
      );
    });

    return simplified;
  }

  /// Add clarifying elements for confused users
  String _addClarifyingElements(String response) {
    // Add clarifying phrases
    final clarifyingPhrases = [
      'In other words,',
      'To put it simply,',
      'What this means is',
      'Let me break this down:',
    ];

    // Insert clarifying phrase if response doesn't already have one
    if (!clarifyingPhrases.any(
      (phrase) => response.toLowerCase().contains(phrase.toLowerCase()),
    )) {
      return '${clarifyingPhrases[1]} $response';
    }

    return response;
  }

  /// Add reassurance elements for anxious users
  String _addReassuranceElements(String response) {
    // Add reassuring phrases
    final reassuringPhrases = [
      "Don't worry,",
      "This is completely normal.",
      "You're doing fine.",
      "There's no need to stress about this.",
    ];

    // Check if response needs reassurance
    if (!response.toLowerCase().contains('worry') &&
        !response.toLowerCase().contains('fine') &&
        !response.toLowerCase().contains('normal')) {
      return '${reassuringPhrases[0]} $response';
    }

    return response;
  }

  /// Adjust formality based on emotional state
  String _adjustFormality(
    String response,
    String formality,
    EmotionalState userState,
  ) {
    if (formality == 'casual' &&
        userState.emotions.contains(EmotionType.anxiety)) {
      // Anxious users might prefer slightly more formal, reassuring tone
      return response.replaceAll(
        RegExp(r"\b(gonna|wanna|gotta)\b"),
        'going to',
      );
    } else if (formality == 'professional' &&
        userState.emotions.contains(EmotionType.excitement)) {
      // Excited users might appreciate more casual enthusiasm
      return response
          .replaceAll('I will', "I'll")
          .replaceAll('you will', "you'll");
    }

    return response;
  }

  /// Apply emotional-specific adjustments
  String _applyEmotionalAdjustments(String response, EmotionalState userState) {
    for (final emotion in userState.emotions) {
      final adjustment = _emotionalAdjustments[emotion];
      if (adjustment != null) {
        response = _applySpecificAdjustment(response, adjustment, emotion);
      }
    }

    return response;
  }

  /// Apply specific emotional adjustment
  String _applySpecificAdjustment(
    String response,
    Map<String, String> adjustment,
    EmotionType emotion,
  ) {
    final toneModifier = adjustment['tone_modifier'] ?? '';
    final pace = adjustment['pace'] ?? '';
    final validation = adjustment['validation'] ?? '';

    // Apply tone modifier
    if (toneModifier == 'extra_patient') {
      response = _addPatientElements(response);
    } else if (toneModifier == 'calming') {
      response = _addCalmingElements(response);
    } else if (toneModifier == 'clarifying') {
      response = _addClarifyingElements(response);
    }

    // Apply pace adjustment
    if (pace == 'step_by_step') {
      response = _formatStepByStep(response);
    } else if (pace == 'slower') {
      response = _addPacingElements(response);
    }

    return response;
  }

  /// Add patient elements to response
  String _addPatientElements(String response) {
    if (!response.toLowerCase().contains('take your time') &&
        !response.toLowerCase().contains('no rush')) {
      return 'Take your time with this. $response';
    }
    return response;
  }

  /// Add calming elements to response
  String _addCalmingElements(String response) {
    if (!response.toLowerCase().contains('everything will be') &&
        !response.toLowerCase().contains('it\'s okay')) {
      return 'It\'s okay, $response';
    }
    return response;
  }

  /// Format response in step-by-step manner
  String _formatStepByStep(String response) {
    // If response contains steps, format them clearly
    if (response.contains('.') && response.split('.').length > 2) {
      final sentences = response.split('.');
      final formattedSteps = <String>[];

      for (int i = 0; i < sentences.length - 1; i++) {
        final sentence = sentences[i].trim();
        if (sentence.isNotEmpty) {
          formattedSteps.add('${i + 1}. $sentence.');
        }
      }

      return formattedSteps.join('\n');
    }

    return response;
  }

  /// Add pacing elements for slower delivery
  String _addPacingElements(String response) {
    // Add pauses and pacing phrases
    return response.replaceAll('. ', '. Let me continue - ');
  }

  /// Apply de-escalation techniques for escalating emotions
  String _applyDeEscalationTechniques(
    String response,
    EmotionalState userState,
  ) {
    // Add de-escalation opening
    final deEscalationOpening = "I can see this is really important to you. ";

    // Make response more collaborative
    String deEscalated = response.replaceAll(
      RegExp(r'\bYou need to\b'),
      'We can',
    );
    deEscalated = deEscalated.replaceAll(
      RegExp(r'\bYou should\b'),
      'You might want to',
    );
    deEscalated = deEscalated.replaceAll(
      RegExp(r'\bYou must\b'),
      'It would help to',
    );

    return '$deEscalationOpening$deEscalated';
  }

  /// Get advanced contextual closing
  String _getAdvancedContextualClosing(
    ResponseTone tone,
    EmotionalState userState,
    Map<String, dynamic> realTimeTrend,
  ) {
    // Different closings based on emotional state and trends
    if (userState.emotions.contains(EmotionType.frustration)) {
      return "I'm here to help if you need anything else.";
    } else if (userState.emotions.contains(EmotionType.satisfaction)) {
      return "Great job! Feel free to ask if you have more questions.";
    } else if (realTimeTrend['trend'] == 'escalating') {
      return "Take your time, and let me know how I can better assist you.";
    } else if (userState.emotions.contains(EmotionType.anxiety)) {
      return "Remember, there's no pressure. I'm here whenever you're ready.";
    }

    return "Let me know if you need any clarification!";
  }

  /// Apply real-time sentiment adjustments
  String _applyRealTimeSentimentAdjustments(
    String response,
    Map<String, dynamic> realTimeTrend,
  ) {
    final trend = realTimeTrend['trend'] as String;
    final confidence = realTimeTrend['confidence'] as double;

    if (trend == 'escalating' && confidence > 0.7) {
      // High confidence escalation - add more calming elements
      response = "Let's pause for a moment. $response";
    } else if (trend == 'calming' && confidence > 0.6) {
      // User is calming down - maintain supportive tone
      response = "$response I'm glad we're making progress together.";
    }

    return response;
  }

  /// Record response for machine learning
  Future<void> _recordResponseForLearning(
    ResponseTone tone,
    EmotionalState userState,
    String sessionId,
  ) async {
    // This will be used by the emotional memory service to learn effectiveness
    // The actual user reaction will be recorded when they respond next

    if (kDebugMode) {
      print(
        'Recorded response tone ${tone.displayName} for learning '
        'against ${userState.sentiment.displayName} sentiment',
      );
    }
  }

  /// Analyze response effectiveness (to be called after user responds)
  Future<void> analyzeResponseEffectiveness(
    ResponseTone usedTone,
    EmotionalState userReaction,
    String sessionId, {
    double? userSatisfactionScore,
  }) async {
    await _emotionalMemory.recordResponseEffectiveness(
      usedTone,
      userReaction,
      satisfactionScore: userSatisfactionScore,
    );

    if (kDebugMode) {
      print(
        'Analyzed effectiveness of ${usedTone.displayName} tone: '
        'User reacted with ${userReaction.sentiment.displayName} sentiment',
      );
    }
  }

  /// Get response adaptation insights
  Map<String, dynamic> getAdaptationInsights() {
    return {
      'last_used_tone': _lastUsedTone?.displayName,
      'available_tones': ResponseTone.values.map((t) => t.displayName).toList(),
      'emotional_adjustments_available': _emotionalAdjustments.keys
          .map((e) => e.displayName)
          .toList(),
      'service_initialized': _isInitialized,
    };
  }

  /// Predict optimal tone for given context (for testing/analysis)
  Future<ResponseTone> predictOptimalTone(
    String userMessage,
    String sessionId,
  ) async {
    if (!_isInitialized) await initialize();

    final emotionalState = await _sentimentAnalysis.analyzeText(userMessage);
    return _emotionalMemory.predictOptimalResponseToneEnhanced(
      userMessage,
      sessionId,
      previousResponseTone: _lastUsedTone?.name,
    );
  }
}
