import 'package:json_annotation/json_annotation.dart';

part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastActive;
  final UserPreferences preferences;
  final DeviceInfo deviceInfo;
  final List<BehaviorPattern> behaviorPatterns;
  final Map<String, dynamic> contextMemory;
  final List<String> frequentTopics;
  final Map<String, DateTime> projectTimelines;

  const UserProfile({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastActive,
    required this.preferences,
    required this.deviceInfo,
    required this.behaviorPatterns,
    required this.contextMemory,
    required this.frequentTopics,
    required this.projectTimelines,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastActive,
    UserPreferences? preferences,
    DeviceInfo? deviceInfo,
    List<BehaviorPattern>? behaviorPatterns,
    Map<String, dynamic>? contextMemory,
    List<String>? frequentTopics,
    Map<String, DateTime>? projectTimelines,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      preferences: preferences ?? this.preferences,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      behaviorPatterns: behaviorPatterns ?? this.behaviorPatterns,
      contextMemory: contextMemory ?? this.contextMemory,
      frequentTopics: frequentTopics ?? this.frequentTopics,
      projectTimelines: projectTimelines ?? this.projectTimelines,
    );
  }
}

@JsonSerializable()
class UserPreferences {
  final String preferredLanguage;
  final String timeZone;
  final String responseStyle; // concise, detailed, conversational
  final List<String> interests;
  final Map<String, dynamic> personalizations;
  final bool enableContextualReminders;
  final bool enableIntentPrediction;
  final int sessionTimeoutMinutes;

  const UserPreferences({
    required this.preferredLanguage,
    required this.timeZone,
    required this.responseStyle,
    required this.interests,
    required this.personalizations,
    required this.enableContextualReminders,
    required this.enableIntentPrediction,
    required this.sessionTimeoutMinutes,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
  Map<String, dynamic> toJson() => _$UserPreferencesToJson(this);

  static UserPreferences get defaultPreferences => UserPreferences(
    preferredLanguage: 'en',
    timeZone: DateTime.now().timeZoneName,
    responseStyle: 'conversational',
    interests: [],
    personalizations: {},
    enableContextualReminders: true,
    enableIntentPrediction: true,
    sessionTimeoutMinutes: 30,
  );

  UserPreferences copyWith({
    String? preferredLanguage,
    String? timeZone,
    String? responseStyle,
    List<String>? interests,
    Map<String, dynamic>? personalizations,
    bool? enableContextualReminders,
    bool? enableIntentPrediction,
    int? sessionTimeoutMinutes,
  }) {
    return UserPreferences(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      timeZone: timeZone ?? this.timeZone,
      responseStyle: responseStyle ?? this.responseStyle,
      interests: interests ?? this.interests,
      personalizations: personalizations ?? this.personalizations,
      enableContextualReminders:
          enableContextualReminders ?? this.enableContextualReminders,
      enableIntentPrediction:
          enableIntentPrediction ?? this.enableIntentPrediction,
      sessionTimeoutMinutes:
          sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
    );
  }
}

@JsonSerializable()
class DeviceInfo {
  final String platform; // Windows, Android, iOS, etc.
  final String deviceModel;
  final String osVersion;
  final String appVersion;
  final List<String> capabilities;
  final Map<String, dynamic> specifications;
  final DateTime lastUpdated;

  const DeviceInfo({
    required this.platform,
    required this.deviceModel,
    required this.osVersion,
    required this.appVersion,
    required this.capabilities,
    required this.specifications,
    required this.lastUpdated,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);
  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  DeviceInfo copyWith({
    String? platform,
    String? deviceModel,
    String? osVersion,
    String? appVersion,
    List<String>? capabilities,
    Map<String, dynamic>? specifications,
    DateTime? lastUpdated,
  }) {
    return DeviceInfo(
      platform: platform ?? this.platform,
      deviceModel: deviceModel ?? this.deviceModel,
      osVersion: osVersion ?? this.osVersion,
      appVersion: appVersion ?? this.appVersion,
      capabilities: capabilities ?? this.capabilities,
      specifications: specifications ?? this.specifications,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

@JsonSerializable()
class BehaviorPattern {
  final String id;
  final BehaviorType type;
  final String description;
  final DateTime firstObserved;
  final DateTime lastObserved;
  final int frequency;
  final double confidence;
  final Map<String, dynamic> metadata;

  const BehaviorPattern({
    required this.id,
    required this.type,
    required this.description,
    required this.firstObserved,
    required this.lastObserved,
    required this.frequency,
    required this.confidence,
    required this.metadata,
  });

  factory BehaviorPattern.fromJson(Map<String, dynamic> json) =>
      _$BehaviorPatternFromJson(json);
  Map<String, dynamic> toJson() => _$BehaviorPatternToJson(this);

  BehaviorPattern copyWith({
    String? id,
    BehaviorType? type,
    String? description,
    DateTime? firstObserved,
    DateTime? lastObserved,
    int? frequency,
    double? confidence,
    Map<String, dynamic>? metadata,
  }) {
    return BehaviorPattern(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      firstObserved: firstObserved ?? this.firstObserved,
      lastObserved: lastObserved ?? this.lastObserved,
      frequency: frequency ?? this.frequency,
      confidence: confidence ?? this.confidence,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum BehaviorType {
  frequentQuestionPattern,
  imageAnalysisPreference,
  sessionTiming,
  topicInterest,
  responsePreference,
  contextSwitching,
  problemSolvingApproach,
  helpSeekingPattern,
}

extension BehaviorTypeExtension on BehaviorType {
  String get displayName {
    switch (this) {
      case BehaviorType.frequentQuestionPattern:
        return 'Frequent Question Pattern';
      case BehaviorType.imageAnalysisPreference:
        return 'Image Analysis Preference';
      case BehaviorType.sessionTiming:
        return 'Session Timing';
      case BehaviorType.topicInterest:
        return 'Topic Interest';
      case BehaviorType.responsePreference:
        return 'Response Preference';
      case BehaviorType.contextSwitching:
        return 'Context Switching';
      case BehaviorType.problemSolvingApproach:
        return 'Problem Solving Approach';
      case BehaviorType.helpSeekingPattern:
        return 'Help Seeking Pattern';
    }
  }

  String get description {
    switch (this) {
      case BehaviorType.frequentQuestionPattern:
        return 'Patterns in the types of questions frequently asked';
      case BehaviorType.imageAnalysisPreference:
        return 'Preferences for how images should be analyzed';
      case BehaviorType.sessionTiming:
        return 'Timing patterns for chat sessions';
      case BehaviorType.topicInterest:
        return 'Interest levels in different topics';
      case BehaviorType.responsePreference:
        return 'Preferred response formats and styles';
      case BehaviorType.contextSwitching:
        return 'How user switches between different contexts';
      case BehaviorType.problemSolvingApproach:
        return 'Approach to problem-solving tasks';
      case BehaviorType.helpSeekingPattern:
        return 'Patterns in seeking help and guidance';
    }
  }
}
