# Integration Guide - Enhanced AI Performance System

## 🚀 Quick Integration Steps

Follow these steps to integrate the new performance optimizations into your existing ImageQuery app:

### Step 1: Update Main App Entry Point

Update your `main.dart` to initialize the performance services:

```dart
// Add this import at the top
import 'lib/services/enhanced_ai_service.dart';

// In your main() function, add initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize enhanced AI service with all optimizations
  final enhancedAI = EnhancedAIService();
  await enhancedAI.init();
  
  runApp(MyApp());
}
```

### Step 2: Update Chat Providers

Replace existing AI service calls in your chat providers with the enhanced service:

#### Example: Update `lib/providers/chat_provider.dart`

```dart
// Add import
import '../services/enhanced_ai_service.dart';

class ChatProvider with ChangeNotifier {
  final EnhancedAIService _enhancedAI = EnhancedAIService();
  
  // Replace existing processMessage method
  Future<void> processMessage(String message, {List<File>? images}) async {
    try {
      // For real-time streaming responses
      await for (final chunk in _enhancedAI.processStreamingQuery(
        query: message,
        images: images,
      )) {
        // Update UI with streaming response
        _updateMessageWithChunk(chunk);
        notifyListeners();
      }
    } catch (e) {
      // Error handling
      _handleError(e);
    }
  }
  
  // For non-streaming responses (with caching)
  Future<String> processNonStreamingMessage(String message, {List<File>? images}) async {
    return await _enhancedAI.processQuery(
      query: message,
      images: images,
      enableCaching: true, // Enable caching for faster responses
    );
  }
}
```

### Step 3: Update Existing AI Service Calls

Find and replace existing AI service usage throughout your app:

#### Before (Old Code):
```dart
// Old way
final geminiService = GeminiService();
final response = await geminiService.sendMessage(prompt, images);
```

#### After (New Code):
```dart
// New optimized way
final enhancedAI = EnhancedAIService();
final response = await enhancedAI.processQuery(
  query: prompt,
  images: images,
  enableCaching: true,
);
```

### Step 4: Add Performance Dashboard to Navigation

Update your main navigation to include the performance dashboard:

#### Example: Update `lib/screens/main_screen.dart`

```dart
// Add import
import '../widgets/performance_dashboard_widget.dart';

// In your navigation drawer or menu
ListTile(
  leading: const Icon(Icons.speed),
  title: const Text('Performance Monitor'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PerformanceDashboardWidget(),
      ),
    );
  },
),
```

### Step 5: Update Settings Screen

Add performance-related settings to your existing settings screen:

#### Example: Update `lib/screens/settings_screen.dart`

```dart
// Add these settings
SwitchListTile(
  title: const Text('Enable Response Caching'),
  subtitle: const Text('Cache AI responses for faster access'),
  value: _cachingEnabled,
  onChanged: (value) {
    setState(() => _cachingEnabled = value);
    // Save setting to SharedPreferences
    _saveSettings();
  },
),

SwitchListTile(
  title: const Text('Enable Streaming Responses'),
  subtitle: const Text('Show AI responses in real-time'),
  value: _streamingEnabled,
  onChanged: (value) {
    setState(() => _streamingEnabled = value);
    _saveSettings();
  },
),

ListTile(
  title: const Text('Clear Response Cache'),
  subtitle: const Text('Free up storage space'),
  trailing: const Icon(Icons.delete_outline),
  onTap: () async {
    await ResponseCacheService.clearAllCache();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  },
),
```

## 🔧 Specific File Updates

### Update `lib/services/ai_service.dart`

If you have an existing AI service, update it to use the enhanced service:

```dart
import 'enhanced_ai_service.dart';

class AIService {
  static final EnhancedAIService _enhanced = EnhancedAIService();
  
  // Migrate existing methods to use enhanced service
  static Future<String> analyzeImage(File image, String prompt) async {
    return await _enhanced.processQuery(
      query: prompt,
      images: [image],
      enableCaching: true,
    );
  }
  
  static Stream<String> analyzeImageStreaming(File image, String prompt) {
    return _enhanced.processStreamingQuery(
      query: prompt,
      images: [image],
    );
  }
}
```

### Update Chat Screens

For any chat or messaging screens, update to use streaming:

```dart
// In your chat widget build method
StreamBuilder<String>(
  stream: _enhancedAI.processStreamingQuery(
    query: message,
    images: attachedImages,
  ),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text(snapshot.data!);
    } else if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    } else {
      return const CircularProgressIndicator();
    }
  },
)
```

