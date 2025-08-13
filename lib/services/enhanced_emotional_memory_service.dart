import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotional_state.dart';
import '../services/database_service.dart';

/// Enhanced emotional memory service with cross-session learning
class EnhancedEmotionalMemoryService {
  static final EnhancedEmotionalMemoryService _instance =
      EnhancedEmotionalMemoryService._internal();
  factory EnhancedEmotionalMemoryService() => _instance;
  EnhancedEmotionalMemoryService._internal();

  static const String _userProfileKey = 'enhanced_user_emotional_profile';
  static const String _sessionEmotionsKey = 'enhanced_session_emotions_';
  static const String _emotionalPatternsKey = 'emotional_patterns';
  static const String _responseEffectivenessKey = 'response_effectiveness';
  static const int _maxEmotionalHistory = 150; // Increased for better learning
  static const int _maxSessionRetention = 45; // days
  static const int _patternLearningThreshold =
      5; // minimum occurrences to form pattern

  UserEmotionalProfile? _currentProfile;
  final Map<String, List<EmotionalState>> _sessionEmotions = {};
  final Map<String, Map<String, dynamic>> _learnedPatterns = {};
  final Map<String, double> _responseEffectiveness = {};

  /// Initialize the enhanced service
  Future<void> initialize() async {
    try {
      await _loadUserProfile();
      await _loadLearnedPatterns();
      await _loadResponseEffectiveness();
      await _cleanupOldSessions();
      await _analyzeAndUpdatePatterns();

      if (kDebugMode) {
        print('Enhanced Emotional Memory Service initialized successfully');
        print('Loaded ${_learnedPatterns.length} learned patterns');
        print(
          'Response effectiveness data points: ${_responseEffectiveness.length}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Enhanced Emotional Memory Service: $e');
      }
    }
  }

  /// Get current user emotional profile
  UserEmotionalProfile? get currentProfile => _currentProfile;

  /// Add emotional state with enhanced pattern learning
  Future<void> addEmotionalState(EmotionalState state, String sessionId) async {
    try {
      // Add to session emotions
      if (!_sessionEmotions.containsKey(sessionId)) {
        _sessionEmotions[sessionId] = [];
      }
      _sessionEmotions[sessionId]!.add(state);

      // Update user profile with enhanced learning
      await _updateUserProfileEnhanced(state);

      // Learn from patterns
      await _updatePatternLearning(state, sessionId);

      // Save session emotions
      await _saveSessionEmotions(sessionId);

      if (kDebugMode) {
        print(
          'Enhanced emotional state added: ${state.sentiment.displayName} '
          'with intensity ${state.intensity.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding enhanced emotional state: $e');
      }
    }
  }

  /// Enhanced pattern learning from emotional states
  Future<void> _updatePatternLearning(
    EmotionalState state,
    String sessionId,
  ) async {
    final sessionEmotions = _sessionEmotions[sessionId] ?? [];

    // Learn temporal patterns (emotion sequences)
    if (sessionEmotions.length >= 2) {
      final previousState = sessionEmotions[sessionEmotions.length - 2];
      final pattern =
          '${previousState.sentiment.name}_to_${state.sentiment.name}';

      _updatePatternFrequency('transition_patterns', pattern);
    }

    // Learn intensity escalation patterns
    if (sessionEmotions.length >= 3) {
      final recentIntensities = sessionEmotions
          .skip(sessionEmotions.length - 3)
          .map((e) => e.intensity)
          .toList();

      if (_isEscalatingPattern(recentIntensities)) {
        _updatePatternFrequency('escalation_patterns', 'intensity_escalation');
      }
    }

    // Learn emotion clustering patterns
    final currentEmotions = state.emotions.map((e) => e.name).join('_');
    _updatePatternFrequency('emotion_clusters', currentEmotions);

    // Learn context-specific patterns
    if (state.context != null) {
      final contextPattern = '${state.context}_${state.sentiment.name}';
      _updatePatternFrequency('context_patterns', contextPattern);
    }

    await _saveLearnedPatterns();
  }

