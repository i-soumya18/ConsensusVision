import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

class TextExtractionService {
  static final TextRecognizer _textRecognizer = GoogleMlKit.vision
      .textRecognizer();

  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }

      return extractedText.trim();
    } catch (e) {
      print('Error extracting text: $e');
      return '';
    }
  }

  static Future<String> extractTextFromMultipleImages(
    List<File> imageFiles,
  ) async {
    List<String> allTexts = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final text = await extractTextFromImage(imageFiles[i]);
      if (text.isNotEmpty) {
        allTexts.add('--- Image ${i + 1} ---\n$text');
      }
    }

    return allTexts.join('\n\n');
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
