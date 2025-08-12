import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/user_profile.dart';
import '../models/conversation_context.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../models/emotional_state.dart';
import '../models/ai_response.dart';
import '../services/persistent_memory_service.dart';
import '../services/situational_awareness_service.dart';
import '../services/intent_prediction_service.dart';
import '../services/database_service.dart';
import '../services/emotional_memory_service.dart';
import '../services/ai_evaluation_service.dart';
import '../services/sentiment_analysis_service.dart';
import '../services/context_management_service.dart';

/// Enhanced chat provider with true context awareness and memory capabilities
/// Integrates persistent memory, situational awareness, and intent prediction
class ContextAwareChatProvider extends ChangeNotifier {
  final PersistentMemoryService _memoryService =
      PersistentMemoryService.instance;
  final SituationalAwarenessService _awarenessService =
      SituationalAwarenessService.instance;
  final IntentPredictionService _intentService =
      IntentPredictionService.instance;
  late EmotionalMemoryService _emotionalMemoryService;
  final AIEvaluationService _aiEvaluationService;
  final Uuid _uuid = const Uuid();

  ContextAwareChatProvider({
    required String geminiApiKey,
    required String huggingFaceApiKey,
  }) : _aiEvaluationService = AIEvaluationService(
         geminiApiKey: geminiApiKey,
         huggingFaceApiKey: huggingFaceApiKey,
       );

  // User and session management
  UserProfile? _currentUser;
  ChatSession? _currentSession;
  List<Message> _currentMessages = [];
  List<ChatSession> _chatSessions = [];
  ConversationContext? _currentContext;

  // State management
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  String? _currentUserId;

  // Context awareness features
  bool _enableContextAwareness = true;
  bool _enableIntentPrediction = true;
  bool _enableSituationalAwareness = true;
  bool _enableEmotionalIntelligence = true;

  // Getters
  UserProfile? get currentUser => _currentUser;
  ChatSession? get currentSession => _currentSession;
  List<Message> get currentMessages => List.unmodifiable(_currentMessages);
  List<ChatSession> get chatSessions => List.unmodifiable(_chatSessions);
  ConversationContext? get currentContext => _currentContext;
  String? get currentSessionDefaultPrompt => _currentSession?.defaultPrompt;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get emotionalIntelligenceEnabled => _enableEmotionalIntelligence;
  bool get enableContextAwareness => _enableContextAwareness;
  bool get enableIntentPrediction => _enableIntentPrediction;
  bool get enableSituationalAwareness => _enableSituationalAwareness;
  bool get enableEmotionalIntelligence => _enableEmotionalIntelligence;

  /// Initialize the context-aware chat provider
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      _clearError();

      // Generate or use provided user ID
      _currentUserId = userId ?? _uuid.v4();

      // Initialize core services
      await _memoryService.initialize();
      await _awarenessService.initialize(_currentUserId!);
      await _intentService.initialize(_currentUserId!);
      _emotionalMemoryService = EmotionalMemoryService();
      await _emotionalMemoryService.initialize();

      // Load or create user profile
      await _initializeUserProfile();

      // Load chat sessions
      await _loadChatSessions();

      // Update session start time for situational awareness
      await _awarenessService.updateSessionStartTime();

      _isInitialized = true;

