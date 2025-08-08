import '../services/ai_service.dart';
import '../services/gemini_service.dart';
import '../services/huggingface_service.dart';

class ModelInfo {
  final String id;
  final String displayName;
  final String description;
  final AIService Function(String apiKey) serviceFactory;
  final bool requiresGeminiKey;
  final bool requiresHuggingFaceKey;

  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.serviceFactory,
    this.requiresGeminiKey = false,
    this.requiresHuggingFaceKey = false,
  });
}

/// Service for managing and registering available AI models
///
/// This service provides a centralized registry of all available AI models,
/// their capabilities, and requirements. It handles model discovery,
/// availability checking, and service instantiation.
class ModelRegistryService {
  static const List<ModelInfo> availableModels = [
    ModelInfo(
      id: 'Auto',
      displayName: 'Auto-select Best Model',
      description:
          'Automatically selects the best model based on query analysis',
      serviceFactory: _dummyFactory,
    ),
    ModelInfo(
      id: 'Gemini-2.0-Flash',
      displayName: 'Google Gemini 2.0 Flash',
      description: 'Fast and efficient multimodal model from Google',
      serviceFactory: _geminiFactory,
      requiresGeminiKey: true,
    ),
    ModelInfo(
      id: 'HuggingFace-DialoGPT',
      displayName: 'HuggingFace DialoGPT Large',
      description: 'Conversational AI model for text-based interactions',
      serviceFactory: _huggingFaceDialogFactory,
      requiresHuggingFaceKey: true,
    ),
    ModelInfo(
      id: 'HuggingFace-Llama',
      displayName: 'HuggingFace Llama-2-7B',
      description: 'Advanced language model for complex reasoning',
      serviceFactory: _huggingFaceLlamaFactory,
      requiresHuggingFaceKey: true,
    ),
    ModelInfo(
      id: 'HuggingFace-BERT',
      displayName: 'HuggingFace BERT Large',
      description: 'Excellent for text understanding and classification',
      serviceFactory: _huggingFaceBertFactory,
      requiresHuggingFaceKey: true,
    ),
  ];

  // Factory methods for creating AI services
  static AIService _dummyFactory(String apiKey) {
    throw UnimplementedError('Auto-select does not create a specific service');
  }

  static AIService _geminiFactory(String apiKey) {
    return GeminiService(apiKey: apiKey);
  }

  static AIService _huggingFaceDialogFactory(String apiKey) {
    return HuggingFaceService(
      apiKey: apiKey,
      modelId: 'microsoft/DialoGPT-large',
    );
  }

  static AIService _huggingFaceLlamaFactory(String apiKey) {
    return HuggingFaceService(
      apiKey: apiKey,
      modelId: 'meta-llama/Llama-2-7b-chat-hf',
    );
  }

  static AIService _huggingFaceBertFactory(String apiKey) {
    return HuggingFaceService(apiKey: apiKey, modelId: 'bert-large-uncased');
  }

  /// Get all available models
  static List<ModelInfo> getAllModels() {
    return availableModels;
  }

  /// Get models that can be used with current API key configuration
  static List<ModelInfo> getAvailableModels({
    bool hasGeminiKey = false,
    bool hasHuggingFaceKey = false,
  }) {
    return availableModels.where((model) {
      // Auto-select is always available
      if (model.id == 'Auto') return true;

      // Check if required API keys are available
      if (model.requiresGeminiKey && !hasGeminiKey) return false;
      if (model.requiresHuggingFaceKey && !hasHuggingFaceKey) return false;

      return true;
    }).toList();
  }

  /// Get model info by ID
  static ModelInfo? getModelById(String id) {
    try {
      return availableModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if a model is available with current configuration
  static bool isModelAvailable(
    String modelId, {
    bool hasGeminiKey = false,
    bool hasHuggingFaceKey = false,
  }) {
    final model = getModelById(modelId);
    if (model == null) return false;

    if (model.requiresGeminiKey && !hasGeminiKey) return false;
    if (model.requiresHuggingFaceKey && !hasHuggingFaceKey) return false;

    return true;
  }

  /// Create AI service instance for a specific model
  static AIService? createServiceForModel(
    String modelId, {
    String? geminiApiKey,
    String? huggingFaceApiKey,
  }) {
    final model = getModelById(modelId);
    if (model == null || modelId == 'Auto') return null;

    try {
      if (model.requiresGeminiKey && geminiApiKey != null) {
        return model.serviceFactory(geminiApiKey);
      } else if (model.requiresHuggingFaceKey && huggingFaceApiKey != null) {
        return model.serviceFactory(huggingFaceApiKey);
      }
    } catch (e) {
      return null;
    }

    return null;
  }
}
