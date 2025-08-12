import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user_profile.dart';
import '../models/conversation_context.dart';

/// Advanced persistent memory service that maintains context across multiple sessions
/// Implements sophisticated memory management for true context awareness
class PersistentMemoryService {
  static PersistentMemoryService? _instance;
  static Database? _memoryDatabase;

  // Table names for memory storage
  static const String _userProfilesTable = 'user_profiles';
  static const String _conversationContextsTable = 'conversation_contexts';
  static const String _behaviorPatternsTable = 'behavior_patterns';
  static const String _contextMemoryTable = 'context_memory';
  static const String _intentHistoryTable = 'intent_history';
  static const String _topicMemoryTable = 'topic_memory';
  static const String _sessionContinuityTable = 'session_continuity';

  PersistentMemoryService._();

  static PersistentMemoryService get instance {
    _instance ??= PersistentMemoryService._();
    return _instance!;
  }

  /// Initialize the persistent memory system
  Future<void> initialize() async {
    try {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      _memoryDatabase = await _initMemoryDatabase();

      if (kDebugMode) {
        print('Persistent Memory Service initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Persistent Memory Service: $e');
      }
    }
  }

  Future<Database> _initMemoryDatabase() async {
    String dbPath;
    if (Platform.isWindows) {
      final appDir = await getApplicationDocumentsDirectory();
      dbPath = join(appDir.path, 'imagequery_memory.db');
    } else {
      dbPath = join(await getDatabasesPath(), 'imagequery_memory.db');
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _createMemoryTables,
      onUpgrade: _onMemoryUpgrade,
    );
  }

  Future<void> _createMemoryTables(Database db, int version) async {
    // User profiles table
    await db.execute('''
      CREATE TABLE $_userProfilesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_active INTEGER NOT NULL,
        preferences TEXT NOT NULL,
        device_info TEXT NOT NULL,
        behavior_patterns TEXT NOT NULL,
        context_memory TEXT NOT NULL,
        frequent_topics TEXT NOT NULL,
        project_timelines TEXT NOT NULL
      )
    ''');

    // Conversation contexts table
    await db.execute('''
      CREATE TABLE $_conversationContextsTable (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        active_topics TEXT NOT NULL,
        situational_context TEXT NOT NULL,
        environmental_context TEXT NOT NULL,
        current_intent TEXT NOT NULL,
        referenced_entities TEXT NOT NULL,
        temporal_context TEXT NOT NULL,
        context_continuity_score REAL NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Behavior patterns table
    await db.execute('''
      CREATE TABLE $_behaviorPatternsTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        type TEXT NOT NULL,
        description TEXT NOT NULL,
        first_observed INTEGER NOT NULL,
        last_observed INTEGER NOT NULL,
        frequency INTEGER NOT NULL,
        confidence REAL NOT NULL,
        metadata TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_userProfilesTable (id) ON DELETE CASCADE
      )
    ''');

    // Context memory table - stores specific contextual information
    await db.execute('''
      CREATE TABLE $_contextMemoryTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        context_key TEXT NOT NULL,
        context_value TEXT NOT NULL,
        context_type TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_accessed INTEGER NOT NULL,
        access_count INTEGER NOT NULL DEFAULT 1,
        importance_score REAL NOT NULL DEFAULT 0.5,
        expires_at INTEGER,
        FOREIGN KEY (user_id) REFERENCES $_userProfilesTable (id) ON DELETE CASCADE
      )
    ''');

    // Intent history table
    await db.execute('''
      CREATE TABLE $_intentHistoryTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        session_id TEXT NOT NULL,
        intent_type TEXT NOT NULL,
        confidence REAL NOT NULL,
        description TEXT NOT NULL,
        parameters TEXT NOT NULL,
        context TEXT NOT NULL,
        inferred_at INTEGER NOT NULL,
        alternative_intents TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_userProfilesTable (id) ON DELETE CASCADE,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    // Topic memory table - tracks topic discussions and preferences
    await db.execute('''
      CREATE TABLE $_topicMemoryTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        topic_name TEXT NOT NULL,
        first_discussed INTEGER NOT NULL,
        last_discussed INTEGER NOT NULL,
        discussion_count INTEGER NOT NULL DEFAULT 1,
        interest_score REAL NOT NULL DEFAULT 0.5,
        expertise_level TEXT NOT NULL DEFAULT 'beginner',
        related_topics TEXT NOT NULL,
        context_notes TEXT,
        FOREIGN KEY (user_id) REFERENCES $_userProfilesTable (id) ON DELETE CASCADE
      )
    ''');

