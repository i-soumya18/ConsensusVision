import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/emotional_state.dart';

class SentimentAnalysisService {
  static final SentimentAnalysisService _instance =
      SentimentAnalysisService._internal();
  factory SentimentAnalysisService() => _instance;
  SentimentAnalysisService._internal();

  bool _isInitialized = false;

  // Simple sentiment lexicon for basic analysis
  final Map<String, double> _sentimentLexicon = {
    // Positive words
    'love': 3.0,
    'amazing': 3.0,
    'awesome': 3.0,
    'fantastic': 3.0,
    'excellent': 3.0,
    'wonderful': 3.0,
    'brilliant': 3.0,
    'perfect': 3.0,
    'great': 2.5,
    'good': 2.0,
    'nice': 2.0, 'happy': 2.5, 'pleased': 2.0, 'satisfied': 2.0, 'thank': 2.0,
    'thanks': 2.0,
    'helpful': 2.0,
    'useful': 2.0,
    'clear': 1.5,
    'understand': 1.5,
    'got it': 2.0, 'makes sense': 2.0, 'solved': 2.5, 'works': 2.0, 'easy': 1.5,

    // Negative words
    'hate': -3.0,
    'terrible': -3.0,
    'awful': -3.0,
    'horrible': -3.0,
    'worst': -3.0,
    'stupid': -2.5,
    'bad': -2.0,
    'frustrated': -2.5,
    'angry': -2.5,
    'confused': -2.0,
    'difficult': -1.5,
    'hard': -1.5,
    'stuck': -2.0,
    'lost': -2.0,
    'unclear': -1.5,
    'doesn\'t work': -2.5, 'not working': -2.5, 'broken': -2.0, 'wrong': -1.5,
    'error': -1.5,
    'problem': -1.0,
    'issue': -1.0,
    'trouble': -1.5,
    'fail': -2.0,

    // Neutral/question words
    'what': 0.0, 'how': 0.0, 'why': 0.0, 'when': 0.0, 'where': 0.0, 'help': 0.5,
  };

