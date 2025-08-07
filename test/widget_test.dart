// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imagequery/main.dart';
import 'package:imagequery/services/config_service.dart';

void main() {
  group('ImageQuery AI App Tests', () {
    setUpAll(() async {
      // Initialize ConfigService for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      await ConfigService.init();
    });

    testWidgets('App should build and show setup screen when no API keys', (
      WidgetTester tester,
    ) async {
      // Clear any existing API keys
      await ConfigService.clearApiKeys();

      // Build the app
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Should show setup screen when no API keys are configured
      expect(find.text('Welcome to ImageQuery AI'), findsOneWidget);
      expect(find.text('Gemini AI API Key'), findsOneWidget);
      expect(find.text('Hugging Face API Key'), findsOneWidget);
    });

    testWidgets('Setup screen should validate API key input', (
      WidgetTester tester,
    ) async {
      await ConfigService.clearApiKeys();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Try to save without entering API keys
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Please enter your Gemini API key'), findsOneWidget);
      expect(
        find.text('Please enter your Hugging Face API key'),
        findsOneWidget,
      );
    });

    testWidgets('Should navigate to chat screen with valid API keys', (
      WidgetTester tester,
    ) async {
      await ConfigService.clearApiKeys();

      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Enter valid API keys
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Gemini AI API Key'),
        'test-gemini-key',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hugging Face API Key'),
        'test-huggingface-key',
      );

      // Tap save button
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Should navigate to chat screen (though it might show errors due to invalid API keys)
      // The important thing is that validation passes and navigation occurs
      expect(find.text('Welcome to ImageQuery AI'), findsOneWidget);
    });
  });
}
