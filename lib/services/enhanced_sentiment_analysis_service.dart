import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/emotional_state.dart';

class EnhancedSentimentAnalysisService {
  static final EnhancedSentimentAnalysisService _instance =
      EnhancedSentimentAnalysisService._internal();
  factory EnhancedSentimentAnalysisService() => _instance;
  EnhancedSentimentAnalysisService._internal();

  bool _isInitialized = false;

  // Real-time analysis state
  final List<EmotionalState> _recentAnalyses = [];
  static const int _maxRecentAnalyses = 10;

  // Voice tone simulation patterns (for future voice integration)
  final Map<String, double> _voiceToneIndicators = {
    'CAPS': 0.8, // All caps indicates strong emotion
    '!!!': 0.9, // Multiple exclamations
    '???': 0.7, // Multiple questions (confusion/frustration)
    '...': -0.3, // Ellipsis (hesitation/uncertainty)
    'repeated_char': 0.6, // Character repetition (yessss, nooo)
  };

  // Advanced emotional cue patterns
  final Map<String, Map<String, dynamic>> _advancedPatterns = {
    'frustration_escalation': {
      'keywords': ['still', 'again', 'why', 'always', 'never'],
      'intensity_multiplier': 1.4,
      'emotion': EmotionType.frustration,
    },
    'confusion_persistence': {
      'keywords': ['unclear', 'don\'t get', 'confused', 'what do you mean'],
      'intensity_multiplier': 1.3,
      'emotion': EmotionType.confusion,
    },
    'satisfaction_achievement': {
      'keywords': ['finally', 'got it', 'perfect', 'exactly', 'that\'s it'],
      'intensity_multiplier': 1.5,
      'emotion': EmotionType.satisfaction,
    },
    'anxiety_uncertainty': {
      'keywords': ['worried', 'scared', 'nervous', 'afraid', 'unsure'],
      'intensity_multiplier': 1.2,
      'emotion': EmotionType.anxiety,
    },
  };

  // Enhanced sentiment lexicon
  final Map<String, double> _sentimentLexicon = {
    // Positive words
    'love': 3.0, 'amazing': 3.0, 'awesome': 3.0, 'fantastic': 3.0,
    'excellent': 3.0, 'wonderful': 3.0, 'brilliant': 3.0, 'perfect': 3.0,
    'great': 2.5, 'good': 2.0, 'nice': 2.0, 'happy': 2.5, 'pleased': 2.0,
    'satisfied': 2.0, 'thank': 2.0, 'thanks': 2.0, 'helpful': 2.0,
    'useful': 2.0, 'clear': 1.5, 'understand': 1.5, 'got it': 2.0,
    'makes sense': 2.0, 'solved': 2.5, 'works': 2.0, 'easy': 1.5,

    // Negative words
    'hate': -3.0, 'terrible': -3.0, 'awful': -3.0, 'horrible': -3.0,
    'worst': -3.0, 'stupid': -2.5, 'bad': -2.0, 'frustrated': -2.5,
    'angry': -2.5, 'confused': -2.0, 'difficult': -1.5, 'hard': -1.5,
    'stuck': -2.0, 'lost': -2.0, 'unclear': -1.5, 'doesn\'t work': -2.5,
    'not working': -2.5, 'broken': -2.0, 'wrong': -1.5, 'error': -1.5,
    'problem': -1.0, 'issue': -1.0, 'trouble': -1.5, 'fail': -2.0,

    // Neutral/question words
    'what': 0.0, 'how': 0.0, 'why': 0.0, 'when': 0.0, 'where': 0.0, 'help': 0.5,
  };

