import 'package:json_annotation/json_annotation.dart';

part 'emotional_state.g.dart';

@JsonSerializable()
class EmotionalState {
  final String id;
  final DateTime timestamp;
  final SentimentType sentiment;
  final double intensity; // 0.0 to 1.0
  final List<EmotionType> emotions;
  final String? context; // What triggered this emotional state
  final Map<String, dynamic>? metadata;

  const EmotionalState({
    required this.id,
    required this.timestamp,
    required this.sentiment,
    required this.intensity,
    required this.emotions,
    this.context,
    this.metadata,
  });

  factory EmotionalState.fromJson(Map<String, dynamic> json) =>
      _$EmotionalStateFromJson(json);
  Map<String, dynamic> toJson() => _$EmotionalStateToJson(this);

  EmotionalState copyWith({
    String? id,
    DateTime? timestamp,
    SentimentType? sentiment,
    double? intensity,
    List<EmotionType>? emotions,
    String? context,
    Map<String, dynamic>? metadata,
  }) {
    return EmotionalState(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      sentiment: sentiment ?? this.sentiment,
      intensity: intensity ?? this.intensity,
      emotions: emotions ?? this.emotions,
      context: context ?? this.context,
      metadata: metadata ?? this.metadata,
    );
  }
}

@JsonSerializable()
class UserEmotionalProfile {
  final String userId;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<EmotionalState> emotionalHistory;
  final Map<SentimentType, int> sentimentFrequency;
  final Map<EmotionType, double> emotionTrends;
  final List<String> triggerPatterns;
  final double averageIntensity;

  const UserEmotionalProfile({
    required this.userId,
    required this.createdAt,
    required this.lastUpdated,
    required this.emotionalHistory,
    required this.sentimentFrequency,
    required this.emotionTrends,
    required this.triggerPatterns,
    required this.averageIntensity,
  });

  factory UserEmotionalProfile.fromJson(Map<String, dynamic> json) =>
      _$UserEmotionalProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserEmotionalProfileToJson(this);

  UserEmotionalProfile copyWith({
    String? userId,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<EmotionalState>? emotionalHistory,
    Map<SentimentType, int>? sentimentFrequency,
    Map<EmotionType, double>? emotionTrends,
    List<String>? triggerPatterns,
    double? averageIntensity,
  }) {
    return UserEmotionalProfile(
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      emotionalHistory: emotionalHistory ?? this.emotionalHistory,
      sentimentFrequency: sentimentFrequency ?? this.sentimentFrequency,
      emotionTrends: emotionTrends ?? this.emotionTrends,
      triggerPatterns: triggerPatterns ?? this.triggerPatterns,
      averageIntensity: averageIntensity ?? this.averageIntensity,
    );
  }
}

enum SentimentType { veryPositive, positive, neutral, negative, veryNegative }

enum EmotionType {
  joy,
  excitement,
  satisfaction,
  calm,
  confusion,
  frustration,
  anger,
  sadness,
  anxiety,
  fear,
  surprise,
  interest,
  boredom,
  disappointment,
}

enum ResponseTone {
  supportive,
  encouraging,
  celebratory,
  reassuring,
  patient,
  empathetic,
  professional,
  casual,
  enthusiastic,
  gentle,
}

extension SentimentTypeExtension on SentimentType {
  String get displayName {
    switch (this) {
      case SentimentType.veryPositive:
        return 'Very Positive';
      case SentimentType.positive:
        return 'Positive';
      case SentimentType.neutral:
        return 'Neutral';
      case SentimentType.negative:
        return 'Negative';
      case SentimentType.veryNegative:
        return 'Very Negative';
    }
  }

  double get score {
    switch (this) {
      case SentimentType.veryPositive:
        return 1.0;
      case SentimentType.positive:
        return 0.5;
      case SentimentType.neutral:
        return 0.0;
      case SentimentType.negative:
        return -0.5;
      case SentimentType.veryNegative:
        return -1.0;
    }
  }
}

extension EmotionTypeExtension on EmotionType {
  String get displayName {
    switch (this) {
      case EmotionType.joy:
        return 'Joy';
      case EmotionType.excitement:
        return 'Excitement';
      case EmotionType.satisfaction:
        return 'Satisfaction';
      case EmotionType.calm:
        return 'Calm';
      case EmotionType.confusion:
        return 'Confusion';
      case EmotionType.frustration:
        return 'Frustration';
      case EmotionType.anger:
        return 'Anger';
      case EmotionType.sadness:
        return 'Sadness';
      case EmotionType.anxiety:
        return 'Anxiety';
      case EmotionType.fear:
        return 'Fear';
      case EmotionType.surprise:
        return 'Surprise';
      case EmotionType.interest:
        return 'Interest';
      case EmotionType.boredom:
        return 'Boredom';
      case EmotionType.disappointment:
        return 'Disappointment';
    }
  }

  bool get isPositive {
    switch (this) {
      case EmotionType.joy:
      case EmotionType.excitement:
      case EmotionType.satisfaction:
      case EmotionType.calm:
      case EmotionType.surprise:
      case EmotionType.interest:
        return true;
      default:
        return false;
    }
  }
}

extension ResponseToneExtension on ResponseTone {
  String get displayName {
    switch (this) {
      case ResponseTone.supportive:
        return 'Supportive';
      case ResponseTone.encouraging:
        return 'Encouraging';
      case ResponseTone.celebratory:
        return 'Celebratory';
      case ResponseTone.reassuring:
        return 'Reassuring';
      case ResponseTone.patient:
        return 'Patient';
      case ResponseTone.empathetic:
        return 'Empathetic';
      case ResponseTone.professional:
        return 'Professional';
      case ResponseTone.casual:
        return 'Casual';
      case ResponseTone.enthusiastic:
        return 'Enthusiastic';
      case ResponseTone.gentle:
        return 'Gentle';
    }
  }
}
