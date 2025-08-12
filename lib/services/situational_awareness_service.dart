import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../models/conversation_context.dart';
import 'persistent_memory_service.dart';

/// Advanced situational awareness service that understands user's current context
/// Implements environmental awareness, device capabilities detection, and contextual adaptation
class SituationalAwarenessService {
  static SituationalAwarenessService? _instance;
  late PersistentMemoryService _memoryService;
  DeviceInfo? _currentDeviceInfo;
  EnvironmentalContext? _currentEnvironmentalContext;
  String? _currentUserId;

  SituationalAwarenessService._();

  static SituationalAwarenessService get instance {
    _instance ??= SituationalAwarenessService._();
    return _instance!;
  }

  /// Initialize situational awareness
  Future<void> initialize(String userId) async {
    try {
      _currentUserId = userId;
      _memoryService = PersistentMemoryService.instance;
      await _detectDeviceCapabilities();
      await _updateEnvironmentalContext();
      
      if (kDebugMode) {
        print('Situational Awareness Service initialized for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Situational Awareness Service: $e');
      }
    }
  }

  /// Detect comprehensive device capabilities and information
  Future<void> _detectDeviceCapabilities() async {
    try {
      Map<String, dynamic> deviceData = {};
      List<String> capabilities = [];
      String platform = 'unknown';
      String deviceModel = 'unknown';
      String osVersion = 'unknown';

      if (Platform.isWindows) {
        platform = 'Windows';
        deviceModel = Platform.localHostname;
        osVersion = Platform.operatingSystemVersion;
        
        deviceData = {
          'hostname': Platform.localHostname,
          'operating_system': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'number_of_processors': Platform.numberOfProcessors,
          'path_separator': Platform.pathSeparator,
          'dart_version': Platform.version,
        };

        capabilities.addAll([
          'file_system_access',
          'multi_window',
          'desktop_notifications',
          'system_tray',
          'clipboard_access',
          'drag_drop',
          'keyboard_shortcuts',
          'right_click_context',
        ]);

        if (Platform.numberOfProcessors > 4) capabilities.add('high_performance');
        
      } else if (Platform.isAndroid) {
        platform = 'Android';
        deviceModel = 'Android Device';
        osVersion = Platform.operatingSystemVersion;
        
        deviceData = {
          'operating_system': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'number_of_processors': Platform.numberOfProcessors,
          'dart_version': Platform.version,
        };

        capabilities.addAll([
          'touch_interface',
          'camera',
          'microphone',
          'gps_location',
          'accelerometer',
          'gyroscope',
          'notifications',
          'background_processing',
          'share_functionality',
        ]);
        
      } else if (Platform.isIOS) {
        platform = 'iOS';
        deviceModel = 'iOS Device';
        osVersion = Platform.operatingSystemVersion;
        
        deviceData = {
          'operating_system': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'number_of_processors': Platform.numberOfProcessors,
          'dart_version': Platform.version,
        };

        capabilities.addAll([
          'touch_interface',
          'camera',
          'microphone',
          'gps_location',
          'accelerometer',
          'gyroscope',
          'notifications',
          'background_processing',
          'share_functionality',
          'biometric_auth',
        ]);
        
      } else if (Platform.isMacOS) {
        platform = 'macOS';
        deviceModel = Platform.localHostname;
        osVersion = Platform.operatingSystemVersion;
        
        deviceData = {
          'hostname': Platform.localHostname,
          'operating_system': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'number_of_processors': Platform.numberOfProcessors,
          'dart_version': Platform.version,
        };

        capabilities.addAll([
          'file_system_access',
          'multi_window',
          'desktop_notifications',
          'menu_bar',
          'clipboard_access',
          'drag_drop',
          'keyboard_shortcuts',
          'right_click_context',
          'spotlight_integration',
        ]);
      } else if (Platform.isLinux) {
        platform = 'Linux';
        deviceModel = Platform.localHostname;
        osVersion = Platform.operatingSystemVersion;
        
        deviceData = {
          'hostname': Platform.localHostname,
          'operating_system': Platform.operatingSystem,
          'os_version': Platform.operatingSystemVersion,
          'number_of_processors': Platform.numberOfProcessors,
          'dart_version': Platform.version,
        };

        capabilities.addAll([
          'file_system_access',
          'multi_window',
          'desktop_notifications',
          'clipboard_access',
          'drag_drop',
          'keyboard_shortcuts',
          'terminal_access',
          'package_management',
        ]);
      }

      // Add common capabilities
      capabilities.addAll([
        'text_input',
        'image_display',
        'file_upload',
        'data_export',
        'network_access',
        'local_storage',
      ]);

      // Get app version
      String appVersion = '1.0.0'; // Default, could be retrieved from package info
      
      _currentDeviceInfo = DeviceInfo(
        platform: platform,
        deviceModel: deviceModel,
        osVersion: osVersion,
        appVersion: appVersion,
        capabilities: capabilities,
        specifications: deviceData,
        lastUpdated: DateTime.now(),
      );

      if (kDebugMode) {
        print('Device capabilities detected: ${capabilities.length} capabilities');
        print('Platform: $platform, Model: $deviceModel, OS: $osVersion');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error detecting device capabilities: $e');
      }
      
      // Fallback device info
      _currentDeviceInfo = DeviceInfo(
        platform: Platform.operatingSystem,
        deviceModel: 'Unknown',
        osVersion: 'Unknown',
        appVersion: '1.0.0',
        capabilities: ['text_input', 'image_display', 'network_access'],
        specifications: {},
        lastUpdated: DateTime.now(),
      );
    }
  }

