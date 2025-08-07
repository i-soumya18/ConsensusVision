import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/config_service.dart';
import 'providers/chat_provider.dart';
import 'screens/setup_screen.dart';
import 'screens/chat_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize configuration service
  await ConfigService.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ImageQuery AI',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ConfigService.isDarkMode() ? ThemeMode.dark : ThemeMode.light,
      home: const AppWrapper(),
      routes: {
        '/setup': (context) => const SetupScreen(),
        '/chat': (context) => const ChatWrapper(),
      },
      debugShowCheckedModeBanner: false,
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
