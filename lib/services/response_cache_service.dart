import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_response.dart';

/// High-performance response caching service for faster AI responses
/// Implements intelligent caching with TTL, size limits, and cache warming
class ResponseCacheService {
  static const String _cacheKeyPrefix = 'ai_response_cache_';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _cacheStatsKey = 'cache_statistics';

  // Cache configuration
  static const int _maxCacheSize = 100; // Maximum cached responses
  static const int _defaultTtlHours = 24; // Time to live in hours
  static const int _maxQueryLength = 500; // Max query length to cache
  static const double _similarityThreshold = 0.85; // For fuzzy matching

  static SharedPreferences? _prefs;
  static Map<String, CacheEntry> _memoryCache = {};
  static CacheStatistics _stats = CacheStatistics();

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadCacheMetadata();
    await _loadCacheStatistics();
    await _cleanupExpiredEntries();
  }

  /// Cache a response with intelligent key generation
  static Future<void> cacheResponse({
    required String query,
    required AIResponse response,
    List<File>? images,
    String? extractedText,
    int ttlHours = _defaultTtlHours,
    bool highPriority = false,
  }) async {
    await init();

    // Don't cache errors or very long queries
    if (!response.isSuccessful || query.length > _maxQueryLength) {
      return;
    }

    final cacheKey = _generateCacheKey(query, images, extractedText);
    final expiresAt = DateTime.now().add(Duration(hours: ttlHours));

    final cacheEntry = CacheEntry(
      key: cacheKey,
      query: query,
      response: response,
      extractedText: extractedText,
      imageHashes: images != null ? await _generateImageHashes(images) : null,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      accessCount: 1,
      lastAccessed: DateTime.now(),
      highPriority: highPriority,
    );

    // Store in memory cache
    _memoryCache[cacheKey] = cacheEntry;

    // Store in persistent cache
    await _prefs!.setString(
      '$_cacheKeyPrefix$cacheKey',
      jsonEncode(cacheEntry.toJson()),
    );

    await _updateCacheMetadata();
    await _enforceCacheLimits();

    _stats.cacheWrites++;
    await _saveCacheStatistics();
  }

  /// Retrieve cached response with fuzzy matching
  static Future<AIResponse?> getCachedResponse({
    required String query,
    List<File>? images,
    String? extractedText,
    bool enableFuzzyMatching = true,
  }) async {
    await init();

    // Try exact match first
    final exactKey = _generateCacheKey(query, images, extractedText);
    final exactMatch = await _getCacheEntry(exactKey);

    if (exactMatch != null && !exactMatch.isExpired) {
      await _updateCacheAccess(exactMatch);
      _stats.cacheHits++;
      await _saveCacheStatistics();
      return exactMatch.response;
    }

    // Try fuzzy matching for similar queries
    if (enableFuzzyMatching) {
      final fuzzyMatch = await _findSimilarCachedResponse(
        query,
        images,
        extractedText,
      );

      if (fuzzyMatch != null) {
        await _updateCacheAccess(fuzzyMatch);
        _stats.cacheHits++;
        _stats.fuzzyHits++;
        await _saveCacheStatistics();
        return fuzzyMatch.response;
      }
    }

    _stats.cacheMisses++;
    await _saveCacheStatistics();
    return null;
  }

  /// Pre-warm cache with common queries
  static Future<void> warmCache(List<String> commonQueries) async {
    for (final query in commonQueries) {
      final cacheKey = _generateCacheKey(query, null, null);
      if (!_memoryCache.containsKey(cacheKey)) {
        // Mark for pre-warming (could trigger background AI calls)
        await _markForPreWarming(query);
      }
    }
  }

  /// Get cache statistics for monitoring
  static Future<CacheStatistics> getCacheStatistics() async {
    await init();

    _stats.totalEntries = _memoryCache.length;
    _stats.memoryUsage = _calculateMemoryUsage();
    _stats.hitRate = _stats.cacheHits > 0
        ? _stats.cacheHits / (_stats.cacheHits + _stats.cacheMisses)
        : 0.0;

    return _stats;
  }

  /// Clear expired cache entries
  static Future<void> clearExpiredCache() async {
    await init();

    final expiredKeys = <String>[];
    final now = DateTime.now();

    for (final entry in _memoryCache.values) {
      if (entry.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      await _prefs!.remove('$_cacheKeyPrefix$key');
    }

    await _updateCacheMetadata();
    _stats.expiredEntries += expiredKeys.length;
    await _saveCacheStatistics();
  }

  /// Clear all cache
  static Future<void> clearAllCache() async {
    await init();

    _memoryCache.clear();

    final keys = _prefs!
        .getKeys()
        .where((key) => key.startsWith(_cacheKeyPrefix))
        .toList();

    for (final key in keys) {
      await _prefs!.remove(key);
    }

    _stats = CacheStatistics();
    await _saveCacheStatistics();
    await _updateCacheMetadata();
  }

  // Private helper methods

  static String _generateCacheKey(
    String query,
    List<File>? images,
    String? extractedText,
  ) {
    final buffer = StringBuffer();
    buffer.write(query.toLowerCase().trim());

    if (extractedText != null && extractedText.isNotEmpty) {
      buffer.write('|text:${extractedText.toLowerCase().trim()}');
    }

    if (images != null && images.isNotEmpty) {
      final imageInfo = images.map((img) => '${img.lengthSync()}').join(',');
      buffer.write('|images:$imageInfo');
    }

    final bytes = utf8.encode(buffer.toString());
    return sha256.convert(bytes).toString().substring(0, 16);
  }

  static Future<List<String>?> _generateImageHashes(List<File> images) async {
    final hashes = <String>[];

    for (final image in images) {
      try {
        final bytes = await image.readAsBytes();
        final hash = sha256.convert(bytes).toString().substring(0, 16);
        hashes.add(hash);
      } catch (e) {
        // Skip invalid images
        continue;
      }
    }

    return hashes.isNotEmpty ? hashes : null;
  }

  static Future<CacheEntry?> _getCacheEntry(String key) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    // Check persistent cache
    final cached = _prefs!.getString('$_cacheKeyPrefix$key');
    if (cached != null) {
      try {
        final entry = CacheEntry.fromJson(jsonDecode(cached));
        _memoryCache[key] = entry; // Load into memory
        return entry;
      } catch (e) {
        // Remove corrupted cache entry
        await _prefs!.remove('$_cacheKeyPrefix$key');
      }
    }

    return null;
  }

  static Future<CacheEntry?> _findSimilarCachedResponse(
    String query,
    List<File>? images,
    String? extractedText,
  ) async {
    final queryWords = query.toLowerCase().split(' ').toSet();
    CacheEntry? bestMatch;
    double bestSimilarity = 0.0;

    for (final entry in _memoryCache.values) {
      if (entry.isExpired) continue;

      final entryWords = entry.query.toLowerCase().split(' ').toSet();
      final similarity = _calculateSimilarity(queryWords, entryWords);

      if (similarity > _similarityThreshold && similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestMatch = entry;
      }
    }

    return bestMatch;
  }

  static double _calculateSimilarity(Set<String> words1, Set<String> words2) {
    if (words1.isEmpty && words2.isEmpty) return 1.0;
    if (words1.isEmpty || words2.isEmpty) return 0.0;

    final intersection = words1.intersection(words2).length;
    final union = words1.union(words2).length;

    return intersection / union;
  }

  static Future<void> _updateCacheAccess(CacheEntry entry) async {
    entry.accessCount++;
    entry.lastAccessed = DateTime.now();

    _memoryCache[entry.key] = entry;
    await _prefs!.setString(
      '$_cacheKeyPrefix${entry.key}',
      jsonEncode(entry.toJson()),
    );
  }

  static Future<void> _enforceCacheLimits() async {
    if (_memoryCache.length <= _maxCacheSize) return;

    // Sort by priority and access patterns
    final entries = _memoryCache.values.toList();
    entries.sort((a, b) {
      // High priority entries stay longer
      if (a.highPriority != b.highPriority) {
        return b.highPriority ? 1 : -1;
      }

      // Sort by access frequency and recency
      final scoreA =
          a.accessCount +
          (DateTime.now().difference(a.lastAccessed).inHours * -0.1);
      final scoreB =
          b.accessCount +
          (DateTime.now().difference(b.lastAccessed).inHours * -0.1);

      return scoreB.compareTo(scoreA);
    });

    // Remove least valuable entries
    final toRemove = entries.skip(_maxCacheSize).toList();
    for (final entry in toRemove) {
      _memoryCache.remove(entry.key);
      await _prefs!.remove('$_cacheKeyPrefix${entry.key}');
    }

    await _updateCacheMetadata();
  }

  static Future<void> _loadCacheMetadata() async {
    final metadata = _prefs!.getString(_cacheMetadataKey);
    if (metadata != null) {
      try {
        final data = jsonDecode(metadata) as Map<String, dynamic>;
        // Store metadata for future use if needed
        print('Cache metadata loaded: ${data.length} entries');
      } catch (e) {
        // Reset metadata on corruption
        await _prefs!.remove(_cacheMetadataKey);
      }
    }
  }

  static Future<void> _updateCacheMetadata() async {
    final metadata = {
      'totalEntries': _memoryCache.length,
      'lastUpdated': DateTime.now().toIso8601String(),
    };

    await _prefs!.setString(_cacheMetadataKey, jsonEncode(metadata));
  }

  static Future<void> _cleanupExpiredEntries() async {
    await clearExpiredCache();
  }

  static Future<void> _loadCacheStatistics() async {
    final statsData = _prefs!.getString(_cacheStatsKey);
    if (statsData != null) {
      try {
        _stats = CacheStatistics.fromJson(jsonDecode(statsData));
      } catch (e) {
        _stats = CacheStatistics();
      }
    }
  }

  static Future<void> _saveCacheStatistics() async {
    await _prefs!.setString(_cacheStatsKey, jsonEncode(_stats.toJson()));
  }

  static int _calculateMemoryUsage() {
    // Rough estimation of memory usage in bytes
    int totalSize = 0;
    for (final entry in _memoryCache.values) {
      totalSize += entry.query.length * 2; // UTF-16 chars
      totalSize += entry.response.content.length * 2;
      totalSize += 200; // Overhead
    }
    return totalSize;
  }

  static Future<void> _markForPreWarming(String query) async {
    // Implementation for marking queries for background processing
    final prewarmQueries = _prefs!.getStringList('prewarm_queries') ?? [];
    if (!prewarmQueries.contains(query)) {
      prewarmQueries.add(query);
      await _prefs!.setStringList('prewarm_queries', prewarmQueries);
    }
  }
}