  // Enhanced emotion keywords
  final Map<EmotionType, List<String>> _emotionKeywords = {
    EmotionType.joy: [
      'happy',
      'great',
      'awesome',
      'amazing',
      'wonderful',
      'fantastic',
      'excellent',
      'love',
    ],
    EmotionType.excitement: [
      'excited',
      'thrilled',
      'wow',
      'incredible',
      'awesome',
      'can\'t wait',
    ],
    EmotionType.satisfaction: [
      'satisfied',
      'pleased',
      'content',
      'good',
      'accomplished',
      'done',
    ],
    EmotionType.calm: [
      'calm',
      'peaceful',
      'relaxed',
      'serene',
      'quiet',
      'still',
    ],
    EmotionType.confusion: [
      'confused',
      'unclear',
      'don\'t understand',
      'lost',
      'what',
    ],
    EmotionType.frustration: [
      'frustrated',
      'annoyed',
      'stuck',
      'difficult',
      'hard',
      'why',
    ],
    EmotionType.anger: ['angry', 'mad', 'furious', 'hate', 'stupid'],
    EmotionType.sadness: ['sad', 'disappointed', 'unhappy', 'depressed'],
    EmotionType.anxiety: ['worried', 'nervous', 'anxious', 'scared', 'afraid'],
    EmotionType.fear: ['scared', 'afraid', 'terrified', 'worried'],
    EmotionType.surprise: ['surprised', 'wow', 'unexpected', 'shocked'],
    EmotionType.interest: ['interesting', 'curious', 'want to know', 'learn'],
    EmotionType.boredom: ['boring', 'bored', 'dull', 'tedious'],
    EmotionType.disappointment: [
      'disappointed',
      'let down',
      'expected',
      'hoped',
    ],
  };

