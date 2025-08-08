import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/message.dart';
import '../services/database_service.dart';

class ExportService {
  /// Export all chat data as JSON
  static Future<bool> exportChatDataAsJson() async {
    try {
      // Get all chat sessions
      final chatSessions = await DatabaseService.getAllChatSessions();

      // Create export data structure
      final exportData = <String, dynamic>{
        'export_info': {
          'app_name': 'ImageQuery AI',
          'export_date': DateTime.now().toIso8601String(),
          'total_sessions': chatSessions.length,
          'version': '1.0.0',
        },
        'chat_sessions': [],
      };

      // Add each session with its messages
      for (final session in chatSessions) {
        final messages = await DatabaseService.getMessagesForSession(
          session.id,
        );

        final sessionData = {
          'session_info': session.toJson(),
          'messages': messages.map((message) => message.toJson()).toList(),
        };

        exportData['chat_sessions'].add(sessionData);
      }

      // Convert to JSON string with pretty formatting
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'imagequery_chat_export_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ImageQuery AI Chat Export',
        subject: 'Chat Data Export',
      );

      return true;
    } catch (e) {
      throw Exception('Failed to export chat data: $e');
    }
  }

  /// Export chat data as CSV format
  static Future<bool> exportChatDataAsCsv() async {
    try {
      // Get all chat sessions
      final chatSessions = await DatabaseService.getAllChatSessions();

      // Create CSV content
      final csvLines = <String>[];

      // Add header
      csvLines.add(
        'Session ID,Session Title,Session Created,Message ID,Message Type,Content,Image Count,Timestamp,AI Model,Confidence',
      );

      // Add data rows
      for (final session in chatSessions) {
        final messages = await DatabaseService.getMessagesForSession(
          session.id,
        );

        for (final message in messages) {
          final row = [
            _escapeCSV(session.id),
            _escapeCSV(session.title),
            _escapeCSV(session.createdAt.toIso8601String()),
            _escapeCSV(message.id),
            _escapeCSV(message.type.name),
            _escapeCSV(message.content),
            message.imagePaths.length.toString(),
            _escapeCSV(message.timestamp.toIso8601String()),
            _escapeCSV(message.aiModel ?? ''),
            message.confidence?.toString() ?? '',
          ];
          csvLines.add(row.join(','));
        }
      }

      final csvContent = csvLines.join('\n');

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'imagequery_chat_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(csvContent);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ImageQuery AI Chat Export (CSV)',
        subject: 'Chat Data Export',
      );

      return true;
    } catch (e) {
      throw Exception('Failed to export chat data as CSV: $e');
    }
  }

  /// Export chat data as human-readable text
  static Future<bool> exportChatDataAsText() async {
    try {
      // Get all chat sessions
      final chatSessions = await DatabaseService.getAllChatSessions();

      final textLines = <String>[];

      // Add header
      textLines.add('ImageQuery AI Chat Export');
      textLines.add('Export Date: ${DateTime.now().toString()}');
      textLines.add('Total Sessions: ${chatSessions.length}');
      textLines.add('=' * 50);
      textLines.add('');

      // Add each session
      for (int i = 0; i < chatSessions.length; i++) {
        final session = chatSessions[i];
        final messages = await DatabaseService.getMessagesForSession(
          session.id,
        );

        textLines.add('SESSION ${i + 1}: ${session.title}');
        textLines.add('Created: ${session.createdAt}');
        textLines.add('Last Updated: ${session.lastUpdated}');
        textLines.add('Messages: ${messages.length}');
        textLines.add('-' * 30);

        for (int j = 0; j < messages.length; j++) {
          final message = messages[j];
          textLines.add('');
          textLines.add(
            '[${j + 1}] ${message.type.name.toUpperCase()} - ${message.timestamp}',
          );
          if (message.aiModel != null) {
            textLines.add('AI Model: ${message.aiModel}');
          }
          if (message.confidence != null) {
            textLines.add(
              'Confidence: ${(message.confidence! * 100).toStringAsFixed(1)}%',
            );
          }
          if (message.imagePaths.isNotEmpty) {
            textLines.add('Images: ${message.imagePaths.length}');
          }
          textLines.add('Content: ${message.content}');
        }

        textLines.add('');
        textLines.add('=' * 50);
        textLines.add('');
      }

      final textContent = textLines.join('\n');

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'imagequery_chat_export_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(textContent);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ImageQuery AI Chat Export (Text)',
        subject: 'Chat Data Export',
      );

      return true;
    } catch (e) {
      throw Exception('Failed to export chat data as text: $e');
    }
  }

  /// Helper method to escape CSV fields
  static String _escapeCSV(String field) {
    if (field.contains('"') || field.contains(',') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Get export statistics
  static Future<Map<String, dynamic>> getExportStatistics() async {
    try {
      final chatSessions = await DatabaseService.getAllChatSessions();

      int totalMessages = 0;
      int userMessages = 0;
      int aiMessages = 0;
      int totalImages = 0;
      DateTime? oldestSession;
      DateTime? newestSession;

      for (final session in chatSessions) {
        // Update session date tracking
        if (oldestSession == null ||
            session.createdAt.isBefore(oldestSession)) {
          oldestSession = session.createdAt;
        }
        if (newestSession == null || session.createdAt.isAfter(newestSession)) {
          newestSession = session.createdAt;
        }

        final messages = await DatabaseService.getMessagesForSession(
          session.id,
        );
        totalMessages += messages.length;

        for (final message in messages) {
          if (message.type == MessageType.user) {
            userMessages++;
          } else if (message.type == MessageType.ai) {
            aiMessages++;
          }
          totalImages += message.imagePaths.length;
        }
      }

      return {
        'total_sessions': chatSessions.length,
        'total_messages': totalMessages,
        'user_messages': userMessages,
        'ai_messages': aiMessages,
        'total_images': totalImages,
        'oldest_session': oldestSession?.toIso8601String(),
        'newest_session': newestSession?.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to get export statistics: $e');
    }
  }
}
