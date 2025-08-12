// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  content: json['content'] as String,
  imagePaths: (json['imagePaths'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  timestamp: DateTime.parse(json['timestamp'] as String),
  type: $enumDecode(_$MessageTypeEnumMap, json['type']),
  status:
      $enumDecodeNullable(_$MessageStatusEnumMap, json['status']) ??
      MessageStatus.sent,
  aiModel: json['aiModel'] as String?,
  confidence: (json['confidence'] as num?)?.toDouble(),
  emotionalContext: json['emotionalContext'] == null
      ? null
      : EmotionalState.fromJson(
          json['emotionalContext'] as Map<String, dynamic>,
        ),
  responseTone: $enumDecodeNullable(
    _$ResponseToneEnumMap,
    json['responseTone'],
  ),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'imagePaths': instance.imagePaths,
  'timestamp': instance.timestamp.toIso8601String(),
  'type': _$MessageTypeEnumMap[instance.type]!,
  'status': _$MessageStatusEnumMap[instance.status]!,
  'aiModel': instance.aiModel,
  'confidence': instance.confidence,
  'emotionalContext': instance.emotionalContext,
  'responseTone': _$ResponseToneEnumMap[instance.responseTone],
};

const _$MessageTypeEnumMap = {
  MessageType.user: 'user',
  MessageType.ai: 'ai',
  MessageType.system: 'system',
};

const _$MessageStatusEnumMap = {
  MessageStatus.sending: 'sending',
  MessageStatus.sent: 'sent',
  MessageStatus.delivered: 'delivered',
  MessageStatus.error: 'error',
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
