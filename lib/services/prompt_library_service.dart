import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/prompt.dart';

class PromptLibraryService {
  static const String _promptsKey = 'user_prompts';
  static const Uuid _uuid = Uuid();

  // Default prompts that come with the app
  static final List<Prompt> _defaultPrompts = [
    // General Purpose
    Prompt(
      id: 'general_1',
      title: 'Explain Like I\'m 5',
      content:
          'Explain the following concept in simple terms that a 5-year-old would understand: {input}',
      category: 'General',
      description: 'Break down complex topics into simple explanations',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['simple', 'explanation', 'beginner'],
    ),
    Prompt(
      id: 'general_2',
      title: 'Pros and Cons Analysis',
      content:
          'Analyze the pros and cons of: {input}. Provide a balanced perspective with at least 3 points for each side.',
      category: 'General',
      description: 'Get balanced analysis of any topic or decision',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['analysis', 'comparison', 'decision'],
    ),
    Prompt(
      id: 'general_3',
      title: 'Step-by-Step Guide',
      content:
          'Create a detailed step-by-step guide for: {input}. Include all necessary steps and any important tips.',
      category: 'General',
      description: 'Generate comprehensive how-to guides',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['guide', 'tutorial', 'steps'],
    ),

    // Image Analysis
    Prompt(
      id: 'image_1',
      title: 'Detailed Image Description',
      content:
          'Provide a detailed description of this image, including objects, people, colors, composition, and any text visible. Be thorough and observant.',
      category: 'Image Analysis',
      description: 'Get comprehensive descriptions of uploaded images',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['image', 'description', 'analysis'],
    ),
    Prompt(
      id: 'image_2',
      title: 'Document Analysis',
      content:
          'Analyze this document image. Extract key information, summarize the content, and identify the document type. Highlight any important data or findings.',
      category: 'Image Analysis',
      description: 'Analyze and summarize document images',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['document', 'analysis', 'extraction'],
    ),
    Prompt(
      id: 'image_3',
      title: 'Chart/Graph Interpretation',
      content:
          'Interpret this chart or graph. Explain what data is being shown, identify trends, key insights, and any notable patterns or outliers.',
      category: 'Image Analysis',
      description: 'Interpret charts, graphs, and data visualizations',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['chart', 'graph', 'data', 'analysis'],
    ),

    // Text Extraction
    Prompt(
      id: 'text_1',
      title: 'Extract and Format Text',
      content:
          'Extract all text from this image and format it properly. Maintain structure like headings, bullet points, and paragraphs where applicable.',
      category: 'Text Extraction',
      description: 'Extract and properly format text from images',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['text', 'extraction', 'formatting'],
    ),
    Prompt(
      id: 'text_2',
      title: 'OCR with Translation',
      content:
          'Extract all text from this image and translate it to English if it\'s in another language. Provide both the original text and the translation.',
      category: 'Text Extraction',
      description: 'Extract text and translate to English',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['ocr', 'translation', 'multilingual'],
    ),

    // Writing
    Prompt(
      id: 'writing_1',
      title: 'Improve My Writing',
      content:
          'Improve the following text for clarity, grammar, and style: {input}. Keep the original meaning but make it more professional and engaging.',
      category: 'Writing',
      description: 'Enhance writing quality and style',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['writing', 'improvement', 'grammar'],
    ),
    Prompt(
      id: 'writing_2',
      title: 'Creative Story Generator',
      content:
          'Write a creative short story based on: {input}. Make it engaging with interesting characters and a compelling plot.',
      category: 'Creative',
      description: 'Generate creative stories from prompts',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['creative', 'story', 'fiction'],
    ),

    // Coding
    Prompt(
      id: 'coding_1',
      title: 'Code Explanation',
      content:
          'Explain this code in detail: {input}. Break down what each part does and explain the overall functionality.',
      category: 'Coding',
      description: 'Get detailed explanations of code',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['code', 'explanation', 'programming'],
    ),
    Prompt(
      id: 'coding_2',
      title: 'Code Review and Improvement',
      content:
          'Review this code and suggest improvements: {input}. Focus on performance, readability, and best practices.',
      category: 'Coding',
      description: 'Get code reviews and improvement suggestions',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['code', 'review', 'optimization'],
    ),

    // Business
    Prompt(
      id: 'business_1',
      title: 'Business Plan Creator',
      content:
          'Create a basic business plan outline for: {input}. Include market analysis, target audience, revenue model, and key strategies.',
      category: 'Business',
      description: 'Generate business plan outlines',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['business', 'plan', 'strategy'],
    ),
    Prompt(
      id: 'business_2',
      title: 'Email Professional Response',
      content:
          'Write a professional email response for: {input}. Make it polite, clear, and appropriate for business communication.',
      category: 'Business',
      description: 'Generate professional email responses',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['email', 'professional', 'business'],
    ),

    // Advanced Analysis & Strategy
    Prompt(
      id: 'advanced_1',
      title: 'Chain-of-Thought Analysis',
      content:
          'Analyze the following using systematic reasoning: {input}\n\n'
          'Please structure your response as follows:\n'
          '1. **Problem Analysis**: Break down the core components\n'
          '2. **Available Options**: Identify possible approaches or solutions\n'
          '3. **Evaluation Criteria**: Define what makes a good solution\n'
          '4. **Recommended Solution**: Provide your conclusion with detailed rationale\n'
          '5. **Implementation Steps**: Outline actionable next steps',
      category: 'General',
      description: 'Systematic problem-solving with structured reasoning',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['analysis', 'reasoning', 'systematic', 'strategy'],
    ),

    Prompt(
      id: 'advanced_2',
      title: 'Multi-Perspective Evaluator',
      content:
          'Examine the following topic from multiple expert perspectives: {input}\n\n'
          'Provide insights from at least 3 different expert viewpoints (e.g., technical, business, user experience, ethical, etc.)\n'
          'For each perspective:\n'
          '- **Role**: [Expert type]\n'
          '- **Key Concerns**: What this expert would focus on\n'
          '- **Recommendations**: Specific advice from this viewpoint\n'
          '- **Potential Risks**: Concerns this expert would raise\n\n'
          'Conclude with a synthesis that balances all perspectives.',
      category: 'General',
      description: 'Multi-expert analysis for comprehensive understanding',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['perspective', 'expert', 'comprehensive', 'analysis'],
    ),

    Prompt(
      id: 'advanced_3',
      title: 'Context-Aware Explainer',
      content:
          'Explain the following topic with adaptive detail: {input}\n\n'
          'Please provide explanation at three levels:\n'
          '1. **Quick Overview** (1-2 sentences): The essential concept\n'
          '2. **Standard Explanation** (1-2 paragraphs): Moderate detail with examples\n'
          '3. **Deep Dive** (3+ paragraphs): Comprehensive coverage with context, implications, and connections\n\n'
          'Include practical applications and common misconceptions if relevant.',
      category: 'Education',
      description: 'Adaptive explanations with multiple depth levels',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['explanation', 'adaptive', 'layered', 'comprehensive'],
    ),

    // Safety-First Templates
    Prompt(
      id: 'safety_1',
      title: 'Risk Assessment Framework',
      content:
          'Conduct a comprehensive risk assessment for: {input}\n\n'
          'Structure your analysis as follows:\n'
          '**1. Risk Identification**\n'
          '- Potential risks and their likelihood\n'
          '- Impact severity (Low/Medium/High)\n\n'
          '**2. Mitigation Strategies**\n'
          '- Preventive measures\n'
          '- Contingency plans\n\n'
          '**3. Safety Recommendations**\n'
          '- Best practices to follow\n'
          '- Warning signs to monitor\n\n'
          '**4. Decision Framework**\n'
          '- Go/No-go criteria\n'
          '- When to seek additional expertise',
      category: 'Business',
      description: 'Comprehensive risk analysis with safety focus',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['risk', 'safety', 'assessment', 'framework'],
    ),

    // Creative Problem-Solving
    Prompt(
      id: 'creative_1',
      title: 'Innovation Workshop',
      content:
          'Lead a creative brainstorming session for: {input}\n\n'
          '**Phase 1: Divergent Thinking**\n'
          '- Generate 5-7 wildly different approaches\n'
          '- Include both conventional and unconventional ideas\n'
          '- No judgment, focus on quantity and creativity\n\n'
          '**Phase 2: Idea Development**\n'
          '- Expand on the 3 most promising concepts\n'
          '- Identify required resources and potential obstacles\n\n'
          '**Phase 3: Implementation Strategy**\n'
          '- Create action plans for the top idea\n'
          '- Include timeline, milestones, and success metrics\n\n'
          'End with specific next steps to move forward.',
      category: 'Creative',
      description: 'Structured creative problem-solving workshop',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['innovation', 'brainstorming', 'creative', 'workshop'],
    ),

    // Advanced Image Analysis
    Prompt(
      id: 'image_advanced_1',
      title: 'Professional Image Analyst',
      content:
          'Conduct a comprehensive professional analysis of the provided image(s): {input}\n\n'
          'Structure your analysis as follows:\n\n'
          '**1. Visual Elements Analysis**\n'
          '- Composition, lighting, colors, and visual hierarchy\n'
          '- Technical quality and notable features\n\n'
          '**2. Content Interpretation**\n'
          '- Objects, people, text, and activities visible\n'
          '- Context clues and environmental details\n\n'
          '**3. Purpose & Context Assessment**\n'
          '- Likely purpose or use case of the image\n'
          '- Target audience or intended message\n\n'
          '**4. Actionable Insights**\n'
          '- Key information extracted\n'
          '- Recommendations based on the analysis\n'
          '- Follow-up questions for clarification if needed',
      category: 'Image Analysis',
      description: 'Professional-grade image analysis with structured insights',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['image', 'professional', 'analysis', 'comprehensive'],
    ),

    // Education
    Prompt(
      id: 'education_1',
      title: 'Study Notes Generator',
      content:
          'Create comprehensive study notes for: {input}. Include key concepts, definitions, examples, and potential exam questions.',
      category: 'Education',
      description: 'Generate study notes and materials',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['study', 'notes', 'education'],
    ),
    Prompt(
      id: 'education_2',
      title: 'Quiz Generator',
      content:
          'Create a quiz with 10 questions about: {input}. Include multiple choice, true/false, and short answer questions with answers.',
      category: 'Education',
      description: 'Generate educational quizzes',
      isDefault: true,
      createdAt: DateTime.now(),
      tags: ['quiz', 'questions', 'assessment'],
    ),
  ];

