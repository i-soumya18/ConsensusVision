import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:http/http.dart' as http;

/// High-performance HTTP connection pool service for faster API responses
/// Implements connection reuse, concurrent request management, and smart retries
class ConnectionPoolService {
  static final ConnectionPoolService _instance =
      ConnectionPoolService._internal();
  factory ConnectionPoolService() => _instance;
  ConnectionPoolService._internal();

  // Connection pool configuration
  static const int _maxConnections = 10;
  static const int _maxConnectionsPerHost = 3;
  static const Duration _connectionTimeout = Duration(seconds: 15);
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(milliseconds: 500);

  // Connection pools by host
  final Map<String, List<_PooledConnection>> _connectionPools = {};
  final Map<String, int> _activeConnections = {};
  final Map<String, Queue<Completer<_PooledConnection>>> _waitingQueue = {};

  // Request queue for rate limiting
  final Queue<_QueuedRequest> _requestQueue = Queue<_QueuedRequest>();
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCounts = {};
  bool _processingQueue = false;

  // Statistics
  int _totalRequests = 0;
  int _successfulRequests = 0;
  int _failedRequests = 0;
  int _retriedRequests = 0;
  int _cacheHits = 0;

  /// Initialize the connection pool service
  Future<void> init() async {
    // Start queue processor
    _startQueueProcessor();

    // Cleanup timer for idle connections
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupIdleConnections();
    });
  }

  /// Make an optimized HTTP request with connection pooling
  Future<http.Response> request({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int priority = 5, // 1-10 scale, 10 being highest
    bool bypassQueue = false,
  }) async {
    _totalRequests++;

    final requestTimeout = timeout ?? _requestTimeout;
    final host = url.host;

    if (!bypassQueue && _shouldQueueRequest(host)) {
      return _queueRequest(
        method: method,
        url: url,
        headers: headers,
        body: body,
        timeout: requestTimeout,
        priority: priority,
      );
    }

    return _executeRequest(
      method: method,
      url: url,
      headers: headers,
      body: body,
      timeout: requestTimeout,
    );
  }

  /// Optimized GET request
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int priority = 5,
  }) {
    return request(
      method: 'GET',
      url: url,
      headers: headers,
      timeout: timeout,
      priority: priority,
    );
  }

  /// Optimized POST request
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    dynamic body,
    Duration? timeout,
    int priority = 5,
  }) {
    return request(
      method: 'POST',
      url: url,
      headers: headers,
      body: body,
      timeout: timeout,
      priority: priority,
    );
  }

  /// Execute multiple requests concurrently with smart batching
  Future<List<http.Response>> batchRequests(
    List<_BatchRequest> requests, {
    int maxConcurrency = 3,
    Duration? timeout,
  }) async {
    final results = <http.Response>[];
    final futures = <Future<http.Response>>[];

    for (int i = 0; i < requests.length; i += maxConcurrency) {
      final batch = requests.skip(i).take(maxConcurrency);

      for (final req in batch) {
        futures.add(
          request(
            method: req.method,
            url: req.url,
            headers: req.headers,
            body: req.body,
            timeout: timeout,
            priority: req.priority,
            bypassQueue: true, // Batch requests bypass normal queue
          ),
        );
      }

      if (futures.length >= maxConcurrency ||
          i + maxConcurrency >= requests.length) {
        final batchResults = await Future.wait(futures);
        results.addAll(batchResults);
        futures.clear();
      }
    }

    return results;
  }

  /// Get connection pool statistics
  Map<String, dynamic> getStatistics() {
    final totalConnections = _connectionPools.values
        .map((pool) => pool.length)
        .fold(0, (sum, count) => sum + count);

    final activeConnections = _activeConnections.values.fold(
      0,
      (sum, count) => sum + count,
    );

    final queuedRequests = _requestQueue.length;

    final successRate = _totalRequests > 0
        ? _successfulRequests / _totalRequests * 100
        : 0.0;

    return {
      'totalRequests': _totalRequests,
      'successfulRequests': _successfulRequests,
      'failedRequests': _failedRequests,
      'retriedRequests': _retriedRequests,
      'successRate': successRate,
      'totalConnections': totalConnections,
      'activeConnections': activeConnections,
      'queuedRequests': queuedRequests,
      'connectionPools': _connectionPools.keys.toList(),
      'cacheHits': _cacheHits,
    };
  }

  /// Clear all connections and reset pools
  Future<void> clearConnections() async {
    for (final pool in _connectionPools.values) {
      for (final conn in pool) {
        try {
          conn.client.close();
        } catch (e) {
          // Ignore errors during cleanup
        }
      }
    }

    _connectionPools.clear();
    _activeConnections.clear();
    _waitingQueue.clear();
  }

  /// Warm up connections to specific hosts
  Future<void> warmupConnections(List<String> hosts) async {
    for (final host in hosts) {
      try {
        await _getConnection(host);
      } catch (e) {
        // Ignore warmup failures
        print('Failed to warmup connection to $host: $e');
      }
    }
  }

  // Private methods

  Future<http.Response> _executeRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    required Duration timeout,
    int retryCount = 0,
  }) async {
    try {
      final connection = await _getConnection(url.host).timeout(timeout);

      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await connection.client.get(url, headers: headers);
          break;
        case 'POST':
          response = await connection.client.post(
            url,
            headers: headers,
            body: body,
          );
          break;
        case 'PUT':
          response = await connection.client.put(
            url,
            headers: headers,
            body: body,
          );
          break;
        case 'DELETE':
          response = await connection.client.delete(url, headers: headers);
          break;
        default:
          throw UnsupportedError('Method $method not supported');
      }

      _returnConnection(connection);
      _successfulRequests++;
      _updateRequestStats(url.host);

      return response;
    } catch (e) {
      if (retryCount < _maxRetries && _shouldRetry(e)) {
        _retriedRequests++;
        await Future.delayed(_retryDelay * (retryCount + 1));
        return _executeRequest(
          method: method,
          url: url,
          headers: headers,
          body: body,
          timeout: timeout,
          retryCount: retryCount + 1,
        );
      }

      _failedRequests++;
      rethrow;
    }
  }

  Future<_PooledConnection> _getConnection(String host) async {
    // Check for available connection in pool
    final pool = _connectionPools[host] ?? [];
    if (pool.isNotEmpty) {
      final connection = pool.removeAt(0);
      if (connection.isActive) {
        _activeConnections[host] = (_activeConnections[host] ?? 0) + 1;
        return connection;
      }
    }

    // Check connection limits
    final activeCount = _activeConnections[host] ?? 0;
    if (activeCount >= _maxConnectionsPerHost) {
      return _waitForConnection(host);
    }

    // Create new connection
    return _createConnection(host);
  }

  Future<_PooledConnection> _waitForConnection(String host) async {
    final completer = Completer<_PooledConnection>();
    _waitingQueue
        .putIfAbsent(host, () => Queue<Completer<_PooledConnection>>())
        .add(completer);

    return completer.future.timeout(
      _connectionTimeout,
      onTimeout: () => throw TimeoutException('Connection timeout for $host'),
    );
  }

  Future<_PooledConnection> _createConnection(String host) async {
    final client = http.Client();
    final connection = _PooledConnection(
      client: client,
      host: host,
      createdAt: DateTime.now(),
      lastUsed: DateTime.now(),
    );

    _activeConnections[host] = (_activeConnections[host] ?? 0) + 1;
    return connection;
  }

  void _returnConnection(_PooledConnection connection) {
    connection.lastUsed = DateTime.now();

    final host = connection.host;
    _activeConnections[host] = (_activeConnections[host] ?? 1) - 1;

    // Check if there are waiting requests
    final waitingQueue = _waitingQueue[host];
    if (waitingQueue != null && waitingQueue.isNotEmpty) {
      final completer = waitingQueue.removeFirst();
      _activeConnections[host] = (_activeConnections[host] ?? 0) + 1;
      completer.complete(connection);
      return;
    }

    // Return to pool
    final pool = _connectionPools.putIfAbsent(host, () => []);
    if (pool.length < _maxConnections) {
      pool.add(connection);
    } else {
      connection.client.close();
    }
  }

  bool _shouldQueueRequest(String host) {
    final activeCount = _activeConnections[host] ?? 0;
    final requestCount = _requestCounts[host] ?? 0;
    const maxRequestsPerSecond = 10;

    return activeCount >= _maxConnectionsPerHost ||
        requestCount >= maxRequestsPerSecond;
  }

  Future<http.Response> _queueRequest({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    dynamic body,
    required Duration timeout,
    required int priority,
  }) async {
    final completer = Completer<http.Response>();
    final queuedRequest = _QueuedRequest(
      method: method,
      url: url,
      headers: headers,
      body: body,
      timeout: timeout,
      priority: priority,
      completer: completer,
      queuedAt: DateTime.now(),
    );

    _requestQueue.add(queuedRequest);
    _startQueueProcessor();

    return completer.future;
  }

  void _startQueueProcessor() {
    if (_processingQueue) return;

    _processingQueue = true;
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_requestQueue.isEmpty) {
        _processingQueue = false;
        timer.cancel();
        return;
      }

      _processQueuedRequests();
    });
  }

  void _processQueuedRequests() {
    if (_requestQueue.isEmpty) return;

    // Sort by priority and queue time
    final requests = _requestQueue.toList();
    requests.sort((a, b) {
      final priorityCompare = b.priority.compareTo(a.priority);
      if (priorityCompare != 0) return priorityCompare;

      return a.queuedAt.compareTo(b.queuedAt);
    });

    final toProcess = <_QueuedRequest>[];
    for (final request in requests) {
      if (!_shouldQueueRequest(request.url.host) && toProcess.length < 3) {
        toProcess.add(request);
        _requestQueue.remove(request);
      }
    }

    for (final request in toProcess) {
      _executeRequest(
            method: request.method,
            url: request.url,
            headers: request.headers,
            body: request.body,
            timeout: request.timeout,
          )
          .then((response) {
            request.completer.complete(response);
          })
          .catchError((error) {
            request.completer.completeError(error);
          });
    }
  }

  void _updateRequestStats(String host) {
    final now = DateTime.now();
    final lastRequest = _lastRequestTime[host];

    if (lastRequest == null || now.difference(lastRequest).inSeconds >= 1) {
      _requestCounts[host] = 1;
      _lastRequestTime[host] = now;
    } else {
      _requestCounts[host] = (_requestCounts[host] ?? 0) + 1;
    }
  }

  bool _shouldRetry(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) return true;

    return false;
  }

  void _cleanupIdleConnections() {
    final now = DateTime.now();
    const maxIdleTime = Duration(minutes: 10);

    for (final host in _connectionPools.keys.toList()) {
      final pool = _connectionPools[host]!;
      final toRemove = <_PooledConnection>[];

      for (final connection in pool) {
        if (now.difference(connection.lastUsed) > maxIdleTime) {
          toRemove.add(connection);
        }
      }

      for (final connection in toRemove) {
        pool.remove(connection);
        connection.client.close();
      }

      if (pool.isEmpty) {
        _connectionPools.remove(host);
      }
    }
  }
}

/// Pooled HTTP connection wrapper
class _PooledConnection {
  final http.Client client;
  final String host;
  final DateTime createdAt;
  DateTime lastUsed;

  _PooledConnection({
    required this.client,
    required this.host,
    required this.createdAt,
    required this.lastUsed,
  });

  bool get isActive => DateTime.now().difference(createdAt).inMinutes < 30;
}

/// Queued request model
class _QueuedRequest {
  final String method;
  final Uri url;
  final Map<String, String>? headers;
  final dynamic body;
  final Duration timeout;
  final int priority;
  final Completer<http.Response> completer;
  final DateTime queuedAt;

  _QueuedRequest({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    required this.timeout,
    required this.priority,
    required this.completer,
    required this.queuedAt,
  });
}

/// Batch request model
class _BatchRequest {
  final String method;
  final Uri url;
  final Map<String, String>? headers;
  final dynamic body;
  final int priority;

  const _BatchRequest({
    required this.method,
    required this.url,
    this.headers,
    this.body,
    this.priority = 5,
  });
}
