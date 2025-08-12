import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../services/database_service.dart';
import '../services/ai_evaluation_service.dart';
import '../services/prompt_library_service.dart';
import '../services/context_management_service.dart';

class ChatProvider extends ChangeNotifier {
  final AIEvaluationService _aiEvaluationService;
  final Uuid _uuid = const Uuid();

  List<ChatSession> _chatSessions = [];
  ChatSession? _currentSession;
  List<Message> _currentMessages = [];
  bool _isLoading = false;
  String? _error;

  ChatProvider({
    required String geminiApiKey,
    required String huggingFaceApiKey,
  }) : _aiEvaluationService = AIEvaluationService(
         geminiApiKey: geminiApiKey,
         huggingFaceApiKey: huggingFaceApiKey,
       );

  // Getters
  List<ChatSession> get chatSessions => _chatSessions;
  ChatSession? get currentSession => _currentSession;
  List<Message> get currentMessages => _currentMessages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialize provider
  Future<void> initialize() async {
    await _loadChatSessions();
  }

  // Chat session management
  Future<void> _loadChatSessions() async {
    try {
      _chatSessions = await DatabaseService.getAllChatSessions();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load chat sessions: $e');
    }
  }

  Future<void> createNewChatSession({String? title}) async {
    try {
      final sessionTitle =
          title ?? 'New Chat ${DateTime.now().day}/${DateTime.now().month}';
      final sessionId = await DatabaseService.createChatSession(sessionTitle);
      await _loadChatSessions();
      await switchToChatSession(sessionId);
    } catch (e) {
      _setError('Failed to create chat session: $e');
    }
  }