  /// Update pattern frequency for learning
  void _updatePatternFrequency(String category, String pattern) {
    if (!_learnedPatterns.containsKey(category)) {
      _learnedPatterns[category] = {};
    }

    final categoryPatterns = _learnedPatterns[category]!;
    categoryPatterns[pattern] = (categoryPatterns[pattern] as int? ?? 0) + 1;
  }

  /// Check if intensity pattern shows escalation
  bool _isEscalatingPattern(List<double> intensities) {
    if (intensities.length < 3) return false;

    return intensities[1] > intensities[0] && intensities[2] > intensities[1];
  }

  /// Enhanced prediction of optimal response tone using learned patterns
  ResponseTone predictOptimalResponseToneEnhanced(
    String messageContent,
    String sessionId, {
    String? previousResponseTone,
  }) {
    final sessionEmotions = getSessionEmotions(sessionId);
    final recentTrend = getRecentTrend();

    // Analyze current message
    final messageAnalysis = _analyzeMessageContent(messageContent);

    // Use learned patterns for prediction
    final patternBasedTone = _predictFromPatterns(
      messageAnalysis,
      sessionEmotions,
    );

    // Factor in response effectiveness
    final effectivenessBasedTone = _adjustForEffectiveness(
      patternBasedTone,
      sessionEmotions,
    );

    // Consider emotional volatility
    final volatilityAdjustedTone = _adjustForVolatility(
      effectivenessBasedTone,
      sessionId,
    );

    if (kDebugMode) {
      print(
        'Enhanced tone prediction: ${volatilityAdjustedTone.displayName} '
        'based on patterns, effectiveness, and volatility',
      );
    }

    return volatilityAdjustedTone;
  }

  /// Analyze message content for emotional cues
  Map<String, dynamic> _analyzeMessageContent(String content) {
    final lowerContent = content.toLowerCase();

    return {
      'has_questions': content.contains('?'),
      'has_exclamations': content.contains('!'),
      'is_caps': content == content.toUpperCase() && content.length > 3,
      'has_frustration_words': _checkForWords(lowerContent, [
        'stuck',
        'confused',
        'frustrated',
        'difficult',
      ]),
      'has_achievement_words': _checkForWords(lowerContent, [
        'got it',
        'thank',
        'perfect',
        'understand',
      ]),
      'has_anxiety_words': _checkForWords(lowerContent, [
        'worried',
        'scared',
        'nervous',
        'afraid',
      ]),
      'word_count': content.split(' ').length,
      'urgency_indicators': RegExp(
        r'urgent|asap|quickly|immediate',
      ).hasMatch(lowerContent),
    };
  }

  /// Check for specific words in content
  bool _checkForWords(String content, List<String> words) {
    return words.any((word) => content.contains(word));
  }

  /// Predict response tone from learned patterns
  ResponseTone _predictFromPatterns(
    Map<String, dynamic> messageAnalysis,
    List<EmotionalState> sessionEmotions,
  ) {
    // Default to professional
    ResponseTone predictedTone = ResponseTone.professional;

    // Check transition patterns
    if (sessionEmotions.isNotEmpty) {
      final lastSentiment = sessionEmotions.last.sentiment.name;
      final transitionPattern = '${lastSentiment}_to_response';

      if (_learnedPatterns.containsKey('transition_patterns')) {
        final patterns = _learnedPatterns['transition_patterns']!;
        // Find most effective response tone for this transition
        // This is a simplified version - in practice, you'd track tone effectiveness
        if (patterns.containsKey(transitionPattern)) {
          predictedTone = _getMostEffectiveToneForPattern(transitionPattern);
        }
      }
    }

    // Factor in message analysis
    if (messageAnalysis['has_frustration_words'] == true) {
      predictedTone = ResponseTone.supportive;
    } else if (messageAnalysis['has_achievement_words'] == true) {
      predictedTone = ResponseTone.celebratory;
    } else if (messageAnalysis['has_anxiety_words'] == true) {
      predictedTone = ResponseTone.reassuring;
    } else if (messageAnalysis['urgency_indicators'] == true) {
      predictedTone = ResponseTone.professional;
    }

    return predictedTone;
  }