  /// Update environmental context based on current situation
  Future<void> _updateEnvironmentalContext() async {
    if (_currentDeviceInfo == null || _currentUserId == null) return;

    try {
      // Get user's timezone preference or detect system timezone
      String userTimeZone = DateTime.now().timeZoneName; // Fallback to system timezone
      
      // Check if this is the first session today
      final lastSessionTime = await _getLastSessionTime();
      final now = DateTime.now();
      final isFirstSessionToday = lastSessionTime == null || 
          !_isSameDay(lastSessionTime, now);
      
      // Calculate time since last session
      Duration? timeSinceLastSession;
      if (lastSessionTime != null) {
        timeSinceLastSession = now.difference(lastSessionTime);
      }

      _currentEnvironmentalContext = EnvironmentalContext.createCurrent(
        deviceType: _currentDeviceInfo!.platform,
        userTimeZone: userTimeZone,
        deviceCapabilities: _currentDeviceInfo!.specifications,
        timeSinceLastSession: timeSinceLastSession,
        isFirstSessionToday: isFirstSessionToday,
      );

      // Store environmental context for future reference
      await _memoryService.storeContextMemory(
        userId: _currentUserId!,
        contextKey: 'environmental_context',
        contextValue: _currentEnvironmentalContext!.toJson().toString(),
        contextType: 'environmental',
        importanceScore: 0.7,
      );

      if (kDebugMode) {
        print('Environmental context updated: ${_currentEnvironmentalContext!.timeOfDay} on ${_currentEnvironmentalContext!.dayOfWeek}');
        print('Current activity: ${_currentEnvironmentalContext!.currentActivity}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Error updating environmental context: $e');
      }
    }
  }

  /// Get the last session time from memory
  Future<DateTime?> _getLastSessionTime() async {
    try {
      final lastSessionData = await _memoryService.getContextMemory(_currentUserId!, 'last_session_time');
      if (lastSessionData != null) {
        return DateTime.parse(lastSessionData['context_value']);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting last session time: $e');
      }
    }
    return null;
  }

