import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../providers/context_aware_chat_provider.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_widget.dart';
import '../widgets/conversation_context_indicator.dart';
import '../widgets/emotional_intelligence_dashboard.dart';
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
      body: Stack(
        children: [
          // WhatsApp-inspired background pattern
          _buildWhatsAppBackground(context),

          // Main chat content
          Consumer<ContextAwareChatProvider>(
            builder: (context, chatProvider, child) {
              return Column(
                children: [
                  // Error banner
                  if (chatProvider.error != null)
                    _buildErrorBanner(chatProvider.error!),

                  // Emotional Intelligence Dashboard
                  if (chatProvider.enableEmotionalIntelligence &&
                      chatProvider.currentMessages.isNotEmpty)
                    const EmotionalIntelligenceDashboard(),

                  // Messages area with enhanced context awareness
                  Expanded(
                    child: chatProvider.currentMessages.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: [
                              // Show conversation context indicator for ongoing conversations
                              ConversationContextIndicator(
                                messages: chatProvider.currentMessages,
                                isVisible:
                                    chatProvider.currentMessages.length > 2,
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
        ],
      ),
    );
  }

  Widget _buildWhatsAppBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0D1418) // WhatsApp dark chat background
            : const Color(0xFFE5DDD5), // WhatsApp light chat background
      ),
      child: Stack(
        children: [
          // Main pattern background
          CustomPaint(
            painter: WhatsAppBackgroundPainter(isDark: isDark),
            size: Size.infinite,
          ),

          // Floating decorative elements
          ...List.generate(
            6,
            (index) => _buildFloatingElement(context, index, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingElement(BuildContext context, int index, bool isDark) {
    final screenSize = MediaQuery.of(context).size;
    final positions = [
      [
        screenSize.height * 0.1,
        screenSize.width * 0.85,
        null,
      ], // top, left, right
      [screenSize.height * 0.25, null, screenSize.width * 0.9],
      [screenSize.height * 0.4, screenSize.width * 0.05, null],
      [screenSize.height * 0.6, null, screenSize.width * 0.05],
      [screenSize.height * 0.75, screenSize.width * 0.8, null],
      [screenSize.height * 0.9, null, screenSize.width * 0.1],
    ];

    final position = positions[index];
    final sizes = [12.0, 8.0, 15.0, 10.0, 6.0, 9.0];
    final size = sizes[index];

    return Positioned(
      top: position[0],
      left: position[1],
      right: position[2],
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.04),
        ),
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
                  'Lumini AI',
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            // Semi-transparent overlay for better readability on patterned background
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.white.withOpacity(0.3),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: themeService.primaryColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.smart_toy,
                    size: 60,
                    color: themeService.primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Welcome to Lumini AI',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Upload images and ask questions. I\'ll analyze them using multiple AI models to give you the most accurate answers.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.8),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSuggestionChips(themeService),
              ],
            ),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) {
          return ActionChip(
            label: Text(suggestion),
            onPressed: () {
              // Auto-fill suggestion in message input
            },
            backgroundColor: themeService.primaryColor.withOpacity(0.15),
            labelStyle: TextStyle(
              color: themeService.primaryColor,
              fontWeight: FontWeight.w500,
            ),
            elevation: 2,
            pressElevation: 4,
            shadowColor: themeService.primaryColor.withOpacity(0.3),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessagesList(ContextAwareChatProvider chatProvider) {
    return Container(
      decoration: BoxDecoration(
        // Semi-transparent overlay to improve message readability
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.1)
            : Colors.white.withOpacity(0.15),
      ),
      child: ListView.builder(
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
            onReadAloud: message.type == MessageType.ai
                ? () => _readMessageAloud(context, chatProvider, message)
                : null,
          );
        },
      ),
    );
  }

  void _showChatSessions() {
    final chatProvider = Provider.of<ContextAwareChatProvider>(
      context,
      listen: false,
    );
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
    final chatProvider = Provider.of<ContextAwareChatProvider>(
      context,
      listen: false,
    );
    chatProvider.createNewChatSession();
  }

  void _showSettings() {
    final chatProvider = Provider.of<ContextAwareChatProvider>(
      context,
      listen: false,
    );
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
    ContextAwareChatProvider chatProvider,
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
    ContextAwareChatProvider chatProvider,
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

  void _readMessageAloud(
    BuildContext context,
    ContextAwareChatProvider chatProvider,
    Message message,
  ) {
    chatProvider.readMessageAloud(message);

    // Show a snackbar to indicate the message is being read aloud
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.volume_up, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Reading AI response aloud...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

/// WhatsApp-inspired background painter that creates subtle pattern elements
class WhatsAppBackgroundPainter extends CustomPainter {
  final bool isDark;

  WhatsAppBackgroundPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 1.0;

    // Create subtle geometric pattern similar to WhatsApp
    _drawSubtlePattern(canvas, size, paint);

    // Add very faint overlay texture
    _drawTextureOverlay(canvas, size, paint);
  }

  void _drawSubtlePattern(Canvas canvas, Size size, Paint paint) {
    // Very subtle pattern color
    paint.color = isDark
        ? Colors.white.withOpacity(0.02)
        : Colors.black.withOpacity(0.03);

    final spacing = 80.0;
    final dotRadius = 1.5;

    // Create a subtle dot pattern
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Add slight randomization to avoid perfect grid
        final offsetX = x + (math.sin(y / 100) * 8);
        final offsetY = y + (math.cos(x / 100) * 8);

        canvas.drawCircle(Offset(offsetX, offsetY), dotRadius, paint);
      }
    }

    // Add very faint diagonal lines for texture
    paint.strokeWidth = 0.5;
    paint.style = PaintingStyle.stroke;
    paint.color = isDark
        ? Colors.white.withOpacity(0.01)
        : Colors.black.withOpacity(0.015);

    final lineSpacing = 120.0;
    for (
      double i = -size.height;
      i < size.width + size.height;
      i += lineSpacing
    ) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  void _drawTextureOverlay(Canvas canvas, Size size, Paint paint) {
    // Very subtle noise texture using small rectangles
    paint.style = PaintingStyle.fill;
    paint.color = isDark
        ? Colors.white.withOpacity(0.008)
        : Colors.black.withOpacity(0.012);

    final random = math.Random(42); // Fixed seed for consistent pattern
    final noiseCount = (size.width * size.height / 10000).floor();

    for (int i = 0; i < noiseCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final width = random.nextDouble() * 3 + 1;
      final height = random.nextDouble() * 3 + 1;

      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    }

    // Add very subtle gradient overlay for depth
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              Colors.white.withOpacity(0.015),
              Colors.transparent,
              Colors.black.withOpacity(0.02),
            ]
          : [
              Colors.white.withOpacity(0.3),
              Colors.transparent,
              Colors.black.withOpacity(0.05),
            ],
      stops: const [0.0, 0.5, 1.0],
    );

    final gradientPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
