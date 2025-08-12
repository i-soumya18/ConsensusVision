// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConversationContext _$ConversationContextFromJson(Map<String, dynamic> json) =>
    ConversationContext(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      activeTopics: (json['activeTopics'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      situationalContext: json['situationalContext'] as Map<String, dynamic>,
      environmentalContext: EnvironmentalContext.fromJson(
        json['environmentalContext'] as Map<String, dynamic>,
      ),
      currentIntent: UserIntent.fromJson(
        json['currentIntent'] as Map<String, dynamic>,
      ),
      referencedEntities: (json['referencedEntities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      temporalContext: json['temporalContext'] as Map<String, dynamic>,
      contextContinuityScore: (json['contextContinuityScore'] as num)
          .toDouble(),
    );

Map<String, dynamic> _$ConversationContextToJson(
  ConversationContext instance,
) => <String, dynamic>{
  'id': instance.id,
  'sessionId': instance.sessionId,
  'timestamp': instance.timestamp.toIso8601String(),
  'activeTopics': instance.activeTopics,
  'situationalContext': instance.situationalContext,
  'environmentalContext': instance.environmentalContext,
  'currentIntent': instance.currentIntent,
  'referencedEntities': instance.referencedEntities,
  'temporalContext': instance.temporalContext,
  'contextContinuityScore': instance.contextContinuityScore,
};

EnvironmentalContext _$EnvironmentalContextFromJson(
  Map<String, dynamic> json,
) => EnvironmentalContext(
  timeOfDay: json['timeOfDay'] as String,
  dayOfWeek: json['dayOfWeek'] as String,
  userTimeZone: json['userTimeZone'] as String,
  deviceType: json['deviceType'] as String,
  isFirstSessionToday: json['isFirstSessionToday'] as bool,
  timeSinceLastSession: json['timeSinceLastSession'] == null
      ? null
      : Duration(microseconds: (json['timeSinceLastSession'] as num).toInt()),
  currentActivity: json['currentActivity'] as String,
  deviceCapabilities: json['deviceCapabilities'] as Map<String, dynamic>,
);

Map<String, dynamic> _$EnvironmentalContextToJson(
  EnvironmentalContext instance,
) => <String, dynamic>{
  'timeOfDay': instance.timeOfDay,
  'dayOfWeek': instance.dayOfWeek,
  'userTimeZone': instance.userTimeZone,
  'deviceType': instance.deviceType,
  'isFirstSessionToday': instance.isFirstSessionToday,
  'timeSinceLastSession': instance.timeSinceLastSession?.inMicroseconds,
  'currentActivity': instance.currentActivity,
  'deviceCapabilities': instance.deviceCapabilities,
};

UserIntent _$UserIntentFromJson(Map<String, dynamic> json) => UserIntent(
  id: json['id'] as String,
  type: $enumDecode(_$IntentTypeEnumMap, json['type']),
  confidence: (json['confidence'] as num).toDouble(),
  description: json['description'] as String,
  parameters: (json['parameters'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  context: json['context'] as Map<String, dynamic>,
  inferredAt: DateTime.parse(json['inferredAt'] as String),
  alternativeIntents: (json['alternativeIntents'] as List<dynamic>)
      .map((e) => $enumDecode(_$IntentTypeEnumMap, e))
      .toList(),
);

Map<String, dynamic> _$UserIntentToJson(UserIntent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$IntentTypeEnumMap[instance.type]!,
      'confidence': instance.confidence,
      'description': instance.description,
      'parameters': instance.parameters,
      'context': instance.context,
      'inferredAt': instance.inferredAt.toIso8601String(),
      'alternativeIntents': instance.alternativeIntents
          .map((e) => _$IntentTypeEnumMap[e]!)
          .toList(),
    };

const _$IntentTypeEnumMap = {
  IntentType.imageAnalysis: 'imageAnalysis',
  IntentType.questionAnswering: 'questionAnswering',
  IntentType.problemSolving: 'problemSolving',
  IntentType.learning: 'learning',
  IntentType.troubleshooting: 'troubleshooting',
  IntentType.exploration: 'exploration',
  IntentType.comparison: 'comparison',
  IntentType.summarization: 'summarization',
  IntentType.creative: 'creative',
  IntentType.planning: 'planning',
  IntentType.information: 'information',
  IntentType.assistance: 'assistance',
  IntentType.continuation: 'continuation',
  IntentType.clarification: 'clarification',
};
