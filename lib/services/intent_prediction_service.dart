import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/conversation_context.dart';
import '../models/message.dart';
import 'persistent_memory_service.dart';

/// Advanced intent prediction service that anticipates user needs
/// Implements machine learning-like pattern recognition for proactive assistance
class IntentPredictionService {
  static IntentPredictionService? _instance;
  late PersistentMemoryService _memoryService;
  String? _currentUserId;

  // Intent prediction weights for different factors
  static const double _recentPatternWeight = 0.4;
  static const double _sessionContextWeight = 0.3;
  static const double _behaviorHistoryWeight = 0.2;
  static const double _timeContextWeight = 0.1;

  IntentPredictionService._();

  static IntentPredictionService get instance {
    _instance ??= IntentPredictionService._();
    return _instance!;
  }

  /// Initialize intent prediction service
  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      _memoryService = PersistentMemoryService.instance;

      if (kDebugMode) {
        print('Intent Prediction Service initialized for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Intent Prediction Service: $e');
      }
    }
  }

  /// Predict user intent based on conversation context and history
  Future<UserIntent> predictUserIntent({
    required String messageContent,
    required String sessionId,
    List<Message> conversationHistory = const [],
    ConversationContext? currentContext,
  }) async {
    if (_currentUserId == null) {
      return _createDefaultIntent(messageContent);
    }

    try {
      // Analyze the message content for intent signals
      final contentAnalysis = _analyzeMessageContent(messageContent);

      // Get recent intent patterns
      final recentIntents = await _memoryService.getRecentIntents(
        _currentUserId!,
        limit: 20,
      );

      // Analyze conversation context
      final contextAnalysis = _analyzeConversationContext(
        conversationHistory,
        currentContext,
      );

      // Get behavior patterns
      final behaviorPatterns = await _getBehaviorPatterns();

      // Calculate intent probabilities
      final intentProbabilities = _calculateIntentProbabilities(
        contentAnalysis: contentAnalysis,
        recentIntents: recentIntents,
        contextAnalysis: contextAnalysis,
        behaviorPatterns: behaviorPatterns,
        currentContext: currentContext,
      );

      // Select the most likely intent
      final predictedIntent = _selectBestIntent(
        intentProbabilities,
        messageContent,
      );

      // Store the predicted intent for learning
      await _memoryService.storeUserIntent(
        predictedIntent,
        _currentUserId!,
        sessionId,
      );

      if (kDebugMode) {
        print(
          'Predicted intent: ${predictedIntent.type.displayName} (${(predictedIntent.confidence * 100).toStringAsFixed(1)}%)',
        );
      }

      return predictedIntent;
    } catch (e) {
      if (kDebugMode) {
        print('Error predicting user intent: $e');
      }
      return _createDefaultIntent(messageContent);
    }
  }

  /// Analyze message content for intent signals
  Map<IntentType, double> _analyzeMessageContent(String content) {
    final Map<IntentType, double> scores = {};
    final lowercaseContent = content.toLowerCase();

    // Initialize all intent types with base score
    for (final intentType in IntentType.values) {
      scores[intentType] = 0.0;
    }

    // Analyze keywords and patterns
    for (final intentType in IntentType.values) {
      double score = 0.0;
      final keywords = intentType.typicalKeywords;

      for (final keyword in keywords) {
        if (lowercaseContent.contains(keyword.toLowerCase())) {
          score += 1.0;
        }
      }

      // Normalize by number of keywords
      if (keywords.isNotEmpty) {
        score = score / keywords.length;
      }

      scores[intentType] = score;
    }

    // Special pattern detection
    if (content.contains('?')) {
      scores[IntentType.questionAnswering] =
          (scores[IntentType.questionAnswering] ?? 0.0) + 0.5;
    }

    if (content.contains('!') || content.toUpperCase() == content) {
      scores[IntentType.troubleshooting] =
          (scores[IntentType.troubleshooting] ?? 0.0) + 0.3;
    }

    if (content.length > 200) {
      scores[IntentType.problemSolving] =
          (scores[IntentType.problemSolving] ?? 0.0) + 0.2;
    }

    // Check for continuation words
    final continuationWords = [
      'also',
      'and',
      'furthermore',
      'moreover',
      'additionally',
    ];
    for (final word in continuationWords) {
      if (lowercaseContent.contains(word)) {
        scores[IntentType.continuation] =
            (scores[IntentType.continuation] ?? 0.0) + 0.3;
        break;
      }
    }

    return scores;
  }

  /// Analyze conversation context for intent prediction
  Map<IntentType, double> _analyzeConversationContext(
    List<Message> conversationHistory,
    ConversationContext? currentContext,
  ) {
    final Map<IntentType, double> scores = {};

    // Initialize scores
    for (final intentType in IntentType.values) {
      scores[intentType] = 0.0;
    }

    if (conversationHistory.isEmpty) return scores;

    // Analyze recent messages for patterns
    final recentMessages = conversationHistory.length > 5
        ? conversationHistory.sublist(conversationHistory.length - 5)
        : conversationHistory;

    // Check for topic continuity
    final hasImages = recentMessages.any((msg) => msg.imagePaths.isNotEmpty);
    if (hasImages) {
      scores[IntentType.imageAnalysis] = 0.4;
    }

    // Check for problem-solving sequences
    final hasProblemKeywords = recentMessages.any(
      (msg) =>
          msg.content.toLowerCase().contains('error') ||
          msg.content.toLowerCase().contains('issue') ||
          msg.content.toLowerCase().contains('problem'),
    );
    if (hasProblemKeywords) {
      scores[IntentType.troubleshooting] = 0.3;
      scores[IntentType.problemSolving] = 0.3;
    }

    // Check for learning sequences
    final hasLearningKeywords = recentMessages.any(
      (msg) =>
          msg.content.toLowerCase().contains('learn') ||
          msg.content.toLowerCase().contains('understand') ||
          msg.content.toLowerCase().contains('explain'),
    );
    if (hasLearningKeywords) {
      scores[IntentType.learning] = 0.3;
    }

    // Analyze current context
    if (currentContext != null) {
      // Check active topics
      for (final topic in currentContext.activeTopics) {
        if (topic.toLowerCase().contains('image') ||
            topic.toLowerCase().contains('photo')) {
          scores[IntentType.imageAnalysis] =
              (scores[IntentType.imageAnalysis] ?? 0.0) + 0.2;
        }
        if (topic.toLowerCase().contains('problem') ||
            topic.toLowerCase().contains('issue')) {
          scores[IntentType.problemSolving] =
              (scores[IntentType.problemSolving] ?? 0.0) + 0.2;
        }
      }

      // Check continuity score
      if (currentContext.contextContinuityScore > 0.7) {
        scores[IntentType.continuation] = 0.4;
      }
    }

    return scores;
  }

  /// Get behavior patterns for intent prediction
  Future<Map<IntentType, double>> _getBehaviorPatterns() async {
    final Map<IntentType, double> scores = {};

    // Initialize scores
    for (final intentType in IntentType.values) {
      scores[intentType] = 0.0;
    }

    try {
      // Get topic memory to understand preferences
      final topicMemory = await _memoryService.getTopicMemory(
        _currentUserId!,
        limit: 10,
      );

      for (final topic in topicMemory) {
        final topicName = topic['topic_name'] as String;
        final interestScore = topic['interest_score'] as double;

        // Map topics to intents
        if (topicName.toLowerCase().contains('image') ||
            topicName.toLowerCase().contains('photo')) {
          scores[IntentType.imageAnalysis] =
              (scores[IntentType.imageAnalysis] ?? 0.0) + (interestScore * 0.3);
        }
        if (topicName.toLowerCase().contains('problem') ||
            topicName.toLowerCase().contains('debug')) {
          scores[IntentType.problemSolving] =
              (scores[IntentType.problemSolving] ?? 0.0) +
              (interestScore * 0.3);
        }
        if (topicName.toLowerCase().contains('learn') ||
            topicName.toLowerCase().contains('tutorial')) {
          scores[IntentType.learning] =
              (scores[IntentType.learning] ?? 0.0) + (interestScore * 0.3);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting behavior patterns: $e');
      }
    }

    return scores;
  }

  /// Calculate weighted intent probabilities
  Map<IntentType, double> _calculateIntentProbabilities({
    required Map<IntentType, double> contentAnalysis,
    required List<UserIntent> recentIntents,
    required Map<IntentType, double> contextAnalysis,
    required Map<IntentType, double> behaviorPatterns,
    ConversationContext? currentContext,
  }) {
    final Map<IntentType, double> probabilities = {};

    // Initialize probabilities
    for (final intentType in IntentType.values) {
      probabilities[intentType] = 0.0;
    }

    // Calculate recent pattern scores
    final Map<IntentType, double> recentPatternScores = {};
    if (recentIntents.isNotEmpty) {
      final intentCounts = <IntentType, int>{};
      for (final intent in recentIntents) {
        intentCounts[intent.type] = (intentCounts[intent.type] ?? 0) + 1;
      }

      for (final entry in intentCounts.entries) {
        recentPatternScores[entry.key] = entry.value / recentIntents.length;
      }
    }

    // Time context scoring
    final Map<IntentType, double> timeContextScores =
        _calculateTimeContextScores(currentContext);

    // Combine all scores with weights
    for (final intentType in IntentType.values) {
      final contentScore = contentAnalysis[intentType] ?? 0.0;
      final recentScore = recentPatternScores[intentType] ?? 0.0;
      final contextScore = contextAnalysis[intentType] ?? 0.0;
      final behaviorScore = behaviorPatterns[intentType] ?? 0.0;
      final timeScore = timeContextScores[intentType] ?? 0.0;

      probabilities[intentType] =
          (contentScore * _recentPatternWeight +
                  recentScore * _sessionContextWeight +
                  contextScore * _behaviorHistoryWeight +
                  behaviorScore * _behaviorHistoryWeight +
                  timeScore * _timeContextWeight)
              .clamp(0.0, 1.0);
    }

    return probabilities;
  }

  /// Calculate time-based context scores
  Map<IntentType, double> _calculateTimeContextScores(
    ConversationContext? currentContext,
  ) {
    final Map<IntentType, double> scores = {};

    // Initialize scores
    for (final intentType in IntentType.values) {
      scores[intentType] = 0.0;
    }

    if (currentContext == null) return scores;

    final timeOfDay = currentContext.environmentalContext.timeOfDay;
    final currentActivity = currentContext.environmentalContext.currentActivity;

    // Time-based preferences
    switch (timeOfDay) {
      case 'morning':
        scores[IntentType.learning] = 0.3;
        scores[IntentType.planning] = 0.3;
        break;
      case 'afternoon':
        scores[IntentType.problemSolving] = 0.3;
        scores[IntentType.imageAnalysis] = 0.2;
        break;
      case 'evening':
        scores[IntentType.exploration] = 0.2;
        scores[IntentType.learning] = 0.2;
        break;
      case 'night':
        scores[IntentType.troubleshooting] = 0.3;
        break;
    }

    // Activity-based preferences
    switch (currentActivity) {
      case 'work_hours':
        scores[IntentType.problemSolving] = 0.4;
        scores[IntentType.troubleshooting] = 0.3;
        break;
      case 'leisure_morning':
      case 'leisure_afternoon':
        scores[IntentType.exploration] = 0.3;
        scores[IntentType.creative] = 0.2;
        break;
      case 'continuation':
        scores[IntentType.continuation] = 0.5;
        break;
    }

    return scores;
  }

  /// Select the best intent from probabilities
  UserIntent _selectBestIntent(
    Map<IntentType, double> probabilities,
    String messageContent,
  ) {
    // Find the intent with highest probability
    IntentType bestIntent = IntentType.assistance;
    double bestScore = 0.0;

    for (final entry in probabilities.entries) {
      if (entry.value > bestScore) {
        bestScore = entry.value;
        bestIntent = entry.key;
      }
    }

    // Get alternative intents (top 3)
    final sortedIntents = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final alternativeIntents = sortedIntents
        .skip(1)
        .take(3)
        .where((entry) => entry.value > 0.1)
        .map((entry) => entry.key)
        .toList();

    // Ensure minimum confidence
    final confidence = max(bestScore, 0.3);

    return UserIntent(
      id: 'intent_${DateTime.now().millisecondsSinceEpoch}',
      type: bestIntent,
      confidence: confidence,
      description: bestIntent.description,
      parameters: _extractParameters(messageContent, bestIntent),
      context: {
        'message_content': messageContent,
        'prediction_confidence': confidence,
        'alternative_intents': alternativeIntents.map((i) => i.name).toList(),
        'content_length': messageContent.length,
        'has_question': messageContent.contains('?'),
        'has_exclamation': messageContent.contains('!'),
      },
      inferredAt: DateTime.now(),
      alternativeIntents: alternativeIntents,
    );
  }

  /// Extract parameters from message content based on intent
  List<String> _extractParameters(String content, IntentType intentType) {
    final parameters = <String>[];

    switch (intentType) {
      case IntentType.imageAnalysis:
        if (content.toLowerCase().contains('analyze'))
          parameters.add('analysis_requested');
        if (content.toLowerCase().contains('describe'))
          parameters.add('description_requested');
        if (content.toLowerCase().contains('identify'))
          parameters.add('identification_requested');
        break;

      case IntentType.questionAnswering:
        if (content.startsWith('what')) parameters.add('what_question');
        if (content.startsWith('how')) parameters.add('how_question');
        if (content.startsWith('why')) parameters.add('why_question');
        if (content.startsWith('when')) parameters.add('when_question');
        if (content.startsWith('where')) parameters.add('where_question');
        break;

      case IntentType.problemSolving:
        if (content.toLowerCase().contains('error'))
          parameters.add('error_mentioned');
        if (content.toLowerCase().contains('fix'))
          parameters.add('fix_requested');
        if (content.toLowerCase().contains('solve'))
          parameters.add('solution_requested');
        break;

      case IntentType.learning:
        if (content.toLowerCase().contains('learn'))
          parameters.add('learning_requested');
        if (content.toLowerCase().contains('explain'))
          parameters.add('explanation_requested');
        if (content.toLowerCase().contains('understand'))
          parameters.add('understanding_requested');
        break;

      case IntentType.comparison:
        if (content.toLowerCase().contains('vs') ||
            content.toLowerCase().contains('versus')) {
          parameters.add('comparison_requested');
        }
        if (content.toLowerCase().contains('better'))
          parameters.add('preference_requested');
        break;

      default:
        // Extract general parameters
        if (content.length > 100) parameters.add('detailed_content');
        if (content.contains('?')) parameters.add('question_format');
        if (content.contains('!')) parameters.add('urgent_tone');
    }

    return parameters;
  }

  /// Create default intent when prediction fails
  UserIntent _createDefaultIntent(String messageContent) {
    IntentType defaultType = IntentType.assistance;

    // Simple heuristics for fallback
    if (messageContent.contains('?')) {
      defaultType = IntentType.questionAnswering;
    } else if (messageContent.toLowerCase().contains('image') ||
        messageContent.toLowerCase().contains('photo')) {
      defaultType = IntentType.imageAnalysis;
    } else if (messageContent.toLowerCase().contains('help') ||
        messageContent.toLowerCase().contains('assist')) {
      defaultType = IntentType.assistance;
    }

    return UserIntent(
      id: 'intent_default_${DateTime.now().millisecondsSinceEpoch}',
      type: defaultType,
      confidence: 0.5,
      description: defaultType.description,
      parameters: _extractParameters(messageContent, defaultType),
      context: {'message_content': messageContent, 'fallback_prediction': true},
      inferredAt: DateTime.now(),
      alternativeIntents: [],
    );
  }

  /// Predict next likely action based on current conversation
  Future<List<Map<String, dynamic>>> predictNextActions({
    required String sessionId,
    required List<Message> conversationHistory,
    ConversationContext? currentContext,
  }) async {
    if (_currentUserId == null) return [];

    try {
      final recentIntents = await _memoryService.getRecentIntents(
        _currentUserId!,
        limit: 10,
      );
      final predictions = <Map<String, dynamic>>[];

      // Analyze conversation patterns
      if (conversationHistory.isNotEmpty) {
        final lastMessage = conversationHistory.last;

        // Predict follow-up questions
        if (lastMessage.type == MessageType.ai) {
          predictions.add({
            'action': 'follow_up_question',
            'description': 'User might ask a follow-up question',
            'probability': 0.7,
            'suggested_response':
                'Would you like me to explain anything further?',
          });
        }

        // Predict image upload
        if (lastMessage.content.toLowerCase().contains('image') &&
            lastMessage.imagePaths.isEmpty) {
          predictions.add({
            'action': 'image_upload',
            'description': 'User might upload an image for analysis',
            'probability': 0.6,
            'suggested_response':
                'Feel free to upload an image if you\'d like me to analyze it.',
          });
        }

        // Predict continuation
        if (recentIntents.isNotEmpty &&
            recentIntents.first.type == IntentType.learning) {
          predictions.add({
            'action': 'continue_learning',
            'description': 'User might want to learn more about the topic',
            'probability': 0.5,
            'suggested_response':
                'Would you like to explore this topic further?',
          });
        }
      }

      // Time-based predictions
      if (currentContext != null) {
        final timeOfDay = currentContext.environmentalContext.timeOfDay;
        if (timeOfDay == 'evening' || timeOfDay == 'night') {
          predictions.add({
            'action': 'session_wrap_up',
            'description': 'User might be finishing their session',
            'probability': 0.4,
            'suggested_response':
                'Is there anything else I can help you with today?',
          });
        }
      }

      // Sort by probability
      predictions.sort(
        (a, b) =>
            (b['probability'] as double).compareTo(a['probability'] as double),
      );

      return predictions.take(3).toList(); // Return top 3 predictions
    } catch (e) {
      if (kDebugMode) {
        print('Error predicting next actions: $e');
      }
      return [];
    }
  }

  /// Get intent prediction confidence for current conversation
  Future<double> getIntentPredictionConfidence(String sessionId) async {
    if (_currentUserId == null) return 0.5;

    try {
      final recentIntents = await _memoryService.getRecentIntents(
        _currentUserId!,
        limit: 5,
      );
      if (recentIntents.isEmpty) return 0.5;

      // Calculate average confidence of recent predictions
      final totalConfidence = recentIntents.fold(
        0.0,
        (sum, intent) => sum + intent.confidence,
      );
      return totalConfidence / recentIntents.length;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting intent prediction confidence: $e');
      }
      return 0.5;
    }
  }

  /// Update intent prediction based on user feedback
  Future<void> updateIntentPredictionAccuracy({
    required String intentId,
    required bool wasAccurate,
    String? actualIntentType,
  }) async {
    if (_currentUserId == null) return;

    try {
      // Store feedback for learning improvement
      await _memoryService.storeContextMemory(
        userId: _currentUserId!,
        contextKey: 'intent_feedback_$intentId',
        contextValue: jsonEncode({
          'was_accurate': wasAccurate,
          'actual_intent': actualIntentType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
        contextType: 'intent_feedback',
        importanceScore: wasAccurate
            ? 0.8
            : 0.9, // Higher importance for incorrect predictions
      );

      if (kDebugMode) {
        print('Intent prediction feedback stored: $intentId -> $wasAccurate');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating intent prediction accuracy: $e');
      }
    }
  }
}
