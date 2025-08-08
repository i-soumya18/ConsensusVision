// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => ChatSession(
  id: json['id'] as String,
  title: json['title'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
  messageIds: (json['messageIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  messageCount: (json['messageCount'] as num).toInt(),
  defaultPrompt: json['defaultPrompt'] as String?,
);

Map<String, dynamic> _$ChatSessionToJson(ChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'messageIds': instance.messageIds,
      'messageCount': instance.messageCount,
      'defaultPrompt': instance.defaultPrompt,
    };
