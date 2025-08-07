# ImageQuery AI - Setup Guide

## Quick Start

1. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

2. **Generate required files:**
   ```bash
   flutter packages pub run build_runner build
   ```

3. **Run the app:**
   ```bash
   # For Windows
   flutter run -d windows
   
   # For Android (with device/emulator connected)
   flutter run
   ```

## API Keys Setup

### Gemini AI API Key
1. Go to: https://ai.google.dev
2. Sign in with Google account
3. Create new project or select existing
4. Generate API key
5. Enter in app setup screen

### Hugging Face API Key
1. Go to: https://huggingface.co/settings/tokens
2. Create new token
3. Set permissions to "Read"
4. Enter in app setup screen

## Features Overview

### Image Processing
- ✅ Camera capture
- ✅ Gallery selection  
- ✅ Multi-file picker
- ✅ OCR text extraction
- ✅ Image preview

### AI Integration
- ✅ Gemini AI (Vision + Text)
- ✅ Hugging Face GPT models
- ✅ Response comparison
- ✅ Automatic evaluation
- ✅ Confidence scoring

### Chat Management
- ✅ Persistent chat history
- ✅ Session management
- ✅ Message search
- ✅ Export capabilities

### UI/UX
- ✅ Dark/Light themes
- ✅ Smooth animations
- ✅ Modern design
- ✅ Responsive layout
- ✅ Loading indicators

## Troubleshooting

### Common Issues

1. **Build errors**: Run `flutter clean && flutter pub get`
2. **Permission errors**: Check AndroidManifest.xml permissions
3. **API errors**: Verify API keys are valid and have proper permissions
4. **Camera not working**: Ensure camera permissions are granted

### Platform Specific

#### Android
- Minimum SDK: 21
- Target SDK: 34
- Required permissions: Camera, Storage, Internet

#### Windows
- Windows 10/11 required
- Run as administrator if needed for file access

## Development

### Project Structure
```
lib/
├── models/          # Data structures
├── services/        # Business logic
├── providers/       # State management
├── screens/         # UI screens
├── widgets/         # Reusable components
└── theme/          # Styling
```

### Key Dependencies
- google_ml_kit: OCR functionality
- image_picker: Camera/gallery access
- http/dio: API communication
- sqflite: Local database
- provider: State management

## Support

For issues or questions:
1. Check the README.md
2. Review error messages carefully
3. Ensure API keys are valid
4. Check network connectivity

## License

MIT License - see LICENSE file for details.
