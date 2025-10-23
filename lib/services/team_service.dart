import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/specialist_team.dart';

/// Сервис для работы с командами специалистов
class TeamService {
  static const String _collection = 'specialist_teams';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Создать новую команду специалистов
  Future<SpecialistTeam> createTeam({
    required String organizerId,
    required String eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventLocation,
    String? teamName,
    String? description,
    String? notes,
  }) async {
    final now = DateTime.now();
    final teamData = {
      'organizerId': organizerId,
      'eventId': eventId,
      'specialists': <String>[],
      'status': TeamStatus.draft.name,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'eventTitle': eventTitle,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate) : null,
      'eventLocation': eventLocation,
      'teamName': teamName,
      'description': description,
      'notes': notes,
      'specialistRoles': <String, String>{},
      'paymentSplit': <String, double>{},
    };

    final docRef = await _firestore.collection(_collection).add(teamData);

    return SpecialistTeam(
      id: docRef.id,
      organizerId: organizerId,
      eventId: eventId,
      specialists: [],
      status: TeamStatus.draft,
      createdAt: now,
      updatedAt: now,
      eventTitle: eventTitle,
      eventDate: eventDate,
      eventLocation: eventLocation,
      teamName: teamName,
      description: description,
      notes: notes,
    );
  }

  /// Добавить специалиста в команду
  Future<void> addSpecialistToTeam({
    required String teamId,
    required String specialistId,
    String? role,
    double? paymentAmount,
  }) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);

    await _firestore.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);

      if (!teamDoc.exists) {
        throw Exception('Команда не найдена');
      }

      final teamData = teamDoc.data()!;
      final specialists = List<String>.from(teamData['specialists'] ?? []);
      final specialistRoles =
          Map<String, String>.from(teamData['specialistRoles'] ?? {});
      final paymentSplit =
          Map<String, double>.from(teamData['paymentSplit'] ?? {});

      // Проверяем, не добавлен ли уже специалист
      if (specialists.contains(specialistId)) {
        throw Exception('Специалист уже в команде');
      }

      specialists.add(specialistId);
      if (role != null) {
        specialistRoles[specialistId] = role;
      }
      if (paymentAmount != null) {
        paymentSplit[specialistId] = paymentAmount;
      }

      transaction.update(teamRef, {
        'specialists': specialists,
        'specialistRoles': specialistRoles,
        'paymentSplit': paymentSplit,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Удалить специалиста из команды
  Future<void> removeSpecialistFromTeam({
    required String teamId,
    required String specialistId,
  }) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);

    await _firestore.runTransaction((transaction) async {
      final teamDoc = await transaction.get(teamRef);

      if (!teamDoc.exists) {
        throw Exception('Команда не найдена');
      }

      final teamData = teamDoc.data()!;
      final specialists = List<String>.from(teamData['specialists'] ?? []);
      final specialistRoles =
          Map<String, String>.from(teamData['specialistRoles'] ?? {});
      final paymentSplit =
          Map<String, double>.from(teamData['paymentSplit'] ?? {});

      specialists.remove(specialistId);
      specialistRoles.remove(specialistId);
      paymentSplit.remove(specialistId);

      transaction.update(teamRef, {
        'specialists': specialists,
        'specialistRoles': specialistRoles,
        'paymentSplit': paymentSplit,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    });
  }

  /// Подтвердить команду
  Future<void> confirmTeam({required String teamId, String? notes}) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);
    final now = DateTime.now();

    await teamRef.update({
      'status': TeamStatus.confirmed.name,
      'confirmedAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      if (notes != null) 'notes': notes,
    });
  }

  /// Отклонить команду
  Future<void> rejectTeam(
      {required String teamId, required String reason}) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);
    final now = DateTime.now();

    await teamRef.update({
      'status': TeamStatus.rejected.name,
      'rejectedAt': Timestamp.fromDate(now),
      'rejectionReason': reason,
      'updatedAt': Timestamp.fromDate(now),
    });
  }

  /// Активировать команду (начать работу)
  Future<void> activateTeam(String teamId) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);

    await teamRef.update({
      'status': TeamStatus.active.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Завершить работу команды
  Future<void> completeTeam(String teamId) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);

    await teamRef.update({
      'status': TeamStatus.completed.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Обновить информацию о команде
  Future<void> updateTeam({
    required String teamId,
    String? teamName,
    String? description,
    String? notes,
    double? totalPrice,
    Map<String, String>? specialistRoles,
    Map<String, double>? paymentSplit,
  }) async {
    final teamRef = _firestore.collection(_collection).doc(teamId);
    final updateData = <String, dynamic>{
      'updatedAt': Timestamp.fromDate(DateTime.now())
    };

    if (teamName != null) updateData['teamName'] = teamName;
    if (description != null) updateData['description'] = description;
    if (notes != null) updateData['notes'] = notes;
    if (totalPrice != null) updateData['totalPrice'] = totalPrice;
    if (specialistRoles != null) {
      updateData['specialistRoles'] = specialistRoles;
    }
    if (paymentSplit != null) updateData['paymentSplit'] = paymentSplit;

    await teamRef.update(updateData);
  }

  /// Получить команду по ID
  Future<SpecialistTeam?> getTeam(String teamId) async {
    final doc = await _firestore.collection(_collection).doc(teamId).get();

    if (!doc.exists) return null;

    return SpecialistTeam.fromDocument(doc);
  }

  /// Получить команды организатора
  Future<List<SpecialistTeam>> getOrganizerTeams(String organizerId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('organizerId', isEqualTo: organizerId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map(SpecialistTeam.fromDocument).toList();
  }

  /// Получить команды, в которых участвует специалист
  Future<List<SpecialistTeam>> getSpecialistTeams(String specialistId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('specialists', arrayContains: specialistId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map(SpecialistTeam.fromDocument).toList();
  }

  /// Получить команду по мероприятию
  Future<SpecialistTeam?> getTeamByEvent(String eventId) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return SpecialistTeam.fromDocument(querySnapshot.docs.first);
  }

  /// Слушать изменения команды
  Stream<SpecialistTeam?> watchTeam(String teamId) => _firestore
      .collection(_collection)
      .doc(teamId)
      .snapshots()
      .map((doc) => doc.exists ? SpecialistTeam.fromDocument(doc) : null);

  /// Слушать команды организатора
  Stream<List<SpecialistTeam>> watchOrganizerTeams(
          String organizerId) =>
      _firestore
          .collection(_collection)
          .where('organizerId', isEqualTo: organizerId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(SpecialistTeam.fromDocument).toList());

  /// Слушать команды специалиста
  Stream<List<SpecialistTeam>> watchSpecialistTeams(String specialistId) =>
      _firestore
          .collection(_collection)
          .where('specialists', arrayContains: specialistId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map(SpecialistTeam.fromDocument).toList());

  /// Удалить команду
  Future<void> deleteTeam(String teamId) async {
    await _firestore.collection(_collection).doc(teamId).delete();
  }

  /// Проверить, может ли специалист быть добавлен в команду
  Future<bool> canAddSpecialistToTeam({
    required String teamId,
    required String specialistId,
  }) async {
    final team = await getTeam(teamId);
    if (team == null) return false;

    // Проверяем, не добавлен ли уже специалист
    if (team.containsSpecialist(specialistId)) return false;

    // Проверяем статус команды
    if (team.status != TeamStatus.draft) return false;

    return true;
  }

  /// Получить статистику команды
  Future<Map<String, dynamic>> getTeamStats(String teamId) async {
    final team = await getTeam(teamId);
    if (team == null) {
      throw Exception('Команда не найдена');
    }

    return {
      'specialistCount': team.specialistCount,
      'totalPrice': team.totalPrice ?? 0.0,
      'totalPaymentAmount': team.totalPaymentAmount,
      'status': team.status.name,
      'createdAt': team.createdAt,
      'updatedAt': team.updatedAt,
    };
  }
}