    // Session continuity table - tracks relationships between sessions
    await db.execute('''
      CREATE TABLE $_sessionContinuityTable (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        previous_session_id TEXT NOT NULL,
        current_session_id TEXT NOT NULL,
        continuity_type TEXT NOT NULL,
        continuity_score REAL NOT NULL,
        context_bridge TEXT,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_userProfilesTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_context_user_id ON $_conversationContextsTable (session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_context_timestamp ON $_conversationContextsTable (timestamp)',
    );
    await db.execute(
      'CREATE INDEX idx_behavior_user_id ON $_behaviorPatternsTable (user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_behavior_type ON $_behaviorPatternsTable (type)',
    );
    await db.execute(
      'CREATE INDEX idx_memory_user_key ON $_contextMemoryTable (user_id, context_key)',
    );
    await db.execute(
      'CREATE INDEX idx_memory_type ON $_contextMemoryTable (context_type)',
    );
    await db.execute(
      'CREATE INDEX idx_intent_user_session ON $_intentHistoryTable (user_id, session_id)',
    );
    await db.execute(
      'CREATE INDEX idx_topic_user_name ON $_topicMemoryTable (user_id, topic_name)',
    );
    await db.execute(
      'CREATE INDEX idx_continuity_user ON $_sessionContinuityTable (user_id)',
    );
  }

  Future<void> _onMemoryUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic if needed
    }
  }

  /// Store user profile with comprehensive information
  Future<void> saveUserProfile(UserProfile profile) async {
    final db = _memoryDatabase!;

    final profileMap = {
      'id': profile.id,
      'name': profile.name,
      'created_at': profile.createdAt.millisecondsSinceEpoch,
      'last_active': profile.lastActive.millisecondsSinceEpoch,
      'preferences': jsonEncode(profile.preferences.toJson()),
      'device_info': jsonEncode(profile.deviceInfo.toJson()),
      'behavior_patterns': jsonEncode(
        profile.behaviorPatterns.map((p) => p.toJson()).toList(),
      ),
      'context_memory': jsonEncode(profile.contextMemory),
      'frequent_topics': jsonEncode(profile.frequentTopics),
      'project_timelines': jsonEncode(
        profile.projectTimelines.map(
          (k, v) => MapEntry(k, v.millisecondsSinceEpoch),
        ),
      ),
    };

    await db.insert(
      _userProfilesTable,
      profileMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    final db = _memoryDatabase!;
    final results = await db.query(
      _userProfilesTable,
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) return null;

    final data = results.first;
    return UserProfile(
      id: data['id'] as String,
      name: data['name'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      lastActive: DateTime.fromMillisecondsSinceEpoch(
        data['last_active'] as int,
      ),
      preferences: UserPreferences.fromJson(
        jsonDecode(data['preferences'] as String),
      ),
      deviceInfo: DeviceInfo.fromJson(
        jsonDecode(data['device_info'] as String),
      ),
      behaviorPatterns:
          (jsonDecode(data['behavior_patterns'] as String) as List)
              .map((p) => BehaviorPattern.fromJson(p))
              .toList(),
      contextMemory: Map<String, dynamic>.from(
        jsonDecode(data['context_memory'] as String),
      ),
      frequentTopics: List<String>.from(
        jsonDecode(data['frequent_topics'] as String),
      ),
      projectTimelines:
          (jsonDecode(data['project_timelines'] as String)
                  as Map<String, dynamic>)
              .map(
                (k, v) =>
                    MapEntry(k, DateTime.fromMillisecondsSinceEpoch(v as int)),
              ),
    );
  }

  /// Store conversation context for future reference
  Future<void> saveConversationContext(ConversationContext context) async {
    final db = _memoryDatabase!;

    final contextMap = {
      'id': context.id,
      'session_id': context.sessionId,
      'timestamp': context.timestamp.millisecondsSinceEpoch,
      'active_topics': jsonEncode(context.activeTopics),
      'situational_context': jsonEncode(context.situationalContext),
      'environmental_context': jsonEncode(
        context.environmentalContext.toJson(),
      ),
      'current_intent': jsonEncode(context.currentIntent.toJson()),
      'referenced_entities': jsonEncode(context.referencedEntities),
      'temporal_context': jsonEncode(context.temporalContext),
      'context_continuity_score': context.contextContinuityScore,
    };

    await db.insert(
      _conversationContextsTable,
      contextMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve conversation contexts for a session
  Future<List<ConversationContext>> getConversationContexts(
    String sessionId,
  ) async {
    final db = _memoryDatabase!;
    final results = await db.query(
      _conversationContextsTable,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp DESC',
    );

    return results
        .map(
          (data) => ConversationContext(
            id: data['id'] as String,
            sessionId: data['session_id'] as String,
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              data['timestamp'] as int,
            ),
            activeTopics: List<String>.from(
              jsonDecode(data['active_topics'] as String),
            ),
            situationalContext: Map<String, dynamic>.from(
              jsonDecode(data['situational_context'] as String),
            ),
            environmentalContext: EnvironmentalContext.fromJson(
              jsonDecode(data['environmental_context'] as String),
            ),
            currentIntent: UserIntent.fromJson(
              jsonDecode(data['current_intent'] as String),
            ),
            referencedEntities: List<String>.from(
              jsonDecode(data['referenced_entities'] as String),
            ),
            temporalContext: Map<String, dynamic>.from(
              jsonDecode(data['temporal_context'] as String),
            ),
            contextContinuityScore: data['context_continuity_score'] as double,
          ),
        )
        .toList();
  }

  /// Store behavior pattern
  Future<void> saveBehaviorPattern(
    BehaviorPattern pattern,
    String userId,
  ) async {
    final db = _memoryDatabase!;

    final patternMap = {
      'id': pattern.id,
      'user_id': userId,
      'type': pattern.type.name,
      'description': pattern.description,
      'first_observed': pattern.firstObserved.millisecondsSinceEpoch,
      'last_observed': pattern.lastObserved.millisecondsSinceEpoch,
      'frequency': pattern.frequency,
      'confidence': pattern.confidence,
      'metadata': jsonEncode(pattern.metadata),
    };

    await db.insert(
      _behaviorPatternsTable,
      patternMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Store contextual memory item
  Future<void> storeContextMemory({
    required String userId,
    required String contextKey,
    required String contextValue,
    required String contextType,
    double importanceScore = 0.5,
    DateTime? expiresAt,
  }) async {
    final db = _memoryDatabase!;
    final now = DateTime.now();

    final memoryMap = {
      'id': '${userId}_${contextKey}_${now.millisecondsSinceEpoch}',
      'user_id': userId,
      'context_key': contextKey,
      'context_value': contextValue,
      'context_type': contextType,
      'created_at': now.millisecondsSinceEpoch,
      'last_accessed': now.millisecondsSinceEpoch,
      'access_count': 1,
      'importance_score': importanceScore,
      'expires_at': expiresAt?.millisecondsSinceEpoch,
    };

    await db.insert(
      _contextMemoryTable,
      memoryMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieve contextual memory
  Future<Map<String, dynamic>?> getContextMemory(
    String userId,
    String contextKey,
  ) async {
    final db = _memoryDatabase!;
    final results = await db.query(
      _contextMemoryTable,
      where:
          'user_id = ? AND context_key = ? AND (expires_at IS NULL OR expires_at > ?)',
      whereArgs: [userId, contextKey, DateTime.now().millisecondsSinceEpoch],
      orderBy: 'importance_score DESC, last_accessed DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final data = results.first;

    // Update access information
    await db.update(
      _contextMemoryTable,
      {
        'last_accessed': DateTime.now().millisecondsSinceEpoch,
        'access_count': (data['access_count'] as int) + 1,
      },
      where: 'id = ?',
      whereArgs: [data['id']],
    );

    return {
      'context_value': data['context_value'],
      'context_type': data['context_type'],
      'importance_score': data['importance_score'],
      'access_count': data['access_count'],
      'created_at': DateTime.fromMillisecondsSinceEpoch(
        data['created_at'] as int,
      ),
      'last_accessed': DateTime.fromMillisecondsSinceEpoch(
        data['last_accessed'] as int,
      ),
    };
  }

  /// Store user intent for pattern analysis
  Future<void> storeUserIntent(
    UserIntent intent,
    String userId,
    String sessionId,
  ) async {
    final db = _memoryDatabase!;

    final intentMap = {
      'id': intent.id,
      'user_id': userId,
      'session_id': sessionId,
      'intent_type': intent.type.name,
      'confidence': intent.confidence,
      'description': intent.description,
      'parameters': jsonEncode(intent.parameters),
      'context': jsonEncode(intent.context),
      'inferred_at': intent.inferredAt.millisecondsSinceEpoch,
      'alternative_intents': jsonEncode(
        intent.alternativeIntents.map((i) => i.name).toList(),
      ),
    };

    await db.insert(
      _intentHistoryTable,
      intentMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get recent intent history for pattern analysis
  Future<List<UserIntent>> getRecentIntents(
    String userId, {
    int limit = 50,
  }) async {
    final db = _memoryDatabase!;
    final results = await db.query(
      _intentHistoryTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'inferred_at DESC',
      limit: limit,
    );

    return results
        .map(
          (data) => UserIntent(
            id: data['id'] as String,
            type: IntentType.values.firstWhere(
              (t) => t.name == data['intent_type'],
            ),
            confidence: data['confidence'] as double,
            description: data['description'] as String,
            parameters: List<String>.from(
              jsonDecode(data['parameters'] as String),
            ),
            context: Map<String, dynamic>.from(
              jsonDecode(data['context'] as String),
            ),
            inferredAt: DateTime.fromMillisecondsSinceEpoch(
              data['inferred_at'] as int,
            ),
            alternativeIntents:
                (jsonDecode(data['alternative_intents'] as String)
                        as List<String>)
                    .map(
                      (name) =>
                          IntentType.values.firstWhere((t) => t.name == name),
                    )
                    .toList(),
          ),
        )
        .toList();
  }

  /// Update topic memory
  Future<void> updateTopicMemory({
    required String userId,
    required String topicName,
    double interestScore = 0.5,
    String expertiseLevel = 'beginner',
    List<String> relatedTopics = const [],
    String? contextNotes,
  }) async {
    final db = _memoryDatabase!;
    final now = DateTime.now();

    // Check if topic already exists
    final existing = await db.query(
      _topicMemoryTable,
      where: 'user_id = ? AND topic_name = ?',
      whereArgs: [userId, topicName],
    );

    if (existing.isEmpty) {
      // Create new topic entry
      final topicMap = {
        'id': '${userId}_${topicName}_${now.millisecondsSinceEpoch}',
        'user_id': userId,
        'topic_name': topicName,
        'first_discussed': now.millisecondsSinceEpoch,
        'last_discussed': now.millisecondsSinceEpoch,
        'discussion_count': 1,
        'interest_score': interestScore,
        'expertise_level': expertiseLevel,
        'related_topics': jsonEncode(relatedTopics),
        'context_notes': contextNotes,
      };

      await db.insert(_topicMemoryTable, topicMap);
    } else {
      // Update existing topic
      final existingData = existing.first;
      final newDiscussionCount = (existingData['discussion_count'] as int) + 1;
      final currentInterestScore = existingData['interest_score'] as double;

      // Calculate weighted average for interest score
      final newInterestScore =
          (currentInterestScore * 0.7) + (interestScore * 0.3);

      await db.update(
        _topicMemoryTable,
        {
          'last_discussed': now.millisecondsSinceEpoch,
          'discussion_count': newDiscussionCount,
          'interest_score': newInterestScore,
          'expertise_level': expertiseLevel,
          'related_topics': jsonEncode(relatedTopics),
          'context_notes': contextNotes,
        },
        where: 'id = ?',
        whereArgs: [existingData['id']],
      );
    }
  }

  /// Get topic memory for user
  Future<List<Map<String, dynamic>>> getTopicMemory(
    String userId, {
    int limit = 20,
  }) async {
    final db = _memoryDatabase!;
    final results = await db.query(
      _topicMemoryTable,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'interest_score DESC, discussion_count DESC',
      limit: limit,
    );

    return results
        .map(
          (data) => {
            'topic_name': data['topic_name'],
            'first_discussed': DateTime.fromMillisecondsSinceEpoch(
              data['first_discussed'] as int,
            ),
            'last_discussed': DateTime.fromMillisecondsSinceEpoch(
              data['last_discussed'] as int,
            ),
            'discussion_count': data['discussion_count'],
            'interest_score': data['interest_score'],
            'expertise_level': data['expertise_level'],
            'related_topics': List<String>.from(
              jsonDecode(data['related_topics'] as String),
            ),
            'context_notes': data['context_notes'],
          },
        )
        .toList();
  }

  /// Store session continuity information
  Future<void> storeSessionContinuity({
    required String userId,
    required String previousSessionId,
    required String currentSessionId,
    required String continuityType,
    required double continuityScore,
    String? contextBridge,
  }) async {
    final db = _memoryDatabase!;
    final now = DateTime.now();

    final continuityMap = {
      'id': '${userId}_${currentSessionId}_${now.millisecondsSinceEpoch}',
      'user_id': userId,
      'previous_session_id': previousSessionId,
      'current_session_id': currentSessionId,
      'continuity_type': continuityType,
      'continuity_score': continuityScore,
      'context_bridge': contextBridge,
      'created_at': now.millisecondsSinceEpoch,
    };

    await db.insert(_sessionContinuityTable, continuityMap);
  }

  /// Get session continuity information
  Future<Map<String, dynamic>?> getSessionContinuity(
    String userId,
    String currentSessionId,
  ) async {
    final db = _memoryDatabase!;
    final results = await db.query(
      _sessionContinuityTable,
      where: 'user_id = ? AND current_session_id = ?',
      whereArgs: [userId, currentSessionId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;

    final data = results.first;
    return {
      'previous_session_id': data['previous_session_id'],
      'continuity_type': data['continuity_type'],
      'continuity_score': data['continuity_score'],
      'context_bridge': data['context_bridge'],
      'created_at': DateTime.fromMillisecondsSinceEpoch(
        data['created_at'] as int,
      ),
    };
  }

  /// Clean up expired memory items
  Future<void> cleanupExpiredMemory() async {
    final db = _memoryDatabase!;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.delete(
      _contextMemoryTable,
      where: 'expires_at IS NOT NULL AND expires_at <= ?',
      whereArgs: [now],
    );
  }

  /// Get comprehensive memory statistics
  Future<Map<String, dynamic>> getMemoryStatistics(String userId) async {
    final db = _memoryDatabase!;

    final contextCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_contextMemoryTable WHERE user_id = ?',
      [userId],
    );
    final contextCount = contextCountResult.first['count'] as int? ?? 0;

    final intentCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_intentHistoryTable WHERE user_id = ?',
      [userId],
    );
    final intentCount = intentCountResult.first['count'] as int? ?? 0;

    final topicCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_topicMemoryTable WHERE user_id = ?',
      [userId],
    );
    final topicCount = topicCountResult.first['count'] as int? ?? 0;

    final behaviorCountResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_behaviorPatternsTable WHERE user_id = ?',
      [userId],
    );
    final behaviorCount = behaviorCountResult.first['count'] as int? ?? 0;

    return {
      'total_context_items': contextCount,
      'total_intents_tracked': intentCount,
      'total_topics_discussed': topicCount,
      'total_behavior_patterns': behaviorCount,
      'memory_health_score': _calculateMemoryHealthScore(
        contextCount,
        intentCount,
        topicCount,
        behaviorCount,
      ),
    };
  }

  double _calculateMemoryHealthScore(
    int contextCount,
    int intentCount,
    int topicCount,
    int behaviorCount,
  ) {
    // Simple scoring algorithm - can be enhanced based on requirements
    final totalItems = contextCount + intentCount + topicCount + behaviorCount;
    if (totalItems == 0) return 0.0;

    final diversity =
        [
          contextCount,
          intentCount,
          topicCount,
          behaviorCount,
        ].where((count) => count > 0).length /
        4.0;

    final richness = (totalItems / 100.0).clamp(
      0.0,
      1.0,
    ); // Scale based on 100 items

    return (diversity * 0.6 + richness * 0.4).clamp(0.0, 1.0);
  }
}
