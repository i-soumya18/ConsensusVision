# ConsensusVision

A modern, creative chatbot interface for Android and Windows that processes images using AI to extract text and provide accurate responses. The app uses multiple AI models (Gemini AI and Hugging Face) to ensure the most accurate answers by comparing and evaluating responses.

![App Preview](assets/app_preview.png)

## ✨ Features

- **🖼️ Multi-Image Processing**: Upload and analyze multiple images simultaneously
- **🤖 Dual AI Integration**: Uses both Gemini AI and Hugging Face GPT models
- **🧠 Smart Response Evaluation**: Automatically compares AI responses and provides the most accurate answer
- **� Continuous Contextual Chatting**: AI maintains conversation context across multiple exchanges
  - Remembers previous messages and images
  - References earlier discussion points
  - Maintains conversation flow naturally
  - Smart context window management (last 20 messages)
  - Preserves important early messages in long conversations
- **�📱 Cross-Platform**: Supports both Android and Windows
- **💾 Chat History**: Persistent storage of all conversations with context preservation
- **🔍 Text Extraction**: OCR capabilities using Google ML Kit
- **🎨 Modern UI**: Beautiful, dark-themed interface with animations and context indicators
- **🔒 Privacy First**: API keys stored locally, no data shared

## 🛠️ How It Works

1. **Upload Images**: Take photos or select from gallery/files
2. **Ask Questions**: Type your query about the images
3. **Text Extraction**: App automatically extracts text from images using OCR
4. **Contextual Processing**: App builds conversation context from previous exchanges
5. **Dual AI Processing**: Both Gemini and Hugging Face models process your query with full context
6. **Smart Evaluation**: AI responses are compared and the best contextual answer is selected
7. **Continuous Conversation**: Follow-up questions maintain full conversation context
8. **Instant Response**: Get comprehensive, contextually-aware answers quickly

### 🧠 Contextual Conversation Features

- **Memory Retention**: AI remembers what you've discussed before
- **Image References**: Previously uploaded images are referenced in ongoing conversations
- **Follow-up Awareness**: Questions like "What about this?" or "Can you explain more?" are understood in context
- **Smart Context Trimming**: Long conversations automatically preserve important early context
- **Visual Indicators**: See when responses use conversation context with special icons

## 📋 Prerequisites

- Flutter SDK (3.8.1 or higher)
- Android Studio / VS Code with Flutter extensions
- API Keys:
  - **Gemini AI API Key**: Get from [Google AI Studio](https://ai.google.dev)
  - **Hugging Face API Key**: Get from [Hugging Face](https://huggingface.co/settings/tokens)

## 🚀 Setup Instructions

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/imagequery-ai.git
cd imagequery-ai
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Generate Code
```bash
flutter packages pub run build_runner build
```

### 4. Get API Keys

#### Gemini AI API Key:
1. Visit [Google AI Studio](https://ai.google.dev)
2. Sign in with your Google account
3. Go to "Get API key"
4. Create a new project or select existing
5. Generate your API key

#### Hugging Face API Key:
1. Visit [Hugging Face](https://huggingface.co)
2. Sign up/login to your account
3. Go to Settings → Access Tokens
4. Create a new token with read permissions

### 5. Run the App
```bash
# For Android
flutter run

# For Windows
flutter run -d windows
```

On first launch, the app will prompt you to enter your API keys.

## 📱 Platform Support

### Android
- Minimum SDK: 21 (Android 5.0)
- Target SDK: 34 (Android 14)
- Permissions: Camera, Storage, Internet

### Windows
- Windows 10/11
- x64 architecture

## 🏗️ Architecture

```
lib/
├── models/           # Data models (Message, ChatSession, AIResponse)
├── services/         # Business logic (AI services, Database, Config)
├── providers/        # State management (ChatProvider)
├── screens/          # UI screens (Chat, Setup, Sessions)
├── widgets/          # Reusable UI components
├── theme/           # App theming and styling
└── main.dart        # App entry point
```

## 🔧 Configuration

The app stores configuration locally using SharedPreferences:
- API keys (encrypted)
- Theme preferences
- User settings

## 🤝 AI Model Integration

### Gemini AI
- **Model**: Gemini Pro Vision
- **Capabilities**: Text + Image analysis
- **Strengths**: Visual understanding, context awareness

### Hugging Face
- **Models**: DialoGPT, BlenderBot (with fallbacks)
- **Capabilities**: Conversational AI
- **Strengths**: Natural language processing

### Evaluation System
The app implements a sophisticated evaluation system that:
1. Runs both AI models in parallel
2. Compares response similarity
3. Uses cross-validation for different responses
4. Selects the most accurate answer automatically

## 📦 Dependencies

Key packages used:
- `google_ml_kit`: OCR text extraction
- `image_picker`: Camera and gallery access
- `sqflite`: Local database storage
- `http` & `dio`: API communications
- `provider`: State management
- `shared_preferences`: Local configuration
- `cached_network_image`: Image caching
- `lottie`: Animations

## 🎨 UI/UX Features

- **Dark/Light themes**
- **Animated message bubbles**
- **Typing indicators**
- **Image previews**
- **Confidence indicators**
- **Retry mechanisms**
- **Search functionality**
- **Session management**

## 🔐 Privacy & Security

- All API keys stored locally
- No data transmitted to third parties
- Images processed on-device for OCR
- Chat history stored locally

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Google for Gemini AI API
- Hugging Face for transformer models
- Flutter team for the amazing framework
- Google ML Kit for OCR capabilities

## 📞 Support

For support, email sahoosoumya242004@gmail.com or create an issue on GitHub.

---

**Made with ❤️ using Flutter**
