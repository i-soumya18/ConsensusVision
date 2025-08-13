import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotional_state.dart';
import '../services/database_service.dart';

class EmotionalMemoryService {
  static final EmotionalMemoryService _instance =
      EmotionalMemoryService._internal();
  factory EmotionalMemoryService() => _instance;
  EmotionalMemoryService._internal();

  static const String _userProfileKey = 'user_emotional_profile';
  static const String _sessionEmotionsKey = 'session_emotions_';
  static const int _maxEmotionalHistory = 100;
  static const int _maxSessionRetention = 30; // days

  UserEmotionalProfile? _currentProfile;
  final Map<String, List<EmotionalState>> _sessionEmotions = {};

  /// Initialize the service and load existing profile
  Future<void> initialize() async {
    try {
      await _loadUserProfile();
      await _cleanupOldSessions();
      if (kDebugMode) {
        print('Emotional Memory Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Emotional Memory Service: $e');
      }
    }
  }

  /// Get current user emotional profile
  UserEmotionalProfile? get currentProfile => _currentProfile;

  /// Add emotional state to memory
  Future<void> addEmotionalState(EmotionalState state, String sessionId) async {
    try {
      // Add to session emotions
      if (!_sessionEmotions.containsKey(sessionId)) {
        _sessionEmotions[sessionId] = [];
      }
      _sessionEmotions[sessionId]!.add(state);

      // Update user profile
      await _updateUserProfile(state);

      // Save session emotions
      await _saveSessionEmotions(sessionId);

      if (kDebugMode) {
        print(
          'Added emotional state: ${state.sentiment.displayName} with ${state.emotions.length} emotions',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error adding emotional state: $e');
      }
    }
  }

  /// Get emotional history for a session
  List<EmotionalState> getSessionEmotions(String sessionId) {
    return _sessionEmotions[sessionId] ?? [];
  }

  /// Get recent emotional trend
  EmotionalTrend getRecentTrend({int days = 7}) {
    if (_currentProfile == null) {
      return EmotionalTrend.stable;
    }

    final recentStates = _currentProfile!.emotionalHistory
        .where(
          (state) => DateTime.now().difference(state.timestamp).inDays <= days,
        )
        .toList();

    if (recentStates.length < 3) {
      return EmotionalTrend.stable;
    }

    // Calculate trend based on sentiment progression
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

  /// Get dominant emotion pattern
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

  /// Predict likely emotional response based on patterns
  ResponseTone predictOptimalResponseTone(
    String messageContent,
    String sessionId,
  ) {
    final sessionEmotions = getSessionEmotions(sessionId);
    final recentTrend = getRecentTrend();

    // Analyze current message for emotional cues
    final hasQuestions = messageContent.contains('?');
    final hasExclamations = messageContent.contains('!');
    final isUpperCase =
        messageContent == messageContent.toUpperCase() &&
        messageContent.length > 3;

    // Check for frustration patterns
    final frustrationWords = [
      'stuck',
      'confused',
      'don\'t understand',
      'frustrated',
      'difficult',
    ];
    final hasFrustration = frustrationWords.any(
      (word) => messageContent.toLowerCase().contains(word),
    );

    // Check for achievement patterns
    final achievementWords = [
      'got it',
      'thank you',
      'perfect',
      'works',
      'understand now',
    ];
    final hasAchievement = achievementWords.any(
      (word) => messageContent.toLowerCase().contains(word),
    );

    // Recent emotional context
    final recentNegativeCount = sessionEmotions
        .where((state) => !state.sentiment.score.isNegative)
        .length;

    // Decision logic
    if (hasAchievement) {
      return ResponseTone.celebratory;
    } else if (hasFrustration || recentNegativeCount >= 2) {
      return ResponseTone.supportive;
    } else if (isUpperCase || hasExclamations) {
      return ResponseTone.patient;
    } else if (hasQuestions && recentTrend == EmotionalTrend.declining) {
      return ResponseTone.encouraging;
    } else if (recentTrend == EmotionalTrend.improving) {
      return ResponseTone.enthusiastic;
    } else {
      return ResponseTone.professional;
    }
  }

  /// Load user profile from storage
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = prefs.getString(_userProfileKey);

      if (profileData != null) {
        final profileJson = jsonDecode(profileData);
        _currentProfile = UserEmotionalProfile.fromJson(profileJson);
      } else {
        // Create new profile
        _currentProfile = UserEmotionalProfile(
          userId: 'default_user',
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
        print('Error loading user profile: $e');
      }
      // Create fallback profile
      _currentProfile = UserEmotionalProfile(
        userId: 'default_user',
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

  /// Update user profile with new emotional state
  Future<void> _updateUserProfile(EmotionalState state) async {
    if (_currentProfile == null) return;

    // Add to history
    final updatedHistory = List<EmotionalState>.from(
      _currentProfile!.emotionalHistory,
    )..add(state);

    // Trim history if too long
    if (updatedHistory.length > _maxEmotionalHistory) {
      updatedHistory.removeAt(0);
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

    // Calculate new average intensity
    final totalIntensity = updatedHistory.fold(
      0.0,
      (sum, s) => sum + s.intensity,
    );
    final newAverageIntensity = totalIntensity / updatedHistory.length;

    _currentProfile = _currentProfile!.copyWith(
      lastUpdated: DateTime.now(),
      emotionalHistory: updatedHistory,
      sentimentFrequency: updatedSentimentFreq,
      emotionTrends: updatedEmotionTrends,
      averageIntensity: newAverageIntensity,
    );

    await _saveUserProfile();
  }

  /// Save user profile to storage
  Future<void> _saveUserProfile() async {
    if (_currentProfile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(_currentProfile!.toJson());
      await prefs.setString(_userProfileKey, profileJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving user profile: $e');
      }
    }
  }

  /// Save session emotions to storage
  Future<void> _saveSessionEmotions(String sessionId) async {
    try {
      final emotions = _sessionEmotions[sessionId];
      if (emotions == null) return;

      final prefs = await SharedPreferences.getInstance();
      final emotionsJson = jsonEncode(emotions.map((e) => e.toJson()).toList());
      await prefs.setString('$_sessionEmotionsKey$sessionId', emotionsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving session emotions: $e');
      }
    }
  }

  /// Load session emotions from storage
  Future<void> loadSessionEmotions(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final emotionsData = prefs.getString('$_sessionEmotionsKey$sessionId');

      if (emotionsData != null) {
        final emotionsJson = jsonDecode(emotionsData) as List;
        _sessionEmotions[sessionId] = emotionsJson
            .map((json) => EmotionalState.fromJson(json))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading session emotions: $e');
      }
    }
  }

  /// Clean up old session data
  Future<void> _cleanupOldSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.startsWith(_sessionEmotionsKey),
      );
      final cutoffDate = DateTime.now().subtract(
        Duration(days: _maxSessionRetention),
      );

      for (final key in keys) {
        final sessionId = key.replaceFirst(_sessionEmotionsKey, '');

        // Check if session still exists in database
        final session = await DatabaseService.getChatSession(sessionId);
        if (session == null || session.lastUpdated.isBefore(cutoffDate)) {
          await prefs.remove(key);
          _sessionEmotions.remove(sessionId);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old sessions: $e');
      }
    }
  }

  /// Get emotional insights for analytics
  Map<String, dynamic> getEmotionalInsights() {
    if (_currentProfile == null) return {};

    final recentStates = _currentProfile!.emotionalHistory
        .where(
          (state) => DateTime.now().difference(state.timestamp).inDays <= 30,
        )
        .toList();

    if (recentStates.isEmpty) return {};

    final positiveCount = recentStates
        .where((s) => s.sentiment.score > 0)
        .length;
    final negativeCount = recentStates
        .where((s) => s.sentiment.score < 0)
        .length;
    final neutralCount = recentStates.length - positiveCount - negativeCount;

    return {
      'total_interactions': recentStates.length,
      'positive_ratio': positiveCount / recentStates.length,
      'negative_ratio': negativeCount / recentStates.length,
      'neutral_ratio': neutralCount / recentStates.length,
      'average_intensity': _currentProfile!.averageIntensity,
      'dominant_emotions': getDominantEmotions(),
      'recent_trend': getRecentTrend().name,
      'most_common_sentiment': _currentProfile!.sentimentFrequency.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key
          .displayName,
    };
  }
}
