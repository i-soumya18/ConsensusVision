import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/chat_session.dart';
import '../services/database_service.dart';
import '../services/ai_evaluation_service.dart';
import '../services/prompt_library_service.dart';

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

      // Process prompt template if provided
      String finalContent = content;
      if (promptTemplate != null && promptTemplate.isNotEmpty) {
        finalContent = PromptLibraryService.processPromptTemplate(
          promptTemplate,
          content,
        );
      }

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

      // Create placeholder AI message
      final aiMessageId = _uuid.v4();
      final aiMessage = Message(
        id: aiMessageId,
        content: 'Thinking...',
        imagePaths: [],
        timestamp: DateTime.now(),
        type: MessageType.ai,
        status: MessageStatus.sending,
      );

      _currentMessages.add(aiMessage);
      notifyListeners();

      // Build conversation history for context
      final conversationHistory = _buildConversationHistory();

      // Process query with AI evaluation and conversation context
      final evaluationResult = await _aiEvaluationService
          .processQueryWithEvaluation(
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
      _setError('Failed to send message: $e');

      // Update AI message to show error
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
        _currentMessages[errorIndex] = errorMessage.copyWith(
          content: 'Sorry, I encountered an error. Please try again.',
          status: MessageStatus.error,
        );
      }
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Build conversation history for context
  List<Map<String, dynamic>> _buildConversationHistory() {
    final history = <Map<String, dynamic>>[];

    // Get the last 10 messages (5 exchanges) for context, excluding the current exchange
    final messagesToInclude = _currentMessages.length > 2
        ? _currentMessages.sublist(0, _currentMessages.length - 2)
        : <Message>[];

    // Take only the last 10 messages to keep context manageable
    final recentMessages = messagesToInclude.length > 10
        ? messagesToInclude.sublist(messagesToInclude.length - 10)
        : messagesToInclude;

    for (final message in recentMessages) {
      final role = message.type == MessageType.user ? 'user' : 'assistant';

      if (message.type == MessageType.user && message.imagePaths.isNotEmpty) {
        // For user messages with images, create multimodal content
        final content = <Map<String, dynamic>>[];
        content.add({'type': 'text', 'text': message.content});

        // Note: In a real implementation, you'd need to load and encode images
        // For now, we'll just add a placeholder
        for (final imagePath in message.imagePaths) {
          content.add({
            'type': 'text',
            'text': '[Image was attached: $imagePath]',
          });
        }

        history.add({'role': role, 'content': content});
      } else {
        // For text-only messages
        history.add({
          'role': role,
          'content': [
            {'type': 'text', 'text': message.content},
          ],
        });
      }
    }

    return history;
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
