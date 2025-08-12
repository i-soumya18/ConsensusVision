import 'package:json_annotation/json_annotation.dart';
import 'emotional_state.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  final String content;
  final List<String> imagePaths;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final String? aiModel;
  final double? confidence;
  final EmotionalState?
  emotionalContext; // New field for emotional intelligence
  final ResponseTone? responseTone; // Tone used for AI responses

  const Message({
    required this.id,
    required this.content,
    required this.imagePaths,
    required this.timestamp,
    required this.type,
    this.status = MessageStatus.sent,
    this.aiModel,
    this.confidence,
    this.emotionalContext,
    this.responseTone,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);

  Message copyWith({
    String? id,
    String? content,
    List<String>? imagePaths,
    DateTime? timestamp,
    MessageType? type,
    MessageStatus? status,
    String? aiModel,
    double? confidence,
    EmotionalState? emotionalContext,
    ResponseTone? responseTone,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      status: status ?? this.status,
      aiModel: aiModel ?? this.aiModel,
      confidence: confidence ?? this.confidence,
      emotionalContext: emotionalContext ?? this.emotionalContext,
      responseTone: responseTone ?? this.responseTone,
    );
  }
}

enum MessageType { user, ai, system }

enum MessageStatus { sending, sent, delivered, error }
