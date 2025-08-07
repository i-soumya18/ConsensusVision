import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'app_theme_mode';
  static const String _primaryColorKey = 'primary_color';

  AppThemeMode _themeMode = AppThemeMode.system;
  Color _primaryColor = const Color(0xFF2563EB);
  bool _systemIsDark = false;

  AppThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
        return _systemIsDark;
    }
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          background: Colors.white,
          surface: const Color(0xFFF8F9FA),
          onSurface: const Color(0xFF1A1A1A),
          onBackground: const Color(0xFF1A1A1A),
        ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFF8F9FA),
      elevation: 2,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: Color(0xFF1A1A1A)),
      headlineMedium: TextStyle(color: Color(0xFF1A1A1A)),
      headlineSmall: TextStyle(color: Color(0xFF1A1A1A)),
      titleLarge: TextStyle(color: Color(0xFF1A1A1A)),
      titleMedium: TextStyle(color: Color(0xFF1A1A1A)),
      titleSmall: TextStyle(color: Color(0xFF1A1A1A)),
      bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
      bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
      bodySmall: TextStyle(color: Color(0xFF666666)),
      labelLarge: TextStyle(color: Color(0xFF1A1A1A)),
      labelMedium: TextStyle(color: Color(0xFF1A1A1A)),
      labelSmall: TextStyle(color: Color(0xFF666666)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF999999)),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ).copyWith(
          background: const Color(0xFF121212),
          surface: const Color(0xFF1E1E1E),
          onSurface: const Color(0xFFE1E1E1),
          onBackground: const Color(0xFFE1E1E1),
        ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFFE1E1E1),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF1E1E1E),
      elevation: 4,
      surfaceTintColor: Colors.transparent,
    ),
  );

  Future<void> initialize() async {
    // Detect system theme
    _systemIsDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;

    // Load preferences
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey);
    if (themeModeString != null) {
      _themeMode = AppThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => AppThemeMode.system,
      );
    }

    final colorValue = prefs.getInt(_primaryColorKey);
    if (colorValue != null) {
      _primaryColor = Color(colorValue);
    }

    // Listen to system theme changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged =
        () {
          _systemIsDark =
              WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark;
          if (_themeMode == AppThemeMode.system) {
            notifyListeners();
          }
        };

    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_primaryColorKey, color.value);
  }
}
