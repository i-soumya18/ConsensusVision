import '../models/message.dart';

/// Advanced context management service implementing sophisticated conversation handling
/// Based on prompt engineering best practices for context retention and topic transitions
class ContextManagementService {
  static const int _maxContextWindow = 20;
  static const int _recentMessagesCount = 12;
  static const int _importantEarlyMessagesCount = 6;

  /// Enhanced context message selection with intelligent prioritization
  static List<Message> getOptimalContextMessages(List<Message> allMessages) {
    if (allMessages.length <= _maxContextWindow) {
      return allMessages;
    }

    // Stage 1: Recent context (highest priority)
    final recentMessages = _getRecentMessages(allMessages);

    // Stage 2: Important early context
    final importantEarlyMessages = _getImportantEarlyMessages(allMessages);

    // Stage 3: Topic-relevant middle messages
    final topicRelevantMessages = _getTopicRelevantMessages(
      allMessages,
      recentMessages,
    );

    // Stage 4: Combine and optimize
    return _combineContextMessages(
      allMessages,
      recentMessages,
      importantEarlyMessages,
      topicRelevantMessages,
    );
  }

  /// Get recent messages with content quality filtering
  static List<Message> _getRecentMessages(List<Message> allMessages) {
    final recent = allMessages.length >= _recentMessagesCount
        ? allMessages.sublist(allMessages.length - _recentMessagesCount)
        : allMessages;

    // Filter out very short or system messages, but keep images
    return recent
        .where(
          (message) =>
              message.imagePaths.isNotEmpty ||
              message.content.trim().length > 10 ||
              message.type == MessageType.ai,
        )
        .toList();
  }

  /// Identify important early messages that establish context
  static List<Message> _getImportantEarlyMessages(List<Message> allMessages) {
    final earlyMessages = allMessages
        .take(_importantEarlyMessagesCount)
        .toList();
    final importantMessages = <Message>[];

    for (final message in earlyMessages) {
      if (_isMessageImportant(message)) {
        importantMessages.add(message);
      }
    }

    return importantMessages;
  }

  /// Determine if a message is contextually important
  static bool _isMessageImportant(Message message) {
    // Images are always important for context
    if (message.imagePaths.isNotEmpty) return true;

    // Long, detailed messages
    if (message.content.length > 150) return true;

    // Questions that establish conversation direction
    if (message.content.contains('?') && message.type == MessageType.user)
      return true;

    // AI responses with structured information
    if (message.type == MessageType.ai &&
        _hasStructuredContent(message.content))
      return true;

    // Messages with specific keywords indicating important context
    final importantKeywords = [
      'analyze',
      'explain',
      'summarize',
      'compare',
      'evaluate',
      'recommend',
      'solve',
      'create',
      'design',
      'implement',
    ];

    final content = message.content.toLowerCase();
    return importantKeywords.any((keyword) => content.contains(keyword));
  }

  /// Check if content has structured formatting (likely important AI response)
  static bool _hasStructuredContent(String content) {
    return content.contains('##') ||
        content.contains('**') ||
        content.contains('1.') ||
        content.contains('•') ||
        content.contains('- ') ||
        content.contains('```');
  }

  /// Find messages relevant to current conversation topics
  static List<Message> _getTopicRelevantMessages(
    List<Message> allMessages,
    List<Message> recentMessages,
  ) {
    if (allMessages.length < 25) return [];

    // Extract topics from recent messages
    final currentTopics = _extractTopics(recentMessages);
    if (currentTopics.isEmpty) return [];

    // Find middle messages (between early and recent) that relate to current topics
    final middleStart = _importantEarlyMessagesCount;
    final middleEnd = allMessages.length - _recentMessagesCount;

    if (middleEnd <= middleStart) return [];

    final middleMessages = allMessages.sublist(middleStart, middleEnd);
    final relevantMessages = <Message>[];

    for (final message in middleMessages.reversed.take(10)) {
      if (_isMessageRelevantToTopics(message, currentTopics)) {
        relevantMessages.insert(0, message); // Maintain chronological order
        if (relevantMessages.length >= 3)
          break; // Limit topic-relevant messages
      }
    }

    return relevantMessages;
  }

