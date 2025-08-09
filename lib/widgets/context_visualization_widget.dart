import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/context_management_service.dart';
import '../theme/app_theme.dart';

/// Widget to visualize and debug context management decisions
class ContextVisualizationWidget extends StatelessWidget {
  final List<Message> allMessages;
  final String currentQuery;

  const ContextVisualizationWidget({
    super.key,
    required this.allMessages,
    required this.currentQuery,
  });

  @override
  Widget build(BuildContext context) {
    final contextMessages = ContextManagementService.getOptimalContextMessages(
      allMessages,
    );
    final topicTransition = ContextManagementService.detectTopicTransition(
      allMessages,
      currentQuery,
    );
    final enhancedQuery = ContextManagementService.enhanceQueryWithContext(
      currentQuery,
      contextMessages,
    );

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildQueryAnalysis(topicTransition, enhancedQuery),
            const SizedBox(height: 16),
            _buildContextSummary(contextMessages),
            const SizedBox(height: 16),
            _buildMessageAnalysis(contextMessages),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.psychology, color: AppTheme.primaryColor, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Context Management Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'Advanced conversation context and topic tracking',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.onSurfaceColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQueryAnalysis(TopicTransition transition, String enhancedQuery) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getTransitionColor(transition).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getTransitionColor(transition).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTransitionIcon(transition),
                color: _getTransitionColor(transition),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Query Analysis',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAnalysisRow(
            'Topic Transition',
            _getTransitionLabel(transition),
          ),
          if (enhancedQuery != currentQuery) ...[
            const SizedBox(height: 8),
            _buildAnalysisRow('Original Query', currentQuery),
            const SizedBox(height: 4),
            _buildAnalysisRow('Enhanced Query', enhancedQuery),
          ],
        ],
      ),
    );
  }

  Widget _buildContextSummary(List<Message> contextMessages) {
    final recentCount = contextMessages
        .where((m) => allMessages.indexOf(m) >= allMessages.length - 12)
        .length;
    final earlyCount = contextMessages
        .where((m) => allMessages.indexOf(m) < 6)
        .length;
    final bridgeCount = contextMessages
        .where((m) => m.id.startsWith('context-bridge'))
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Context Window Summary',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceColor,
            ),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Total Messages in Context',
            '${contextMessages.length}/${allMessages.length}',
          ),
          _buildSummaryRow('Recent Messages', '$recentCount'),
          _buildSummaryRow('Important Early Messages', '$earlyCount'),
          if (bridgeCount > 0)
            _buildSummaryRow('Context Bridges', '$bridgeCount'),
        ],
      ),
    );
  }

  Widget _buildMessageAnalysis(List<Message> contextMessages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Context Messages',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: contextMessages.length,
            itemBuilder: (context, index) {
              final message = contextMessages[index];
              final originalIndex = allMessages.indexOf(message);

              return _buildMessageCard(message, originalIndex, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMessageCard(
    Message message,
    int originalIndex,
    int contextIndex,
  ) {
    final isRecent = originalIndex >= allMessages.length - 12;
    final isEarly = originalIndex < 6;
    final isBridge = message.id.startsWith('context-bridge');

    Color categoryColor;
    String category;

    if (isBridge) {
      categoryColor = Colors.orange;
      category = 'Bridge';
    } else if (isRecent) {
      categoryColor = Colors.green;
      category = 'Recent';
    } else if (isEarly) {
      categoryColor = Colors.blue;
      category = 'Early';
    } else {
      categoryColor = Colors.purple;
      category = 'Topic';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: categoryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: categoryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$contextIndex',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.type == MessageType.user ? 'User' : 'AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.onSurfaceColor.withOpacity(0.8),
                      ),
                    ),
                    if (message.imagePaths.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.image, size: 12, color: AppTheme.primaryColor),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _truncateContent(message.content),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.onSurfaceColor.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceColor.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: AppTheme.onSurfaceColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.onSurfaceColor.withOpacity(0.8),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTransitionColor(TopicTransition transition) {
    switch (transition) {
      case TopicTransition.newConversation:
        return Colors.blue;
      case TopicTransition.continuation:
        return Colors.green;
      case TopicTransition.related:
        return Colors.orange;
      case TopicTransition.newTopic:
        return Colors.red;
    }
  }

  IconData _getTransitionIcon(TopicTransition transition) {
    switch (transition) {
      case TopicTransition.newConversation:
        return Icons.new_label;
      case TopicTransition.continuation:
        return Icons.trending_flat;
      case TopicTransition.related:
        return Icons.trending_up;
      case TopicTransition.newTopic:
        return Icons.change_circle;
    }
  }

  String _getTransitionLabel(TopicTransition transition) {
    switch (transition) {
      case TopicTransition.newConversation:
        return 'New Conversation';
      case TopicTransition.continuation:
        return 'Topic Continuation';
      case TopicTransition.related:
        return 'Related Topic';
      case TopicTransition.newTopic:
        return 'New Topic';
    }
  }

  String _truncateContent(String content) {
    if (content.length <= 80) return content;
    return '${content.substring(0, 80)}...';
  }
}