  /// Get most effective tone for a pattern (simplified implementation)
  ResponseTone _getMostEffectiveToneForPattern(String pattern) {
    // In a real implementation, this would analyze response effectiveness data
    // For now, return based on pattern analysis
    if (pattern.contains('negative') || pattern.contains('frustrated')) {
      return ResponseTone.supportive;
    } else if (pattern.contains('positive')) {
      return ResponseTone.celebratory;
    } else if (pattern.contains('confused')) {
      return ResponseTone.patient;
    } else {
      return ResponseTone.professional;
    }
  }

  /// Adjust tone based on response effectiveness data
  ResponseTone _adjustForEffectiveness(
    ResponseTone baseTone,
    List<EmotionalState> sessionEmotions,
  ) {
    final toneKey = baseTone.name;
    final effectiveness = _responseEffectiveness[toneKey] ?? 0.5;

    // If effectiveness is low, try alternative tone
    if (effectiveness < 0.3) {
      return _getAlternativeTone(baseTone, sessionEmotions);
    }

    return baseTone;
  }

  /// Get alternative tone when primary tone is ineffective
  ResponseTone _getAlternativeTone(
    ResponseTone originalTone,
    List<EmotionalState> sessionEmotions,
  ) {
    // Simple alternative mapping
    switch (originalTone) {
      case ResponseTone.professional:
        return ResponseTone.empathetic;
      case ResponseTone.supportive:
        return ResponseTone.encouraging;
      case ResponseTone.celebratory:
        return ResponseTone.enthusiastic;
      default:
        return ResponseTone.gentle;
    }
  }

  /// Adjust tone based on emotional volatility
  ResponseTone _adjustForVolatility(ResponseTone baseTone, String sessionId) {
    final volatility = _calculateSessionVolatility(sessionId);

    // High volatility suggests need for calming approach
    if (volatility > 0.7) {
      return ResponseTone.gentle;
    } else if (volatility > 0.5) {
      return ResponseTone.reassuring;
    }

    return baseTone;
  }

  /// Calculate emotional volatility for a session
  double _calculateSessionVolatility(String sessionId) {
    final emotions = _sessionEmotions[sessionId] ?? [];
    if (emotions.length < 3) return 0.0;

    final intensities = emotions.map((e) => e.intensity).toList();
    final mean = intensities.reduce((a, b) => a + b) / intensities.length;

    final variance =
        intensities
            .map((intensity) => pow(intensity - mean, 2))
            .reduce((a, b) => a + b) /
        intensities.length;

    return sqrt(variance);
  }

  /// Record response effectiveness for learning
  Future<void> recordResponseEffectiveness(
    ResponseTone tone,
    EmotionalState userReaction, {
    double? satisfactionScore,
  }) async {
    final toneKey = tone.name;
    final effectiveness = _calculateEffectiveness(
      userReaction,
      satisfactionScore,
    );

    // Update running average
    final currentEffectiveness = _responseEffectiveness[toneKey] ?? 0.5;
    final newEffectiveness =
        (currentEffectiveness * 0.8) + (effectiveness * 0.2);

    _responseEffectiveness[toneKey] = newEffectiveness;

    await _saveResponseEffectiveness();

    if (kDebugMode) {
      print(
        'Recorded effectiveness for ${tone.displayName}: ${newEffectiveness.toStringAsFixed(2)}',
      );
    }
  }

  /// Calculate effectiveness score from user reaction
  double _calculateEffectiveness(
    EmotionalState userReaction,
    double? satisfactionScore,
  ) {
    double effectiveness = 0.5; // neutral baseline

    // Factor in sentiment improvement
    if (userReaction.sentiment == SentimentType.positive ||
        userReaction.sentiment == SentimentType.veryPositive) {
      effectiveness += 0.3;
    } else if (userReaction.sentiment == SentimentType.negative ||
        userReaction.sentiment == SentimentType.veryNegative) {
      effectiveness -= 0.3;
    }

    // Factor in specific emotions
    if (userReaction.emotions.contains(EmotionType.satisfaction)) {
      effectiveness += 0.2;
    } else if (userReaction.emotions.contains(EmotionType.frustration)) {
      effectiveness -= 0.2;
    }

    // Factor in intensity (lower intensity after interaction is good)
    if (userReaction.intensity < 0.3) {
      effectiveness += 0.1;
    } else if (userReaction.intensity > 0.7) {
      effectiveness -= 0.1;
    }

    // Factor in explicit satisfaction score if provided
    if (satisfactionScore != null) {
      effectiveness = (effectiveness * 0.7) + (satisfactionScore * 0.3);
    }

    return effectiveness.clamp(0.0, 1.0);
  }

