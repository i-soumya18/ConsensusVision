import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/context_aware_chat_provider.dart';
import '../models/message.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_widget.dart';
import '../services/theme_service.dart';
import 'chat_sessions_screen.dart';
import 'settings_screen.dart';
import 'dart:math' as math;

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _fabAnimationController;
  late AnimationController _headerAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _headerAnimation;
  
  // Golden ratio constants
  static const double goldenRatio = 1.618033988749;
  static const double inverseGoldenRatio = 0.618033988749;
  
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );
    
    _headerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOutCubic),
    );
    
    _scrollController.addListener(() {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
        if (showButton) {
          _fabAnimationController.forward();
        } else {
          _fabAnimationController.reverse();
        }
      }
    });
    
    // Start header animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _headerAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Golden ratio proportions
    final headerHeight = screenHeight * inverseGoldenRatio * 0.15; // ~6.2% of screen
    final messagesHeight = screenHeight * inverseGoldenRatio * 0.85; // ~52.6% of screen
    final inputHeight = screenHeight * (1 - inverseGoldenRatio) * 0.35; // ~13.4% of screen
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Background gradient
          _buildBackgroundGradient(),
          
          // Main content
          Column(
            children: [
              // Custom innovative header
              _buildInnovativeHeader(headerHeight),
              
              // Messages area with golden ratio proportions
              Expanded(
                child: Consumer<ContextAwareChatProvider>(
                  builder: (context, chatProvider, child) {
                    return Stack(
                      children: [
                        // Messages container
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Theme.of(context).colorScheme.surface.withOpacity(0.95),
                                Theme.of(context).colorScheme.surface,
                              ],
                            ),
                          ),
                          child: Column(
                            children: [
                              // Error banner
                              if (chatProvider.error != null)
                                _buildEnhancedErrorBanner(chatProvider.error!),

                              // Emotional Intelligence Dashboard
                              if (chatProvider.enableEmotionalIntelligence &&
                                  chatProvider.currentMessages.isNotEmpty)
                                _buildEnhancedEmotionalDashboard(),

                              // Messages area
                              Expanded(
                                child: chatProvider.currentMessages.isEmpty
                                    ? _buildInnovativeEmptyState()
                                    : _buildEnhancedMessagesList(chatProvider),
                              ),
                            ],
                          ),
                        ),
                        
                        // Floating scroll to bottom button
                        if (_showScrollToBottom)
                          _buildFloatingScrollButton(),
                      ],
                    );
                  },
                ),
              ),
              
              // Enhanced input area with golden ratio proportions
              _buildEnhancedInputArea(),
            ],
          ),
          
          // Floating action elements
          _buildFloatingElements(),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.02),
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.secondary.withOpacity(0.01),
          ],
        ),
      ),
    );
  }

  Widget _buildInnovativeHeader(double height) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return AnimatedBuilder(
          animation: _headerAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -50 * (1 - _headerAnimation.value)),
              child: Opacity(
                opacity: _headerAnimation.value,
                child: Container(
                  height: height + 50, // Extra space for safe area
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        themeService.primaryColor.withOpacity(0.1),
                        themeService.primaryColor.withOpacity(0.05),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: themeService.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // Innovative logo with golden ratio sizing
                          _buildInnovativeLogo(themeService),
                          
                          const Spacer(),
                          
                          // Action buttons with golden ratio spacing
                          _buildHeaderActions(themeService),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInnovativeLogo(ThemeService themeService) {
    final logoSize = 48.0; // Golden ratio: base size
    final iconSize = logoSize * inverseGoldenRatio; // ~29.7px
    
    return Row(
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeService.primaryColor,
                themeService.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(logoSize * 0.3), // Golden ratio curve
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: iconSize,
          ),
        ),
        SizedBox(width: logoSize * 0.3), // Golden ratio spacing
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'ConsensusVision',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'AI Vision Intelligence',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActions(ThemeService themeService) {
    const buttonSize = 44.0;
    const spacing = buttonSize * 0.3; // Golden ratio spacing
    
    return Row(
      children: [
        _buildHeaderActionButton(
          icon: Icons.history_rounded,
          onPressed: _showChatSessions,
          tooltip: 'Chat History',
          themeService: themeService,
        ),
        const SizedBox(width: spacing),
        _buildHeaderActionButton(
          icon: Icons.add_rounded,
          onPressed: _createNewChat,
          tooltip: 'New Chat',
          themeService: themeService,
        ),
        const SizedBox(width: spacing),
        _buildHeaderActionButton(
          icon: Icons.settings_rounded,
          onPressed: _showSettings,
          tooltip: 'Settings',
          themeService: themeService,
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required ThemeService themeService,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  themeService.primaryColor.withOpacity(0.1),
                  themeService.primaryColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: themeService.primaryColor.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: themeService.primaryColor,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
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
                  'ConsensusVision',
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

  Widget _buildEnhancedErrorBanner(String error) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.error.withOpacity(0.1),
            Theme.of(context).colorScheme.error.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.error.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Clear error in provider
                final chatProvider = Provider.of<ContextAwareChatProvider>(
                  context,
                  listen: false,
                );
                chatProvider.clearError();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedEmotionalDashboard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.08),
            Theme.of(context).colorScheme.primary.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emotional Intelligence Active',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI is analyzing conversation context and emotions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInnovativeEmptyState() {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Golden ratio sized elements
              _buildEmptyStateIllustration(themeService),
              SizedBox(height: 80 * inverseGoldenRatio), // Golden ratio spacing
              _buildEmptyStateContent(themeService),
              SizedBox(height: 40 * inverseGoldenRatio),
              _buildEmptyStateSuggestions(themeService),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateIllustration(ThemeService themeService) {
    const baseSize = 120.0;
    final iconSize = baseSize * inverseGoldenRatio; // ~74px
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: baseSize * 1.5,
          height: baseSize * 1.5,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                themeService.primaryColor.withOpacity(0.1),
                themeService.primaryColor.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
        // Main container
        Container(
          width: baseSize,
          height: baseSize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeService.primaryColor.withOpacity(0.15),
                themeService.primaryColor.withOpacity(0.1),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: themeService.primaryColor.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: themeService.primaryColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: iconSize,
            color: themeService.primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateContent(ThemeService themeService) {
    return Column(
      children: [
        Text(
          'Welcome to ConsensusVision',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * inverseGoldenRatio,
          ),
          child: Text(
            'Upload images and ask questions. I\'ll analyze them using multiple AI models to give you the most accurate and insightful answers.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyStateSuggestions(ThemeService themeService) {
    final suggestions = [
      {'icon': Icons.document_scanner_rounded, 'text': 'Analyze document'},
      {'icon': Icons.text_fields_rounded, 'text': 'Extract text'},
      {'icon': Icons.image_search_rounded, 'text': 'Describe image'},
      {'icon': Icons.compare_rounded, 'text': 'Compare photos'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: suggestions.map((suggestion) {
        return _buildSuggestionChip(
          icon: suggestion['icon'] as IconData,
          text: suggestion['text'] as String,
          themeService: themeService,
        );
      }).toList(),
    );
  }

  Widget _buildSuggestionChip({
    required IconData icon,
    required String text,
    required ThemeService themeService,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          // Auto-fill suggestion in message input
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                themeService.primaryColor.withOpacity(0.1),
                themeService.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: themeService.primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: themeService.primaryColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: themeService.primaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedMessagesList(ContextAwareChatProvider chatProvider) {
    return Column(
      children: [
        // Conversation context indicator with enhanced design
        if (chatProvider.currentMessages.length > 2)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  Theme.of(context).colorScheme.primary.withOpacity(0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Conversation context maintained across ${chatProvider.currentMessages.length} messages',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Messages list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            itemCount: chatProvider.currentMessages.length,
            itemBuilder: (context, index) {
              final message = chatProvider.currentMessages[index];
              return Padding(
                padding: EdgeInsets.symmetric(
                  vertical: 8 * inverseGoldenRatio, // Golden ratio spacing
                ),
                child: MessageBubble(
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingScrollButton() {
    return Positioned(
      right: 20,
      bottom: 100,
      child: AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: _scrollToBottom,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnhancedInputArea() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
            Theme.of(context).colorScheme.surface,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Consumer<ContextAwareChatProvider>(
        builder: (context, chatProvider, child) {
          return MessageInputWidget(
            onSendMessage: (message, images, {String? promptTemplate}) {
              chatProvider.sendMessage(
                content: message,
                images: images,
                promptTemplate: promptTemplate,
              );
              _scrollToBottom();
            },
            isLoading: chatProvider.isLoading,
          );
        },
      ),
    );
  }

  Widget _buildFloatingElements() {
    // For future enhancements like floating quick actions
    return const SizedBox.shrink();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text('Edit Message'),
            ],
          ),
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
                      avatar: const Icon(Icons.image_rounded, size: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: editController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Edit your message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Editing will regenerate the AI response and remove subsequent messages.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
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
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text('Message copied to clipboard'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _readMessageAloud(
    BuildContext context,
    ContextAwareChatProvider chatProvider,
    Message message,
  ) {
    chatProvider.readMessageAloud(message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.volume_up_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Reading AI response aloud...'),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
