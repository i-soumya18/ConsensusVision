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
            left: isUser ? 60 : 16,
            right: isUser ? 16 : 60,
            top: 2,
            bottom: 2,
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message content
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: message.imagePaths.isNotEmpty ? 8 : 10,
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
                                themeService,
                              ),
                          ],
                        ),
                      ),

                      // Message metadata
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 12,
                          bottom: 8,
                        ),
                        child: _buildMessageMetadata(
                          isUser,
                          isError,
                          isSending,
                          themeService,
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
                    top: 2,
                    left: isUser ? 0 : 8,
                    right: isUser ? 8 : 0,
                  ),
                  child: Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 11,
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
      return themeService.primaryColor;
    }
    return Colors.grey.shade100;
  }

  BorderRadius _getBorderRadius(bool isUser) {
    return BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isUser
          ? const Radius.circular(4)
          : const Radius.circular(18),
    );
  }

  Widget _buildMessageContent(
    bool isUser,
    bool isSending,
    ThemeService themeService,
  ) {
    if (isSending) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              message.content.isNotEmpty ? message.content : 'Typing...',
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
                fontSize: 16,
                height: 1.4,
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
                isUser ? Colors.white70 : themeService.primaryColor,
              ),
            ),
          ),
        ],
      );
    }

    if (isUser) {
      return SelectableText(
        message.content,
        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
      );
    } else {
      return _buildMarkdownContent(message.content, themeService);
    }
  }

  Widget _buildMessageMetadata(
    bool isUser,
    bool isError,
    bool isSending,
    ThemeService themeService,
  ) {
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
        if (!isUser &&
            message.confidence != null &&
            message.confidence! > 0) ...[
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

        // Message status for user messages
        if (isUser && !isSending) ...[
          Icon(
            message.status == MessageStatus.sent ? Icons.check : Icons.schedule,
            size: 14,
            color: Colors.white70,
          ),
        ],
      ],
    );
  }

  Widget _buildMarkdownContent(String content, ThemeService themeService) {
    return Container(
      constraints: const BoxConstraints(minHeight: 0),
      child: MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          // Base text style
          p: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.4),

          // Headers
          h1: const TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h2: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h3: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),

          // Code styling
          code: TextStyle(
            backgroundColor: Colors.grey.shade100,
            color: Colors.red.shade700,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          codeblockPadding: const EdgeInsets.all(12),

          // Lists
          listBullet: TextStyle(color: themeService.primaryColor, fontSize: 16),

          // Quotes
          blockquote: TextStyle(
            color: Colors.black54,
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
          blockquoteDecoration: BoxDecoration(
            color: Colors.grey.shade50,
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

          // Emphasis
          strong: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
          em: const TextStyle(
            color: Colors.black87,
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
    return ListTile(leading: Icon(icon), title: Text(title), onTap: onTap);
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