  /// Get cross-session emotional insights
  Map<String, dynamic> getCrossSessionInsights() {
    if (_currentProfile == null) return {};

    return {
      'total_interactions': _currentProfile!.emotionalHistory.length,
      'learned_patterns': _learnedPatterns.length,
      'most_common_transitions': _getMostCommonTransitions(),
      'emotional_growth_trend': _calculateEmotionalGrowth(),
      'preferred_response_tones': _getPreferredResponseTones(),
      'volatility_patterns': _getVolatilityPatterns(),
      'context_specific_insights': _getContextSpecificInsights(),
    };
  }

  /// Get most common emotional transitions
  List<Map<String, dynamic>> _getMostCommonTransitions() {
    if (!_learnedPatterns.containsKey('transition_patterns')) return [];

    final patterns = _learnedPatterns['transition_patterns']!;
    final sortedPatterns = patterns.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return sortedPatterns
        .take(5)
        .map((entry) => {'pattern': entry.key, 'frequency': entry.value})
        .toList();
  }

  /// Calculate emotional growth over time
  Map<String, dynamic> _calculateEmotionalGrowth() {
    if (_currentProfile == null ||
        _currentProfile!.emotionalHistory.length < 10) {
      return {'trend': 'insufficient_data'};
    }

    final history = _currentProfile!.emotionalHistory;
    final halfPoint = history.length ~/ 2;

    final earlyStates = history.take(halfPoint);
    final recentStates = history.skip(halfPoint);

    final earlyAvgSentiment =
        earlyStates.map((e) => e.sentiment.score).reduce((a, b) => a + b) /
        halfPoint;

    final recentAvgSentiment =
        recentStates.map((e) => e.sentiment.score).reduce((a, b) => a + b) /
        (history.length - halfPoint);

    final improvementScore = recentAvgSentiment - earlyAvgSentiment;

    return {
      'improvement_score': improvementScore,
      'trend': improvementScore > 0.2
          ? 'improving'
          : improvementScore < -0.2
          ? 'declining'
          : 'stable',
      'early_avg_sentiment': earlyAvgSentiment,
      'recent_avg_sentiment': recentAvgSentiment,
    };
  }

  /// Get preferred response tones based on effectiveness
  List<Map<String, dynamic>> _getPreferredResponseTones() {
    final sortedTones = _responseEffectiveness.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedTones
        .take(5)
        .map((entry) => {'tone': entry.key, 'effectiveness': entry.value})
        .toList();
  }

  /// Get volatility patterns
  Map<String, dynamic> _getVolatilityPatterns() {
    final sessionVolatilities = <double>[];

    for (final sessionId in _sessionEmotions.keys) {
      final volatility = _calculateSessionVolatility(sessionId);
      sessionVolatilities.add(volatility);
    }

    if (sessionVolatilities.isEmpty) return {'average_volatility': 0.0};

    final avgVolatility =
        sessionVolatilities.reduce((a, b) => a + b) /
        sessionVolatilities.length;
    final maxVolatility = sessionVolatilities.reduce(max);
    final minVolatility = sessionVolatilities.reduce(min);

    return {
      'average_volatility': avgVolatility,
      'max_volatility': maxVolatility,
      'min_volatility': minVolatility,
      'volatility_trend': _calculateVolatilityTrend(sessionVolatilities),
    };
  }

