import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/context_management_service.dart';
import '../widgets/context_visualization_widget.dart';
import '../theme/app_theme.dart';

/// Demo screen to showcase context management capabilities
class ContextManagementDemoScreen extends StatefulWidget {
  const ContextManagementDemoScreen({super.key});

  @override
  State<ContextManagementDemoScreen> createState() =>
      _ContextManagementDemoScreenState();
}

class _ContextManagementDemoScreenState
    extends State<ContextManagementDemoScreen> {
  List<Message> _demoMessages = [];
  String _currentQuery = '';
  int _messageCounter = 0;

  @override
  void initState() {
    super.initState();
    _generateDemoConversation();
  }

  void _generateDemoConversation() {
    _demoMessages = [
      _createMessage(
        'Hello! I need help understanding AI and machine learning concepts.',
        MessageType.user,
      ),
      _createMessage(
        'I\'d be happy to help you understand AI and machine learning! These fields are fascinating and have many practical applications. What specific aspect would you like to explore first?',
        MessageType.ai,
      ),
      _createMessage('What are neural networks exactly?', MessageType.user),
      _createMessage(
        'Neural networks are computational models inspired by biological neural networks in the brain. They consist of interconnected nodes (neurons) organized in layers that process information and learn patterns from data.',
        MessageType.ai,
      ),
      _createMessage('Can you explain how they learn?', MessageType.user),
      _createMessage(
        'Neural networks learn through a process called training, where they adjust the weights of connections between neurons based on examples. This happens through backpropagation, which minimizes prediction errors.',
        MessageType.ai,
      ),
      _createMessage(
        'Here\'s a diagram of a neural network I found',
        MessageType.user,
        hasImage: true,
      ),
      _createMessage(
        'This diagram shows a classic feedforward neural network with an input layer, hidden layers, and an output layer. Each connection has a weight that determines how much influence one neuron has on another.',
        MessageType.ai,
      ),
      _createMessage(
        'What about computer vision? How does that work?',
        MessageType.user,
      ),
      _createMessage(
        'Computer vision uses neural networks, particularly Convolutional Neural Networks (CNNs), to analyze and understand visual content. They can identify objects, faces, text, and even complex scenes in images.',
        MessageType.ai,
      ),
      _createMessage(
        'I want to learn about object detection specifically',
        MessageType.user,
      ),
      _createMessage(
        'Object detection combines image classification and localization. Popular algorithms include YOLO (You Only Look Once), R-CNN, and SSD. They can identify multiple objects in an image and draw bounding boxes around them.',
        MessageType.ai,
      ),
      _createMessage('Tell me more about YOLO algorithm', MessageType.user),
      _createMessage(
        'YOLO is a real-time object detection system that treats detection as a regression problem. It divides images into a grid and predicts bounding boxes and class probabilities directly, making it very fast for real-time applications.',
        MessageType.ai,
      ),
      _createMessage(
        'Actually, let me switch topics. What about natural language processing?',
        MessageType.user,
      ),
      _createMessage(
        'Natural Language Processing (NLP) is another exciting AI field that helps computers understand, interpret, and generate human language. It powers chatbots, translation services, sentiment analysis, and text summarization.',
        MessageType.ai,
      ),
      _createMessage('How do transformers work in NLP?', MessageType.user),
      _createMessage(
        'Transformers revolutionized NLP with their attention mechanism. They can process sequences in parallel and focus on relevant parts of input text, making them highly effective for tasks like translation and text generation.',
        MessageType.ai,
      ),
      _createMessage(
        'This is getting really complex. Can you summarize what we\'ve covered?',
        MessageType.user,
      ),
      _createMessage(
        'Certainly! We\'ve explored several key AI concepts: neural networks and their learning process, computer vision with CNNs for image analysis, object detection algorithms like YOLO, and natural language processing with transformers. Each area builds on foundational machine learning principles but applies them to different types of data and problems.',
        MessageType.ai,
      ),
    ];

    _currentQuery = 'What are the latest developments in generative AI?';
  }

  Message _createMessage(
    String content,
    MessageType type, {
    bool hasImage = false,
  }) {
    _messageCounter++;
    return Message(
      id: 'demo_$_messageCounter',
      content: content,
      type: type,
      timestamp: DateTime.now().subtract(
        Duration(minutes: (_demoMessages.length * 2)),
      ),
      imagePaths: hasImage ? ['/demo/path/image.png'] : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Management Demo'),
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildConversationOverview(),
            const SizedBox(height: 24),
            _buildContextAnalysis(),
            const SizedBox(height: 24),
            _buildTopicAnalysis(),
            const SizedBox(height: 24),
            _buildContextVisualization(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _regenerateDemo,
        icon: const Icon(Icons.refresh),
        label: const Text('Regenerate Demo'),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.psychology, color: AppTheme.primaryColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Context Management',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                      ),
                      Text(
                        'Intelligent conversation context handling with topic detection and smart message selection',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This demo showcases the advanced context management system that implements prompt engineering best practices for maintaining conversation continuity and handling topic transitions.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationOverview() {
    final topics = _extractTopicsFromMessages();
    final imageCount = _demoMessages
        .where((m) => m.imagePaths.isNotEmpty)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conversation Overview',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  'Messages',
                  '${_demoMessages.length}',
                  Icons.chat,
                ),
                const SizedBox(width: 8),
                _buildStatChip('Images', '$imageCount', Icons.image),
                const SizedBox(width: 8),
                _buildStatChip('Topics', '${topics.length}', Icons.topic),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Main Topics: ${topics.take(5).join(', ')}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextAnalysis() {
    final contextMessages = ContextManagementService.getOptimalContextMessages(
      _demoMessages,
    );
    final summary = ContextManagementService.generateIntelligentSummary(
      _demoMessages,
    );
    final transition = ContextManagementService.detectTopicTransition(
      _demoMessages,
      _currentQuery,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Context Analysis Results',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildAnalysisRow(
              'Context Window Size',
              '${contextMessages.length}/${_demoMessages.length}',
            ),
            _buildAnalysisRow(
              'Topic Transition',
              _getTransitionLabel(transition),
            ),
            _buildAnalysisRow('Next Query', _currentQuery),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Generated Summary:',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  summary,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopicAnalysis() {
    final enhancedQuery = ContextManagementService.enhanceQueryWithContext(
      _currentQuery,
      ContextManagementService.getOptimalContextMessages(_demoMessages),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Query Enhancement',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildQueryComparison('Original Query', _currentQuery),
            const SizedBox(height: 12),
            _buildQueryComparison('Enhanced Query', enhancedQuery),
            const SizedBox(height: 16),
            Text(
              'Enhancement Analysis:',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              enhancedQuery == _currentQuery
                  ? 'No enhancement needed - query is already specific enough'
                  : 'Query enhanced with conversational context to improve AI response quality',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextVisualization() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Context Visualization',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ContextVisualizationWidget(
          allMessages: _demoMessages,
          currentQuery: _currentQuery,
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
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

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryComparison(String label, String query) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.onSurfaceColor.withOpacity(0.2)),
          ),
          child: Text(query, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  List<String> _extractTopicsFromMessages() {
    final topics = <String>{};
    for (final message in _demoMessages) {
      final words = message.content
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((word) => word.length > 4)
          .toSet();
      topics.addAll(words.take(3));
    }
    return topics.take(8).toList();
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

  void _regenerateDemo() {
    setState(() {
      _messageCounter = 0;
      _generateDemoConversation();
      _currentQuery = [
        'What are the latest developments in generative AI?',
        'How can I apply these concepts to my own projects?',
        'What are the ethical considerations in AI development?',
        'Can you explain the difference between supervised and unsupervised learning?',
      ][DateTime.now().millisecond % 4];
    });
  }
}