  /// Extract key topics from messages using keyword analysis
  static Set<String> _extractTopics(List<Message> messages) {
    final topics = <String>{};

    for (final message in messages) {
      final words = message.content
          .toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), ' ')
          .split(' ')
          .where((word) => word.length > 4)
          .toSet();

      // Add significant words that might represent topics
      topics.addAll(
        words.where((word) => !_isCommonWord(word) && word.length <= 15),
      );
    }

    return topics.take(10).toSet(); // Limit topic count
  }

  /// Check if a word is too common to be a meaningful topic
  static bool _isCommonWord(String word) {
    const commonWords = {
      'this',
      'that',
      'with',
      'have',
      'will',
      'from',
      'they',
      'been',
      'were',
      'said',
      'each',
      'which',
      'their',
      'time',
      'about',
      'would',
      'there',
      'could',
      'other',
      'after',
      'first',
      'well',
      'water',
      'very',
      'what',
      'know',
      'just',
      'year',
      'work',
      'think',
      'come',
      'good',
      'want',
      'right',
      'look',
      'make',
      'people',
      'take',
      'see',
      'way',
    };
    return commonWords.contains(word);
  }

  /// Check if a message relates to current conversation topics
  static bool _isMessageRelevantToTopics(Message message, Set<String> topics) {
    final content = message.content.toLowerCase();

    // Count topic matches with weighted scoring
    int relevanceScore = 0;

    for (final topic in topics) {
      if (content.contains(topic)) {
        // Higher score for exact matches, lower for partial
        relevanceScore += content.split(' ').contains(topic) ? 3 : 1;
      }
    }

    // Consider message important if it has strong topic relevance
    return relevanceScore >= 2 ||
        (message.imagePaths.isNotEmpty && relevanceScore >= 1);
  }

  /// Combine all context message types into optimal context window
  static List<Message> _combineContextMessages(
    List<Message> allMessages,
    List<Message> recentMessages,
    List<Message> importantEarlyMessages,
    List<Message> topicRelevantMessages,
  ) {
    final contextMessages = <Message>[];
    final usedMessageIds = <String>{};

    // Add important early messages first
    for (final message in importantEarlyMessages) {
      if (!usedMessageIds.contains(message.id)) {
        contextMessages.add(message);
        usedMessageIds.add(message.id);
      }
    }

    // Add context bridge if needed
    if (importantEarlyMessages.isNotEmpty &&
        (topicRelevantMessages.isNotEmpty ||
            _shouldAddContextBridge(allMessages, recentMessages))) {
      contextMessages.add(
        _createContextBridgeMessage(
          allMessages,
          importantEarlyMessages,
          recentMessages,
        ),
      );
    }

    // Add topic-relevant middle messages
    for (final message in topicRelevantMessages) {
      if (!usedMessageIds.contains(message.id) &&
          contextMessages.length < _maxContextWindow - recentMessages.length) {
        contextMessages.add(message);
        usedMessageIds.add(message.id);
      }
    }

    // Add recent messages
    for (final message in recentMessages) {
      if (!usedMessageIds.contains(message.id)) {
        contextMessages.add(message);
        usedMessageIds.add(message.id);
      }
    }

    return contextMessages;
  }

  /// Determine if a context bridge message should be added
  static bool _shouldAddContextBridge(
    List<Message> allMessages,
    List<Message> recentMessages,
  ) {
    final totalMessages = allMessages.length;
    final recentStartIndex = totalMessages - recentMessages.length;

    // Add bridge if there's a significant gap
    return recentStartIndex > _importantEarlyMessagesCount + 5;
  }

  /// Create an informative context bridge message
  static Message _createContextBridgeMessage(
    List<Message> allMessages,
    List<Message> earliestMessages,
    List<Message> recentMessages,
  ) {
    final skippedCount =
        allMessages.length - earliestMessages.length - recentMessages.length;
    final timeSpan = _calculateTimeSpan(
      earliestMessages.last,
      recentMessages.first,
    );

    String bridgeContent = '[... conversation continued';

    if (skippedCount > 0) {
      bridgeContent += ' ($skippedCount messages)';
    }

    if (timeSpan.isNotEmpty) {
      bridgeContent += ' over $timeSpan';
    }

    // Add topic hint if possible
    final skippedMessages = _getSkippedMessages(
      allMessages,
      earliestMessages,
      recentMessages,
    );
    final mainTopics = _extractTopics(skippedMessages).take(2).toList();

    if (mainTopics.isNotEmpty) {
      bridgeContent += ' discussing ${mainTopics.join(', ')}';
    }

    bridgeContent += ' ...]';

    return Message(
      id: 'context-bridge-${DateTime.now().millisecondsSinceEpoch}',
      content: bridgeContent,
      imagePaths: [],
      timestamp: DateTime.now(),
      type: MessageType.ai,
      status: MessageStatus.delivered,
    );
  }

  /// Get messages that were skipped in context selection
  static List<Message> _getSkippedMessages(
    List<Message> allMessages,
    List<Message> earliestMessages,
    List<Message> recentMessages,
  ) {
    final usedIds = {
      ...earliestMessages.map((m) => m.id),
      ...recentMessages.map((m) => m.id),
    };
    return allMessages
        .where((message) => !usedIds.contains(message.id))
        .toList();
  }

  /// Calculate human-readable time span between messages
  static String _calculateTimeSpan(Message earliest, Message latest) {
    final duration = latest.timestamp.difference(earliest.timestamp);

    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    } else if (duration.inMinutes > 10) {
      return '${duration.inMinutes} minutes';
    }

    return '';
  }

  /// Generate comprehensive conversation summary for very long conversations
  /// Generate intelligent summary for conversations longer than threshold
  static String generateIntelligentSummary(List<Message> allMessages) {
    // Lower threshold for testing, but still require substantial conversation
    if (allMessages.length < 6) return '';

    final userMessages = allMessages
        .where((m) => m.type == MessageType.user)
        .toList();

    // Analyze conversation patterns
    final topics = _extractTopics(allMessages);
    final imageCount = allMessages.where((m) => m.imagePaths.isNotEmpty).length;
    final questionCount = userMessages
        .where((m) => m.content.contains('?'))
        .length;

    // Identify conversation phases
    final phases = _identifyConversationPhases(allMessages);

    var summary = 'Conversation Summary: ';

    // Add conversation scope
    summary += 'This ${allMessages.length}-message conversation ';

    if (imageCount > 0) {
      summary +=
          'included analysis of $imageCount image${imageCount > 1 ? 's' : ''} and ';
    }

    // Add main topics
    if (topics.isNotEmpty) {
      final mainTopics = topics.take(3).toList();
      summary += 'explored topics including ${mainTopics.join(', ')}. ';
    }

    // Add conversation flow information
    if (phases.length > 1) {
      summary +=
          'The discussion evolved through ${phases.length} main phases: ${phases.join(' → ')}. ';
    }

    // Add interaction pattern
    if (questionCount > userMessages.length * 0.5) {
      summary +=
          'The conversation was highly interactive with many clarifying questions. ';
    }

    // Add recency context
    final recentTopics = _extractTopics(allMessages.reversed.take(10).toList());
    if (recentTopics.isNotEmpty) {
      summary += 'Recent focus: ${recentTopics.take(2).join(', ')}.';
    }

    return summary;
  }

  /// Identify distinct phases in the conversation based on topic shifts
  static List<String> _identifyConversationPhases(List<Message> messages) {
    const phaseSize = 8; // Messages per phase for analysis
    final phases = <String>[];

    for (int i = 0; i < messages.length; i += phaseSize) {
      final phaseMessages = messages.skip(i).take(phaseSize).toList();
      final phaseTopics = _extractTopics(phaseMessages);

      if (phaseTopics.isNotEmpty) {
        phases.add(phaseTopics.first);
      }
    }

    // Remove duplicate consecutive phases
    final uniquePhases = <String>[];
    String? lastPhase;

    for (final phase in phases) {
      if (phase != lastPhase) {
        uniquePhases.add(phase);
        lastPhase = phase;
      }
    }

    return uniquePhases;
  }

  /// Enhance user query with contextual information for better AI understanding
  static String enhanceQueryWithContext(
    String originalQuery,
    List<Message> contextMessages, {
    bool includeImageContext = true,
  }) {
    if (contextMessages.isEmpty || originalQuery.trim().length < 3) {
      return originalQuery;
    }

    // Check for contextual references that need enhancement
    if (_hasContextualReferences(originalQuery)) {
      return _addExplicitContext(
        originalQuery,
        contextMessages,
        includeImageContext,
      );
    }

    // Check for follow-up patterns
    if (_isFollowUpQuery(originalQuery)) {
      return _enhanceFollowUpQuery(originalQuery, contextMessages);
    }

    return originalQuery;
  }

  /// Check if query contains contextual references
  static bool _hasContextualReferences(String query) {
    const contextualWords = [
      'this',
      'that',
      'it',
      'they',
      'them',
      'these',
      'those',
      'above',
      'mentioned',
      'previous',
      'earlier',
      'before',
      'same',
      'similar',
      'different',
      'compare',
      'contrast',
    ];

    final queryWords = query.toLowerCase().split(' ');
    return contextualWords.any((word) => queryWords.contains(word));
  }

  /// Check if query is a follow-up question
  static bool _isFollowUpQuery(String query) {
    const followUpPatterns = [
      'what about',
      'how about',
      'can you also',
      'explain more',
      'tell me more',
      'continue',
      'also',
      'additionally',
      'furthermore',
      'what if',
      'but what',
      'and what',
    ];

    final queryLower = query.toLowerCase();
    return followUpPatterns.any((pattern) => queryLower.contains(pattern));
  }

  /// Add explicit context to queries with vague references
  static String _addExplicitContext(
    String query,
    List<Message> contextMessages,
    bool includeImageContext,
  ) {
    final recentUserMessages = contextMessages
        .where((m) => m.type == MessageType.user)
        .toList()
        .reversed
        .take(3)
        .toList();

    if (recentUserMessages.isEmpty) return query;

    final lastUserMessage = recentUserMessages.first;
    final contextSnippet = lastUserMessage.content
        .split(' ')
        .take(10)
        .join(' ');

    String enhancedQuery =
        'Referring to our previous discussion about "$contextSnippet", $query';

    // Add image context if relevant
    if (includeImageContext && lastUserMessage.imagePaths.isNotEmpty) {
      enhancedQuery +=
          ' (regarding the uploaded image${lastUserMessage.imagePaths.length > 1 ? 's' : ''})';
    }

    return enhancedQuery;
  }

  /// Enhance follow-up queries with conversation flow context
  static String _enhanceFollowUpQuery(
    String query,
    List<Message> contextMessages,
  ) {
    final lastAiMessage = contextMessages
        .where((m) => m.type == MessageType.ai)
        .lastOrNull;

    if (lastAiMessage == null) return query;

    // Extract the main topic from the last AI response
    final topics = _extractTopics([lastAiMessage]);
    if (topics.isEmpty) return query;

    final mainTopic = topics.first;
    return 'Building on your explanation about $mainTopic: $query';
  }

  /// Topic transition detection and management
  static TopicTransition detectTopicTransition(
    List<Message> previousMessages,
    String newQuery,
  ) {
    if (previousMessages.length < 3) {
      return TopicTransition.newConversation;
    }

    // Get recent conversation content for analysis
    final recentMessages = previousMessages.length > 6
        ? previousMessages.sublist(previousMessages.length - 6)
        : previousMessages;

    final conversationText = recentMessages
        .map((m) => m.content.toLowerCase())
        .join(' ');

    final queryText = newQuery.toLowerCase();

    // Extract meaningful words from both
    final conversationWords = _extractMeaningfulWords(conversationText);
    final queryWords = _extractMeaningfulWords(queryText);

    if (queryWords.isEmpty) return TopicTransition.continuation;

    // Calculate overlap ratio
    final commonWords = conversationWords.intersection(queryWords);
    final overlapRatio = commonWords.length / queryWords.length;

    // Use more nuanced thresholds for topic detection
    if (overlapRatio >= 0.5) {
      return TopicTransition.continuation;
    } else if (overlapRatio >= 0.2) {
      return TopicTransition.related;
    } else {
      return TopicTransition.newTopic;
    }
  }

  /// Extract meaningful words from text for topic analysis
  static Set<String> _extractMeaningfulWords(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(' ')
        .where((word) => word.length > 2 && !_isCommonWord(word))
        .toSet();
  }
}

/// Enum for topic transition types
enum TopicTransition { newConversation, continuation, related, newTopic }
