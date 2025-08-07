import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/chat_session.dart';
import '../theme/app_theme.dart';

class ChatSessionsScreen extends StatefulWidget {
  const ChatSessionsScreen({super.key});

  @override
  State<ChatSessionsScreen> createState() => _ChatSessionsScreenState();
}

class _ChatSessionsScreenState extends State<ChatSessionsScreen> {
  @override
  void initState() {
    super.initState();
    // Ensure sessions are loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ChatProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _createNewChat(),
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.chatSessions.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chatProvider.chatSessions.length,
            itemBuilder: (context, index) {
              final session = chatProvider.chatSessions[index];
              return _buildSessionCard(session, chatProvider);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.onSurfaceColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No chat history yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your first conversation!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _createNewChat(),
            icon: const Icon(Icons.add_comment),
            label: const Text('New Chat'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(ChatSession session, ChatProvider chatProvider) {
    final isActive = chatProvider.currentSession?.id == session.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isActive ? 4 : 2,
      color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.chat, color: AppTheme.primaryColor, size: 24),
        ),
        title: Text(
          session.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? AppTheme.primaryColor : null,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${session.messageCount} messages',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(session.lastUpdated),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.onSurfaceColor.withOpacity(0.6),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) =>
              _handleSessionAction(value, session, chatProvider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Rename'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          child: Icon(
            Icons.more_vert,
            color: AppTheme.onSurfaceColor.withOpacity(0.6),
          ),
        ),
        onTap: () => _selectSession(session, chatProvider),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sessionDate = DateTime(date.year, date.month, date.day);

    if (sessionDate == today) {
      return 'Today ${DateFormat('HH:mm').format(date)}';
    } else if (sessionDate == yesterday) {
      return 'Yesterday ${DateFormat('HH:mm').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE HH:mm').format(date);
    } else {
      return DateFormat('MMM dd, HH:mm').format(date);
    }
  }

  void _createNewChat() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.createNewChatSession().then((_) {
      Navigator.pop(context);
    });
  }

  void _selectSession(ChatSession session, ChatProvider chatProvider) {
    chatProvider.switchToChatSession(session.id).then((_) {
      Navigator.pop(context);
    });
  }

  void _handleSessionAction(
    String action,
    ChatSession session,
    ChatProvider chatProvider,
  ) {
    switch (action) {
      case 'rename':
        _showRenameDialog(session, chatProvider);
        break;
      case 'delete':
        _showDeleteConfirmation(session, chatProvider);
        break;
    }
  }

  void _showRenameDialog(ChatSession session, ChatProvider chatProvider) {
    final TextEditingController controller = TextEditingController(
      text: session.title,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Chat'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Chat title',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty && newTitle != session.title) {
                chatProvider.renameChatSession(session.id, newTitle);
              }
              Navigator.pop(context);
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(ChatSession session, ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: Text(
          'Are you sure you want to delete "${session.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.deleteChatSession(session.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
