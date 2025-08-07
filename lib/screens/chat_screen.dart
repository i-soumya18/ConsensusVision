import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_widget.dart';
import '../theme/app_theme.dart';
import 'chat_sessions_screen.dart';
import 'package:shimmer/shimmer.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
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

              // Messages area
              Expanded(
                child: chatProvider.currentMessages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(chatProvider),
              ),

              // Input area
              MessageInputWidget(
                onSendMessage: (message, images) {
                  chatProvider.sendMessage(content: message, images: images);
                  _scrollToBottom();
                },
                isLoading: chatProvider.isLoading,
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                chatProvider.currentSession?.title ?? 'ImageQuery AI',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (chatProvider.currentSession != null)
                Text(
                  '${chatProvider.currentMessages.length} messages',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          onPressed: () => _showChatSessions(),
          tooltip: 'Chat History',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'new_chat',
              child: Row(
                children: [
                  Icon(Icons.add_comment),
                  SizedBox(width: 8),
                  Text('New Chat'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'search',
              child: Row(
                children: [
                  Icon(Icons.search),
                  SizedBox(width: 8),
                  Text('Search Messages'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
          ],
        ),
      ],
      elevation: 0,
      backgroundColor: AppTheme.surfaceColor,
    );
  }

  Widget _buildErrorBanner(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: AppTheme.errorColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: AppTheme.errorColor, fontSize: 14),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: AppTheme.errorColor,
            onPressed: () {
              // Clear error in provider
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy,
              size: 60,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Welcome to ImageQuery AI',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Upload images and ask questions. I\'ll analyze them using multiple AI models to give you the most accurate answers.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.onSurfaceColor.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          _buildSuggestionChips(),
        ],
      ),
    );
  }

  Widget _buildSuggestionChips() {
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
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          labelStyle: TextStyle(
            color: AppTheme.primaryColor,
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
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimationController,
      child: FloatingActionButton(
        onPressed: () => _createNewChat(),
        child: const Icon(Icons.add_comment),
        tooltip: 'New Chat',
      ),
    );
  }

  void _showChatSessions() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ChatSessionsScreen()));
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_chat':
        _createNewChat();
        break;
      case 'search':
        _showSearch();
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  void _createNewChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.createNewChatSession();
  }

  void _showSearch() {
    showSearch(context: context, delegate: MessageSearchDelegate());
  }

  void _showSettings() {
    // Implement settings screen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings coming soon!')));
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
}

class MessageSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: const Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Enter a search term'));
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        return FutureBuilder(
          future: chatProvider.searchMessages(query),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingShimmer();
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final messages = snapshot.data ?? [];
            if (messages.isEmpty) {
              return const Center(child: Text('No messages found'));
            }

            return ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: messages[index]);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search through your message history'));
    }

    return buildResults(context);
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceColor,
      highlightColor: AppTheme.surfaceColor.withOpacity(0.8),
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(16),
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
          );
        },
      ),
    );
  }
}
