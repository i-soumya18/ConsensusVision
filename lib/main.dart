import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'services/config_service.dart';
import 'services/database_service.dart';
import 'services/theme_service.dart';
import 'providers/chat_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Suppress keyboard event assertions in debug mode
  FlutterError.onError = (FlutterErrorDetails details) {
    // Filter out known harmless keyboard event assertions
    if (details.exception.toString().contains('KeyDownEvent is dispatched') ||
        details.exception.toString().contains('_pressedKeys.containsKey')) {
      // Silently ignore this known Flutter framework issue
      return;
    }
    // For other errors, use default handler
    FlutterError.presentError(details);
  };

  // Initialize SQLite for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Initialize database service
  DatabaseService.initializeDatabase();

  // Initialize configuration service
  await ConfigService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService()..initialize(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) => MaterialApp(
          title: 'ImageQuery AI',
          theme: themeService.lightTheme,
          darkTheme: themeService.darkTheme,
          themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const AppWrapper(),
          routes: {
            '/setup': (context) => const SetupScreen(),
            '/chat': (context) => const ChatWrapper(),
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Check if API keys are configured
    if (!ConfigService.hasValidApiKeys()) {
      return const SetupScreen();
    }

    return const ChatWrapper();
  }
}

class ChatWrapper extends StatelessWidget {
  const ChatWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final geminiApiKey = ConfigService.getGeminiApiKey();
    final huggingFaceApiKey = ConfigService.getHuggingFaceApiKey();

    if (geminiApiKey == null || huggingFaceApiKey == null) {
      return const SetupScreen();
    }

    return ChangeNotifierProvider(
      create: (context) => ChatProvider(
        geminiApiKey: geminiApiKey,
        huggingFaceApiKey: huggingFaceApiKey,
      )..initialize(),
      child: const ChatScreen(),
    );
  }
}
