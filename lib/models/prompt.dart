class Prompt {
  final String id;
  final String title;
  final String content;
  final String category;
  final String description;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? modifiedAt;
  final List<String> tags;

  const Prompt({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.description,
    this.isDefault = false,
    required this.createdAt,
    this.modifiedAt,
    this.tags = const [],
  });

  factory Prompt.fromJson(Map<String, dynamic> json) {
    return Prompt(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      description: json['description'] as String,
      isDefault: json['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] != null
          ? DateTime.parse(json['modifiedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'description': description,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  Prompt copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
  }) {
    return Prompt(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      description: description ?? this.description,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Prompt && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Prompt{id: $id, title: $title, category: $category}';
  }
}

enum PromptCategory {
  general('General'),
  imageAnalysis('Image Analysis'),
  textExtraction('Text Extraction'),
  coding('Coding'),
  writing('Writing'),
  creative('Creative'),
  business('Business'),
  education('Education'),
  custom('Custom');

  const PromptCategory(this.displayName);
  final String displayName;
}