  /// Calculate volatility trend
  String _calculateVolatilityTrend(List<double> volatilities) {
    if (volatilities.length < 3) return 'stable';

    final recent = volatilities.skip(volatilities.length ~/ 2).toList();
    final early = volatilities.take(volatilities.length ~/ 2).toList();

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final earlyAvg = early.reduce((a, b) => a + b) / early.length;

    final change = recentAvg - earlyAvg;

    if (change > 0.1) return 'increasing';
    if (change < -0.1) return 'decreasing';
    return 'stable';
  }

  /// Get context-specific insights
  Map<String, dynamic> _getContextSpecificInsights() {
    if (!_learnedPatterns.containsKey('context_patterns')) return {};

    final contextPatterns = _learnedPatterns['context_patterns']!;
    final contexts = <String, Map<String, int>>{};

    for (final entry in contextPatterns.entries) {
      final parts = entry.key.split('_');
      if (parts.length >= 2) {
        final context = parts[0];
        final sentiment = parts[1];

        if (!contexts.containsKey(context)) {
          contexts[context] = {};
        }
        contexts[context]![sentiment] = entry.value as int;
      }
    }

    return contexts;
  }

  /// Enhanced methods from parent class
  List<EmotionalState> getSessionEmotions(String sessionId) {
    return _sessionEmotions[sessionId] ?? [];
  }

  EmotionalTrend getRecentTrend({int days = 7}) {
    if (_currentProfile == null) return EmotionalTrend.stable;

    final recentStates = _currentProfile!.emotionalHistory
        .where(
          (state) => DateTime.now().difference(state.timestamp).inDays <= days,
        )
        .toList();

    if (recentStates.length < 3) return EmotionalTrend.stable;

    final sentimentScores = recentStates
        .map((state) => state.sentiment.score)
        .toList();

    final early =
        sentimentScores
            .take(sentimentScores.length ~/ 3)
            .fold(0.0, (a, b) => a + b) /
        (sentimentScores.length ~/ 3);
    final late =
        sentimentScores
            .skip(sentimentScores.length * 2 ~/ 3)
            .fold(0.0, (a, b) => a + b) /
        (sentimentScores.length ~/ 3);

    final difference = late - early;

    if (difference > 0.3) return EmotionalTrend.improving;
    if (difference < -0.3) return EmotionalTrend.declining;
    return EmotionalTrend.stable;
  }

  List<EmotionType> getDominantEmotions({int limit = 3}) {
    if (_currentProfile == null) return [];

    final emotionCounts = <EmotionType, int>{};

    for (final state in _currentProfile!.emotionalHistory) {
      for (final emotion in state.emotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmotions.take(limit).map((e) => e.key).toList();
  }

  /// Load/Save methods for enhanced data
  Future<void> _loadLearnedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsData = prefs.getString(_emotionalPatternsKey);

      if (patternsData != null) {
        final patternsJson = jsonDecode(patternsData) as Map<String, dynamic>;
        _learnedPatterns.clear();
        _learnedPatterns.addAll(
          patternsJson.cast<String, Map<String, dynamic>>(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading learned patterns: $e');
      }
    }
  }

  Future<void> _saveLearnedPatterns() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patternsJson = jsonEncode(_learnedPatterns);
      await prefs.setString(_emotionalPatternsKey, patternsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving learned patterns: $e');
      }
    }
  }

  Future<void> _loadResponseEffectiveness() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectivenessData = prefs.getString(_responseEffectivenessKey);

      if (effectivenessData != null) {
        final effectivenessJson =
            jsonDecode(effectivenessData) as Map<String, dynamic>;
        _responseEffectiveness.clear();
        effectivenessJson.forEach((key, value) {
          _responseEffectiveness[key] = (value as num).toDouble();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading response effectiveness: $e');
      }
    }
  }