  // Emotional patterns for enhanced detection
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
      'what',
      'how',
      'why',
      'lost',
    ],
    EmotionType.frustration: [
      'frustrated',
      'annoying',
      'stuck',
      'difficult',
      'hard',
      'ugh',
      'argh',
    ],
    EmotionType.anger: [
      'angry',
      'mad',
      'furious',
      'hate',
      'stupid',
      'terrible',
      'awful',
    ],
    EmotionType.sadness: [
      'sad',
      'disappointed',
      'down',
      'depressed',
      'unhappy',
      'sorry',
    ],
    EmotionType.anxiety: [
      'anxious',
      'worried',
      'nervous',
      'scared',
      'afraid',
      'stress',
    ],
    EmotionType.fear: [
      'fear',
      'terrified',
      'afraid',
      'scary',
      'frightened',
      'panic',
    ],
    EmotionType.surprise: [
      'surprised',
      'wow',
      'unexpected',
      'sudden',
      'shocked',
      'amazed',
    ],
    EmotionType.interest: [
      'interesting',
      'curious',
      'tell me more',
      'explain',
      'learn',
    ],
    EmotionType.boredom: [
      'boring',
      'bored',
      'dull',
      'tedious',
      'uninteresting',
    ],
    EmotionType.disappointment: [
      'disappointed',
      'let down',
      'expected',
      'hoped',
      'thought',
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
        print('Sentiment Analysis Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Sentiment Analysis Service: $e');
      }
    }
  }

  /// Analyze text sentiment and emotions using simple lexicon-based approach
  Future<EmotionalState> analyzeText(String text, {String? context}) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Calculate sentiment score using lexicon
      final sentimentScore = _calculateSentimentScore(text);
      final sentimentType = _mapSentimentScore(sentimentScore);

      // Emotion detection
      final emotions = _detectEmotions(text);

      // Intensity calculation
      final intensity = _calculateIntensity(text, sentimentScore);

      return EmotionalState(
        id: 'emotion_${DateTime.now().millisecondsSinceEpoch}',
        timestamp: DateTime.now(),
        sentiment: sentimentType,
        intensity: intensity,
        emotions: emotions,
        context: context,
        metadata: {
          'raw_sentiment_score': sentimentScore,
          'text_length': text.length,
          'analysis_method': 'lexicon_based',
        },
      );
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

  /// Calculate sentiment score using simple lexicon
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

    // Check for phrases
    final lowerText = text.toLowerCase();
    for (final entry in _sentimentLexicon.entries) {
      if (entry.key.contains(' ') && lowerText.contains(entry.key)) {
        totalScore += entry.value;
        matchedWords++;
      }
    }

    return matchedWords > 0 ? totalScore / matchedWords : 0.0;
  }

  /// Analyze conversation patterns for emotional trends
  List<EmotionalState> analyzeConversationPattern(List<String> messages) {
    final results = <EmotionalState>[];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final contextualWeight = _calculateContextualWeight(i, messages.length);

      // Analyze with conversation context
      final emotionalState = analyzeText(
        message,
        context: 'conversation_message_${i + 1}',
      );

      // Adjust intensity based on conversation flow
      final adjustedState = emotionalState.then((state) {
        return state.copyWith(
          intensity: (state.intensity * contextualWeight).clamp(0.0, 1.0),
          metadata: {
            ...?state.metadata,
            'contextual_weight': contextualWeight,
            'message_position': i + 1,
            'total_messages': messages.length,
          },
        );
      });

      results.add(adjustedState as EmotionalState);
    }

    return results;
  }

  /// Detect frustration patterns specifically
  bool detectFrustrationPattern(List<String> recentMessages) {
    if (recentMessages.length < 2) return false;

    final frustrationIndicators = [
      'doesn\'t work',
      'not working',
      'still confused',
      'I don\'t get it',
      'this is hard',
      'give up',
      'nevermind',
      'forget it',
      'ugh',
      'argh',
    ];

    int frustrationCount = 0;
    for (final message in recentMessages.take(3)) {
      final lowerMessage = message.toLowerCase();
      for (final indicator in frustrationIndicators) {
        if (lowerMessage.contains(indicator)) {
          frustrationCount++;
          break;
        }
      }
    }

    return frustrationCount >= 2;
  }

  /// Detect achievement/success patterns
  bool detectAchievementPattern(String text) {
    final achievementKeywords = [
      'got it',
      'understand',
      'thank you',
      'thanks',
      'perfect',
      'exactly',
      'that works',
      'solved',
      'figured it out',
      'makes sense',
      'brilliant',
      'helpful',
    ];

    final lowerText = text.toLowerCase();
    return achievementKeywords.any((keyword) => lowerText.contains(keyword));
  }

  SentimentType _mapSentimentScore(double score) {
    if (score >= 3) return SentimentType.veryPositive;
    if (score >= 1) return SentimentType.positive;
    if (score <= -3) return SentimentType.veryNegative;
    if (score <= -1) return SentimentType.negative;
    return SentimentType.neutral;
  }

  List<EmotionType> _detectEmotions(String text) {
    final emotions = <EmotionType>[];
    final lowerText = text.toLowerCase();

    for (final entry in _emotionKeywords.entries) {
      final emotionType = entry.key;
      final keywords = entry.value;

      for (final keyword in keywords) {
        if (lowerText.contains(keyword)) {
          emotions.add(emotionType);
          break;
        }
      }
    }

    // Default to calm if no emotions detected
    if (emotions.isEmpty) {
      emotions.add(EmotionType.calm);
    }

    return emotions;
  }

  double _calculateIntensity(String text, double sentimentScore) {
    double intensity = (sentimentScore.abs() / 5.0).clamp(0.0, 1.0);

    // Apply intensity modifiers
    final lowerText = text.toLowerCase();
    for (final entry in _intensityModifiers.entries) {
      if (lowerText.contains(entry.key)) {
        intensity *= entry.value;
        break;
      }
    }

    // Punctuation-based intensity
    final exclamationCount = '!'.allMatches(text).length;
    final questionCount = '?'.allMatches(text).length;
    final capsRatio =
        text.replaceAll(RegExp(r'[^A-Z]'), '').length / text.length;

    intensity += (exclamationCount * 0.1);
    intensity += (questionCount * 0.05);
    intensity += (capsRatio * 0.3);

    return intensity.clamp(0.0, 1.0);
  }

  double _calculateContextualWeight(int position, int totalMessages) {
    // Recent messages have higher weight
    if (totalMessages <= 1) return 1.0;

    final recencyFactor = 1.0 - (position / totalMessages);
    return 0.5 + (recencyFactor * 0.5);
  }
}
