// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emotional_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmotionalState _$EmotionalStateFromJson(Map<String, dynamic> json) =>
    EmotionalState(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      sentiment: $enumDecode(_$SentimentTypeEnumMap, json['sentiment']),
      intensity: (json['intensity'] as num).toDouble(),
      emotions: (json['emotions'] as List<dynamic>)
          .map((e) => $enumDecode(_$EmotionTypeEnumMap, e))
          .toList(),
      context: json['context'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$EmotionalStateToJson(
  EmotionalState instance,
) => <String, dynamic>{
  'id': instance.id,
  'timestamp': instance.timestamp.toIso8601String(),
  'sentiment': _$SentimentTypeEnumMap[instance.sentiment]!,
  'intensity': instance.intensity,
  'emotions': instance.emotions.map((e) => _$EmotionTypeEnumMap[e]!).toList(),
  'context': instance.context,
  'metadata': instance.metadata,
};

const _$SentimentTypeEnumMap = {
  SentimentType.veryPositive: 'veryPositive',
  SentimentType.positive: 'positive',
  SentimentType.neutral: 'neutral',
  SentimentType.negative: 'negative',
  SentimentType.veryNegative: 'veryNegative',
};

const _$EmotionTypeEnumMap = {
  EmotionType.joy: 'joy',
  EmotionType.excitement: 'excitement',
  EmotionType.satisfaction: 'satisfaction',
  EmotionType.calm: 'calm',
  EmotionType.confusion: 'confusion',
  EmotionType.frustration: 'frustration',
  EmotionType.anger: 'anger',
  EmotionType.sadness: 'sadness',
  EmotionType.anxiety: 'anxiety',
  EmotionType.fear: 'fear',
  EmotionType.surprise: 'surprise',
  EmotionType.interest: 'interest',
  EmotionType.boredom: 'boredom',
  EmotionType.disappointment: 'disappointment',
};

UserEmotionalProfile _$UserEmotionalProfileFromJson(
  Map<String, dynamic> json,
) => UserEmotionalProfile(
  userId: json['userId'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  emotionalHistory: (json['emotionalHistory'] as List<dynamic>)
      .map((e) => EmotionalState.fromJson(e as Map<String, dynamic>))
      .toList(),
  sentimentFrequency: (json['sentimentFrequency'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$SentimentTypeEnumMap, k), (e as num).toInt()),
  ),
  emotionTrends: (json['emotionTrends'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$EmotionTypeEnumMap, k), (e as num).toDouble()),
  ),
  triggerPatterns: (json['triggerPatterns'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  averageIntensity: (json['averageIntensity'] as num).toDouble(),
);

Map<String, dynamic> _$UserEmotionalProfileToJson(
  UserEmotionalProfile instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'createdAt': instance.createdAt.toIso8601String(),
  'lastUpdated': instance.lastUpdated.toIso8601String(),
  'emotionalHistory': instance.emotionalHistory,
  'sentimentFrequency': instance.sentimentFrequency.map(
    (k, e) => MapEntry(_$SentimentTypeEnumMap[k]!, e),
  ),
  'emotionTrends': instance.emotionTrends.map(
    (k, e) => MapEntry(_$EmotionTypeEnumMap[k]!, e),
  ),
  'triggerPatterns': instance.triggerPatterns,
  'averageIntensity': instance.averageIntensity,
};

RealTimeEmotionalAnalysis _$RealTimeEmotionalAnalysisFromJson(
  Map<String, dynamic> json,
) => RealTimeEmotionalAnalysis(
  sessionId: json['sessionId'] as String,
  timestamp: DateTime.parse(json['timestamp'] as String),
  recentStates: (json['recentStates'] as List<dynamic>)
      .map((e) => EmotionalState.fromJson(e as Map<String, dynamic>))
      .toList(),
  trend: $enumDecode(_$EmotionalTrendEnumMap, json['trend']),
  confidence: (json['confidence'] as num).toDouble(),
  patterns: json['patterns'] as Map<String, dynamic>,
);

Map<String, dynamic> _$RealTimeEmotionalAnalysisToJson(
  RealTimeEmotionalAnalysis instance,
) => <String, dynamic>{
  'sessionId': instance.sessionId,
  'timestamp': instance.timestamp.toIso8601String(),
  'recentStates': instance.recentStates,
  'trend': _$EmotionalTrendEnumMap[instance.trend]!,
  'confidence': instance.confidence,
  'patterns': instance.patterns,
};

const _$EmotionalTrendEnumMap = {
  EmotionalTrend.improving: 'improving',
  EmotionalTrend.stable: 'stable',
  EmotionalTrend.declining: 'declining',
};

EnhancedEmotionalContext _$EnhancedEmotionalContextFromJson(
  Map<String, dynamic> json,
) => EnhancedEmotionalContext(
  primaryState: EmotionalState.fromJson(
    json['primaryState'] as Map<String, dynamic>,
  ),
  contextualStates: (json['contextualStates'] as List<dynamic>)
      .map((e) => EmotionalState.fromJson(e as Map<String, dynamic>))
      .toList(),
  recommendedTone: $enumDecode(_$ResponseToneEnumMap, json['recommendedTone']),
  voiceToneAnalysis: json['voiceToneAnalysis'] as Map<String, dynamic>,
  patternAnalysis: json['patternAnalysis'] as Map<String, dynamic>,
  emotionalComplexity: (json['emotionalComplexity'] as num).toDouble(),
);

Map<String, dynamic> _$EnhancedEmotionalContextToJson(
  EnhancedEmotionalContext instance,
) => <String, dynamic>{
  'primaryState': instance.primaryState,
  'contextualStates': instance.contextualStates,
  'recommendedTone': _$ResponseToneEnumMap[instance.recommendedTone]!,
  'voiceToneAnalysis': instance.voiceToneAnalysis,
  'patternAnalysis': instance.patternAnalysis,
  'emotionalComplexity': instance.emotionalComplexity,
};

const _$ResponseToneEnumMap = {
  ResponseTone.supportive: 'supportive',
  ResponseTone.encouraging: 'encouraging',
  ResponseTone.celebratory: 'celebratory',
  ResponseTone.reassuring: 'reassuring',
  ResponseTone.patient: 'patient',
  ResponseTone.empathetic: 'empathetic',
  ResponseTone.professional: 'professional',
  ResponseTone.casual: 'casual',
  ResponseTone.enthusiastic: 'enthusiastic',
  ResponseTone.gentle: 'gentle',
};
