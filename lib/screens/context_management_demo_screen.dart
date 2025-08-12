import 'package:flutter/material.dart';
import '../models/message.dart';
import '../widgets/context_visualization_widget.dart';

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
    ];
  }

  Message _createMessage(String content, MessageType type) {
    _messageCounter++;
    return Message(
      id: 'demo_message_$_messageCounter',
      content: content,
      type: type,
      timestamp: DateTime.now().subtract(
        Duration(minutes: _messageCounter * 2),
      ),
      imagePaths: [], // Added to fix the lint error
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Context Management Demo'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildConversationDemo(),
            const SizedBox(height: 24),
            _buildContextExplanation(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Context Management Demo',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'This interactive demo shows how the app manages conversation context to provide relevant responses.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildConversationDemo() {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.psychology,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sample Conversation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        'See how context influences AI responses',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _demoMessages.length + 1, // +1 for input
                itemBuilder: (context, index) {
                  if (index < _demoMessages.length) {
                    final message = _demoMessages[index];
                    return _buildMessageTile(message);
                  } else {
                    return _buildInputField();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageTile(Message message) {
    final isUser = message.type == MessageType.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              radius: 16,
              child: const Icon(Icons.smart_toy, size: 18, color: Colors.blue),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUser
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Text(message.content),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.green.shade100,
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Type a question about AI...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _currentQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: _currentQuery.isEmpty ? null : _handleQuerySubmit,
          ),
        ],
      ),
    );
  }

  void _handleQuerySubmit() {
    if (_currentQuery.isEmpty) return;

    setState(() {
      _demoMessages.add(_createMessage(_currentQuery, MessageType.user));
      _currentQuery = '';
    });

    // Simulate an AI response after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      final response = _generateResponse(_demoMessages.last.content);
      setState(() {
        _demoMessages.add(_createMessage(response, MessageType.ai));
      });
    });
  }

  String _generateResponse(String query) {
    if (query.toLowerCase().contains('neural network')) {
      return 'Neural networks are computing systems inspired by the biological neural networks in animal brains. They consist of layers of interconnected nodes or "neurons" that process information. Each connection can transmit a signal from one neuron to another, and the receiving neuron can process the signal and then signal neurons connected to it.';
    } else if (query.toLowerCase().contains('machine learning')) {
      return 'Machine learning is a subset of AI focused on building systems that learn from data. Instead of explicitly programming rules, these systems identify patterns in data and make decisions with minimal human intervention. There are three main types: supervised learning, unsupervised learning, and reinforcement learning.';
    } else if (query.toLowerCase().contains('deep learning')) {
      return 'Deep learning is a subset of machine learning using neural networks with many layers (hence "deep"). It\'s particularly good at processing unstructured data like images, text, and audio. Deep learning powers technologies like image recognition, natural language processing, and speech recognition.';
    } else {
      return 'That\'s an interesting question about AI! AI (Artificial Intelligence) refers to systems that can perform tasks requiring human-like intelligence. This includes learning from experience, recognizing patterns, understanding language, and making decisions. Would you like to know about a specific aspect of AI?';
    }
  }

  Widget _buildContextExplanation() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How Context Management Works',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildContextInfoCard(
              'Conversational Memory',
              'The app maintains a history of your conversation to provide continuous and coherent responses.',
              Icons.history,
            ),
            const SizedBox(height: 8),
            _buildContextInfoCard(
              'Entity Recognition',
              'Key topics, concepts, and entities in your conversation are identified and remembered.',
              Icons.category,
            ),
            const SizedBox(height: 8),
            _buildContextInfoCard(
              'Context Window Management',
              'The app intelligently manages the conversation window to stay within token limits while preserving important context.',
              Icons.crop_free,
            ),
            const SizedBox(height: 16),
            _buildActionButton(
              'Visualize Context',
              Icons.visibility,
              _showContextVisualization,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextInfoCard(
    String title,
    String description,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showContextVisualization() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, controller) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: Column(
              children: [
                _buildSheetHandle(),
                Expanded(
                  child: ContextVisualizationWidget(
                    allMessages: _demoMessages,
                    currentQuery: _currentQuery,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
