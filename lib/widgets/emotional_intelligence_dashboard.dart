import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/emotional_state.dart';
import '../services/emotional_memory_service.dart';

class EmotionalIntelligenceDashboard extends StatefulWidget {
  const EmotionalIntelligenceDashboard({super.key});

  @override
  State<EmotionalIntelligenceDashboard> createState() =>
      _EmotionalIntelligenceDashboardState();
}

class _EmotionalIntelligenceDashboardState
    extends State<EmotionalIntelligenceDashboard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (!chatProvider.emotionalIntelligenceEnabled) {
          return const SizedBox.shrink();
        }

        final emotionalContext = chatProvider.getSessionEmotionalContext();
        final insights = chatProvider.getEmotionalInsights();
        final dominantEmotions = chatProvider.getCurrentDominantEmotions();
        final trend = chatProvider.getCurrentEmotionalTrend();
        final needsSupport = chatProvider.shouldProvideEmotionalSupport();

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 2,
          child: ExpansionTile(
            title: Row(
              children: [
                Icon(
                  Icons.psychology,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Emotional Intelligence',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (needsSupport)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Support Recommended',
                      style: TextStyle(
                        color: Colors.orange.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            initiallyExpanded: _isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _isExpanded = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Emotional State
                    _buildSectionHeader(
                      'Current State',
                      Icons.sentiment_satisfied,
                    ),
                    const SizedBox(height: 8),
                    _buildEmotionalStateRow(trend, dominantEmotions),

                    const SizedBox(height: 16),

                    // Session Context
                    if (emotionalContext.isNotEmpty) ...[
                      _buildSectionHeader('Session Context', Icons.timeline),
                      const SizedBox(height: 8),
                      _buildSessionContextCard(emotionalContext),
                      const SizedBox(height: 16),
                    ],

                    // Insights
                    if (insights.isNotEmpty) ...[
                      _buildSectionHeader('Insights', Icons.insights),
                      const SizedBox(height: 8),
                      _buildInsightsCard(insights),
                      const SizedBox(height: 16),
                    ],

                    // Action Buttons
                    _buildActionButtons(chatProvider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmotionalStateRow(
    EmotionalTrend trend,
    List<EmotionType> emotions,
  ) {
    return Row(
      children: [
        // Trend Indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTrendColor(trend).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getTrendIcon(trend),
                size: 14,
                color: _getTrendColor(trend),
              ),
              const SizedBox(width: 4),
              Text(
                trend.displayName,
                style: TextStyle(
                  color: _getTrendColor(trend),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Emotions
        Expanded(
          child: Wrap(
            spacing: 4,
            children: emotions.take(3).map((emotion) {
              return Chip(
                label: Text(
                  emotion.displayName,
                  style: const TextStyle(fontSize: 10),
                ),
                backgroundColor: emotion.isPositive
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                side: BorderSide(
                  color: emotion.isPositive
                      ? Colors.green.shade200
                      : Colors.orange.shade200,
                  width: 1,
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionContextCard(Map<String, dynamic> contextData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Emotions Detected:',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                '${contextData['session_emotion_count'] ?? 0}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (contextData['last_emotions'] != null &&
              contextData['last_emotions'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Recent: ${(contextData['last_emotions'] as List).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightsCard(Map<String, dynamic> insights) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (insights['positive_ratio'] != null) ...[
            _buildInsightRow(
              'Positive Interactions',
              '${(insights['positive_ratio'] * 100).toStringAsFixed(1)}%',
              Colors.green,
            ),
          ],
          if (insights['most_common_sentiment'] != null) ...[
            const SizedBox(height: 8),
            _buildInsightRow(
              'Most Common Mood',
              insights['most_common_sentiment'],
              Theme.of(context).colorScheme.primary,
            ),
          ],
          if (insights['total_interactions'] != null) ...[
            const SizedBox(height: 8),
            _buildInsightRow(
              'Total Interactions',
              '${insights['total_interactions']}',
              Theme.of(context).colorScheme.secondary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInsightRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ChatProvider chatProvider) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              chatProvider.setEmotionalIntelligenceEnabled(false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emotional Intelligence disabled'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.visibility_off, size: 16),
            label: const Text('Disable'),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Show detailed emotional analytics
              _showDetailedAnalytics(context, chatProvider);
            },
            icon: const Icon(Icons.analytics, size: 16),
            label: const Text('Analytics'),
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ),
      ],
    );
  }

  Color _getTrendColor(EmotionalTrend trend) {
    switch (trend) {
      case EmotionalTrend.improving:
        return Colors.green;
      case EmotionalTrend.stable:
        return Colors.blue;
      case EmotionalTrend.declining:
        return Colors.orange;
    }
  }

  IconData _getTrendIcon(EmotionalTrend trend) {
    switch (trend) {
      case EmotionalTrend.improving:
        return Icons.trending_up;
      case EmotionalTrend.stable:
        return Icons.trending_flat;
      case EmotionalTrend.declining:
        return Icons.trending_down;
    }
  }

  void _showDetailedAnalytics(BuildContext context, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emotional Intelligence Analytics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This feature provides insights into user emotional patterns and helps the AI provide more empathetic responses.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text('Features:'),
              const SizedBox(height: 8),
              _buildFeatureList(),
              const SizedBox(height: 16),
              Text(
                'Facial Expression Recognition: ${chatProvider.getFacialExpressionCapabilities()['is_supported'] ? 'Available' : 'Coming Soon'}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    const features = [
      '• Real-time sentiment analysis',
      '• Emotional memory across sessions',
      '• Adaptive response tone',
      '• Frustration detection',
      '• Achievement recognition',
      '• Proactive emotional support',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(feature, style: Theme.of(context).textTheme.bodySmall),
        );
      }).toList(),
    );
  }
}
