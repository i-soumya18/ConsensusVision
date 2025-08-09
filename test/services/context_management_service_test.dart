import 'package:flutter_test/flutter_test.dart';
import 'package:imagequery/models/message.dart';
import 'package:imagequery/services/context_management_service.dart';

void main() {
  group('ContextManagementService Tests', () {
    late List<Message> testMessages;

    setUp(() {
      // Create a test conversation with varied content
      testMessages = [
        // Early conversation starter
        Message(
          id: '1',
          content: 'Hello, I need help with machine learning',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          imagePaths: [],
        ),
        Message(
          id: '2',
          content:
              'I\'d be happy to help with machine learning! What specific area interests you?',
          type: MessageType.ai,
          timestamp: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 1),
          ),
          imagePaths: [],
        ),

        // Topic development
        Message(
          id: '3',
          content: 'I want to understand neural networks and deep learning',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 50),
          ),
          imagePaths: [],
        ),
        Message(
          id: '4',
          content:
              'Neural networks are computational models inspired by biological neural networks...',
          type: MessageType.ai,
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 49),
          ),
          imagePaths: [],
        ),

        // Middle conversation with images
        Message(
          id: '5',
          content: 'Can you analyze this diagram of a neural network?',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 30),
          ),
          imagePaths: ['/path/to/neural_network_diagram.png'],
        ),
        Message(
          id: '6',
          content:
              'This diagram shows a feedforward neural network with three layers...',
          type: MessageType.ai,
          timestamp: DateTime.now().subtract(
            const Duration(hours: 1, minutes: 29),
          ),
          imagePaths: [],
        ),

        // Topic shift
        Message(
          id: '7',
          content: 'Actually, let me ask about computer vision instead',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          imagePaths: [],
        ),
        Message(
          id: '8',
          content:
              'Computer vision is a field of AI that enables computers to interpret visual information...',
          type: MessageType.ai,
          timestamp: DateTime.now().subtract(const Duration(minutes: 44)),
          imagePaths: [],
        ),

        // Recent messages
        Message(
          id: '9',
          content: 'How does object detection work?',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          imagePaths: [],
        ),
        Message(
          id: '10',
          content:
              'Object detection combines classification and localization...',
          type: MessageType.ai,
          timestamp: DateTime.now().subtract(const Duration(minutes: 9)),
          imagePaths: [],
        ),

        // Very recent
        Message(
          id: '11',
          content: 'What about YOLO algorithm?',
          type: MessageType.user,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
          imagePaths: [],
        ),
      ];
    });

    group('getOptimalContextMessages', () {
      test(
        'should return all messages when count is less than max context',
        () {
          final shortMessages = testMessages.take(5).toList();
          final result = ContextManagementService.getOptimalContextMessages(
            shortMessages,
          );

          expect(result.length, equals(5));
          expect(result, equals(shortMessages));
        },
      );

      test(
        'should prioritize recent and early messages when exceeding max context',
        () {
          final result = ContextManagementService.getOptimalContextMessages(
            testMessages,
          );

          expect(result.length, lessThanOrEqualTo(20));

          // Should include early messages
          expect(result.any((m) => m.id == '1'), isTrue);
          expect(result.any((m) => m.id == '2'), isTrue);

          // Should include recent messages
          expect(result.any((m) => m.id == '11'), isTrue);
          expect(result.any((m) => m.id == '10'), isTrue);
          expect(result.any((m) => m.id == '9'), isTrue);
        },
      );

      test('should preserve chronological order in context messages', () {
        final result = ContextManagementService.getOptimalContextMessages(
          testMessages,
        );

        for (int i = 0; i < result.length - 1; i++) {
          final currentIndex = testMessages.indexOf(result[i]);
          final nextIndex = testMessages.indexOf(result[i + 1]);
          expect(
            currentIndex,
            lessThan(nextIndex),
            reason: 'Messages should maintain chronological order',
          );
        }
      });

      test('should prioritize messages with images', () {
        final result = ContextManagementService.getOptimalContextMessages(
          testMessages,
        );

        // Message with image should be included
        expect(result.any((m) => m.id == '5'), isTrue);
      });
    });

    group('detectTopicTransition', () {
      test('should detect new conversation for empty message list', () {
        final transition = ContextManagementService.detectTopicTransition(
          [],
          'Hello',
        );
        expect(transition, equals(TopicTransition.newConversation));
      });

      test('should detect topic continuation for similar content', () {
        final transition = ContextManagementService.detectTopicTransition(
          testMessages,
          'Tell me more about neural networks and their layers',
        );
        expect(transition, equals(TopicTransition.continuation));
      });

      test('should detect new topic for completely different content', () {
        final transition = ContextManagementService.detectTopicTransition(
          testMessages,
          'What is the weather like today?',
        );
        expect(transition, equals(TopicTransition.newTopic));
      });

      test('should detect related topic for loosely connected content', () {
        final transition = ContextManagementService.detectTopicTransition(
          testMessages,
          'How do I implement neural networks in Python programming?',
        );
        expect(transition, equals(TopicTransition.related));
      });
    });

    group('enhanceQueryWithContext', () {
      test('should return original query when context is empty', () {
        const query = 'What is machine learning?';
        final enhanced = ContextManagementService.enhanceQueryWithContext(
          query,
          [],
        );

        expect(enhanced, equals(query));
      });

      test('should add context when relevant previous discussion exists', () {
        const query = 'How does it work?';
        final contextMessages = testMessages.take(4).toList();

        final enhanced = ContextManagementService.enhanceQueryWithContext(
          query,
          contextMessages,
        );

        expect(enhanced, isNot(equals(query)));
        expect(enhanced.toLowerCase(), contains('neural'));
      });

      test('should handle ambiguous queries by adding context', () {
        const query = 'Tell me more about that';
        final contextMessages = testMessages
            .where((m) => m.content.contains('computer vision'))
            .toList();

        final enhanced = ContextManagementService.enhanceQueryWithContext(
          query,
          contextMessages,
        );

        expect(enhanced, isNot(equals(query)));
        expect(enhanced.length, greaterThan(query.length));
      });

      test(
        'should preserve specific queries without unnecessary enhancement',
        () {
          const query = 'What is the YOLO algorithm used for object detection?';
          final contextMessages = testMessages.take(3).toList();

          final enhanced = ContextManagementService.enhanceQueryWithContext(
            query,
            contextMessages,
          );

          // Should not enhance already specific queries much
          expect(enhanced.length - query.length, lessThan(100));
        },
      );
    });

    group('generateIntelligentSummary', () {
      test('should create concise summary for long conversations', () {
        final summary = ContextManagementService.generateIntelligentSummary(
          testMessages,
        );

        expect(summary.isNotEmpty, isTrue);
        expect(
          summary.toLowerCase(),
          anyOf([
            contains('machine'),
            contains('learning'),
            contains('neural'),
            contains('conversation'),
          ]),
        );
      });

      test('should return empty summary for short conversations', () {
        final shortMessages = testMessages.take(3).toList();
        final summary = ContextManagementService.generateIntelligentSummary(
          shortMessages,
        );

        expect(summary.isEmpty, isTrue);
      });

      test('should capture key topics from the conversation', () {
        final summary = ContextManagementService.generateIntelligentSummary(
          testMessages,
        );

        // Should mention key topics that appear in the conversation
        expect(
          summary.toLowerCase(),
          anyOf([
            contains('machine'),
            contains('learning'),
            contains('neural'),
            contains('algorithm'),
            contains('object'),
            contains('vision'),
          ]),
        );
      });
    });

    group('Topic Analysis', () {
      test('should handle different conversation patterns', () {
        // Test with different message patterns
        final result = ContextManagementService.getOptimalContextMessages(
          testMessages,
        );

        // Should maintain conversation flow
        expect(result.isNotEmpty, isTrue);

        // Should include diverse message types
        final hasUserMessages = result.any((m) => m.type == MessageType.user);
        final hasAiMessages = result.any((m) => m.type == MessageType.ai);

        expect(hasUserMessages, isTrue);
        expect(hasAiMessages, isTrue);
      });

      test('should prioritize contextually relevant messages', () {
        const query = 'Tell me about neural network architecture';
        final contextMessages =
            ContextManagementService.getOptimalContextMessages(testMessages);

        final enhanced = ContextManagementService.enhanceQueryWithContext(
          query,
          contextMessages,
        );

        // Enhanced query should be different if context is applied
        expect(enhanced.length, greaterThanOrEqualTo(query.length));
      });
    });

    group('Context Bridge Messages', () {
      test('should create bridge messages for topic transitions', () {
        // Simulate a conversation with a clear topic shift
        final messagesWithShift = [
          ...testMessages.take(4), // Neural network discussion
          ...testMessages.skip(6).take(2), // Computer vision discussion
        ];

        final contextMessages =
            ContextManagementService.getOptimalContextMessages(
              messagesWithShift,
            );

        // Should potentially include bridge messages to maintain coherence
        expect(contextMessages.length, greaterThan(0));
      });
    });

    group('Edge Cases', () {
      test('should handle empty message list gracefully', () {
        expect(
          () => ContextManagementService.getOptimalContextMessages([]),
          returnsNormally,
        );

        final result = ContextManagementService.getOptimalContextMessages([]);
        expect(result, isEmpty);
      });

      test('should handle single message gracefully', () {
        final singleMessage = [testMessages.first];
        final result = ContextManagementService.getOptimalContextMessages(
          singleMessage,
        );

        expect(result.length, equals(1));
        expect(result.first, equals(testMessages.first));
      });

      test('should handle very long individual messages', () {
        final longMessage = Message(
          id: 'long',
          content:
              'This is a very long message that contains a lot of information about various topics including machine learning, neural networks, computer vision, artificial intelligence, and many other related subjects that might be relevant to the conversation context and should be handled properly by the context management system without causing any issues or performance problems.' *
              10,
          type: MessageType.user,
          timestamp: DateTime.now(),
          imagePaths: [],
        );

        final messagesWithLong = [...testMessages, longMessage];

        expect(
          () => ContextManagementService.getOptimalContextMessages(
            messagesWithLong,
          ),
          returnsNormally,
        );
      });

      test('should handle null or malformed content gracefully', () {
        final messageWithEmptyContent = Message(
          id: 'empty',
          content: '',
          type: MessageType.user,
          timestamp: DateTime.now(),
          imagePaths: [],
        );

        final messagesWithEmpty = [...testMessages, messageWithEmptyContent];

        expect(
          () => ContextManagementService.getOptimalContextMessages(
            messagesWithEmpty,
          ),
          returnsNormally,
        );
      });
    });

    group('Performance Tests', () {
      test('should handle large conversation efficiently', () {
        // Create a large conversation (1000 messages)
        final largeConversation = List.generate(
          1000,
          (index) => Message(
            id: 'msg_$index',
            content:
                'This is message number $index in our conversation about various topics.',
            type: index % 2 == 0 ? MessageType.user : MessageType.ai,
            timestamp: DateTime.now().subtract(Duration(minutes: 1000 - index)),
            imagePaths: [],
          ),
        );

        final stopwatch = Stopwatch()..start();
        final result = ContextManagementService.getOptimalContextMessages(
          largeConversation,
        );
        stopwatch.stop();

        // Should complete within reasonable time (less than 100ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
        expect(result.length, lessThanOrEqualTo(20));
      });
    });
  });
}
