import 'package:json_annotation/json_annotation.dart';

part 'conversation_context.g.dart';

@JsonSerializable()
class ConversationContext {
  final String id;
  final String sessionId;
  final DateTime timestamp;
  final List<String> activeTopics;
  final Map<String, dynamic> situationalContext;
  final EnvironmentalContext environmentalContext;
  final UserIntent currentIntent;
  final List<String> referencedEntities;
  final Map<String, dynamic> temporalContext;
  final double contextContinuityScore;

  const ConversationContext({
    required this.id,
    required this.sessionId,
    required this.timestamp,
    required this.activeTopics,
    required this.situationalContext,
    required this.environmentalContext,
    required this.currentIntent,
    required this.referencedEntities,
    required this.temporalContext,
    required this.contextContinuityScore,
  });

  factory ConversationContext.fromJson(Map<String, dynamic> json) =>
      _$ConversationContextFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationContextToJson(this);

  ConversationContext copyWith({
    String? id,
    String? sessionId,
    DateTime? timestamp,
    List<String>? activeTopics,
    Map<String, dynamic>? situationalContext,
    EnvironmentalContext? environmentalContext,
    UserIntent? currentIntent,
    List<String>? referencedEntities,
    Map<String, dynamic>? temporalContext,
    double? contextContinuityScore,
  }) {
    return ConversationContext(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      timestamp: timestamp ?? this.timestamp,
      activeTopics: activeTopics ?? this.activeTopics,
      situationalContext: situationalContext ?? this.situationalContext,
      environmentalContext: environmentalContext ?? this.environmentalContext,
      currentIntent: currentIntent ?? this.currentIntent,
      referencedEntities: referencedEntities ?? this.referencedEntities,
      temporalContext: temporalContext ?? this.temporalContext,
      contextContinuityScore:
          contextContinuityScore ?? this.contextContinuityScore,
    );
  }
}

@JsonSerializable()
class EnvironmentalContext {
  final String timeOfDay;
  final String dayOfWeek;
  final String userTimeZone;
  final String deviceType;
  final bool isFirstSessionToday;
  final Duration? timeSinceLastSession;
  final String currentActivity; // inferred from usage patterns
  final Map<String, dynamic> deviceCapabilities;

  const EnvironmentalContext({
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.userTimeZone,
    required this.deviceType,
    required this.isFirstSessionToday,
    this.timeSinceLastSession,
    required this.currentActivity,
    required this.deviceCapabilities,
  });

  factory EnvironmentalContext.fromJson(Map<String, dynamic> json) =>
      _$EnvironmentalContextFromJson(json);
  Map<String, dynamic> toJson() => _$EnvironmentalContextToJson(this);

  static EnvironmentalContext createCurrent({
    required String deviceType,
    required String userTimeZone,
    required Map<String, dynamic> deviceCapabilities,
    Duration? timeSinceLastSession,
    bool isFirstSessionToday = false,
  }) {
    final now = DateTime.now();
    return EnvironmentalContext(
      timeOfDay: _getTimeOfDay(now),
      dayOfWeek: _getDayOfWeek(now),
      userTimeZone: userTimeZone,
      deviceType: deviceType,
      isFirstSessionToday: isFirstSessionToday,
      timeSinceLastSession: timeSinceLastSession,
      currentActivity: _inferCurrentActivity(now, timeSinceLastSession),
      deviceCapabilities: deviceCapabilities,
    );
  }

  static String _getTimeOfDay(DateTime time) {
    final hour = time.hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  static String _getDayOfWeek(DateTime time) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[time.weekday - 1];
  }

  static String _inferCurrentActivity(
    DateTime time,
    Duration? timeSinceLastSession,
  ) {
    final hour = time.hour;
    final isWeekend = time.weekday >= 6;

    if (timeSinceLastSession != null && timeSinceLastSession.inMinutes < 5) {
      return 'continuation';
    }

    if (isWeekend) {
      if (hour >= 9 && hour <= 12) return 'leisure_morning';
      if (hour >= 13 && hour <= 17) return 'leisure_afternoon';
      return 'leisure_other';
    }

    if (hour >= 9 && hour <= 17) return 'work_hours';
    if (hour >= 18 && hour <= 22) return 'evening_personal';
    return 'off_hours';
  }
}

@JsonSerializable()
class UserIntent {
  final String id;
  final IntentType type;
  final double confidence;
  final String description;
  final List<String> parameters;
  final Map<String, dynamic> context;
  final DateTime inferredAt;
  final List<IntentType> alternativeIntents;

  const UserIntent({
    required this.id,
    required this.type,
    required this.confidence,
    required this.description,
    required this.parameters,
    required this.context,
    required this.inferredAt,
    required this.alternativeIntents,
  });