  static Future<List<Prompt>> getAllPrompts() async {
    final userPrompts = await getUserPrompts();
    final allPrompts = [..._defaultPrompts, ...userPrompts];

    // Sort by category, then by title
    allPrompts.sort((a, b) {
      final categoryComparison = a.category.compareTo(b.category);
      if (categoryComparison != 0) return categoryComparison;
      return a.title.compareTo(b.title);
    });

    return allPrompts;
  }

  static Future<List<Prompt>> getUserPrompts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final promptsJson = prefs.getString(_promptsKey);

      if (promptsJson != null) {
        final List<dynamic> promptsList = jsonDecode(promptsJson);
        return promptsList.map((json) => Prompt.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error loading user prompts: $e');
    }

    return [];
  }

  static Future<void> saveUserPrompts(List<Prompt> prompts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final promptsJson = jsonEncode(prompts.map((p) => p.toJson()).toList());
      await prefs.setString(_promptsKey, promptsJson);
    } catch (e) {
      print('Error saving user prompts: $e');
    }
  }

  static Future<Prompt> addPrompt({
    required String title,
    required String content,
    required String category,
    required String description,
    List<String> tags = const [],
  }) async {
    final prompt = Prompt(
      id: _uuid.v4(),
      title: title,
      content: content,
      category: category,
      description: description,
      isDefault: false,
      createdAt: DateTime.now(),
      tags: tags,
    );

    final userPrompts = await getUserPrompts();
    userPrompts.add(prompt);
    await saveUserPrompts(userPrompts);

    return prompt;
  }

  static Future<void> updatePrompt(Prompt updatedPrompt) async {
    if (updatedPrompt.isDefault) {
      throw Exception('Cannot modify default prompts');
    }

    final userPrompts = await getUserPrompts();
    final index = userPrompts.indexWhere((p) => p.id == updatedPrompt.id);

    if (index != -1) {
      userPrompts[index] = updatedPrompt.copyWith(modifiedAt: DateTime.now());
      await saveUserPrompts(userPrompts);
    }
  }

  static Future<void> deletePrompt(String promptId) async {
    final userPrompts = await getUserPrompts();
    final prompt = userPrompts.firstWhere((p) => p.id == promptId);

    if (prompt.isDefault) {
      throw Exception('Cannot delete default prompts');
    }

    userPrompts.removeWhere((p) => p.id == promptId);
    await saveUserPrompts(userPrompts);
  }

  static Future<List<Prompt>> getPromptsByCategory(String category) async {
    final allPrompts = await getAllPrompts();
    return allPrompts.where((p) => p.category == category).toList();
  }

  static Future<List<Prompt>> searchPrompts(String query) async {
    final allPrompts = await getAllPrompts();
    final lowercaseQuery = query.toLowerCase();

    return allPrompts.where((prompt) {
      return prompt.title.toLowerCase().contains(lowercaseQuery) ||
          prompt.description.toLowerCase().contains(lowercaseQuery) ||
          prompt.content.toLowerCase().contains(lowercaseQuery) ||
          prompt.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  static List<String> getCategories() {
    return PromptCategory.values
        .map((category) => category.displayName)
        .toList();
  }

  static String processPromptTemplate(String template, String userInput) {
    return template.replaceAll('{input}', userInput);
  }
}
