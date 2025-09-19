import 'package:cloud_firestore/cloud_firestore.dart';

/// Модель для управления документацией
class Documentation {
  const Documentation({
    required this.id,
    required this.title,
    required this.content,
    this.summary,
    required this.type,
    required this.category,
    required this.status,
    this.version,
    this.parentId,
    required this.tags,
    required this.attachments,
    required this.metadata,
    required this.isPublic,
    required this.isArchived,
    required this.viewCount,
    required this.likeCount,
    required this.contributors,
    this.authorId,
    this.authorName,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory Documentation.fromMap(Map<String, dynamic> map) => Documentation(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        content: map['content'] ?? '',
        summary: map['summary'],
        type: DocumentType.fromString(map['type'] ?? 'article'),
        category: DocumentCategory.fromString(map['category'] ?? 'general'),
        status: DocumentStatus.fromString(map['status'] ?? 'draft'),
        version: map['version'],
        parentId: map['parentId'],
        tags: List<String>.from(map['tags'] ?? []),
        attachments: List<String>.from(map['attachments'] ?? []),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        isPublic: map['isPublic'] ?? false,
        isArchived: map['isArchived'] ?? false,
        viewCount: map['viewCount'] ?? 0,
        likeCount: map['likeCount'] ?? 0,
        contributors: List<String>.from(map['contributors'] ?? []),
        authorId: map['authorId'],
        authorName: map['authorName'],
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String title;
  final String content;
  final String? summary;
  final DocumentType type;
  final DocumentCategory category;
  final DocumentStatus status;
  final String? version;
  final String? parentId;
  final List<String> tags;
  final List<String> attachments;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final bool isArchived;
  final int viewCount;
  final int likeCount;
  final List<String> contributors;
  final String? authorId;
  final String? authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'summary': summary,
        'type': type.value,
        'category': category.value,
        'status': status.value,
        'version': version,
        'parentId': parentId,
        'tags': tags,
        'attachments': attachments,
        'metadata': metadata,
        'isPublic': isPublic,
        'isArchived': isArchived,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'contributors': contributors,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  Documentation copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    DocumentType? type,
    DocumentCategory? category,
    DocumentStatus? status,
    String? version,
    String? parentId,
    List<String>? tags,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    bool? isArchived,
    int? viewCount,
    int? likeCount,
    List<String>? contributors,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      Documentation(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        summary: summary ?? this.summary,
        type: type ?? this.type,
        category: category ?? this.category,
        status: status ?? this.status,
        version: version ?? this.version,
        parentId: parentId ?? this.parentId,
        tags: tags ?? this.tags,
        attachments: attachments ?? this.attachments,
        metadata: metadata ?? this.metadata,
        isPublic: isPublic ?? this.isPublic,
        isArchived: isArchived ?? this.isArchived,
        viewCount: viewCount ?? this.viewCount,
        likeCount: likeCount ?? this.likeCount,
        contributors: contributors ?? this.contributors,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'Documentation(id: $id, title: $title, type: $type, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Documentation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Типы документов
enum DocumentType {
  article('article', 'Статья'),
  tutorial('tutorial', 'Руководство'),
  api('api', 'API документация'),
  faq('faq', 'FAQ'),
  changelog('changelog', 'Журнал изменений'),
  policy('policy', 'Политика'),
  guide('guide', 'Руководство'),
  reference('reference', 'Справочник'),
  specification('specification', 'Спецификация'),
  manual('manual', 'Руководство пользователя');

  const DocumentType(this.value, this.displayName);

  final String value;
  final String displayName;

  static DocumentType fromString(String value) =>
      DocumentType.values.firstWhere(
        (type) => type.value == value,
        orElse: () => DocumentType.article,
      );

  String get icon {
    switch (this) {
      case DocumentType.article:
        return '📄';
      case DocumentType.tutorial:
        return '📚';
      case DocumentType.api:
        return '🔌';
      case DocumentType.faq:
        return '❓';
      case DocumentType.changelog:
        return '📝';
      case DocumentType.policy:
        return '📋';
      case DocumentType.guide:
        return '🗺️';
      case DocumentType.reference:
        return '📖';
      case DocumentType.specification:
        return '📋';
      case DocumentType.manual:
        return '📖';
    }
  }

  String get color {
    switch (this) {
      case DocumentType.article:
        return 'blue';
      case DocumentType.tutorial:
        return 'green';
      case DocumentType.api:
        return 'purple';
      case DocumentType.faq:
        return 'orange';
      case DocumentType.changelog:
        return 'teal';
      case DocumentType.policy:
        return 'red';
      case DocumentType.guide:
        return 'cyan';
      case DocumentType.reference:
        return 'indigo';
      case DocumentType.specification:
        return 'brown';
      case DocumentType.manual:
        return 'pink';
    }
  }
}

/// Категории документов
enum DocumentCategory {
  general('general', 'Общее'),
  technical('technical', 'Техническое'),
  user('user', 'Пользовательское'),
  developer('developer', 'Разработчик'),
  admin('admin', 'Администратор'),
  business('business', 'Бизнес'),
  legal('legal', 'Правовое'),
  support('support', 'Поддержка'),
  marketing('marketing', 'Маркетинг'),
  training('training', 'Обучение');

  const DocumentCategory(this.value, this.displayName);

  final String value;
  final String displayName;

  static DocumentCategory fromString(String value) =>
      DocumentCategory.values.firstWhere(
        (category) => category.value == value,
        orElse: () => DocumentCategory.general,
      );

  String get icon {
    switch (this) {
      case DocumentCategory.general:
        return '📄';
      case DocumentCategory.technical:
        return '⚙️';
      case DocumentCategory.user:
        return '👥';
      case DocumentCategory.developer:
        return '👨‍💻';
      case DocumentCategory.admin:
        return '👨‍💼';
      case DocumentCategory.business:
        return '💼';
      case DocumentCategory.legal:
        return '⚖️';
      case DocumentCategory.support:
        return '🆘';
      case DocumentCategory.marketing:
        return '📢';
      case DocumentCategory.training:
        return '🎓';
    }
  }

  String get color {
    switch (this) {
      case DocumentCategory.general:
        return 'blue';
      case DocumentCategory.technical:
        return 'green';
      case DocumentCategory.user:
        return 'purple';
      case DocumentCategory.developer:
        return 'orange';
      case DocumentCategory.admin:
        return 'red';
      case DocumentCategory.business:
        return 'teal';
      case DocumentCategory.legal:
        return 'indigo';
      case DocumentCategory.support:
        return 'cyan';
      case DocumentCategory.marketing:
        return 'lime';
      case DocumentCategory.training:
        return 'pink';
    }
  }
}

/// Статусы документов
enum DocumentStatus {
  draft('draft', 'Черновик'),
  review('review', 'На рассмотрении'),
  approved('approved', 'Одобрен'),
  published('published', 'Опубликован'),
  archived('archived', 'Архивирован'),
  deprecated('deprecated', 'Устарел');

  const DocumentStatus(this.value, this.displayName);

  final String value;
  final String displayName;

  static DocumentStatus fromString(String value) =>
      DocumentStatus.values.firstWhere(
        (status) => status.value == value,
        orElse: () => DocumentStatus.draft,
      );

  String get icon {
    switch (this) {
      case DocumentStatus.draft:
        return '📝';
      case DocumentStatus.review:
        return '👀';
      case DocumentStatus.approved:
        return '✅';
      case DocumentStatus.published:
        return '📢';
      case DocumentStatus.archived:
        return '📦';
      case DocumentStatus.deprecated:
        return '⚠️';
    }
  }

  String get color {
    switch (this) {
      case DocumentStatus.draft:
        return 'grey';
      case DocumentStatus.review:
        return 'orange';
      case DocumentStatus.approved:
        return 'green';
      case DocumentStatus.published:
        return 'blue';
      case DocumentStatus.archived:
        return 'brown';
      case DocumentStatus.deprecated:
        return 'red';
    }
  }
}

/// Модель для шаблонов документов
class DocumentTemplate {
  const DocumentTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.content,
    required this.type,
    required this.category,
    required this.tags,
    required this.metadata,
    required this.isPublic,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    required this.updatedBy,
  });

  factory DocumentTemplate.fromMap(Map<String, dynamic> map) =>
      DocumentTemplate(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        description: map['description'] ?? '',
        content: map['content'] ?? '',
        type: DocumentType.fromString(map['type'] ?? 'article'),
        category: DocumentCategory.fromString(map['category'] ?? 'general'),
        tags: List<String>.from(map['tags'] ?? []),
        metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
        isPublic: map['isPublic'] ?? false,
        usageCount: map['usageCount'] ?? 0,
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
        createdBy: map['createdBy'] ?? '',
        updatedBy: map['updatedBy'] ?? '',
      );
  final String id;
  final String name;
  final String description;
  final String content;
  final DocumentType type;
  final DocumentCategory category;
  final List<String> tags;
  final Map<String, dynamic> metadata;
  final bool isPublic;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'content': content,
        'type': type.value,
        'category': category.value,
        'tags': tags,
        'metadata': metadata,
        'isPublic': isPublic,
        'usageCount': usageCount,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
      };

  DocumentTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? content,
    DocumentType? type,
    DocumentCategory? category,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    int? usageCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
  }) =>
      DocumentTemplate(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        content: content ?? this.content,
        type: type ?? this.type,
        category: category ?? this.category,
        tags: tags ?? this.tags,
        metadata: metadata ?? this.metadata,
        isPublic: isPublic ?? this.isPublic,
        usageCount: usageCount ?? this.usageCount,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
      );

