// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  id: json['id'] as String,
  name: json['name'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  lastActive: DateTime.parse(json['lastActive'] as String),
  preferences: UserPreferences.fromJson(
    json['preferences'] as Map<String, dynamic>,
  ),
  deviceInfo: DeviceInfo.fromJson(json['deviceInfo'] as Map<String, dynamic>),
  behaviorPatterns: (json['behaviorPatterns'] as List<dynamic>)
      .map((e) => BehaviorPattern.fromJson(e as Map<String, dynamic>))
      .toList(),
  contextMemory: json['contextMemory'] as Map<String, dynamic>,
  frequentTopics: (json['frequentTopics'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  projectTimelines: (json['projectTimelines'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, DateTime.parse(e as String)),
  ),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActive': instance.lastActive.toIso8601String(),
      'preferences': instance.preferences,
      'deviceInfo': instance.deviceInfo,
      'behaviorPatterns': instance.behaviorPatterns,
      'contextMemory': instance.contextMemory,
      'frequentTopics': instance.frequentTopics,
      'projectTimelines': instance.projectTimelines.map(
        (k, e) => MapEntry(k, e.toIso8601String()),
      ),
    };

UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    UserPreferences(
      preferredLanguage: json['preferredLanguage'] as String,
      timeZone: json['timeZone'] as String,
      responseStyle: json['responseStyle'] as String,
      interests: (json['interests'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      personalizations: json['personalizations'] as Map<String, dynamic>,
      enableContextualReminders: json['enableContextualReminders'] as bool,
      enableIntentPrediction: json['enableIntentPrediction'] as bool,
      sessionTimeoutMinutes: (json['sessionTimeoutMinutes'] as num).toInt(),
    );

Map<String, dynamic> _$UserPreferencesToJson(UserPreferences instance) =>
    <String, dynamic>{
      'preferredLanguage': instance.preferredLanguage,
      'timeZone': instance.timeZone,
      'responseStyle': instance.responseStyle,
      'interests': instance.interests,
      'personalizations': instance.personalizations,
      'enableContextualReminders': instance.enableContextualReminders,
      'enableIntentPrediction': instance.enableIntentPrediction,
      'sessionTimeoutMinutes': instance.sessionTimeoutMinutes,
    };

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) => DeviceInfo(
  platform: json['platform'] as String,
  deviceModel: json['deviceModel'] as String,
  osVersion: json['osVersion'] as String,
  appVersion: json['appVersion'] as String,
  capabilities: (json['capabilities'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  specifications: json['specifications'] as Map<String, dynamic>,
  lastUpdated: DateTime.parse(json['lastUpdated'] as String),
);

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'platform': instance.platform,
      'deviceModel': instance.deviceModel,
      'osVersion': instance.osVersion,
      'appVersion': instance.appVersion,
      'capabilities': instance.capabilities,
      'specifications': instance.specifications,
      'lastUpdated': instance.lastUpdated.toIso8601String(),
    };

BehaviorPattern _$BehaviorPatternFromJson(Map<String, dynamic> json) =>
    BehaviorPattern(
      id: json['id'] as String,
      type: $enumDecode(_$BehaviorTypeEnumMap, json['type']),
      description: json['description'] as String,
      firstObserved: DateTime.parse(json['firstObserved'] as String),
      lastObserved: DateTime.parse(json['lastObserved'] as String),
      frequency: (json['frequency'] as num).toInt(),
      confidence: (json['confidence'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$BehaviorPatternToJson(BehaviorPattern instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$BehaviorTypeEnumMap[instance.type]!,
      'description': instance.description,
      'firstObserved': instance.firstObserved.toIso8601String(),
      'lastObserved': instance.lastObserved.toIso8601String(),
      'frequency': instance.frequency,
      'confidence': instance.confidence,
      'metadata': instance.metadata,
    };

const _$BehaviorTypeEnumMap = {
  BehaviorType.frequentQuestionPattern: 'frequentQuestionPattern',
  BehaviorType.imageAnalysisPreference: 'imageAnalysisPreference',
  BehaviorType.sessionTiming: 'sessionTiming',
  BehaviorType.topicInterest: 'topicInterest',
  BehaviorType.responsePreference: 'responsePreference',
  BehaviorType.contextSwitching: 'contextSwitching',
  BehaviorType.problemSolvingApproach: 'problemSolvingApproach',
  BehaviorType.helpSeekingPattern: 'helpSeekingPattern',
};
