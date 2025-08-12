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