## 📱 UI Updates for Better Performance Visibility

### Add Performance Indicators

Show cache status and performance metrics in your UI:

```dart
// Cache hit rate indicator
FutureBuilder<Map<String, dynamic>>(
  future: ResponseCacheService.getCacheStatistics(),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final hitRate = snapshot.data!['hitRate'] as double;
      return Chip(
        label: Text('Cache: ${(hitRate * 100).toStringAsFixed(1)}%'),
        backgroundColor: hitRate > 0.5 ? Colors.green : Colors.orange,
      );
    }
    return const SizedBox.shrink();
  },
)
```

### Show Response Time Metrics

```dart
// Response time indicator
class ResponseTimeIndicator extends StatefulWidget {
  final String lastResponseTime;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Response: ${lastResponseTime}ms',
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
```

## 🔍 Debugging and Monitoring Integration

### Add Performance Logging

Update your existing logging to include performance metrics:

```dart
// In your existing logging service
class LoggingService {
  static void logPerformance(String operation, int durationMs) {
    print('Performance: $operation took ${durationMs}ms');
    
    // Send to performance monitoring
    PerformanceMonitoringService().recordOperation(
      operation: operation,
      durationMs: durationMs,
      success: true,
    );
  }
}
```

### Error Handling Updates

Enhance error handling to work with the new performance system:

```dart
try {
  final response = await _enhancedAI.processQuery(query: message);
  // Success handling
} on CacheException catch (e) {
  // Handle cache-specific errors
  print('Cache error: $e');
} on ConnectionPoolException catch (e) {
  // Handle connection pool errors
  print('Connection error: $e');
} catch (e) {
  // Handle general errors
  print('General error: $e');
}
```

## 🎯 Testing the Integration

### 1. Test Basic Functionality

```dart
// Test that enhanced AI service works
final testResponse = await EnhancedAIService().processQuery(
  query: "Test query",
);
print('Test response: $testResponse');
```

### 2. Test Caching

```dart
// Make the same request twice to test caching
final query = "What's in this image?";
final image = File('path/to/test/image.jpg');

// First request (should be slow, cache miss)
final start1 = DateTime.now();
final response1 = await enhancedAI.processQuery(query: query, images: [image]);
final duration1 = DateTime.now().difference(start1).inMilliseconds;

// Second request (should be fast, cache hit)
final start2 = DateTime.now();
final response2 = await enhancedAI.processQuery(query: query, images: [image]);
final duration2 = DateTime.now().difference(start2).inMilliseconds;

print('First request: ${duration1}ms');
print('Second request: ${duration2}ms');
print('Cache hit: ${duration2 < duration1 / 2}');
```

### 3. Test Streaming

```dart
// Test streaming responses
await for (final chunk in enhancedAI.processStreamingQuery(
  query: "Describe this image in detail",
  images: [testImage],
)) {
  print('Chunk received: $chunk');
}
```

## ⚠️ Migration Checklist

- [ ] Initialize EnhancedAIService in main.dart
- [ ] Update all AI service calls to use enhanced service
- [ ] Add performance dashboard to navigation
- [ ] Update settings screen with performance options
- [ ] Test caching functionality
- [ ] Test streaming responses
- [ ] Verify error handling works correctly
- [ ] Check performance metrics in dashboard
- [ ] Test on different network conditions
- [ ] Validate memory usage is reasonable

## 🚨 Common Issues and Solutions

### Issue 1: Import Errors
**Solution:** Make sure all new service files are in the correct location and imports are updated.

### Issue 2: Null Safety Errors
**Solution:** Check that all nullable types are properly handled with null checks or default values.

### Issue 3: Performance Dashboard Not Loading
**Solution:** Ensure all performance services are initialized before accessing the dashboard.

### Issue 4: Cache Not Working
**Solution:** Check that SharedPreferences is properly initialized and the crypto package is available.

### Issue 5: Streaming Not Working
**Solution:** Verify that the stream is properly subscribed to and error handling is in place.

## 📞 Post-Integration Support

After integration, monitor these metrics:
- Response times compared to before
- Cache hit rates (target: >40%)
- Error rates (should be low)
- Memory usage (should be stable)
- User experience improvements

If you encounter issues, check:
1. Performance Dashboard for metrics
2. Console logs for errors
3. Network connectivity
4. Cache storage availability

---

*This integration should provide immediate performance improvements while maintaining all existing functionality. The new system is designed to be backward-compatible and non-breaking.*
