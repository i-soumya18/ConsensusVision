import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/conversation_context_indicator.dart';
import '../services/theme_service.dart';
import 'chat_sessions_screen.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // Error banner
              if (chatProvider.error != null)
                _buildErrorBanner(chatProvider.error!),

              // Messages area with enhanced context awareness
              Expanded(
                child: chatProvider.currentMessages.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          // Show conversation context indicator for ongoing conversations
                          ConversationContextIndicator(
                            messages: chatProvider.currentMessages,
                            isVisible: chatProvider.currentMessages.length > 2,
                          ),

                          // Messages list
                          Expanded(child: _buildMessagesList(chatProvider)),
                        ],
                      ),
              ),

              // Input area
              MessageInputWidget(
                onSendMessage: (message, images, {String? promptTemplate}) {
                  chatProvider.sendMessage(
                    content: message,
                    images: images,
                    promptTemplate: promptTemplate,
                  );
                  _scrollToBottom();
                },
                isLoading: chatProvider.isLoading,
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return AppBar(
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: themeService.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'ImageQuery AI',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              // New Chat Button
              IconButton(
                icon: const Icon(Icons.add_comment),
                onPressed: () => _createNewChat(),
                tooltip: 'New Chat',
                iconSize: 24.0,
              ),
              // Chat History Button
              IconButton(
                icon: const Icon(Icons.history),
                onPressed: () => _showChatSessions(),
                tooltip: 'Chat History',
                iconSize: 24.0,
              ),
              // More Options Menu
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                iconSize: 24.0,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings),
                        SizedBox(width: 12),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: Theme.of(context).colorScheme.error,
            onPressed: () {
              // Clear error in provider
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: themeService.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  size: 60,
                  color: themeService.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to ImageQuery AI',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Upload images and ask questions. I\'ll analyze them using multiple AI models to give you the most accurate answers.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              _buildSuggestionChips(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSuggestionChips(ThemeService themeService) {
    final suggestions = [
      'Analyze document',
      'Extract text',
      'Describe image',
      'Compare photos',
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: suggestions.map((suggestion) {
        return ActionChip(
          label: Text(suggestion),
          onPressed: () {
            // Auto-fill suggestion in message input
          },
          backgroundColor: themeService.primaryColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: themeService.primaryColor,
            fontWeight: FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: chatProvider.currentMessages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.currentMessages[index];
        return MessageBubble(
          message: message,
          onRetry: () => chatProvider.retryLastMessage(),
          onEdit: message.type == MessageType.user
              ? () => _showEditMessageDialog(context, chatProvider, message)
              : null,
          onShare: message.type == MessageType.ai
              ? () => _shareMessage(context, chatProvider, message)
              : null,
        );
      },
    );
  }

  void _showChatSessions() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: chatProvider,
          child: const ChatSessionsScreen(),
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _createNewChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.createNewChatSession();
  }

  void _showSettings() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: chatProvider,
          child: const SettingsScreen(),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showEditMessageDialog(
    BuildContext context,
    ChatProvider chatProvider,
    Message message,
  ) {
    final TextEditingController editController = TextEditingController(
      text: message.content,
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Message'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show images if present
              if (message.imagePaths.isNotEmpty) ...[
                const Text(
                  'Images attached:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: message.imagePaths.map((path) {
                    final fileName = path.split('/').last;
                    return Chip(
                      label: Text(fileName),
                      avatar: const Icon(Icons.image, size: 16),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: editController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Edit your message...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Note: Editing will regenerate the AI response and remove subsequent messages.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newContent = editController.text.trim();
                if (newContent.isNotEmpty && newContent != message.content) {
                  chatProvider.editMessage(
                    messageId: message.id,
                    newContent: newContent,
                  );
                }
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _shareMessage(
    BuildContext context,
    ChatProvider chatProvider,
    Message message,
  ) {
    chatProvider.shareMessage(message);

    // Show a snackbar to indicate the message was copied to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
