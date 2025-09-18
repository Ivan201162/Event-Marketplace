import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../models/incident_management.dart';
import '../core/feature_flags.dart';

/// Сервис для управления инцидентами
class IncidentManagementService {
  static final IncidentManagementService _instance =
      IncidentManagementService._internal();
  factory IncidentManagementService() => _instance;
  IncidentManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  // Коллекции
  static const String _incidentsCollection = 'incidents';
  static const String _commentsCollection = 'incident_comments';
  static const String _slaCollection = 'incident_sla';

  // Потоки для real-time обновлений
  final StreamController<Incident> _incidentStreamController =
      StreamController<Incident>.broadcast();
  final StreamController<IncidentComment> _commentStreamController =
      StreamController<IncidentComment>.broadcast();
  final StreamController<IncidentSLA> _slaStreamController =
      StreamController<IncidentSLA>.broadcast();

  // Кэш данных
  final Map<String, Incident> _incidentCache = {};
  final Map<String, IncidentComment> _commentCache = {};
  final Map<String, IncidentSLA> _slaCache = {};

  bool _isInitialized = false;

  /// Инициализация сервиса
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadIncidents();
      await _loadComments();
      await _loadSLA();
      _isInitialized = true;
    } catch (e) {
      await _crashlytics.recordError(e, null, fatal: true);
      rethrow;
    }
  }

  /// Загрузка инцидентов
  Future<void> _loadIncidents() async {
    try {
      final snapshot = await _firestore
          .collection(_incidentsCollection)
          .orderBy('createdAt', descending: true)
          .get();

      for (final doc in snapshot.docs) {
        final incident = Incident.fromMap(doc.data());
        _incidentCache[incident.id] = incident;
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
        final comment = IncidentComment.fromMap(doc.data());
        _commentCache[comment.id] = comment;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Загрузка SLA
  Future<void> _loadSLA() async {
    try {
      final snapshot = await _firestore.collection(_slaCollection).get();

      for (final doc in snapshot.docs) {
        final sla = IncidentSLA.fromMap(doc.data());
        _slaCache[sla.id] = sla;
      }
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Поток инцидентов
  Stream<Incident> get incidentStream => _incidentStreamController.stream;

  /// Поток комментариев
  Stream<IncidentComment> get commentStream => _commentStreamController.stream;

  /// Поток SLA
  Stream<IncidentSLA> get slaStream => _slaStreamController.stream;

  /// Создание инцидента
  Future<Incident> createIncident({
    required String title,
    required String description,
    required IncidentType type,
    required IncidentSeverity severity,
    IncidentPriority? priority,
    String? assignedTo,
    String? assignedToName,
    String? reporterId,
    String? reporterName,
    String? reporterEmail,
    List<String>? affectedServices,
    List<String>? affectedUsers,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    DateTime? detectedAt,
  }) async {
    if (!FeatureFlags.incidentManagementEnabled) {
      throw Exception('Incident management is disabled');
    }

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final incident = Incident(
        id: _generateId(),
        title: title,
        description: description,
        type: type,
        severity: severity,
        status: IncidentStatus.open,
        priority: priority ?? _calculatePriority(severity),
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        reporterId: reporterId ?? user.uid,
        reporterName: reporterName ?? user.displayName ?? 'Unknown',
        reporterEmail: reporterEmail ?? user.email,
        affectedServices: affectedServices ?? [],
        affectedUsers: affectedUsers ?? [],
        tags: tags ?? [],
        metadata: metadata ?? {},
        attachments: attachments ?? [],
        detectedAt: detectedAt,
        reportedAt: now,
        createdAt: now,
        updatedAt: now,
        createdBy: user.uid,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_incidentsCollection)
          .doc(incident.id)
          .set(incident.toMap());

      _incidentCache[incident.id] = incident;
      _incidentStreamController.add(incident);

      // Создаем SLA для инцидента
      await _createSLA(incident);

      return incident;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление инцидента
  Future<Incident> updateIncident({
    required String id,
    String? title,
    String? description,
    IncidentType? type,
    IncidentSeverity? severity,
    IncidentStatus? status,
    IncidentPriority? priority,
    String? assignedTo,
    String? assignedToName,
    List<String>? affectedServices,
    List<String>? affectedUsers,
    String? rootCause,
    String? resolution,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingIncident = _incidentCache[id];
      if (existingIncident == null) throw Exception('Incident not found');

      final now = DateTime.now();
      final updatedIncident = existingIncident.copyWith(
        title: title,
        description: description,
        type: type,
        severity: severity,
        status: status,
        priority: priority,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        affectedServices: affectedServices,
        affectedUsers: affectedUsers,
        rootCause: rootCause,
        resolution: resolution,
        tags: tags,
        metadata: metadata,
        attachments: attachments,
        acknowledgedAt: status == IncidentStatus.acknowledged &&
                existingIncident.acknowledgedAt == null
            ? now
            : existingIncident.acknowledgedAt,
        resolvedAt: status == IncidentStatus.resolved &&
                existingIncident.resolvedAt == null
            ? now
            : existingIncident.resolvedAt,
        closedAt:
            status == IncidentStatus.closed && existingIncident.closedAt == null
                ? now
                : existingIncident.closedAt,
        updatedAt: now,
        updatedBy: user.uid,
      );

      await _firestore
          .collection(_incidentsCollection)
          .doc(id)
          .update(updatedIncident.toMap());

      _incidentCache[id] = updatedIncident;
      _incidentStreamController.add(updatedIncident);

      // Обновляем SLA
      await _updateSLA(updatedIncident);

      return updatedIncident;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Получение инцидента
  Incident? getIncident(String id) {
    return _incidentCache[id];
  }

  /// Получение всех инцидентов
  List<Incident> getAllIncidents() {
    return _incidentCache.values.toList();
  }

  /// Получение инцидентов по типу
  List<Incident> getIncidentsByType(IncidentType type) {
    return _incidentCache.values
        .where((incident) => incident.type == type)
        .toList();
  }

  /// Получение инцидентов по серьезности
  List<Incident> getIncidentsBySeverity(IncidentSeverity severity) {
    return _incidentCache.values
        .where((incident) => incident.severity == severity)
        .toList();
  }

  /// Получение инцидентов по статусу
  List<Incident> getIncidentsByStatus(IncidentStatus status) {
    return _incidentCache.values
        .where((incident) => incident.status == status)
        .toList();
  }

  /// Получение инцидентов по приоритету
  List<Incident> getIncidentsByPriority(IncidentPriority priority) {
    return _incidentCache.values
        .where((incident) => incident.priority == priority)
        .toList();
  }

  /// Получение инцидентов назначенных пользователю
  List<Incident> getIncidentsAssignedTo(String userId) {
    return _incidentCache.values
        .where((incident) => incident.assignedTo == userId)
        .toList();
  }

  /// Получение открытых инцидентов
  List<Incident> getOpenIncidents() {
    return _incidentCache.values
        .where((incident) => incident.status == IncidentStatus.open)
        .toList();
  }

  /// Создание комментария
  Future<IncidentComment> createComment({
    required String incidentId,
    required String content,
    String? parentId,
    String? authorName,
    String? authorEmail,
    CommentType type = CommentType.comment,
    bool isInternal = false,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final now = DateTime.now();
      final comment = IncidentComment(
        id: _generateId(),
        incidentId: incidentId,
        content: content,
        parentId: parentId,
        authorId: user.uid,
        authorName: authorName ?? user.displayName ?? 'Unknown',
        authorEmail: authorEmail ?? user.email,
        type: type,
        isInternal: isInternal,
        attachments: attachments ?? [],
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
  Future<IncidentComment> updateComment({
    required String id,
    String? content,
    CommentType? type,
    bool? isInternal,
    List<String>? attachments,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final existingComment = _commentCache[id];
      if (existingComment == null) throw Exception('Comment not found');

      final updatedComment = existingComment.copyWith(
        content: content,
        type: type,
        isInternal: isInternal,
        attachments: attachments,
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

  /// Получение комментариев к инциденту
  List<IncidentComment> getIncidentComments(String incidentId) {
    return _commentCache.values
        .where((comment) => comment.incidentId == incidentId)
        .toList();
  }

  /// Получение всех комментариев
  List<IncidentComment> getAllComments() {
    return _commentCache.values.toList();
  }

  /// Создание SLA для инцидента
  Future<IncidentSLA> _createSLA(Incident incident) async {
    try {
      final now = DateTime.now();
      final sla = IncidentSLA(
        id: _generateId(),
        incidentId: incident.id,
        status: SLAStatus.active,
        acknowledgedDeadline: _calculateAcknowledgedDeadline(incident.priority),
        resolvedDeadline: _calculateResolvedDeadline(incident.priority),
        acknowledgedOnTime: true,
        resolvedOnTime: true,
        createdAt: now,
        updatedAt: now,
      );

      await _firestore.collection(_slaCollection).doc(sla.id).set(sla.toMap());

      _slaCache[sla.id] = sla;
      _slaStreamController.add(sla);

      return sla;
    } catch (e) {
      await _crashlytics.recordError(e, null);
      rethrow;
    }
  }

  /// Обновление SLA
  Future<void> _updateSLA(Incident incident) async {
    try {
      final sla = _slaCache.values
          .where((s) => s.incidentId == incident.id)
          .firstOrNull;

      if (sla == null) return;

      final now = DateTime.now();
      final updatedSLA = sla.copyWith(
        acknowledgedAt: incident.acknowledgedAt,
        resolvedAt: incident.resolvedAt,
        acknowledgedOnTime: incident.acknowledgedAt != null
            ? incident.acknowledgedAt!.isBefore(sla.acknowledgedDeadline ?? now)
            : true,
        resolvedOnTime: incident.resolvedAt != null
            ? incident.resolvedAt!.isBefore(sla.resolvedDeadline ?? now)
            : true,
        status: incident.status == IncidentStatus.closed
            ? SLAStatus.met
            : incident.status == IncidentStatus.cancelled
                ? SLAStatus.cancelled
                : SLAStatus.active,
        updatedAt: now,
      );

      await _firestore
          .collection(_slaCollection)
          .doc(sla.id)
          .update(updatedSLA.toMap());

      _slaCache[sla.id] = updatedSLA;
      _slaStreamController.add(updatedSLA);
    } catch (e) {
      await _crashlytics.recordError(e, null);
    }
  }

  /// Получение SLA для инцидента
  IncidentSLA? getIncidentSLA(String incidentId) {
    return _slaCache.values
        .where((sla) => sla.incidentId == incidentId)
        .firstOrNull;
  }

  /// Получение всех SLA
  List<IncidentSLA> getAllSLA() {
    return _slaCache.values.toList();
  }

  /// Получение нарушенных SLA
  List<IncidentSLA> getBreachedSLA() {
    return _slaCache.values
        .where((sla) => sla.status == SLAStatus.breached)
        .toList();
  }

  /// Расчет приоритета на основе серьезности
  IncidentPriority _calculatePriority(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.critical:
        return IncidentPriority.p1;
      case IncidentSeverity.high:
        return IncidentPriority.p2;
      case IncidentSeverity.medium:
        return IncidentPriority.p3;
      case IncidentSeverity.low:
        return IncidentPriority.p4;
      case IncidentSeverity.info:
        return IncidentPriority.p5;
    }
  }

  /// Расчет дедлайна для подтверждения
  DateTime _calculateAcknowledgedDeadline(IncidentPriority priority) {
    final now = DateTime.now();
    switch (priority) {
      case IncidentPriority.p1:
        return now.add(const Duration(minutes: 15));
      case IncidentPriority.p2:
        return now.add(const Duration(minutes: 30));
      case IncidentPriority.p3:
        return now.add(const Duration(hours: 2));
      case IncidentPriority.p4:
        return now.add(const Duration(hours: 8));
      case IncidentPriority.p5:
        return now.add(const Duration(days: 1));
    }
  }

  /// Расчет дедлайна для решения
  DateTime _calculateResolvedDeadline(IncidentPriority priority) {
    final now = DateTime.now();
    switch (priority) {
      case IncidentPriority.p1:
        return now.add(const Duration(hours: 4));
      case IncidentPriority.p2:
        return now.add(const Duration(hours: 8));
      case IncidentPriority.p3:
        return now.add(const Duration(days: 1));
      case IncidentPriority.p4:
        return now.add(const Duration(days: 3));
      case IncidentPriority.p5:
        return now.add(const Duration(days: 7));
    }
  }

  /// Анализ инцидентов
  Future<Map<String, dynamic>> analyzeIncidents() async {
    try {
      final incidents = _incidentCache.values;
      final comments = _commentCache.values;
      final sla = _slaCache.values;

      return {
        'incidents': {
          'total': incidents.length,
          'byType': _groupIncidentsByType(incidents),
          'bySeverity': _groupIncidentsBySeverity(incidents),
          'byStatus': _groupIncidentsByStatus(incidents),
          'byPriority': _groupIncidentsByPriority(incidents),
          'open':
              incidents.where((i) => i.status == IncidentStatus.open).length,
          'resolved': incidents
              .where((i) => i.status == IncidentStatus.resolved)
              .length,
          'closed':
              incidents.where((i) => i.status == IncidentStatus.closed).length,
        },
        'comments': {
          'total': comments.length,
          'byType': _groupCommentsByType(comments),
          'internal': comments.where((c) => c.isInternal).length,
          'external': comments.where((c) => !c.isInternal).length,
        },
        'sla': {
          'total': sla.length,
          'active': sla.where((s) => s.status == SLAStatus.active).length,
          'breached': sla.where((s) => s.status == SLAStatus.breached).length,
          'met': sla.where((s) => s.status == SLAStatus.met).length,
          'acknowledgedOnTime': sla.where((s) => s.acknowledgedOnTime).length,
          'resolvedOnTime': sla.where((s) => s.resolvedOnTime).length,
        },
      };
    } catch (e) {
      await _crashlytics.recordError(e, null);
      return {};
    }
  }

  /// Группировка инцидентов по типу
  Map<String, int> _groupIncidentsByType(List<Incident> incidents) {
    final Map<String, int> groups = {};
    for (final incident in incidents) {
      groups[incident.type.value] = (groups[incident.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка инцидентов по серьезности
  Map<String, int> _groupIncidentsBySeverity(List<Incident> incidents) {
    final Map<String, int> groups = {};
    for (final incident in incidents) {
      groups[incident.severity.value] =
          (groups[incident.severity.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка инцидентов по статусу
  Map<String, int> _groupIncidentsByStatus(List<Incident> incidents) {
    final Map<String, int> groups = {};
    for (final incident in incidents) {
      groups[incident.status.value] = (groups[incident.status.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка инцидентов по приоритету
  Map<String, int> _groupIncidentsByPriority(List<Incident> incidents) {
    final Map<String, int> groups = {};
    for (final incident in incidents) {
      groups[incident.priority.value] =
          (groups[incident.priority.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Группировка комментариев по типу
  Map<String, int> _groupCommentsByType(List<IncidentComment> comments) {
    final Map<String, int> groups = {};
    for (final comment in comments) {
      groups[comment.type.value] = (groups[comment.type.value] ?? 0) + 1;
    }
    return groups;
  }

  /// Экспорт инцидентов
  Future<String> exportIncidents({String format = 'json'}) async {
    try {
      final incidents = _incidentCache.values;
      final comments = _commentCache.values;
      final sla = _slaCache.values;

      final exportData = {
        'incidents': incidents.map((i) => i.toMap()).toList(),
        'comments': comments.map((c) => c.toMap()).toList(),
        'sla': sla.map((s) => s.toMap()).toList(),
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

    // Заголовки для инцидентов
    buffer.writeln('Incidents:');
    buffer.writeln(
        'Title,Type,Severity,Status,Priority,Assigned To,Reported At,Resolved At');

    for (final incident in data['incidents']) {
      buffer.writeln(
          '${incident['title']},${incident['type']},${incident['severity']},${incident['status']},${incident['priority']},${incident['assignedToName'] ?? 'N/A'},${incident['reportedAt']},${incident['resolvedAt'] ?? 'N/A'}');
    }

    return buffer.toString();
  }

  /// Генерация уникального ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (1000 + (9999 - 1000) * (DateTime.now().microsecond / 1000000))
            .round()
            .toString();
  }

  /// Закрытие сервиса
  Future<void> dispose() async {
    await _incidentStreamController.close();
    await _commentStreamController.close();
    await _slaStreamController.close();
  }
}
