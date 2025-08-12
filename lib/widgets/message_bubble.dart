import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/theme_service.dart';
import 'image_preview_widget.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRetry;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onReadAloud;

  const MessageBubble({
    super.key,
    required this.message,
    this.onRetry,
    this.onEdit,
    this.onShare,
    this.onReadAloud,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isUser = message.type == MessageType.user;
        final isError = message.status == MessageStatus.error;
        final isSending = message.status == MessageStatus.sending;

        return Container(
          margin: EdgeInsets.only(
            left: isUser ? MediaQuery.of(context).size.width * 0.15 : 16,
            right: isUser ? 16 : MediaQuery.of(context).size.width * 0.15,
            top: 3,
            bottom: 3,
          ),
          child: Column(
            crossAxisAlignment: isUser 
              ? CrossAxisAlignment.end 
              : CrossAxisAlignment.start,
            children: [
              // Message bubble
              GestureDetector(
                onLongPress: () => _showMessageActions(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: _getBubbleColor(isUser, isError, themeService),
                    borderRadius: _getBorderRadius(isUser),
                    boxShadow: [
                      BoxShadow(
                        color: isUser 
                          ? Colors.black.withOpacity(0.1)
                          : Colors.black.withOpacity(0.06),
                        blurRadius: isUser ? 8 : 6,
                        offset: Offset(0, isUser ? 2 : 1),
                      ),
                    ],
                    // Add border for AI messages to better define them
                    border: !isUser && !isError ? Border.all(
                      color: Colors.grey.shade200,
                      width: 0.5,
                    ) : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: message.imagePaths.isNotEmpty ? 10 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Images if present
                            if (message.imagePaths.isNotEmpty) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ImagePreviewWidget(
                                  imagePaths: message.imagePaths,
                                ),
                              ),
                              if (message.content.isNotEmpty)
                                const SizedBox(height: 8),
                            ],

                            // Text content
                            if (message.content.isNotEmpty)
                              _buildMessageContent(
                                isUser, 
                                isSending, 
                                themeService
                              ),
                          ],
                        ),
                      ),

                      // Message metadata
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 14, 
                          right: 14, 
                          bottom: 10,
                        ),
                        child: _buildMessageMetadata(
                          isUser, 
                          isError, 
                          isSending, 
                          themeService
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Timestamp (outside bubble, WhatsApp style)
              if (!isSending)
                Padding(
                  padding: EdgeInsets.only(
                    top: 4,
                    left: isUser ? 0 : 12,
                    right: isUser ? 12 : 0,
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getBubbleColor(bool isUser, bool isError, ThemeService themeService) {
    if (isError) {
      return Colors.red.shade50;
    }
    if (isUser) {
      // Use user-selected bubble color
      return themeService.userBubbleColor;
    }
    // Use user-selected AI bubble color  
    return themeService.aiBubbleColor;
  }

  Color _getTextColor(bool isUser, ThemeService themeService) {
    if (isUser) {
      // Calculate contrast color for user bubble
      final bubbleColor = themeService.userBubbleColor;
      return _getContrastColor(bubbleColor);
    }
    // Calculate contrast color for AI bubble
    final bubbleColor = themeService.aiBubbleColor;
    return _getContrastColor(bubbleColor);
  }

  Color _getContrastColor(Color backgroundColor) {
    // Calculate luminance to determine if we need dark or light text
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  BorderRadius _getBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
    );
  }

  Widget _buildMessageContent(bool isUser, bool isSending, ThemeService themeService) {
    if (isSending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message.content.isNotEmpty ? message.content : 'Sending...',
              style: TextStyle(
                color: _getTextColor(isUser, themeService),
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                isUser ? _getTextColor(isUser, themeService).withOpacity(0.8) : themeService.primaryColor,
              ),
            ),
          ),
        ],
      );
    }

    if (isUser) {
      return SelectableText(
        message.content,
        style: TextStyle(
          color: _getTextColor(isUser, themeService),
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      );
    } else {
      return _buildMarkdownContent(message.content, themeService, false);
    }
  }

  Widget _buildMessageMetadata(bool isUser, bool isError, bool isSending, ThemeService themeService) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Model indicator
        if (!isUser && message.aiModel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: themeService.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message.aiModel!.split(' ').first.toUpperCase(),
              style: TextStyle(
                color: themeService.primaryColor,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],

        // Confidence indicator
        if (!isUser && message.confidence != null && message.confidence! > 0) ...[
          Icon(
            _getConfidenceIcon(message.confidence!),
            size: 12,
            color: _getConfidenceColor(message.confidence!),
          ),
          const SizedBox(width: 6),
        ],

        // Context indicator
        if (!isUser && _isContextualResponse(message.content)) ...[
          Icon(
            Icons.link,
            size: 12,
            color: themeService.primaryColor.withOpacity(0.6),
          ),
          const SizedBox(width: 6),
        ],

        const Spacer(),

        // Error retry button
        if (isError && onRetry != null)
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Message status for user messages (WhatsApp-style)
        if (isUser && !isSending) ...[
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Double check mark for sent messages
              Icon(
                message.status == MessageStatus.sent 
                  ? Icons.done_all 
                  : Icons.done,
                size: 16,
                color: message.status == MessageStatus.sent
                  ? Colors.blue.shade300 // Read receipt color
                  : _getTextColor(isUser, themeService).withOpacity(0.8), // Sent color
              ),
            ],
          ),
        ] else if (isUser) ...[
          const Spacer(),
          // Clock icon for sending messages
          Icon(
            Icons.schedule,
            size: 14,
            color: _getTextColor(isUser, themeService).withOpacity(0.8),
          ),
        ],
      ],
    );
  }

  Widget _buildMarkdownContent(String content, ThemeService themeService, bool isUser) {
    final textColor = _getTextColor(isUser, themeService);
    final isDarkBackground = textColor == Colors.white;
    
    return Container(
      constraints: const BoxConstraints(minHeight: 0),
      child: MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          // Base text style with dynamic color
          p: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.4,
          ),
          
          // Headers with dynamic color
          h1: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h2: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h3: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),

          // Code styling with adaptive colors
          code: TextStyle(
            backgroundColor: isDarkBackground ? Colors.grey.shade800 : Colors.grey.shade100,
            color: isDarkBackground ? Colors.orange.shade300 : Colors.red.shade700,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: isDarkBackground ? Colors.grey.shade800 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkBackground ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
          ),
          codeblockPadding: const EdgeInsets.all(12),

          // Lists
          listBullet: TextStyle(
            color: themeService.primaryColor,
            fontSize: 16,
          ),

          // Quotes with adaptive colors
          blockquote: TextStyle(
            color: isDarkBackground ? Colors.white70 : Colors.black54,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
          blockquoteDecoration: BoxDecoration(
            color: isDarkBackground ? Colors.grey.shade800 : Colors.grey.shade50,
            border: Border(
              left: BorderSide(color: themeService.primaryColor, width: 3),
            ),
          ),
          blockquotePadding: const EdgeInsets.all(12),

          // Links
          a: TextStyle(
            color: themeService.primaryColor,
            decoration: TextDecoration.underline,
          ),

          // Emphasis with dynamic colors
          strong: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
          em: TextStyle(
            color: textColor,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    final isUser = message.type == MessageType.user;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Actions
              if (isUser && onEdit != null)
                _buildActionTile(
                  icon: Icons.edit,
                  title: 'Edit Message',
                  onTap: () {
                    Navigator.pop(context);
                    onEdit!();
                  },
                ),

              if (!isUser && onShare != null)
                _buildActionTile(
                  icon: Icons.share,
                  title: 'Share Response',
                  onTap: () {
                    Navigator.pop(context);
                    onShare!();
                  },
                ),

              if (!isUser && onReadAloud != null)
                _buildActionTile(
                  icon: Icons.volume_up,
                  title: 'Read Aloud',
                  onTap: () {
                    Navigator.pop(context);
                    onReadAloud!();
                  },
                ),

              _buildActionTile(
                icon: Icons.copy,
                title: 'Copy Text',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement copy functionality
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 0.8) return Icons.verified;
    if (confidence >= 0.6) return Icons.check_circle_outline;
    return Icons.help_outline;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  bool _isContextualResponse(String content) {
    final contextualIndicators = [
      'as we discussed',
      'from the previous',
      'building on',
      'continuing from',
      'as mentioned',
      'referring to',
      'earlier',
      'previously',
      'that image',
      'those images',
      'the image you',
      'your previous',
      'our conversation',
      'we talked about',
      'you asked about',
      'regarding',
      'about that',
      'from before',
      'as you said',
      'following up',
    ];

    final lowerContent = content.toLowerCase();
    return contextualIndicators.any(
      (indicator) => lowerContent.contains(indicator),
    );
  }
}
