import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../core/feature_flags.dart';
import '../models/documentation_management.dart';

/// Сервис для управления документацией
class DocumentationManagementService {
  factory DocumentationManagementService() => _instance;
  DocumentationManagementService._internal();
  static final DocumentationManagementService _instance =
      DocumentationManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _documentsCollection = 'documents';
  static const String _templatesCollection = 'document_templates';
  static const String _commentsCollection = 'document_comments';

  // Потоки для real-time обновлений
  final StreamController<Documentation> _documentStreamController =
      StreamController<Documentation>.broadcast();
  final StreamController<DocumentTemplate> _templateStreamController =
      StreamController<DocumentTemplate>.broadcast();
  final StreamController<DocumentComment> _commentStreamController =
      StreamController<DocumentComment>.broadcast();

  // Кэш данных
  final Map<String, Documentation> _documentCache = {};
  final Map<String, DocumentTemplate> _templateCache = {};
  final Map<String, DocumentComment> _commentCache = {};

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadDocuments();
      await _loadTemplates();
      await _loadComments();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка документов
  Future<void> _loadDocuments() async {
    try {
      final snapshot = await _firestore
          .collection(_documentsCollection)
          .where('isArchived', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        final document = Documentation.fromMap(doc.data());
        _documentCache[document.id] = document;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка шаблонов
  Future<void> _loadTemplates() async {
    try {
      final snapshot = await _firestore.collection(_templatesCollection).get();

      for (final doc in snapshot.docs) {
        final template = DocumentTemplate.fromMap(doc.data());
        _templateCache[template.id] = template;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка комментариев
  Future<void> _loadComments() async {
    try {
      final snapshot = await _firestore.collection(_commentsCollection).get();

      for (final doc in snapshot.docs) {
        final comment = DocumentComment.fromMap(doc.data());
        _commentCache[comment.id] = comment;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Поток документов
  Stream<Documentation> get documentStream => _documentStreamController.stream;

  /// Поток шаблонов
  Stream<DocumentTemplate> get templateStream =>
      _templateStreamController.stream;

  /// Поток комментариев
  Stream<DocumentComment> get commentStream => _commentStreamController.stream;

  /// Создание документа
  Future<Documentation> createDocument({
    required String title,
    required String content,
    String? summary,
    required DocumentType type,
    required DocumentCategory category,
    String? version,
    String? parentId,
    List<String>? tags,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool isPublic = false,
    String? authorId,
    String? authorName,
  }) async {
    if (!FeatureFlags.documentationManagementEnabled) {
      throw Exception('Documentation management is disabled');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final document = Documentation(
        id: _generateId(),
        title: title,
        content: content,
        summary: summary,
        type: type,
        category: category,
        status: DocumentStatus.draft,
        version: version,
        parentId: parentId,
        tags: tags ?? [],
        attachments: attachments ?? [],
        metadata: metadata ?? {},
        isPublic: isPublic,
        isArchived: false,
        viewCount: 0,
        likeCount: 0,
        contributors: [user.uid],
        authorId: authorId ?? user.uid,
        authorName: authorName ?? user.displayName ?? 'Unknown',
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_documentsCollection)
          .doc(document.id)
          .set(document.toMap());

      _documentCache[document.id] = document;
      _documentStreamController.add(document);

      return document;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление документа
  Future<Documentation> updateDocument({
    required String id,
    String? title,
    String? content,
    String? summary,
    DocumentType? type,
    DocumentCategory? category,
    DocumentStatus? status,
    String? version,
    List<String>? tags,
    List<String>? attachments,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    bool? isArchived,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingDocument = _documentCache[id];
      if (existingDocument == null) throw Exception('Document not found');

      final now = DateTime.now();
      final updatedDocument = existingDocument.copyWith(
        title: title,
        content: content,
        summary: summary,
        type: type,
        category: category,
        status: status,
        version: version,
        tags: tags,
        attachments: attachments,
        metadata: metadata,
        isPublic: isPublic,
        isArchived: isArchived,
        updatedAt: now,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_documentsCollection)
          .doc(id)
          .update(updatedDocument.toMap());

      _documentCache[id] = updatedDocument;
      _documentStreamController.add(updatedDocument);

      return updatedDocument;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение документа
  Documentation? getDocument(String id) => _documentCache[id];

  /// Получение всех документов
  List<Documentation> getAllDocuments() => _documentCache.values.toList();

  /// Получение документов по типу
  List<Documentation> getDocumentsByType(DocumentType type) =>
      _documentCache.values.where((doc) => doc.type == type).toList();

  /// Получение документов по категории
  List<Documentation> getDocumentsByCategory(DocumentCategory category) =>
      _documentCache.values.where((doc) => doc.category == category).toList();

  /// Получение документов по статусу
  List<Documentation> getDocumentsByStatus(DocumentStatus status) =>
      _documentCache.values.where((doc) => doc.status == status).toList();

  /// Получение публичных документов
  List<Documentation> getPublicDocuments() => _documentCache.values
      .where((doc) => doc.isPublic && doc.status == DocumentStatus.published)
      .toList();

  /// Поиск документов
  List<Documentation> searchDocuments(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _documentCache.values
        .where(
          (doc) =>
              doc.title.toLowerCase().contains(lowercaseQuery) ||
              doc.content.toLowerCase().contains(lowercaseQuery) ||
              doc.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery)),
        )
        .toList();
  }

  /// Увеличение счетчика просмотров
  Future<void> incrementViewCount(String documentId) async {
    try {
      final document = _documentCache[documentId];
      if (document == null) return;

      final updatedDocument = document.copyWith(
        viewCount: document.viewCount + 1,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_documentsCollection)
          .doc(documentId)
          .update({'viewCount': updatedDocument.viewCount});

      _documentCache[documentId] = updatedDocument;
      _documentStreamController.add(updatedDocument);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Создание шаблона
  Future<DocumentTemplate> createTemplate({
    required String name,
    required String description,
    required String content,
    required DocumentType type,
    required DocumentCategory category,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool isPublic = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final template = DocumentTemplate(
        id: _generateId(),
        name: name,
        description: description,
        content: content,
        type: type,
        category: category,
        tags: tags ?? [],
        metadata: metadata ?? {},
        isPublic: isPublic,
        usageCount: 0,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_templatesCollection)
          .doc(template.id)
          .set(template.toMap());

      _templateCache[template.id] = template;
      _templateStreamController.add(template);

      return template;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление шаблона
  Future<DocumentTemplate> updateTemplate({
    required String id,
    String? name,
    String? description,
    String? content,
    DocumentType? type,
    DocumentCategory? category,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    bool? isPublic,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingTemplate = _templateCache[id];
      if (existingTemplate == null) throw Exception('Template not found');

      final updatedTemplate = existingTemplate.copyWith(
        name: name,
        description: description,
        content: content,
        type: type,
        category: category,
        tags: tags,
        metadata: metadata,
        isPublic: isPublic,
        updatedAt: DateTime.now(),
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_templatesCollection)
          .doc(id)
          .update(updatedTemplate.toMap());

      _templateCache[id] = updatedTemplate;
      _templateStreamController.add(updatedTemplate);

      return updatedTemplate;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение шаблона
  DocumentTemplate? getTemplate(String id) => _templateCache[id];

  /// Получение всех шаблонов
  List<DocumentTemplate> getAllTemplates() => _templateCache.values.toList();

  /// Получение шаблонов по типу
  List<DocumentTemplate> getTemplatesByType(DocumentType type) =>
      _templateCache.values.where((template) => template.type == type).toList();

  /// Увеличение счетчика использования шаблона
  Future<void> incrementTemplateUsage(String templateId) async {
    try {
      final template = _templateCache[templateId];
      if (template == null) return;

      final updatedTemplate = template.copyWith(
        usageCount: template.usageCount + 1,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_templatesCollection)
          .doc(templateId)
          .update({'usageCount': updatedTemplate.usageCount});

      _templateCache[templateId] = updatedTemplate;
      _templateStreamController.add(updatedTemplate);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Создание комментария
  Future<DocumentComment> createComment({
    required String documentId,
    required String content,
    String? parentId,
    String? authorName,
    String? authorEmail,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final comment = DocumentComment(
        id: _generateId(),
        documentId: documentId,
        content: content,
        parentId: parentId,
        authorId: user.uid,
        authorName: authorName ?? user.displayName ?? 'Anonymous',
        authorEmail: authorEmail ?? user.email,
        isResolved: false,
        likes: [],
        createdAt: now,
        updatedAt: now,
      );

      await _firestore
          .collection(_commentsCollection)
          .doc(comment.id)
          .set(comment.toMap());

      _commentCache[comment.id] = comment;
      _commentStreamController.add(comment);

      return comment;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление комментария
  Future<DocumentComment> updateComment({
    required String id,
    String? content,
    bool? isResolved,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingComment = _commentCache[id];
      if (existingComment == null) throw Exception('Comment not found');

      final updatedComment = existingComment.copyWith(
        content: content,
        isResolved: isResolved,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_commentsCollection)
          .doc(id)
          .update(updatedComment.toMap());

      _commentCache[id] = updatedComment;
      _commentStreamController.add(updatedComment);

      return updatedComment;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение комментариев к документу
  List<DocumentComment> getDocumentComments(String documentId) =>
      _commentCache.values
          .where((comment) => comment.documentId == documentId)
          .toList();

  /// Получение всех комментариев
  List<DocumentComment> getAllComments() => _commentCache.values.toList();

  /// Лайк комментария
  Future<void> likeComment(String commentId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final comment = _commentCache[commentId];
      if (comment == null) return;

      final updatedLikes = List<String>.from(comment.likes);
      if (updatedLikes.contains(user.uid)) {
        updatedLikes.remove(user.uid);
      } else {
        updatedLikes.add(user.uid);
      }

      final updatedComment = comment.copyWith(
        likes: updatedLikes,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_commentsCollection)
          .doc(commentId)
          .update({'likes': updatedLikes});

      _commentCache[commentId] = updatedComment;
      _commentStreamController.add(updatedComment);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Анализ документации
  Future<Map<String, dynamic>> analyzeDocumentation() async {
    try {
      final documents = _documentCache.values;
      final templates = _templateCache.values;
      final comments = _commentCache.values;

      return {
        'documents': {
          'total': documents.length,
          'byType': _groupDocumentsByType(documents),
          'byCategory': _groupDocumentsByCategory(documents),
          'byStatus': _groupDocumentsByStatus(documents),
          'public': documents.where((d) => d.isPublic).length,
          'archived': documents.where((d) => d.isArchived).length,
          'totalViews': documents.fold(0, (sum, doc) => sum + doc.viewCount),
          'totalLikes': documents.fold(0, (sum, doc) => sum + doc.likeCount),
        },
        'templates': {
          'total': templates.length,
          'byType': _groupTemplatesByType(templates),
          'byCategory': _groupTemplatesByCategory(templates),
          'public': templates.where((t) => t.isPublic).length,
          'totalUsage':
              templates.fold(0, (sum, template) => sum + template.usageCount),
        },
        'comments': {
          'total': comments.length,
          'resolved': comments.where((c) => c.isResolved).length,
          'unresolved': comments.where((c) => !c.isResolved).length,
          'totalLikes':
              comments.fold(0, (sum, comment) => sum + comment.likes.length),
        },
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка документов по типу
  Map<String, int> _groupDocumentsByType(List<Documentation> documents) {
    final groups = <String, int>{};
    for (final doc in documents) {
      groups[doc.type.value] = (groups[doc.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка документов по категории
  Map<String, int> _groupDocumentsByCategory(List<Documentation> documents) {
    final groups = <String, int>{};
    for (final doc in documents) {
      groups[doc.category.value] = (groups[doc.category.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка документов по статусу
  Map<String, int> _groupDocumentsByStatus(List<Documentation> documents) {
    final groups = <String, int>{};
    for (final doc in documents) {
      groups[doc.status.value] = (groups[doc.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка шаблонов по типу
  Map<String, int> _groupTemplatesByType(List<DocumentTemplate> templates) {
    final groups = <String, int>{};
    for (final template in templates) {
      groups[template.type.value] = (groups[template.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка шаблонов по категории
  Map<String, int> _groupTemplatesByCategory(List<DocumentTemplate> templates) {
    final groups = <String, int>{};
    for (final template in templates) {
      groups[template.category.value] =
          (groups[template.category.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Экспорт документации
  Future<String> exportDocumentation({String format = 'json'}) async {
    try {
      final documents = _documentCache.values;
      final templates = _templateCache.values;
      final comments = _commentCache.values;

      final exportData = {
        'documents': documents.map((d) => d.toMap()).toList(),
        'templates': templates.map((t) => t.toMap()).toList(),
        'comments': comments.map((c) => c.toMap()).toList(),
        'exportDate': DateTime.now().toIso8601String(),
      };

      if (format == 'json') {
        return jsonEncode(exportData);
      } else if (format == 'csv') {
        return _convertToCSV(exportData);
      } else {
        throw ArgumentError('Unsupported format: $format');
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Конвертация в CSV
  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();

    // Заголовки для документов
    buffer.writeln('Documents:');
    buffer.writeln('Title,Type,Category,Status,Views,Likes,Author');

    for (final document in data['documents']) {
      buffer.writeln(
        '${document['title']},${document['type']},${document['category']},${document['status']},${document['viewCount']},${document['likeCount']},${document['authorName']}',
      );
    }

    return buffer.toString();
  }

  /// Генерация уникального ID
  String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
          .round()
          .toString();

  /// Закрытие сервиса
  Future<void> dispose() async {
    await _documentStreamController.close();
    await _templateStreamController.close();
    await _commentStreamController.close();
  }
}
