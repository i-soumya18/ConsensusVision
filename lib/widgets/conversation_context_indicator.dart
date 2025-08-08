import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/message.dart';

class ConversationContextIndicator extends StatelessWidget {
  final List<Message> messages;
  final bool isVisible;

  const ConversationContextIndicator({
    super.key,
    required this.messages,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible || messages.length < 3) {
      return const SizedBox.shrink();
    }

    final contextInfo = _getContextInfo();

    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                contextInfo,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getContextInfo() {
    final userMessages = messages
        .where((m) => m.type == MessageType.user)
        .length;
    final imagesCount = messages.where((m) => m.imagePaths.isNotEmpty).length;

    String info = 'Conversation context: $userMessages exchanges';

    if (imagesCount > 0) {
      info += ', $imagesCount image${imagesCount > 1 ? 's' : ''} analyzed';
    }

    return info;
  }
}