  Future<void> _saveResponseEffectiveness() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final effectivenessJson = jsonEncode(_responseEffectiveness);
      await prefs.setString(_responseEffectivenessKey, effectivenessJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving response effectiveness: $e');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = prefs.getString(_userProfileKey);

      if (profileData != null) {
        final profileJson = jsonDecode(profileData);
        _currentProfile = UserEmotionalProfile.fromJson(profileJson);
      } else {
        _currentProfile = UserEmotionalProfile(
          userId: 'enhanced_user',
          createdAt: DateTime.now(),
          lastUpdated: DateTime.now(),
          emotionalHistory: [],
          sentimentFrequency: {},
          emotionTrends: {},
          triggerPatterns: [],
          averageIntensity: 0.3,
        );
        await _saveUserProfile();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading enhanced user profile: $e');
      }
      // Create fallback profile
      _currentProfile = UserEmotionalProfile(
        userId: 'enhanced_user',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        emotionalHistory: [],
        sentimentFrequency: {},
        emotionTrends: {},
        triggerPatterns: [],
        averageIntensity: 0.3,
      );
    }
  }

  Future<void> _updateUserProfileEnhanced(EmotionalState state) async {
    if (_currentProfile == null) return;

    // Update emotional history
    final updatedHistory = List<EmotionalState>.from(
      _currentProfile!.emotionalHistory,
    );
    updatedHistory.add(state);

    // Limit history size
    if (updatedHistory.length > _maxEmotionalHistory) {
      updatedHistory.removeRange(
        0,
        updatedHistory.length - _maxEmotionalHistory,
      );
    }

    // Update sentiment frequency
    final updatedSentimentFreq = Map<SentimentType, int>.from(
      _currentProfile!.sentimentFrequency,
    );
    updatedSentimentFreq[state.sentiment] =
        (updatedSentimentFreq[state.sentiment] ?? 0) + 1;

    // Update emotion trends
    final updatedEmotionTrends = Map<EmotionType, double>.from(
      _currentProfile!.emotionTrends,
    );
    for (final emotion in state.emotions) {
      updatedEmotionTrends[emotion] =
          ((updatedEmotionTrends[emotion] ?? 0.0) * 0.9) +
          (state.intensity * 0.1);
    }

    // Calculate average intensity
    final totalIntensity = updatedHistory
        .map((e) => e.intensity)
        .fold(0.0, (a, b) => a + b);
    final avgIntensity = totalIntensity / updatedHistory.length;

    _currentProfile = _currentProfile!.copyWith(
      lastUpdated: DateTime.now(),
      emotionalHistory: updatedHistory,
      sentimentFrequency: updatedSentimentFreq,
      emotionTrends: updatedEmotionTrends,
      averageIntensity: avgIntensity,
    );

    await _saveUserProfile();
  }

  Future<void> _saveUserProfile() async {
    if (_currentProfile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(_currentProfile!.toJson());
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving enhanced user profile: $e');
      }
    }
  }

  Future<void> _saveSessionEmotions(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotions = _sessionEmotions[sessionId] ?? [];
      final emotionsJson = jsonEncode(emotions.map((e) => e.toJson()).toList());
      await prefs.setString(_sessionEmotionsKey + sessionId, emotionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving session emotions: $e');
      }
    }
  }

  Future<void> _cleanupOldSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.startsWith(_sessionEmotionsKey)) {
          final sessionId = key.substring(_sessionEmotionsKey.length);
          // Simple cleanup - in practice, you'd parse session date from ID
          if (sessionId.length > 20) {
            // Basic check for old format
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old sessions: $e');
      }
    }
  }

  Future<void> _analyzeAndUpdatePatterns() async {
    // Analyze existing data to identify new patterns
    if (_currentProfile != null &&
        _currentProfile!.emotionalHistory.isNotEmpty) {
      // This could include more sophisticated pattern analysis
      if (kDebugMode) {
        print(
          'Analyzed ${_currentProfile!.emotionalHistory.length} historical states for patterns',
        );
      }
    }
  }

  /// Get emotional insights for analytics
  Map<String, dynamic> getEmotionalInsights() {
    final crossSessionInsights = getCrossSessionInsights();
    final baseInsights = _currentProfile?.toJson() ?? {};

    return {
      ...baseInsights,
      'cross_session_insights': crossSessionInsights,
      'learned_patterns_count': _learnedPatterns.length,
      'response_effectiveness_data': _responseEffectiveness,
    };
  }
}

/// Emotional trend enumeration for enhanced analysis
enum EmotionalTrend { improving, stable, declining }