  factory UserIntent.fromJson(Map<String, dynamic> json) =>
      _$UserIntentFromJson(json);
  Map<String, dynamic> toJson() => _$UserIntentToJson(this);

  UserIntent copyWith({
    String? id,
    IntentType? type,
    double? confidence,
    String? description,
    List<String>? parameters,
    Map<String, dynamic>? context,
    DateTime? inferredAt,
    List<IntentType>? alternativeIntents,
  }) {
    return UserIntent(
      id: id ?? this.id,
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      parameters: parameters ?? this.parameters,
      context: context ?? this.context,
      inferredAt: inferredAt ?? this.inferredAt,
      alternativeIntents: alternativeIntents ?? this.alternativeIntents,
    );
  }
}

enum IntentType {
  imageAnalysis,
  questionAnswering,
  problemSolving,
  learning,
  troubleshooting,
  exploration,
  comparison,
  summarization,
  creative,
  planning,
  information,
  assistance,
  continuation,
  clarification,
}

extension IntentTypeExtension on IntentType {
  String get displayName {
    switch (this) {
      case IntentType.imageAnalysis:
        return 'Image Analysis';
      case IntentType.questionAnswering:
        return 'Question Answering';
      case IntentType.problemSolving:
        return 'Problem Solving';
      case IntentType.learning:
        return 'Learning';
      case IntentType.troubleshooting:
        return 'Troubleshooting';
      case IntentType.exploration:
        return 'Exploration';
      case IntentType.comparison:
        return 'Comparison';
      case IntentType.summarization:
        return 'Summarization';
      case IntentType.creative:
        return 'Creative';
      case IntentType.planning:
        return 'Planning';
      case IntentType.information:
        return 'Information';
      case IntentType.assistance:
        return 'Assistance';
      case IntentType.continuation:
        return 'Continuation';
      case IntentType.clarification:
        return 'Clarification';
    }
  }

  String get description {
    switch (this) {
      case IntentType.imageAnalysis:
        return 'User wants to analyze or understand images';
      case IntentType.questionAnswering:
        return 'User is asking direct questions';
      case IntentType.problemSolving:
        return 'User needs help solving a problem';
      case IntentType.learning:
        return 'User wants to learn something new';
      case IntentType.troubleshooting:
        return 'User is experiencing issues';
      case IntentType.exploration:
        return 'User is exploring topics or ideas';
      case IntentType.comparison:
        return 'User wants to compare options';
      case IntentType.summarization:
        return 'User wants a summary of information';
      case IntentType.creative:
        return 'User needs creative assistance';
      case IntentType.planning:
        return 'User is planning something';
      case IntentType.information:
        return 'User seeks specific information';
      case IntentType.assistance:
        return 'User needs general assistance';
      case IntentType.continuation:
        return 'User is continuing previous conversation';
      case IntentType.clarification:
        return 'User needs clarification';
    }
  }

  List<String> get typicalKeywords {
    switch (this) {
      case IntentType.imageAnalysis:
        return [
          'analyze',
          'image',
          'picture',
          'photo',
          'visual',
          'describe',
          'identify',
        ];
      case IntentType.questionAnswering:
        return ['what', 'how', 'why', 'when', 'where', 'who', 'which'];
      case IntentType.problemSolving:
        return ['solve', 'fix', 'issue', 'problem', 'error', 'help', 'stuck'];
      case IntentType.learning:
        return ['learn', 'understand', 'explain', 'teach', 'study', 'tutorial'];
      case IntentType.troubleshooting:
        return ['broken', 'not working', 'error', 'issue', 'debug', 'fix'];
      case IntentType.exploration:
        return ['explore', 'discover', 'find out', 'curious', 'investigate'];
      case IntentType.comparison:
        return ['compare', 'versus', 'vs', 'difference', 'better', 'choose'];
      case IntentType.summarization:
        return ['summarize', 'summary', 'overview', 'brief', 'recap'];
      case IntentType.creative:
        return [
          'create',
          'design',
          'brainstorm',
          'idea',
          'creative',
          'imagine',
        ];
      case IntentType.planning:
        return ['plan', 'organize', 'schedule', 'prepare', 'strategy'];
      case IntentType.information:
        return ['info', 'information', 'details', 'facts', 'data'];
      case IntentType.assistance:
        return ['help', 'assist', 'support', 'guide', 'aid'];
      case IntentType.continuation:
        return ['continue', 'also', 'and', 'next', 'further', 'more'];
      case IntentType.clarification:
        return ['clarify', 'explain', 'mean', 'confused', 'unclear'];
    }
  }
}
