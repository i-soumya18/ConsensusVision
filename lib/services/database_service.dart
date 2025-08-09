import 'dart:convert';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';
import '../models/chat_session.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'imagequery_chat.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _messagesTable = 'messages';
  static const String _chatSessionsTable = 'chat_sessions';

  // Initialize database factory for desktop platforms
  static void initializeDatabase() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static Future<Database> get database async {
    if (_database != null) return _database!;

    // Ensure database factory is initialized
    initializeDatabase();

    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    // For MSIX compatibility, use application documents directory
    String dbPath;
    if (Platform.isWindows) {
      // Use application documents directory for MSIX compatibility
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDir.path, _databaseName);
    } else {
      // Use default databases path for other platforms
      dbPath = join(await getDatabasesPath(), _databaseName);
    }

    return await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // Create chat sessions table
    await db.execute('''
      CREATE TABLE $_chatSessionsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_updated INTEGER NOT NULL,
        message_ids TEXT NOT NULL,
        message_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE $_messagesTable (
        id TEXT PRIMARY KEY,
        content TEXT NOT NULL,
        image_paths TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        type INTEGER NOT NULL,
        status INTEGER NOT NULL,
        ai_model TEXT,
        confidence REAL,
        session_id TEXT,
        FOREIGN KEY (session_id) REFERENCES $_chatSessionsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_messages_session_id ON $_messagesTable (session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_messages_timestamp ON $_messagesTable (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_sessions_last_updated ON $_chatSessionsTable (last_updated)',
    );
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic if needed
    }
  }

  // Chat Session operations
  static Future<String> createChatSession(String title) async {
    final db = await database;
    final now = DateTime.now();
    final sessionId = 'session_${now.millisecondsSinceEpoch}';

    final session = ChatSession(
      id: sessionId,
      title: title,
      createdAt: now,
      lastUpdated: now,
      messageIds: [],
      messageCount: 0,
    );

    await db.insert(_chatSessionsTable, _chatSessionToMap(session));
    return sessionId;
  }

  static Future<List<ChatSession>> getAllChatSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _chatSessionsTable,
      orderBy: 'last_updated DESC',
    );

    return List.generate(maps.length, (i) => _chatSessionFromMap(maps[i]));
  }

  static Future<ChatSession?> getChatSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _chatSessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isNotEmpty) {
      return _chatSessionFromMap(maps.first);
    }
    return null;
  }

  static Future<void> updateChatSession(ChatSession session) async {
    final db = await database;
    await db.update(
      _chatSessionsTable,
      _chatSessionToMap(session),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  static Future<void> deleteChatSession(String sessionId) async {
    final db = await database;
    await db.delete(
      _chatSessionsTable,
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // Message operations
  static Future<void> saveMessage(Message message, String sessionId) async {
    final db = await database;

    // Save the message
    final messageMap = _messageToMap(message);
    messageMap['session_id'] = sessionId;
    await db.insert(_messagesTable, messageMap);

    // Update the session
    final session = await getChatSession(sessionId);
    if (session != null) {
      final updatedMessageIds = List<String>.from(session.messageIds)
        ..add(message.id);
      final updatedSession = session.copyWith(
        messageIds: updatedMessageIds,
        messageCount: updatedMessageIds.length,
        lastUpdated: DateTime.now(),
      );
      await updateChatSession(updatedSession);
    }
  }

  static Future<List<Message>> getMessagesForSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => _messageFromMap(maps[i]));
  }

  static Future<void> updateMessage(Message message) async {
    final db = await database;
    await db.update(
      _messagesTable,
      _messageToMap(message),
      where: 'id = ?',
      whereArgs: [message.id],
    );
  }

  static Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(_messagesTable, where: 'id = ?', whereArgs: [messageId]);
  }

  // Search operations
  static Future<List<Message>> searchMessages(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _messagesTable,
      where: 'content LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'timestamp DESC',
      limit: 100,
    );

    return List.generate(maps.length, (i) => _messageFromMap(maps[i]));
  }

  // Utility methods for conversion
  static Map<String, dynamic> _messageToMap(Message message) {
    return {
      'id': message.id,
      'content': message.content,
      'image_paths': jsonEncode(message.imagePaths),
      'timestamp': message.timestamp.millisecondsSinceEpoch,
      'type': message.type.index,
      'status': message.status.index,
      'ai_model': message.aiModel,
      'confidence': message.confidence,
    };
  }

  static Message _messageFromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      imagePaths: List<String>.from(jsonDecode(map['image_paths'])),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: MessageType.values[map['type']],
      status: MessageStatus.values[map['status']],
      aiModel: map['ai_model'],
      confidence: map['confidence']?.toDouble(),
    );
  }

  static Map<String, dynamic> _chatSessionToMap(ChatSession session) {
    return {
      'id': session.id,
      'title': session.title,
      'created_at': session.createdAt.millisecondsSinceEpoch,
      'last_updated': session.lastUpdated.millisecondsSinceEpoch,
      'message_ids': jsonEncode(session.messageIds),
      'message_count': session.messageCount,
    };
  }

  static ChatSession _chatSessionFromMap(Map<String, dynamic> map) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(map['last_updated']),
      messageIds: List<String>.from(jsonDecode(map['message_ids'])),
      messageCount: map['message_count'],
    );
  }

  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_messagesTable);
    await db.delete(_chatSessionsTable);
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