  /// Check if two dates are on the same day
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && 
           date1.month == date2.month && 
           date1.day == date2.day;
  }

  /// Update session start time
  Future<void> updateSessionStartTime() async {
    if (_currentUserId == null) return;
    
    await _memoryService.storeContextMemory(
      userId: _currentUserId!,
      contextKey: 'last_session_time',
      contextValue: DateTime.now().toIso8601String(),
      contextType: 'session_timing',
      importanceScore: 0.5,
    );
  }

  /// Get current device information
  DeviceInfo? get currentDeviceInfo => _currentDeviceInfo;

  /// Get current environmental context
  EnvironmentalContext? get currentEnvironmentalContext => _currentEnvironmentalContext;

  /// Check if device has specific capability
  bool hasCapability(String capability) {
    return _currentDeviceInfo?.capabilities.contains(capability) ?? false;
  }

  /// Get contextual greeting based on time and situation
  String getContextualGreeting() {
    if (_currentEnvironmentalContext == null) return 'Hello!';
    
    final timeOfDay = _currentEnvironmentalContext!.timeOfDay;
    final isFirstToday = _currentEnvironmentalContext!.isFirstSessionToday;
    final timeSinceLastSession = _currentEnvironmentalContext!.timeSinceLastSession;
    
    String greeting = '';
    
    // Time-based greeting
    switch (timeOfDay) {
      case 'morning':
        greeting = isFirstToday ? 'Good morning!' : 'Welcome back this morning!';
        break;
      case 'afternoon':
        greeting = isFirstToday ? 'Good afternoon!' : 'Welcome back this afternoon!';
        break;
      case 'evening':
        greeting = isFirstToday ? 'Good evening!' : 'Welcome back this evening!';
        break;
      case 'night':
        greeting = isFirstToday ? 'Working late tonight?' : 'Welcome back tonight!';
        break;
      default:
        greeting = 'Hello!';
    }
    
    // Add continuity context
    if (timeSinceLastSession != null) {
      if (timeSinceLastSession.inMinutes < 5) {
        greeting += ' Ready to continue where we left off?';
      } else if (timeSinceLastSession.inHours < 1) {
        greeting += ' I remember our recent conversation.';
      } else if (timeSinceLastSession.inDays < 1) {
        greeting += ' How has your day been going?';
      }
    }
    
    return greeting;
  }

  /// Get device-specific recommendations
  List<String> getDeviceSpecificRecommendations() {
    if (_currentDeviceInfo == null) return [];
    
    List<String> recommendations = [];
    
    // Platform-specific recommendations
    switch (_currentDeviceInfo!.platform.toLowerCase()) {
      case 'windows':
        recommendations.addAll([
          'Use keyboard shortcuts for faster navigation',
          'Right-click for context menus',
          'Drag and drop files for easy uploads',
          'Use multiple windows for better workflow',
        ]);
        break;
      case 'android':
        recommendations.addAll([
          'Use touch gestures for navigation',
          'Take photos directly with your camera',
          'Share content with other apps',
          'Use voice input when available',
        ]);
        break;
      case 'ios':
        recommendations.addAll([
          'Use touch gestures for navigation',
          'Take advantage of camera integration',
          'Share content using the share sheet',
          'Use Siri for voice commands',
        ]);
        break;
      case 'macos':
        recommendations.addAll([
          'Use keyboard shortcuts and trackpad gestures',
          'Drag files from Finder',
          'Use the menu bar for quick access',
          'Take advantage of Spotlight search',
        ]);
        break;
      case 'linux':
        recommendations.addAll([
          'Use keyboard shortcuts for efficiency',
          'Access terminal integration when needed',
          'Utilize package management features',
          'Customize your workflow',
        ]);
        break;
    }
    
    // Capability-based recommendations
    if (hasCapability('camera')) {
      recommendations.add('You can directly capture images for analysis');
    }
    if (hasCapability('high_performance')) {
      recommendations.add('Your device can handle complex image processing');
    }
    if (hasCapability('high_memory')) {
      recommendations.add('Large images and documents can be processed efficiently');
    }
    if (hasCapability('gps_location')) {
      recommendations.add('Location-based features are available');
    }
    
    return recommendations;
  }

  /// Get optimal response format based on device capabilities
  Map<String, dynamic> getOptimalResponseFormat() {
    if (_currentDeviceInfo == null) return {'format': 'text'};
    
    Map<String, dynamic> format = {
      'format': 'text',
      'max_length': 'medium',
      'include_formatting': true,
      'include_emojis': false,
      'preferred_media': [],
    };
    
    // Adjust based on platform
    switch (_currentDeviceInfo!.platform.toLowerCase()) {
      case 'windows':
      case 'macos':
      case 'linux':
        format['max_length'] = 'long';
        format['include_formatting'] = true;
        format['preferred_media'] = ['images', 'documents'];
        break;
      case 'android':
      case 'ios':
        format['max_length'] = 'medium';
        format['include_emojis'] = true;
        format['preferred_media'] = ['images'];
        break;
    }
    
    // Adjust based on current activity
    if (_currentEnvironmentalContext != null) {
      switch (_currentEnvironmentalContext!.currentActivity) {
        case 'work_hours':
          format['max_length'] = 'medium';
          format['include_emojis'] = false;
          break;
        case 'leisure_morning':
        case 'leisure_afternoon':
          format['include_emojis'] = true;
          format['max_length'] = 'long';
          break;
        case 'continuation':
          format['max_length'] = 'short';
          break;
      }
    }
    
    return format;
  }

  /// Create comprehensive conversation context
  Future<ConversationContext> createConversationContext({
    required String sessionId,
    required List<String> activeTopics,
    Map<String, dynamic> situationalContext = const {},
    UserIntent? currentIntent,
    List<String> referencedEntities = const [],
    Map<String, dynamic> temporalContext = const {},
  }) async {
    await _updateEnvironmentalContext(); // Ensure latest context
    
    return ConversationContext(
      id: 'ctx_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: sessionId,
      timestamp: DateTime.now(),
      activeTopics: activeTopics,
      situationalContext: {
        ...situationalContext,
        'device_platform': _currentDeviceInfo?.platform,
        'capabilities': _currentDeviceInfo?.capabilities,
        'user_timezone': _currentEnvironmentalContext?.userTimeZone,
        'session_activity': _currentEnvironmentalContext?.currentActivity,
      },
      environmentalContext: _currentEnvironmentalContext ?? EnvironmentalContext.createCurrent(
        deviceType: _currentDeviceInfo?.platform ?? 'unknown',
        userTimeZone: DateTime.now().timeZoneName,
        deviceCapabilities: {},
      ),
      currentIntent: currentIntent ?? UserIntent(
        id: 'intent_unknown',
        type: IntentType.assistance,
        confidence: 0.5,
        description: 'General assistance',
        parameters: [],
        context: {},
        inferredAt: DateTime.now(),
        alternativeIntents: [],
      ),
      referencedEntities: referencedEntities,
      temporalContext: {
        ...temporalContext,
        'session_start_time': DateTime.now().toIso8601String(),
        'time_of_day': _currentEnvironmentalContext?.timeOfDay,
        'day_of_week': _currentEnvironmentalContext?.dayOfWeek,
      },
      contextContinuityScore: await _calculateContextContinuityScore(sessionId),
    );
  }

  /// Calculate context continuity score
  Future<double> _calculateContextContinuityScore(String sessionId) async {
    if (_currentUserId == null) return 0.5;
    
    try {
      // Check for session continuity
      final continuity = await _memoryService.getSessionContinuity(_currentUserId!, sessionId);
      if (continuity != null) {
        return continuity['continuity_score'] as double;
      }
      
      // Check recent topic memory
      final topicMemory = await _memoryService.getTopicMemory(_currentUserId!, limit: 10);
      if (topicMemory.isNotEmpty) {
        final recentTopics = topicMemory.where((topic) {
          final lastDiscussed = topic['last_discussed'] as DateTime;
          return DateTime.now().difference(lastDiscussed).inHours < 24;
        }).length;
        
        return (recentTopics / 10.0).clamp(0.0, 1.0);
      }
      
      return 0.5; // Default score
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating context continuity score: $e');
      }
      return 0.5;
    }
  }

  /// Get situational awareness summary
  Map<String, dynamic> getSituationalSummary() {
    return {
      'device_info': _currentDeviceInfo?.toJson(),
      'environmental_context': _currentEnvironmentalContext?.toJson(),
      'current_capabilities': _currentDeviceInfo?.capabilities ?? [],
      'contextual_greeting': getContextualGreeting(),
      'device_recommendations': getDeviceSpecificRecommendations(),
      'optimal_response_format': getOptimalResponseFormat(),
      'awareness_health': _currentDeviceInfo != null && _currentEnvironmentalContext != null,
    };
  }
}