  Future<void> switchToChatSession(String sessionId) async {
    try {
      _setLoading(true);
      _currentSession = await DatabaseService.getChatSession(sessionId);
      if (_currentSession != null) {
        _currentMessages = await DatabaseService.getMessagesForSession(
          sessionId,
        );
      } else {
        _currentMessages = [];
      }
      notifyListeners();
    } catch (e) {
      _setError('Failed to switch chat session: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteChatSession(String sessionId) async {
    try {
      await DatabaseService.deleteChatSession(sessionId);
      await _loadChatSessions();

      if (_currentSession?.id == sessionId) {
        _currentSession = null;
        _currentMessages = [];
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete chat session: $e');
    }
  }

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

  String? get currentSessionDefaultPrompt => _currentSession?.defaultPrompt;

  // Message handling
  Future<void> sendMessage({
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

      // Use session's default prompt if no specific prompt template is provided
      String? effectivePromptTemplate =
          promptTemplate ?? _currentSession?.defaultPrompt;

      // Process prompt template if available and enhance with context
      String finalContent = content;
      if (effectivePromptTemplate != null &&
          effectivePromptTemplate.isNotEmpty) {
        finalContent = PromptLibraryService.processPromptTemplate(
          effectivePromptTemplate,
          content,
        );
      }

      // Enhance the query with contextual information for better continuity
      finalContent = _enhanceQueryWithAdvancedContext(finalContent);

      // Create user message
      final userMessage = Message(
        id: _uuid.v4(),
        content: finalContent,
        imagePaths: images?.map((f) => f.path).toList() ?? [],
        timestamp: DateTime.now(),
        type: MessageType.user,
        status: MessageStatus.sent,
      );

      // Add user message to UI immediately
      _currentMessages.add(userMessage);
      notifyListeners();

      // Save user message to database
      await DatabaseService.saveMessage(userMessage, _currentSession!.id);

      // Create placeholder AI message with enhanced loading state
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

      // Build enhanced conversation history using advanced context management
      final conversationHistory = _buildAdvancedConversationHistory();

      // Process query with AI evaluation and enhanced conversation context
      final evaluationResult = await _aiEvaluationService
          .processQueryWithUserPreference(
            query: finalContent,
            images: images,
            conversationHistory: conversationHistory,
          );

      // Update AI message with result
      final updatedAiMessage = aiMessage.copyWith(
        content: evaluationResult.finalAnswer,
        status: MessageStatus.delivered,
        aiModel: evaluationResult.bestResponse.model,
        confidence: evaluationResult.confidence,
      );

      // Update in memory
      final messageIndex = _currentMessages.indexWhere(
        (m) => m.id == aiMessageId,
      );
      if (messageIndex != -1) {
        _currentMessages[messageIndex] = updatedAiMessage;
      }

      // Save AI message to database
      await DatabaseService.saveMessage(updatedAiMessage, _currentSession!.id);

      // Update session title if it's the first exchange
      if (_currentMessages.where((m) => m.type == MessageType.user).length ==
          1) {
        final title = _generateSessionTitle(content);
        await renameChatSession(_currentSession!.id, title);
      }
    } catch (e) {
      _handleErrorWithContext(
        'Failed to send message: $e',
        context: 'Message Processing',
        recovery: 'Try rephrasing your question or check your connection',
      );

      // Update AI message to show error with helpful suggestions
      final errorMessage = _currentMessages.lastWhere(
        (m) => m.type == MessageType.ai && m.status == MessageStatus.sending,
        orElse: () => Message(
          id: _uuid.v4(),
          content: '',
          imagePaths: [],
          timestamp: DateTime.now(),
          type: MessageType.ai,
          status: MessageStatus.error,
        ),
      );

      final errorIndex = _currentMessages.indexOf(errorMessage);
      if (errorIndex != -1) {
        String errorContent =
            'I encountered an issue processing your request. ';

        // Add specific error guidance based on the error type
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorContent +=
              'It seems like there\'s a connection issue. Please check your internet connection and try again.';
        } else if (e.toString().contains('API') ||
            e.toString().contains('rate')) {
          errorContent +=
              'There was an API issue. You might want to wait a moment and try again.';
        } else {
          errorContent +=
              'Please try rephrasing your question or contact support if the issue persists.';
        }

        _currentMessages[errorIndex] = errorMessage.copyWith(
          content: errorContent,
          status: MessageStatus.error,
        );
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Edit user message and regenerate AI response
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

      // Update the user message with new content
      final editedMessage = _currentMessages[messageIndex].copyWith(
        content: newContent,
        imagePaths:
            newImages?.map((f) => f.path).toList() ??
            _currentMessages[messageIndex].imagePaths,
        timestamp: DateTime.now(), // Update timestamp to show it was edited
      );

      messagesToKeep.add(editedMessage);
      _currentMessages = messagesToKeep;

      // Save changes to database
      await DatabaseService.updateMessage(editedMessage);

      // Remove messages that came after the edited message from database
      final originalMessages = await DatabaseService.getMessagesForSession(
        _currentSession!.id,
      );
      for (int i = messageIndex + 1; i < originalMessages.length; i++) {
        await DatabaseService.deleteMessage(originalMessages[i].id);
      }

      notifyListeners();

      // Generate new AI response
      await _generateAIResponse(editedMessage);
    } catch (e) {
      _setError('Failed to edit message: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Extract AI response generation logic for reuse
  Future<void> _generateAIResponse(Message userMessage) async {
    // Create AI message placeholder
    final aiMessage = Message(
      id: _uuid.v4(),
      content: '',
      imagePaths: [],
      timestamp: DateTime.now(),
      type: MessageType.ai,
      status: MessageStatus.sending,
    );

    _currentMessages.add(aiMessage);
    notifyListeners();

    // Save user message to database
    await DatabaseService.saveMessage(userMessage, _currentSession!.id);

    // Get AI response
    final response = await _aiEvaluationService.processQueryWithUserPreference(
      query: userMessage.content,
      images: userMessage.imagePaths.map((path) => File(path)).toList(),
      conversationHistory: _buildAdvancedConversationHistory(),
    );

    // Update AI message with response
    final completedAiMessage = aiMessage.copyWith(
      content: response.finalAnswer,
      status: MessageStatus.sent,
      aiModel: response.bestResponse.model,
      confidence: response.bestResponse.confidence,
    );

    final aiIndex = _currentMessages.indexOf(aiMessage);
    if (aiIndex != -1) {
      _currentMessages[aiIndex] = completedAiMessage;
    }

    // Save AI message to database
    await DatabaseService.saveMessage(completedAiMessage, _currentSession!.id);
    notifyListeners();
  }

  // Share message content
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

        shareContent +=
            '\nTimestamp: ${DateFormat('yyyy-MM-dd HH:mm').format(message.timestamp)}';
        shareContent += '\n\nShared from ImageQuery AI';
      } else {
        shareContent = message.content;
      }

      // Use the clipboard as a fallback since share_plus might not be available
      await Clipboard.setData(ClipboardData(text: shareContent));

      // You can also implement native sharing here if share_plus is added to pubspec.yaml
      // await Share.share(shareContent);
    } catch (e) {
      _setError('Failed to share message: $e');
    }
  }

  // Build conversation history using advanced context management
  List<Map<String, dynamic>> _buildAdvancedConversationHistory() {
    final history = <Map<String, dynamic>>[];

    // Get all completed messages, excluding the current AI message being generated
    final messagesToInclude = _currentMessages
        .where(
          (message) =>
              (message.status == MessageStatus.sent ||
                  message.status == MessageStatus.delivered) &&
              message.status != MessageStatus.sending,
        )
        .toList();

    // Use advanced context management for optimal message selection
    final contextMessages = ContextManagementService.getOptimalContextMessages(
      messagesToInclude,
    );

    // Add conversation summary for very long conversations
    if (_currentMessages.length > 30) {
      final summary = ContextManagementService.generateIntelligentSummary(
        messagesToInclude,
      );
      if (summary.isNotEmpty) {
        history.insert(0, {
          'role': 'system',
          'content': [
            {'type': 'text', 'text': summary},
          ],
        });
      }
    }

    // Build history from context messages
    for (final message in contextMessages) {
      final role = message.type == MessageType.user ? 'user' : 'assistant';

      if (message.type == MessageType.user && message.imagePaths.isNotEmpty) {
        // For user messages with images, create enhanced multimodal content
        final content = <Map<String, dynamic>>[];
        content.add({'type': 'text', 'text': message.content});

        // Enhanced image context - include image analysis context
        for (final imagePath in message.imagePaths) {
          final fileName = imagePath.split('/').last;
          content.add({
            'type': 'text',
            'text':
                '[Image: $fileName - Previously analyzed and discussed in this conversation]',
          });
        }

        history.add({'role': role, 'content': content});
      } else if (message.id.startsWith('context-bridge')) {
        // Handle context bridge messages
        history.add({
          'role': 'system',
          'content': [
            {'type': 'text', 'text': message.content},
          ],
        });
      } else {
        // For text-only messages, add enhanced context markers
        String enhancedContent = message.content;

        // Add context markers for AI responses to maintain continuity
        if (message.type == MessageType.ai && message.aiModel != null) {
          enhancedContent =
              '$enhancedContent\n[Generated by ${message.aiModel}]';
        }

        history.add({
          'role': role,
          'content': [
            {'type': 'text', 'text': enhancedContent},
          ],
        });
      }
    }

    return history;
  }

  // Enhanced query processing with advanced context and error handling
  String _enhanceQueryWithAdvancedContext(String query) {
    if (_currentMessages.isEmpty) {
      return query;
    }

    // Early return for empty or very short queries
    if (query.trim().length < 3) {
      return query;
    }

    // Check for ambiguous or incomplete queries that need clarification
    if (_isAmbiguousQuery(query)) {
      return _addClarificationContext(query);
    }

    // Use advanced context management for query enhancement
    final contextMessages = ContextManagementService.getOptimalContextMessages(
      _currentMessages,
    );

    // Detect topic transitions for better context handling
    final topicTransition = ContextManagementService.detectTopicTransition(
      contextMessages
          .where((m) => m.type == MessageType.user || m.type == MessageType.ai)
          .toList(),
      query,
    );

    // Add topic transition context if needed
    String enhancedQuery = query;
    if (topicTransition == TopicTransition.related) {
      enhancedQuery = '[Topic shift detected] $query';
    } else if (topicTransition == TopicTransition.newTopic) {
      enhancedQuery = '[New topic] $query';
    }

    // Apply advanced context enhancement
    return ContextManagementService.enhanceQueryWithContext(
      enhancedQuery,
      contextMessages,
      includeImageContext: true,
    );
  }

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

  // Search functionality
  Future<List<Message>> searchMessages(String query) async {
    try {
      return await DatabaseService.searchMessages(query);
    } catch (e) {
      _setError('Failed to search messages: $e');
      return [];
    }
  }

  // Utility methods
  String _generateSessionTitle(String firstMessage) {
    // Generate a meaningful title from the first message
    final words = firstMessage.split(' ').take(4).join(' ');
    return words.length > 30 ? '${words.substring(0, 30)}...' : words;
  }

  // Check if a query is ambiguous and might need clarification
  bool _isAmbiguousQuery(String query) {
    final ambiguousPatterns = [
      // Very vague queries
      RegExp(
        r'^(what|how|why|when|where)\s*(is|are|do|does|can|should)?\s*it\??$',
      ),
      RegExp(r'^(this|that|these|those)\??$'),
      RegExp(r'^(help|fix|solve|explain)\s*(this|that|it)?\??$'),

      // Single word queries (except proper nouns)
      RegExp(r'^\w+\??$'),

      // Questions without sufficient context
      RegExp(r'^(what|how)\s+(do|can|should)\s+i\s*\??$'),
    ];

    final queryTrimmed = query.trim().toLowerCase();
    return ambiguousPatterns.any((pattern) => pattern.hasMatch(queryTrimmed));
  }

  // Add clarification context to ambiguous queries
  String _addClarificationContext(String query) {
    final recentMessages = _currentMessages
        .where((m) => m.type == MessageType.user)
        .take(2)
        .toList();

    if (recentMessages.isNotEmpty) {
      final lastContext = recentMessages.first.content
          .split(' ')
          .take(8)
          .join(' ');
      return 'Regarding our discussion about "$lastContext": $query. '
          'Please provide a specific and detailed response. If my question is unclear, '
          'please ask for clarification about what specific aspect you\'d like me to address.';
    }

    return '$query\n\nNote: Your question seems quite general. Please provide more specific details '
        'about what you\'d like to know, or ask me to clarify if you need help formulating your question.';
  }

  // Enhanced error handling with recovery suggestions
  void _handleErrorWithContext(
    String error, {
    String? context,
    String? recovery,
  }) {
    String enhancedError = error;

    // Add context if available
    if (context != null) {
      enhancedError = '$context: $error';
    }

    // Add recovery suggestions based on error type
    if (error.contains('network') || error.contains('connection')) {
      enhancedError +=
          '\n\nSuggestions:\n'
          '• Check your internet connection\n'
          '• Verify your API keys are valid\n'
          '• Try again in a few moments';
    } else if (error.contains('API') || error.contains('rate limit')) {
      enhancedError +=
          '\n\nSuggestions:\n'
          '• Wait a moment before trying again\n'
          '• Check if your API quota is exceeded\n'
          '• Consider using different model settings';
    } else if (error.contains('image') || error.contains('file')) {
      enhancedError +=
          '\n\nSuggestions:\n'
          '• Ensure image file is not corrupted\n'
          '• Try with a different image format\n'
          '• Check file size limitations';
    }

    // Add custom recovery action if provided
    if (recovery != null) {
      enhancedError += '\n\nRecommended action: $recovery';
    }

    _setError(enhancedError);
  }

  // Get contextual loading message based on conversation state
  String _getContextualLoadingMessage() {
    final userMessageCount = _currentMessages
        .where((m) => m.type == MessageType.user)
        .length;
    final hasImages = _currentMessages.any((m) => m.imagePaths.isNotEmpty);

    if (userMessageCount == 1) {
      return hasImages
          ? 'Analyzing your image...'
          : 'Processing your question...';
    } else if (userMessageCount <= 3) {
      return hasImages
          ? 'Continuing image analysis...'
          : 'Building on our conversation...';
    } else {
      return 'Considering our full discussion...';
    }
  }

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
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