  @override
  String toString() =>
      'DocumentTemplate(id: $id, name: $name, type: $type, usageCount: $usageCount)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Модель для комментариев к документам
class DocumentComment {
  const DocumentComment({
    required this.id,
    required this.documentId,
    required this.content,
    this.parentId,
    required this.authorId,
    required this.authorName,
    this.authorEmail,
    required this.isResolved,
    required this.likes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DocumentComment.fromMap(Map<String, dynamic> map) => DocumentComment(
        id: map['id'] ?? '',
        documentId: map['documentId'] ?? '',
        content: map['content'] ?? '',
        parentId: map['parentId'],
        authorId: map['authorId'] ?? '',
        authorName: map['authorName'] ?? '',
        authorEmail: map['authorEmail'],
        isResolved: map['isResolved'] ?? false,
        likes: List<String>.from(map['likes'] ?? []),
        createdAt: (map['createdAt'] as Timestamp).toDate(),
        updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      );
  final String id;
  final String documentId;
  final String content;
  final String? parentId;
  final String authorId;
  final String authorName;
  final String? authorEmail;
  final bool isResolved;
  final List<String> likes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'documentId': documentId,
        'content': content,
        'parentId': parentId,
        'authorId': authorId,
        'authorName': authorName,
        'authorEmail': authorEmail,
        'isResolved': isResolved,
        'likes': likes,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  DocumentComment copyWith({
    String? id,
    String? documentId,
    String? content,
    String? parentId,
    String? authorId,
    String? authorName,
    String? authorEmail,
    bool? isResolved,
    List<String>? likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      DocumentComment(
        id: id ?? this.id,
        documentId: documentId ?? this.documentId,
        content: content ?? this.content,
        parentId: parentId ?? this.parentId,
        authorId: authorId ?? this.authorId,
        authorName: authorName ?? this.authorName,
        authorEmail: authorEmail ?? this.authorEmail,
        isResolved: isResolved ?? this.isResolved,
        likes: likes ?? this.likes,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  String toString() =>
      'DocumentComment(id: $id, documentId: $documentId, authorName: $authorName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentComment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
