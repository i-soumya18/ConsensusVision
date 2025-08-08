import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'image_preview_widget.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onRetry;

  const MessageBubble({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isUser = message.type == MessageType.user;
        final isError = message.status == MessageStatus.error;
        final isSending = message.status == MessageStatus.sending;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Row(
            mainAxisAlignment: isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 16,
                  backgroundColor: themeService.primaryColor,
                  child: Icon(Icons.smart_toy, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? themeService.primaryColor
                        : isError
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.aiMessageColor,
                    borderRadius: BorderRadius.circular(18).copyWith(
                      bottomLeft: isUser ? null : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : null,
                    ),
                    border: isError
                        ? Border.all(color: AppTheme.errorColor, width: 1)
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Images if present
                      if (message.imagePaths.isNotEmpty) ...[
                        ImagePreviewWidget(imagePaths: message.imagePaths),
                        const SizedBox(height: 8),
                      ],

                      // Message content with enhanced loading animation
                      if (isSending)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 150,
                              child: AnimatedTextKit(
                                animatedTexts: [
                                  TypewriterAnimatedText(
                                    message.content.isNotEmpty
                                        ? message.content
                                        : 'Thinking...',
                                    textStyle: TextStyle(
                                      color: isUser
                                          ? Colors.white
                                          : AppTheme.onSurfaceColor,
                                      fontSize: 16,
                                    ),
                                    speed: const Duration(milliseconds: 80),
                                  ),
                                ],
                                repeatForever: true,
                                pause: const Duration(milliseconds: 1000),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  themeService.primaryColor.withOpacity(0.7),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        // Use markdown rendering for AI responses, SelectableText for user messages
                        isUser
                            ? SelectableText(
                                message.content,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              )
                            : _buildMarkdownContent(
                                message.content,
                                themeService,
                              ),

                      const SizedBox(height: 4),

                      // Message metadata with enhanced contextual indicators
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('HH:mm').format(message.timestamp),
                            style: TextStyle(
                              color:
                                  (isUser
                                          ? Colors.white
                                          : AppTheme.onSurfaceColor)
                                      .withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),

                          // Show context indicator for AI responses that reference previous conversation
                          if (!isUser &&
                              _isContextualResponse(message.content)) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: 'Response uses conversation context',
                              child: Icon(
                                Icons.chat_bubble_outline,
                                size: 12,
                                color: themeService.primaryColor.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                          ],

                          if (!isUser && message.aiModel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: themeService.primaryColor.withOpacity(
                                  0.2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                message.aiModel!.split(' ').first,
                                style: TextStyle(
                                  color: themeService.primaryColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (message.confidence != null &&
                              message.confidence! > 0) ...[
                            const SizedBox(width: 4),
                            Tooltip(
                              message:
                                  'Confidence: ${(message.confidence! * 100).toStringAsFixed(0)}%',
                              child: Icon(
                                Icons.verified,
                                size: 12,
                                color: _getConfidenceColor(
                                  message.confidence!,
                                  themeService,
                                ),
                              ),
                            ),
                          ],
                          if (isError) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onRetry,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: themeService.primaryColor,
                  child: Icon(Icons.person, size: 18, color: Colors.white),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getConfidenceColor(double confidence, ThemeService themeService) {
    if (confidence >= 0.8) return AppTheme.successColor;
    if (confidence >= 0.6) return Colors.orange;
    return AppTheme.errorColor;
  }

  Widget _buildMarkdownContent(String content, ThemeService themeService) {
    return Container(
      constraints: const BoxConstraints(minHeight: 0),
      child: MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          // Text styles
          p: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 16,
            height: 1.4,
          ),
          h1: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h2: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h3: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h4: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h5: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          h6: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),

          // Code styles
          code: TextStyle(
            backgroundColor: themeService.primaryColor.withOpacity(0.1),
            color: themeService.primaryColor,
            fontFamily: 'monospace',
            fontSize: 14,
          ),
          codeblockDecoration: BoxDecoration(
            color: themeService.primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: themeService.primaryColor.withOpacity(0.2),
            ),
          ),
          codeblockPadding: const EdgeInsets.all(12),

          // List styles
          listBullet: TextStyle(color: themeService.primaryColor, fontSize: 16),

          // Quote styles
          blockquote: TextStyle(
            color: AppTheme.onSurfaceColor.withOpacity(0.8),
            fontStyle: FontStyle.italic,
            fontSize: 16,
          ),
          blockquoteDecoration: BoxDecoration(
            color: themeService.primaryColor.withOpacity(0.05),
            border: Border(
              left: BorderSide(color: themeService.primaryColor, width: 4),
            ),
          ),
          blockquotePadding: const EdgeInsets.all(12),

          // Link styles
          a: TextStyle(
            color: themeService.primaryColor,
            decoration: TextDecoration.underline,
          ),

          // Table styles
          tableHead: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
          tableBody: TextStyle(color: AppTheme.onSurfaceColor),
          tableBorder: TableBorder.all(
            color: themeService.primaryColor.withOpacity(0.3),
            width: 1,
          ),

          // Strong and emphasis
          strong: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontWeight: FontWeight.bold,
          ),
          em: TextStyle(
            color: AppTheme.onSurfaceColor,
            fontStyle: FontStyle.italic,
          ),
        ),
        onTapLink: (text, href, title) {
          // Handle link taps here if needed
          // You could use url_launcher package to open external links
        },
      ),
    );
  }

  // Check if the AI response shows contextual awareness
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
