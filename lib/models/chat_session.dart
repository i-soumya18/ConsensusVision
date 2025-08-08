import 'package:json_annotation/json_annotation.dart';

part 'chat_session.g.dart';

@JsonSerializable()
class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final List<String> messageIds;
  final int messageCount;
  final String? defaultPrompt;

  const ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastUpdated,
    required this.messageIds,
    required this.messageCount,
    this.defaultPrompt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) =>
      _$ChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);

  ChatSession copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    DateTime? lastUpdated,
    List<String>? messageIds,
    int? messageCount,
    String? defaultPrompt,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      messageIds: messageIds ?? this.messageIds,
      messageCount: messageCount ?? this.messageCount,
      defaultPrompt: defaultPrompt ?? this.defaultPrompt,
    );
  }
}