      if (kDebugMode) {
        print(
          'Context-Aware Chat Provider initialized for user: $_currentUserId',
        );
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to initialize chat provider: $e');
      if (kDebugMode) {
        print('Error initializing Context-Aware Chat Provider: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize or load user profile
  Future<void> _initializeUserProfile() async {
    try {
      // Try to load existing profile
      _currentUser = await _memoryService.getUserProfile(_currentUserId!);

      if (_currentUser == null) {
        // Create new user profile with device information
        final deviceInfo = _awarenessService.currentDeviceInfo;
        final environmentalContext =
            _awarenessService.currentEnvironmentalContext;

        _currentUser = UserProfile(
          id: _currentUserId!,
          name: 'User', // Can be updated later
          createdAt: DateTime.now(),
          lastActive: DateTime.now(),
          preferences: UserPreferences.defaultPreferences,
          deviceInfo:
              deviceInfo ??
              DeviceInfo(
                platform: 'unknown',
                deviceModel: 'unknown',
                osVersion: 'unknown',
                appVersion: '1.0.0',
                capabilities: [],
                specifications: {},
                lastUpdated: DateTime.now(),
              ),
          behaviorPatterns: [],
          contextMemory: {},
          frequentTopics: [],
          projectTimelines: {},
        );

        // Save the new profile
        await _memoryService.saveUserProfile(_currentUser!);

        if (kDebugMode) {
          print('Created new user profile: $_currentUserId');
        }
      } else {
        // Update last active time
        _currentUser = _currentUser!.copyWith(lastActive: DateTime.now());
        await _memoryService.saveUserProfile(_currentUser!);

        if (kDebugMode) {
          print('Loaded existing user profile: $_currentUserId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing user profile: $e');
      }
      throw Exception('Failed to initialize user profile: $e');
    }
  }

  /// Load chat sessions
  Future<void> _loadChatSessions() async {
    try {
      _chatSessions = await DatabaseService.getAllChatSessions();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading chat sessions: $e');
      }
    }
  }

  /// Create new chat session with context awareness
  Future<void> createNewChatSession({String? title}) async {
    try {
      _setLoading(true);
      _clearError();

      // Generate contextual title if not provided
      String sessionTitle = title ?? _generateContextualSessionTitle();

      final sessionId = await DatabaseService.createChatSession(sessionTitle);
      await switchToChatSession(sessionId);

      // Create initial conversation context
      await _createInitialConversationContext(sessionId);

      if (kDebugMode) {
        print('Created new context-aware chat session: $sessionId');
      }
    } catch (e) {
      _setError('Failed to create chat session: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Generate contextual session title based on time and situation
  String _generateContextualSessionTitle() {
    final greeting = _awarenessService.getContextualGreeting();
    final now = DateTime.now();

    if (greeting.contains('morning')) {
      return 'Morning Session - ${_formatDate(now)}';
    } else if (greeting.contains('afternoon')) {
      return 'Afternoon Session - ${_formatDate(now)}';
    } else if (greeting.contains('evening')) {
      return 'Evening Session - ${_formatDate(now)}';
    } else if (greeting.contains('night')) {
      return 'Night Session - ${_formatDate(now)}';
    }

    return 'Chat Session - ${_formatDate(now)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Create initial conversation context for new session
  Future<void> _createInitialConversationContext(String sessionId) async {
    try {
      _currentContext = await _awarenessService.createConversationContext(
        sessionId: sessionId,
        activeTopics: [],
        situationalContext: {
          'session_type': 'new_session',
          'greeting_delivered': false,
          'initial_context': true,
        },
      );

      // Save the context
      await _memoryService.saveConversationContext(_currentContext!);

      if (kDebugMode) {
        print('Created initial conversation context for session: $sessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating initial conversation context: $e');
      }
    }
  }

  /// Switch to a chat session with context continuity
  Future<void> switchToChatSession(String sessionId) async {
    try {
      _setLoading(true);
      _currentSession = await DatabaseService.getChatSession(sessionId);

      if (_currentSession != null) {
        _currentMessages = await DatabaseService.getMessagesForSession(
          sessionId,
        );

        // Load conversation context
        await _loadConversationContext(sessionId);

        // Check for session continuity
        await _checkSessionContinuity(sessionId);

        // Update topic memory based on conversation
        await _updateTopicMemoryFromSession();
      } else {
        _currentMessages = [];
        _currentContext = null;
      }

      notifyListeners();
    } catch (e) {
      _setError('Failed to switch chat session: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load conversation context for session
  Future<void> _loadConversationContext(String sessionId) async {
    try {
      final contexts = await _memoryService.getConversationContexts(sessionId);
      if (contexts.isNotEmpty) {
        _currentContext = contexts.first; // Most recent context
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading conversation context: $e');
      }
    }
  }

  /// Check for session continuity and store relationships
  Future<void> _checkSessionContinuity(String sessionId) async {
    try {
      // Find the most recent previous session
      final sessions = _chatSessions.where((s) => s.id != sessionId).toList();
      if (sessions.isEmpty) return;

      sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      final previousSession = sessions.first;

      // Calculate continuity score based on time gap and topic similarity
      final timeDifference = DateTime.now().difference(
        previousSession.lastUpdated,
      );
      double continuityScore = 0.0;

      if (timeDifference.inMinutes < 30) {
        continuityScore = 0.9;
      } else if (timeDifference.inHours < 2) {
        continuityScore = 0.7;
      } else if (timeDifference.inHours < 24) {
        continuityScore = 0.4;
      } else {
        continuityScore = 0.1;
      }

      // Store session continuity
      await _memoryService.storeSessionContinuity(
        userId: _currentUserId!,
        previousSessionId: previousSession.id,
        currentSessionId: sessionId,
        continuityType: _determineContinuityType(timeDifference),
        continuityScore: continuityScore,
        contextBridge: _generateContextBridge(previousSession, timeDifference),
      );

      if (kDebugMode) {
        print(
          'Session continuity established: ${continuityScore.toStringAsFixed(2)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking session continuity: $e');
      }
    }
  }

  String _determineContinuityType(Duration timeDifference) {
    if (timeDifference.inMinutes < 5) return 'immediate_continuation';
    if (timeDifference.inMinutes < 30) return 'short_break';
    if (timeDifference.inHours < 2) return 'medium_break';
    if (timeDifference.inHours < 24) return 'same_day_return';
    if (timeDifference.inDays < 7) return 'weekly_return';
    return 'long_term_return';
  }

  String _generateContextBridge(
    ChatSession previousSession,
    Duration timeDifference,
  ) {
    if (timeDifference.inMinutes < 30) {
      return 'Continuing from recent conversation in "${previousSession.title}"';
    } else if (timeDifference.inHours < 2) {
      return 'Returning after a short break from "${previousSession.title}"';
    } else if (timeDifference.inHours < 24) {
      return 'Continuing conversation from earlier today in "${previousSession.title}"';
    } else {
      return 'Returning to continue previous discussion from "${previousSession.title}"';
    }
  }

  /// Update topic memory from current session messages
  Future<void> _updateTopicMemoryFromSession() async {
    if (_currentMessages.isEmpty) return;

    try {
      final topics = _extractTopicsFromMessages(_currentMessages);

      for (final topic in topics) {
        await _memoryService.updateTopicMemory(
          userId: _currentUserId!,
          topicName: topic['name'],
          interestScore: topic['interest'],
          relatedTopics: topic['related'],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating topic memory: $e');
      }
    }
  }

  /// Extract topics from conversation messages
  List<Map<String, dynamic>> _extractTopicsFromMessages(
    List<Message> messages,
  ) {
    final Map<String, double> topicScores = {};
    final Map<String, List<String>> relatedTopics = {};

    for (final message in messages) {
      final content = message.content.toLowerCase();

      // Extract potential topics using simple keyword analysis
      final words = content.split(RegExp(r'\W+'));
      final filteredWords = words
          .where((word) => word.length > 4 && !_isCommonWord(word))
          .toList();

      for (final word in filteredWords) {
        topicScores[word] = (topicScores[word] ?? 0.0) + 1.0;

        // Track related words in the same message
        relatedTopics[word] = (relatedTopics[word] ?? [])
          ..addAll(filteredWords.where((w) => w != word).take(3));
      }
    }

    // Convert to list of topic objects
    return topicScores.entries
        .where(
          (entry) => entry.value >= 2,
        ) // Only topics mentioned multiple times
        .map(
          (entry) => {
            'name': entry.key,
            'interest': (entry.value / messages.length).clamp(0.0, 1.0),
            'related': relatedTopics[entry.key]?.toSet().toList() ?? [],
          },
        )
        .toList();
  }

  bool _isCommonWord(String word) {
    const commonWords = {
      'that',
      'this',
      'with',
      'have',
      'will',
      'from',
      'they',
      'know',
      'want',
      'been',
      'good',
      'much',
      'some',
      'time',
      'very',
      'when',
      'come',
      'here',
      'just',
      'like',
      'long',
      'make',
      'many',
      'over',
      'such',
      'take',
      'than',
      'them',
      'well',
      'were',
      'what',
      'your',
    };
    return commonWords.contains(word);
  }

  /// Send message with full context awareness
  Future<void> sendContextAwareMessage({
    required String content,
    List<File>? images,
    String? promptTemplate,
  }) async {
    if (_currentSession == null) {
      await createNewChatSession();
    }
    if (_currentSession == null) return;

    try {
      _setLoading(true);
      _clearError();

      // Predict user intent
      UserIntent? predictedIntent;
      if (_enableIntentPrediction) {
        predictedIntent = await _intentService.predictUserIntent(
          messageContent: content,
          sessionId: _currentSession!.id,
          conversationHistory: _currentMessages,
          currentContext: _currentContext,
        );
      }

      // Analyze emotional state
      EmotionalState? userEmotionalState;
      if (_enableEmotionalIntelligence) {
        try {
          final sentimentAnalysis = SentimentAnalysisService();
          userEmotionalState = await sentimentAnalysis.analyzeText(
            content,
            context: 'user_message_${_currentSession!.id}',
          );
          await _emotionalMemoryService.addEmotionalState(
            userEmotionalState,
            _currentSession!.id,
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error analyzing emotional state: $e');
          }
        }
      }

      // Update conversation context
      if (_enableContextAwareness) {
        await _updateConversationContext(
          content: content,
          predictedIntent: predictedIntent,
        );
      }

      // Process prompt template with context
      String finalContent = content;
      if (promptTemplate != null && promptTemplate.isNotEmpty) {
        // Simple template processing - can be enhanced later
        finalContent = promptTemplate.replaceAll('{user_input}', content);
      }

      // Enhance content with contextual information
      if (_enableSituationalAwareness) {
        finalContent = _enhanceContentWithSituationalContext(finalContent);
      }

      // Create and save user message
      final userMessage = Message(
        id: _uuid.v4(),
        content: finalContent,
        imagePaths: images?.map((f) => f.path).toList() ?? [],
        timestamp: DateTime.now(),
        type: MessageType.user,
        status: MessageStatus.sent,
        emotionalContext: userEmotionalState,
      );

      _currentMessages.add(userMessage);
      notifyListeners();

      await DatabaseService.saveMessage(userMessage, _currentSession!.id);

      // Create AI placeholder message
      final aiMessageId = _uuid.v4();
      final aiMessage = Message(
        id: aiMessageId,
        content: _getContextualLoadingMessage(),
        imagePaths: [],
        timestamp: DateTime.now(),
        type: MessageType.ai,
        status: MessageStatus.sending,
      );

      _currentMessages.add(aiMessage);
      notifyListeners();

      // Build enhanced conversation history
      final conversationHistory = _buildEnhancedConversationHistory();

      // Get AI response using the existing AI evaluation service
      final evaluationResult = await _aiEvaluationService
          .processQueryWithUserPreference(
            query: content,
            images: images,
            conversationHistory: conversationHistory,
          );

      // Convert evaluation result to AI response format
      final aiResponse = evaluationResult.bestResponse;

      // Update AI message with response
      final updatedAiMessage = aiMessage.copyWith(
        content: aiResponse.content,
        status: MessageStatus.sent,
        aiModel: aiResponse.model,
        confidence: aiResponse.confidence,
      );

      final index = _currentMessages.indexWhere((m) => m.id == aiMessageId);
      if (index != -1) {
        _currentMessages[index] = updatedAiMessage;
        notifyListeners();
      }

      await DatabaseService.saveMessage(updatedAiMessage, _currentSession!.id);

      // Update session
      await _updateSessionAfterMessage();

      // Store behavior patterns
      await _analyzeBehaviorPatterns(userMessage, predictedIntent);
    } catch (e) {
      _setError('Failed to send message: $e');
      if (kDebugMode) {
        print('Error sending context-aware message: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Simple sendMessage method for compatibility
  Future<void> sendMessage({
    required String content,
    List<File>? images,
    String? promptTemplate,
  }) async {
    return sendContextAwareMessage(
      content: content,
      images: images,
      promptTemplate: promptTemplate,
    );
  }

  /// Retry the last message
  Future<void> retryLastMessage() async {
    if (_currentMessages.isEmpty) return;

    final lastUserMessage = _currentMessages.lastWhere(
      (m) => m.type == MessageType.user,
      orElse: () => _currentMessages.last,
    );

    if (lastUserMessage.type == MessageType.user) {
      // Remove the last AI message if it exists and has an error
      if (_currentMessages.last.type == MessageType.ai) {
        _currentMessages.removeLast();
      }

      final images = lastUserMessage.imagePaths
          .map((path) => File(path))
          .toList();
      await sendMessage(
        content: lastUserMessage.content,
        images: images.isNotEmpty ? images : null,
      );
    }
  }

  /// Edit a message
  Future<void> editMessage({
    required String messageId,
    required String newContent,
    List<File>? newImages,
  }) async {
    if (_currentSession == null) return;

    try {
      _setLoading(true);
      _clearError();

      // Find the message to edit
      final messageIndex = _currentMessages.indexWhere(
        (m) => m.id == messageId,
      );
      if (messageIndex == -1 ||
          _currentMessages[messageIndex].type != MessageType.user) {
        throw Exception('Message not found or not editable');
      }

      // Remove all messages after the edited message (including AI responses)
      final messagesToKeep = _currentMessages.take(messageIndex).toList();
      _currentMessages = messagesToKeep;

      // Send the edited message
      await sendMessage(content: newContent, images: newImages);
    } catch (e) {
      _setError('Failed to edit message: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Share a message
  Future<void> shareMessage(Message message) async {
    try {
      String shareContent = '';

      if (message.type == MessageType.ai) {
        shareContent = 'AI Response:\n\n${message.content}';

        if (message.aiModel != null) {
          shareContent += '\n\n---\nGenerated by: ${message.aiModel}';
        }

        if (message.confidence != null) {
          shareContent +=
              '\nConfidence: ${(message.confidence! * 100).toStringAsFixed(0)}%';
        }

        shareContent += '\nTimestamp: ${message.timestamp.toString()}';
        shareContent += '\n\nShared from ImageQuery AI';
      } else {
        shareContent = message.content;
      }

      await Clipboard.setData(ClipboardData(text: shareContent));
    } catch (e) {
      _setError('Failed to share message: $e');
    }
  }

  /// Read message aloud
  Future<void> readMessageAloud(Message message) async {
    try {
      // For now, just copy to clipboard as a placeholder
      // TTS integration can be added later
      await Clipboard.setData(ClipboardData(text: message.content));
    } catch (e) {
      _setError('Failed to read message aloud: $e');
    }
  }

  /// Set default prompt for current session
  Future<void> setDefaultPromptForSession(String? promptTemplate) async {
    if (_currentSession == null) return;

    try {
      final updatedSession = _currentSession!.copyWith(
        defaultPrompt: promptTemplate,
        lastUpdated: DateTime.now(),
      );
      await DatabaseService.updateChatSession(updatedSession);
      await _loadChatSessions();

      _currentSession = updatedSession;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update default prompt: $e');
    }
  }

  /// Clear default prompt for current session
  Future<void> clearDefaultPrompt() async {
    await setDefaultPromptForSession(null);
  }

  /// Toggle emotional intelligence features
  void setEmotionalIntelligenceEnabled(bool enabled) {
    _enableEmotionalIntelligence = enabled;
    notifyListeners();
  }

  /// Get emotional insights for analytics
  Map<String, dynamic> getEmotionalInsights() {
    if (_currentSession == null || !_enableEmotionalIntelligence) {
      return {};
    }

    return _emotionalMemoryService.getEmotionalInsights();
  }

  /// Get emotional context for the current session
  Map<String, dynamic> getSessionEmotionalContext() {
    if (_currentSession == null || !_enableEmotionalIntelligence) {
      return {};
    }

    // Return basic emotional context based on available data
    return {
      'session_id': _currentSession!.id,
      'emotion_tracking_enabled': _enableEmotionalIntelligence,
      'context_awareness_enabled': _enableContextAwareness,
    };
  }

  /// Get dominant emotions from current session
  List<EmotionType> getCurrentDominantEmotions() {
    if (!_enableEmotionalIntelligence) return [];

    return _emotionalMemoryService.getDominantEmotions();
  }

  /// Get recent emotional trend
  EmotionalTrend getCurrentEmotionalTrend() {
    if (!_enableEmotionalIntelligence) return EmotionalTrend.stable;

    return _emotionalMemoryService.getRecentTrend();
  }

  /// Check if user needs emotional support
  bool shouldProvideEmotionalSupport() {
    if (_currentSession == null || !_enableEmotionalIntelligence) {
      return false;
    }

    // Basic logic - can be enhanced with more sophisticated algorithms
    final recentMessages = _currentMessages.length > 5
        ? _currentMessages.sublist(_currentMessages.length - 5)
        : _currentMessages;
    if (recentMessages.isEmpty) return false;

    // Check for patterns that might indicate need for support
    final userMessages = recentMessages.where(
      (m) => m.type == MessageType.user,
    );
    return userMessages.any(
      (m) => m.content.toLowerCase().contains(
        RegExp(r'\b(help|stuck|confused|frustrated|difficult|problem)\b'),
      ),
    );
  }

  /// Clear all chat sessions
  Future<void> clearAllChatSessions() async {
    try {
      // Delete all chat sessions
      for (final session in _chatSessions) {
        await DatabaseService.deleteChatSession(session.id);
      }

      // Clear local state
      _chatSessions.clear();
      _currentSession = null;
      _currentMessages.clear();

      notifyListeners();
    } catch (e) {
      _setError('Failed to clear all chat sessions: $e');
    }
  }

  /// Get facial expression capabilities
  Map<String, dynamic> getFacialExpressionCapabilities() {
    return {
      'is_supported': false,
      'version': '1.0.0',
      'features': ['basic_emotions', 'facial_landmarks'],
      'status': 'placeholder_implementation',
    };
  }

  /// Rename a chat session
  Future<void> renameChatSession(String sessionId, String newTitle) async {
    try {
      final session = await DatabaseService.getChatSession(sessionId);
      if (session != null) {
        final updatedSession = session.copyWith(
          title: newTitle,
          lastUpdated: DateTime.now(),
        );
        await DatabaseService.updateChatSession(updatedSession);
        await _loadChatSessions();

        if (_currentSession?.id == sessionId) {
          _currentSession = updatedSession;
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Failed to rename chat session: $e');
    }
  }

  /// Update conversation context with new message
  Future<void> _updateConversationContext({
    required String content,
    UserIntent? predictedIntent,
  }) async {
    if (_currentSession == null) return;

    try {
      // Extract active topics from recent messages
      final recentMessages = _currentMessages.take(10).toList();
      final activeTopics = _extractActiveTopics(recentMessages, content);

      // Update situational context
      final situationalContext = {
        'message_count': _currentMessages.length,
        'session_duration_minutes': _calculateSessionDuration(),
        'has_images': _currentMessages.any((m) => m.imagePaths.isNotEmpty),
        'dominant_intent': predictedIntent?.type.name,
        'conversation_phase': _determineConversationPhase(),
      };

      // Create updated context
      _currentContext = await _awarenessService.createConversationContext(
        sessionId: _currentSession!.id,
        activeTopics: activeTopics,
        situationalContext: situationalContext,
        currentIntent: predictedIntent,
        referencedEntities: _extractReferencedEntities(content),
        temporalContext: {
          'last_message_time': DateTime.now().toIso8601String(),
          'session_start_time': _currentSession!.createdAt.toIso8601String(),
        },
      );

      // Save updated context
      await _memoryService.saveConversationContext(_currentContext!);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating conversation context: $e');
      }
    }
  }

  /// Extract active topics from conversation
  List<String> _extractActiveTopics(
    List<Message> recentMessages,
    String newContent,
  ) {
    final topics = <String>[];
    final allContent =
        recentMessages.map((m) => m.content).join(' ') + ' ' + newContent;

    // Simple topic extraction based on keywords
    if (allContent.toLowerCase().contains('image') ||
        allContent.toLowerCase().contains('photo')) {
      topics.add('image_analysis');
    }
    if (allContent.toLowerCase().contains('problem') ||
        allContent.toLowerCase().contains('error')) {
      topics.add('problem_solving');
    }
    if (allContent.toLowerCase().contains('learn') ||
        allContent.toLowerCase().contains('understand')) {
      topics.add('learning');
    }
    if (allContent.toLowerCase().contains('help') ||
        allContent.toLowerCase().contains('assist')) {
      topics.add('assistance');
    }

    return topics;
  }

  int _calculateSessionDuration() {
    if (_currentSession == null) return 0;
    return DateTime.now().difference(_currentSession!.createdAt).inMinutes;
  }

  String _determineConversationPhase() {
    final messageCount = _currentMessages.length;
    if (messageCount <= 2) return 'opening';
    if (messageCount <= 10) return 'exploration';
    if (messageCount <= 20) return 'deep_dive';
    return 'extended_discussion';
  }

  List<String> _extractReferencedEntities(String content) {
    // Simple entity extraction - can be enhanced with NLP
    final entities = <String>[];

    // Extract capitalized words that might be entities
    final words = content.split(RegExp(r'\W+'));
    for (final word in words) {
      if (word.length > 2 &&
          word[0].toUpperCase() == word[0] &&
          word.toLowerCase() != word) {
        entities.add(word);
      }
    }

    return entities.take(5).toList(); // Limit to 5 entities
  }

  /// Enhance content with situational context
  String _enhanceContentWithSituationalContext(String content) {
    if (!_enableSituationalAwareness) return content;

    final deviceInfo = _awarenessService.currentDeviceInfo;
    final environmentalContext = _awarenessService.currentEnvironmentalContext;

    if (deviceInfo == null || environmentalContext == null) return content;

    // Add device context if relevant
    if (content.toLowerCase().contains('device') ||
        content.toLowerCase().contains('platform')) {
      content +=
          '\n\n[Context: I\'m using ${deviceInfo.platform} on ${deviceInfo.deviceModel}]';
    }

    // Add time context if relevant
    if (content.toLowerCase().contains('time') ||
        content.toLowerCase().contains('when')) {
      content +=
          '\n\n[Context: Current time context - ${environmentalContext.timeOfDay} on ${environmentalContext.dayOfWeek}]';
    }

    return content;
  }

  /// Get contextual loading message
  String _getContextualLoadingMessage() {
    if (!_enableSituationalAwareness) return 'Thinking...';

    final environmentalContext = _awarenessService.currentEnvironmentalContext;
    if (environmentalContext == null) return 'Thinking...';

    switch (environmentalContext.currentActivity) {
      case 'work_hours':
        return 'Processing your request...';
      case 'leisure_morning':
      case 'leisure_afternoon':
        return 'Let me think about that...';
      case 'continuation':
        return 'Building on our conversation...';
      default:
        return 'Analyzing...';
    }
  }

  /// Build enhanced conversation history with context
  List<Map<String, dynamic>> _buildEnhancedConversationHistory() {
    if (!_enableContextAwareness) {
      // Fallback to basic context management
      return ContextManagementService.getOptimalContextMessages(
            _currentMessages,
          )
          .map(
            (msg) => {
              'role': msg.type == MessageType.user ? 'user' : 'assistant',
              'content': msg.content,
              'images': msg.imagePaths,
            },
          )
          .toList();
    }

    final optimalMessages = ContextManagementService.getOptimalContextMessages(
      _currentMessages,
    );

    return optimalMessages.map((msg) {
      final messageMap = {
        'role': msg.type == MessageType.user ? 'user' : 'assistant',
        'content': msg.content,
        'images': msg.imagePaths,
        'timestamp': msg.timestamp.toIso8601String(),
      };

      // Add emotional context if available
      if (msg.emotionalContext != null) {
        messageMap['emotional_context'] = {
          'sentiment': msg.emotionalContext!.sentiment.name,
          'intensity': msg.emotionalContext!.intensity,
          'emotions': msg.emotionalContext!.emotions
              .map((e) => e.name)
              .toList(),
        };
      }

      return messageMap;
    }).toList();
  }

  /// Update session after message exchange
  Future<void> _updateSessionAfterMessage() async {
    if (_currentSession == null) return;

    try {
      final updatedSession = _currentSession!.copyWith(
        messageIds: _currentMessages.map((m) => m.id).toList(),
        messageCount: _currentMessages.length,
        lastUpdated: DateTime.now(),
      );

      await DatabaseService.updateChatSession(updatedSession);
      await _loadChatSessions();

      _currentSession = updatedSession;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating session: $e');
      }
    }
  }

  /// Analyze and store behavior patterns
  Future<void> _analyzeBehaviorPatterns(
    Message userMessage,
    UserIntent? predictedIntent,
  ) async {
    if (_currentUserId == null) return;

    try {
      // Analyze session timing pattern
      await _analyzeSessionTimingPattern();

      // Analyze question patterns
      if (userMessage.content.contains('?')) {
        await _analyzeQuestionPattern(userMessage);
      }

      // Analyze image usage patterns
      if (userMessage.imagePaths.isNotEmpty) {
        await _analyzeImageUsagePattern(userMessage);
      }

      // Analyze intent patterns
      if (predictedIntent != null) {
        await _analyzeIntentPattern(predictedIntent);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error analyzing behavior patterns: $e');
      }
    }
  }

  Future<void> _analyzeSessionTimingPattern() async {
    final now = DateTime.now();
    final timeOfDay =
        _awarenessService.currentEnvironmentalContext?.timeOfDay ?? 'unknown';

    final pattern = BehaviorPattern(
      id: 'timing_${_currentUserId}_${now.millisecondsSinceEpoch}',
      type: BehaviorType.sessionTiming,
      description: 'User session timing pattern - $timeOfDay',
      firstObserved: now,
      lastObserved: now,
      frequency: 1,
      confidence: 0.7,
      metadata: {
        'time_of_day': timeOfDay,
        'day_of_week':
            _awarenessService.currentEnvironmentalContext?.dayOfWeek ??
            'unknown',
        'session_id': _currentSession?.id,
      },
    );

    await _memoryService.saveBehaviorPattern(pattern, _currentUserId!);
  }

  Future<void> _analyzeQuestionPattern(Message message) async {
    final questionType = _classifyQuestion(message.content);

    final pattern = BehaviorPattern(
      id: 'question_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
      type: BehaviorType.frequentQuestionPattern,
      description: 'Question pattern: $questionType',
      firstObserved: DateTime.now(),
      lastObserved: DateTime.now(),
      frequency: 1,
      confidence: 0.8,
      metadata: {
        'question_type': questionType,
        'question_length': message.content.length,
        'has_images': message.imagePaths.isNotEmpty,
      },
    );

    await _memoryService.saveBehaviorPattern(pattern, _currentUserId!);
  }

  String _classifyQuestion(String content) {
    final lowerContent = content.toLowerCase();
    if (lowerContent.startsWith('what')) return 'what_question';
    if (lowerContent.startsWith('how')) return 'how_question';
    if (lowerContent.startsWith('why')) return 'why_question';
    if (lowerContent.startsWith('when')) return 'when_question';
    if (lowerContent.startsWith('where')) return 'where_question';
    if (lowerContent.startsWith('who')) return 'who_question';
    return 'general_question';
  }

  Future<void> _analyzeImageUsagePattern(Message message) async {
    final pattern = BehaviorPattern(
      id: 'image_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
      type: BehaviorType.imageAnalysisPreference,
      description: 'Image usage pattern',
      firstObserved: DateTime.now(),
      lastObserved: DateTime.now(),
      frequency: 1,
      confidence: 0.9,
      metadata: {
        'image_count': message.imagePaths.length,
        'message_length': message.content.length,
        'request_type': _classifyImageRequest(message.content),
      },
    );

    await _memoryService.saveBehaviorPattern(pattern, _currentUserId!);
  }

  String _classifyImageRequest(String content) {
    final lowerContent = content.toLowerCase();
    if (lowerContent.contains('analyze')) return 'analysis_request';
    if (lowerContent.contains('describe')) return 'description_request';
    if (lowerContent.contains('identify')) return 'identification_request';
    if (lowerContent.contains('explain')) return 'explanation_request';
    return 'general_image_request';
  }

  Future<void> _analyzeIntentPattern(UserIntent intent) async {
    final pattern = BehaviorPattern(
      id: 'intent_${_currentUserId}_${DateTime.now().millisecondsSinceEpoch}',
      type: BehaviorType.responsePreference,
      description: 'Intent pattern: ${intent.type.displayName}',
      firstObserved: DateTime.now(),
      lastObserved: DateTime.now(),
      frequency: 1,
      confidence: intent.confidence,
      metadata: {
        'intent_type': intent.type.name,
        'confidence': intent.confidence,
        'parameters': intent.parameters,
        'alternative_intents': intent.alternativeIntents
            .map((i) => i.name)
            .toList(),
      },
    );

    await _memoryService.saveBehaviorPattern(pattern, _currentUserId!);
  }

  /// Delete chat session
  Future<void> deleteChatSession(String sessionId) async {
    try {
      await DatabaseService.deleteChatSession(sessionId);
      await _loadChatSessions();

      if (_currentSession?.id == sessionId) {
        _currentSession = null;
        _currentMessages = [];
        _currentContext = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete chat session: $e');
    }
  }

  /// Get contextual greeting for new session
  String getContextualGreeting() {
    if (!_enableSituationalAwareness) return 'Hello! How can I help you today?';
    return _awarenessService.getContextualGreeting();
  }

  /// Get device-specific recommendations
  List<String> getDeviceRecommendations() {
    if (!_enableSituationalAwareness) return [];
    return _awarenessService.getDeviceSpecificRecommendations();
  }

  /// Get predicted next actions
  Future<List<Map<String, dynamic>>> getPredictedNextActions() async {
    if (!_enableIntentPrediction || _currentSession == null) return [];

    return await _intentService.predictNextActions(
      sessionId: _currentSession!.id,
      conversationHistory: _currentMessages,
      currentContext: _currentContext,
    );
  }

  /// Get memory statistics
  Future<Map<String, dynamic>> getMemoryStatistics() async {
    if (_currentUserId == null) return {};
    return await _memoryService.getMemoryStatistics(_currentUserId!);
  }

  /// Get situational awareness summary
  Map<String, dynamic> getSituationalSummary() {
    if (!_enableSituationalAwareness) return {};
    return _awarenessService.getSituationalSummary();
  }

  /// Toggle context awareness features
  void toggleContextAwareness(bool enabled) {
    _enableContextAwareness = enabled;
    notifyListeners();
  }

  void toggleIntentPrediction(bool enabled) {
    _enableIntentPrediction = enabled;
    notifyListeners();
  }

  void toggleSituationalAwareness(bool enabled) {
    _enableSituationalAwareness = enabled;
    notifyListeners();
  }

  void toggleEmotionalIntelligence(bool enabled) {
    _enableEmotionalIntelligence = enabled;
    notifyListeners();
  }

  /// Get the first user message content for a session to use as display title
  Future<String?> getFirstUserMessageForSession(String sessionId) async {
    try {
      final messages = await DatabaseService.getMessagesForSession(sessionId);
      final firstUserMessage = messages.firstWhere(
        (message) => message.type == MessageType.user,
        orElse: () => throw StateError('No user message found'),
      );

      // Truncate long messages for display
      String content = firstUserMessage.content.trim();
      if (content.length > 50) {
        content = '${content.substring(0, 47)}...';
      }

      return content.isNotEmpty ? content : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting first user message for session $sessionId: $e');
      }
      return null;
    }
  }

  /// Utility methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}