  final Map<String, double> _intensityModifiers = {
    'very': 1.5,
    'extremely': 1.8,
    'really': 1.3,
    'super': 1.4,
    'quite': 1.2,
    'somewhat': 0.8,
    'a bit': 0.7,
    'slightly': 0.6,
    'kind of': 0.7,
    'sort of': 0.7,
  };

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      if (kDebugMode) {
        print('Enhanced Sentiment Analysis Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Enhanced Sentiment Analysis Service: $e');
      }
    }
  }

  /// Enhanced real-time sentiment analysis with voice tone simulation
  Future<EmotionalState> analyzeText(String text, {String? context}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Basic sentiment analysis
      final sentimentScore = _calculateSentimentScore(text);
      final sentimentType = _mapSentimentScore(sentimentScore);

      // Enhanced emotion detection with advanced patterns
      final emotions = _detectEmotionsEnhanced(text);

      // Voice tone analysis simulation
      final voiceToneScore = _analyzeVoiceToneIndicators(text);

      // Calculate enhanced intensity
      final intensity = _calculateEnhancedIntensity(
        text,
        sentimentScore,
        voiceToneScore,
      );

      // Real-time pattern analysis
      final patternAnalysis = _analyzeEmotionalPatterns(text);

      final emotionalState = EmotionalState(
        id: 'emotion_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        sentiment: sentimentType,
        intensity: intensity,
        emotions: emotions,
        context: context,
        metadata: {
          'raw_sentiment_score': sentimentScore,
          'voice_tone_score': voiceToneScore,
          'pattern_analysis': patternAnalysis,
          'text_length': text.length,
          'analysis_method': 'enhanced_lexicon_based',
          'real_time_analysis': true,
        },
      );

      // Store in recent analyses for trend tracking
      _addToRecentAnalyses(emotionalState);

      if (kDebugMode) {
        print(
          'Enhanced analysis - Sentiment: ${sentimentType.displayName}, '
          'Intensity: ${intensity.toStringAsFixed(2)}, '
          'Voice tone: ${voiceToneScore.toStringAsFixed(2)}, '
          'Emotions: ${emotions.map((e) => e.displayName).join(", ")}',
        );
      }

      return emotionalState;
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing text sentiment: $e');
      }

      // Fallback to neutral state
      return EmotionalState(
        id: 'emotion_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        sentiment: SentimentType.neutral,
        intensity: 0.3,
        emotions: [EmotionType.calm],
        context: context,
        metadata: {'error': e.toString(), 'analysis_method': 'fallback'},
      );
    }
  }

  /// Voice tone analysis using text patterns (simulates voice tone detection)
  double _analyzeVoiceToneIndicators(String text) {
    double toneScore = 0.0;

    // Check for caps (indicates shouting/strong emotion)
    final alphabeticText = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (alphabeticText.isNotEmpty) {
      final upperCaseRatio =
          text.replaceAll(RegExp(r'[^A-Z]'), '').length / alphabeticText.length;
      if (upperCaseRatio > 0.5) {
        toneScore += _voiceToneIndicators['CAPS']!;
      }
    }

    // Check for multiple exclamations
    final exclamationCount = RegExp(r'!+').allMatches(text).length;
    if (exclamationCount > 1) {
      toneScore += _voiceToneIndicators['!!!']! * (exclamationCount * 0.2);
    }

    // Check for multiple question marks (confusion/frustration)
    final questionCount = RegExp(r'\?+').allMatches(text).length;
    if (questionCount > 1) {
      toneScore += _voiceToneIndicators['???']! * (questionCount * 0.15);
    }

    // Check for ellipsis (uncertainty)
    if (text.contains('...')) {
      toneScore += _voiceToneIndicators['...']!;
    }

    // Check for character repetition (emotional emphasis)
    final repetitionPattern = RegExp(r'([a-zA-Z])\1{2,}');
    if (repetitionPattern.hasMatch(text)) {
      toneScore += _voiceToneIndicators['repeated_char']!;
    }

    return toneScore.clamp(-1.0, 1.0);
  }

  /// Enhanced emotion detection with advanced pattern recognition
  List<EmotionType> _detectEmotionsEnhanced(String text) {
    final detectedEmotions = <EmotionType>{};
    final lowerText = text.toLowerCase();

    // Basic emotion keyword matching
    for (final emotion in _emotionKeywords.keys) {
      for (final keyword in _emotionKeywords[emotion]!) {
        if (lowerText.contains(keyword)) {
          detectedEmotions.add(emotion);
        }
      }
    }

    // Advanced pattern matching
    for (final patternName in _advancedPatterns.keys) {
      final pattern = _advancedPatterns[patternName]!;
      final keywords = pattern['keywords'] as List<String>;
      final emotion = pattern['emotion'] as EmotionType;

      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          detectedEmotions.add(emotion);
          break;
        }
      }
    }

    // Contextual emotion inference
    detectedEmotions.addAll(_inferContextualEmotions(text));

    return detectedEmotions.isEmpty
        ? [EmotionType.calm]
        : detectedEmotions.toList();
  }

  /// Infer emotions from context and patterns
  List<EmotionType> _inferContextualEmotions(String text) {
    final emotions = <EmotionType>[];
    final lowerText = text.toLowerCase();

    // Frustration patterns
    if ((lowerText.contains('why') && lowerText.contains('not')) ||
        (lowerText.contains('still') && lowerText.contains('problem'))) {
      emotions.add(EmotionType.frustration);
    }

    // Excitement patterns
    if (RegExp(r'[!]{2,}').hasMatch(text) &&
        (lowerText.contains('wow') || lowerText.contains('amazing'))) {
      emotions.add(EmotionType.excitement);
    }

    // Confusion patterns
    if (lowerText.split('?').length > 2 && lowerText.contains('how')) {
      emotions.add(EmotionType.confusion);
    }

    // Satisfaction patterns
    if ((lowerText.contains('thank') && lowerText.contains('work')) ||
        (lowerText.contains('perfect') || lowerText.contains('exactly'))) {
      emotions.add(EmotionType.satisfaction);
    }

    return emotions;
  }

  /// Enhanced intensity calculation with voice tone and pattern factors
  double _calculateEnhancedIntensity(
    String text,
    double sentimentScore,
    double voiceToneScore,
  ) {
    double intensity = _calculateIntensity(text, sentimentScore);

    // Factor in voice tone indicators
    intensity += voiceToneScore.abs() * 0.3;

    // Factor in advanced patterns
    for (final patternName in _advancedPatterns.keys) {
      final pattern = _advancedPatterns[patternName]!;
      final keywords = pattern['keywords'] as List<String>;
      final multiplier = pattern['intensity_multiplier'] as double;

      for (final keyword in keywords) {
        if (text.toLowerCase().contains(keyword)) {
          intensity *= multiplier;
          break;
        }
      }
    }

    // Factor in recent emotional trend
    if (_recentAnalyses.isNotEmpty) {
      final recentAvgIntensity =
          _recentAnalyses.map((e) => e.intensity).reduce((a, b) => a + b) /
          _recentAnalyses.length;

      // If recent intensity is high, current intensity might be influenced
      if (recentAvgIntensity > 0.7) {
        intensity += 0.1;
      }
    }

    return intensity.clamp(0.0, 1.0);
  }

  /// Calculate sentiment score using enhanced lexicon
  double _calculateSentimentScore(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    double totalScore = 0.0;
    int matchedWords = 0;

    for (final word in words) {
      if (_sentimentLexicon.containsKey(word)) {
        totalScore += _sentimentLexicon[word]!;
        matchedWords++;
      }
    }

    // Apply intensity modifiers
    for (final entry in _sentimentLexicon.entries) {
      if (text.toLowerCase().contains(entry.key)) {
        final modifiedScore = _applyIntensityModifiers(
          text,
          entry.key,
          entry.value,
        );
        if (modifiedScore != entry.value) {
          totalScore += (modifiedScore - entry.value);
        }
      }
    }

    return matchedWords > 0 ? totalScore / matchedWords : 0.0;
  }

  /// Apply intensity modifiers to sentiment scores
  double _applyIntensityModifiers(String text, String word, double baseScore) {
    final lowerText = text.toLowerCase();
    double modifiedScore = baseScore;

    for (final entry in _intensityModifiers.entries) {
      final modifier = entry.key;
      final multiplier = entry.value;

      if (lowerText.contains('$modifier $word') ||
          lowerText.contains('$modifier${word}')) {
        modifiedScore *= multiplier;
        break;
      }
    }

    return modifiedScore;
  }

  /// Calculate intensity based on various factors
  double _calculateIntensity(String text, double sentimentScore) {
    double intensity = sentimentScore.abs() * 0.5;

    // Factor in exclamation marks
    final exclamationCount = '!'.allMatches(text).length;
    intensity += exclamationCount * 0.1;

    // Factor in question marks (uncertainty increases intensity)
    final questionCount = '?'.allMatches(text).length;
    intensity += questionCount * 0.05;

    // Factor in caps
    final capsRatio =
        text.replaceAll(RegExp(r'[^A-Z]'), '').length / text.length;
    intensity += capsRatio * 0.3;

    // Factor in emotion keywords
    final emotions = _detectEmotions(text);
    intensity += emotions.length * 0.1;

    return intensity.clamp(0.0, 1.0);
  }

  /// Basic emotion detection (for compatibility)
  List<EmotionType> _detectEmotions(String text) {
    final detectedEmotions = <EmotionType>[];
    final lowerText = text.toLowerCase();

    for (final entry in _emotionKeywords.entries) {
      for (final keyword in entry.value) {
        if (lowerText.contains(keyword)) {
          detectedEmotions.add(entry.key);
          break;
        }
      }
    }

    return detectedEmotions.isEmpty ? [EmotionType.calm] : detectedEmotions;
  }

  /// Map sentiment score to sentiment type
  SentimentType _mapSentimentScore(double score) {
    if (score >= 2.0) return SentimentType.veryPositive;
    if (score >= 0.5) return SentimentType.positive;
    if (score <= -2.0) return SentimentType.veryNegative;
    if (score <= -0.5) return SentimentType.negative;
    return SentimentType.neutral;
  }

  /// Analyze emotional patterns for real-time insights
  Map<String, dynamic> _analyzeEmotionalPatterns(String text) {
    final patterns = <String, dynamic>{};

    // Escalation patterns
    patterns['escalation_detected'] = _detectEscalationPattern(text);

    // Repetition patterns
    patterns['repetitive_concerns'] = _detectRepetitiveConcerns(text);

    // Resolution patterns
    patterns['resolution_indicators'] = _detectResolutionIndicators(text);

    // Emotional complexity
    patterns['emotional_complexity'] = _calculateEmotionalComplexity(text);

    return patterns;
  }

  /// Detect if user is escalating emotionally
  bool _detectEscalationPattern(String text) {
    final escalationWords = ['still', 'again', 'always', 'never', 'every time'];
    return escalationWords.any((word) => text.toLowerCase().contains(word));
  }

  /// Detect repetitive concerns
  bool _detectRepetitiveConcerns(String text) {
    if (_recentAnalyses.length < 2) return false;

    final recentTexts = _recentAnalyses
        .map((e) => e.context ?? '')
        .where((context) => context.isNotEmpty)
        .toList();

    // Simple similarity check
    return recentTexts.any(
      (recentText) => _calculateTextSimilarity(text, recentText) > 0.6,
    );
  }

  /// Detect resolution indicators
  bool _detectResolutionIndicators(String text) {
    final resolutionWords = [
      'thank',
      'got it',
      'understand',
      'perfect',
      'solved',
    ];
    return resolutionWords.any((word) => text.toLowerCase().contains(word));
  }

  /// Calculate emotional complexity score
  double _calculateEmotionalComplexity(String text) {
    final emotions = _detectEmotionsEnhanced(text);
    final sentimentScore = _calculateSentimentScore(text);

    // More emotions and neutral sentiment indicates complexity
    return (emotions.length * 0.2 + (1.0 - sentimentScore.abs()) * 0.5).clamp(
      0.0,
      1.0,
    );
  }

  /// Simple text similarity calculation
  double _calculateTextSimilarity(String text1, String text2) {
    final words1 = text1.toLowerCase().split(RegExp(r'\W+'));
    final words2 = text2.toLowerCase().split(RegExp(r'\W+'));

    final intersection = words1.where((word) => words2.contains(word)).length;
    final union = (words1.length + words2.length - intersection);

    return union > 0 ? intersection / union : 0.0;
  }

  /// Add emotional state to recent analyses for trend tracking
  void _addToRecentAnalyses(EmotionalState state) {
    _recentAnalyses.add(state);
    if (_recentAnalyses.length > _maxRecentAnalyses) {
      _recentAnalyses.removeAt(0);
    }
  }

  /// Get real-time emotional trend
  Map<String, dynamic> getRealTimeEmotionalTrend() {
    if (_recentAnalyses.isEmpty) {
      return {'trend': 'stable', 'confidence': 0.0};
    }

    final recentIntensities = _recentAnalyses.map((e) => e.intensity).toList();
    final recentSentiments = _recentAnalyses
        .map((e) => e.sentiment.score)
        .toList();

    // Calculate trend direction
    String trend = 'stable';
    double confidence = 0.0;

    if (recentIntensities.length >= 3) {
      final early = recentIntensities
          .take(recentIntensities.length ~/ 2)
          .toList();
      final late = recentIntensities
          .skip(recentIntensities.length ~/ 2)
          .toList();

      final earlyAvg = early.reduce((a, b) => a + b) / early.length;
      final lateAvg = late.reduce((a, b) => a + b) / late.length;

      final intensityChange = lateAvg - earlyAvg;
      final sentimentChange = recentSentiments.last - recentSentiments.first;

      if (intensityChange > 0.2 || sentimentChange > 0.3) {
        trend = 'escalating';
        confidence = (intensityChange + sentimentChange.abs()).clamp(0.0, 1.0);
      } else if (intensityChange < -0.2 || sentimentChange < -0.3) {
        trend = 'calming';
        confidence = (intensityChange.abs() + sentimentChange.abs()).clamp(
          0.0,
          1.0,
        );
      } else {
        confidence =
            1.0 -
            (intensityChange.abs() + sentimentChange.abs()).clamp(0.0, 1.0);
      }
    }

    return {
      'trend': trend,
      'confidence': confidence,
      'sample_size': _recentAnalyses.length,
      'recent_emotions': _recentAnalyses
          .map((e) => e.emotions.map((em) => em.displayName).join(', '))
          .toList(),
    };
  }

  /// Get comprehensive emotional insights
  Map<String, dynamic> getComprehensiveEmotionalInsights() {
    return {
      'real_time_trend': getRealTimeEmotionalTrend(),
      'recent_analyses_count': _recentAnalyses.length,
      'dominant_recent_emotions': _getDominantRecentEmotions(),
      'average_intensity': _getAverageRecentIntensity(),
      'emotional_volatility': _calculateEmotionalVolatility(),
    };
  }

  /// Get dominant emotions from recent analyses
  List<String> _getDominantRecentEmotions() {
    if (_recentAnalyses.isEmpty) return [];

    final emotionCounts = <EmotionType, int>{};

    for (final analysis in _recentAnalyses) {
      for (final emotion in analysis.emotions) {
        emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
      }
    }

    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedEmotions.take(3).map((e) => e.key.displayName).toList();
  }

  /// Get average intensity from recent analyses
  double _getAverageRecentIntensity() {
    if (_recentAnalyses.isEmpty) return 0.0;

    final totalIntensity = _recentAnalyses
        .map((e) => e.intensity)
        .reduce((a, b) => a + b);

    return totalIntensity / _recentAnalyses.length;
  }

  /// Calculate emotional volatility (how much emotions change)
  double _calculateEmotionalVolatility() {
    if (_recentAnalyses.length < 2) return 0.0;

    final intensities = _recentAnalyses.map((e) => e.intensity).toList();
    final mean = intensities.reduce((a, b) => a + b) / intensities.length;

    final variance =
        intensities
            .map((intensity) => pow(intensity - mean, 2))
            .reduce((a, b) => a + b) /
        intensities.length;

    return sqrt(variance);
  }
}