/// Cache entry model
class CacheEntry {
  final String key;
  final String query;
  final AIResponse response;
  final String? extractedText;
  final List<String>? imageHashes;
  final DateTime createdAt;
  final DateTime expiresAt;
  int accessCount;
  DateTime lastAccessed;
  final bool highPriority;

  CacheEntry({
    required this.key,
    required this.query,
    required this.response,
    this.extractedText,
    this.imageHashes,
    required this.createdAt,
    required this.expiresAt,
    this.accessCount = 1,
    required this.lastAccessed,
    this.highPriority = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'key': key,
    'query': query,
    'response': {
      'content': response.content,
      'model': response.model,
      'confidence': response.confidence,
      'isSuccessful': response.isSuccessful,
      'error': response.error,
      'metadata': response.metadata,
    },
    'extractedText': extractedText,
    'imageHashes': imageHashes,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'accessCount': accessCount,
    'lastAccessed': lastAccessed.toIso8601String(),
    'highPriority': highPriority,
  };

  factory CacheEntry.fromJson(Map<String, dynamic> json) => CacheEntry(
    key: json['key'],
    query: json['query'],
    response: AIResponse(
      content: json['response']['content'],
      model: json['response']['model'],
      confidence: json['response']['confidence']?.toDouble() ?? 0.0,
      isSuccessful: json['response']['isSuccessful'] ?? false,
      error: json['response']['error'],
      metadata: json['response']['metadata'],
    ),
    extractedText: json['extractedText'],
    imageHashes: json['imageHashes']?.cast<String>(),
    createdAt: DateTime.parse(json['createdAt']),
    expiresAt: DateTime.parse(json['expiresAt']),
    accessCount: json['accessCount'] ?? 1,
    lastAccessed: DateTime.parse(json['lastAccessed']),
    highPriority: json['highPriority'] ?? false,
  );
}

/// Cache statistics for monitoring
class CacheStatistics {
  int cacheHits = 0;
  int cacheMisses = 0;
  int cacheWrites = 0;
  int fuzzyHits = 0;
  int expiredEntries = 0;
  int totalEntries = 0;
  int memoryUsage = 0;
  double hitRate = 0.0;

  CacheStatistics._internal();

  factory CacheStatistics() => CacheStatistics._internal();

  Map<String, dynamic> toJson() => {
    'cacheHits': cacheHits,
    'cacheMisses': cacheMisses,
    'cacheWrites': cacheWrites,
    'fuzzyHits': fuzzyHits,
    'expiredEntries': expiredEntries,
    'totalEntries': totalEntries,
    'memoryUsage': memoryUsage,
    'hitRate': hitRate,
  };

  factory CacheStatistics.fromJson(Map<String, dynamic> json) {
    final stats = CacheStatistics._internal();
    stats.cacheHits = json['cacheHits'] ?? 0;
    stats.cacheMisses = json['cacheMisses'] ?? 0;
    stats.cacheWrites = json['cacheWrites'] ?? 0;
    stats.fuzzyHits = json['fuzzyHits'] ?? 0;
    stats.expiredEntries = json['expiredEntries'] ?? 0;
    stats.totalEntries = json['totalEntries'] ?? 0;
    stats.memoryUsage = json['memoryUsage'] ?? 0;
    stats.hitRate = json['hitRate'] ?? 0.0;
    return stats;
  }
}
