import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_marketplace_app/models/feedback_ticket.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для работы с обратной связью
class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Создать тикет
  Future<void> createTicket(FeedbackTicket ticket) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Пользователь не авторизован');

      final ticketWithUser = ticket.copyWith(userId: userId);

      await _firestore
          .collection('feedback_tickets')
          .doc(ticket.id)
          .set(ticketWithUser.toMap());

      debugPrint('✅ Тикет создан: ${ticket.id}');
    } catch (e) {
      debugPrint('❌ Ошибка создания тикета: $e');
      rethrow;
    }
  }

  /// Получить тикеты пользователя
  Future<List<FeedbackTicket>> getUserTickets() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Пользователь не авторизован');

      final query = await _firestore
          .collection('feedback_tickets')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs.map(FeedbackTicket.fromDocument).toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения тикетов: $e');
      return [];
    }
  }

  /// Получить тикет по ID
  Future<FeedbackTicket?> getTicket(String ticketId) async {
    try {
      final doc =
          await _firestore.collection('feedback_tickets').doc(ticketId).get();

      if (doc.exists) {
        return FeedbackTicket.fromDocument(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Ошибка получения тикета: $e');
      return null;
    }
  }

  /// Обновить тикет
  Future<void> updateTicket(FeedbackTicket ticket) async {
    try {
      await _firestore
          .collection('feedback_tickets')
          .doc(ticket.id)
          .update(ticket.toMap());

      debugPrint('✅ Тикет обновлен: ${ticket.id}');
    } catch (e) {
      debugPrint('❌ Ошибка обновления тикета: $e');
      rethrow;
    }
  }

  /// Добавить сообщение в тикет
  Future<void> addMessage(TicketMessage message) async {
    try {
      await _firestore
          .collection('feedback_tickets')
          .doc(message.ticketId)
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      // Обновляем время последнего обновления тикета
      await _firestore
          .collection('feedback_tickets')
          .doc(message.ticketId)
          .update({
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Сообщение добавлено в тикет: ${message.ticketId}');
    } catch (e) {
      debugPrint('❌ Ошибка добавления сообщения: $e');
      rethrow;
    }
  }

  /// Получить сообщения тикета
  Future<List<TicketMessage>> getTicketMessages(String ticketId) async {
    try {
      final query = await _firestore
          .collection('feedback_tickets')
          .doc(ticketId)
          .collection('messages')
          .orderBy('createdAt', descending: false)
          .get();

      return query.docs
          .map((doc) => TicketMessage.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения сообщений: $e');
      return [];
    }
  }

  /// Изменить статус тикета
  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _firestore.collection('feedback_tickets').doc(ticketId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Статус тикета обновлен: $ticketId -> $status');
    } catch (e) {
      debugPrint('❌ Ошибка обновления статуса: $e');
      rethrow;
    }
  }

  /// Назначить тикет администратору
  Future<void> assignTicket(String ticketId, String adminId) async {
    try {
      await _firestore.collection('feedback_tickets').doc(ticketId).update({
        'adminId': adminId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Тикет назначен администратору: $ticketId -> $adminId');
    } catch (e) {
      debugPrint('❌ Ошибка назначения тикета: $e');
      rethrow;
    }
  }

  /// Добавить тег к тикету
  Future<void> addTag(String ticketId, String tag) async {
    try {
      await _firestore.collection('feedback_tickets').doc(ticketId).update({
        'tags': FieldValue.arrayUnion([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Тег добавлен к тикету: $ticketId -> $tag');
    } catch (e) {
      debugPrint('❌ Ошибка добавления тега: $e');
      rethrow;
    }
  }

  /// Удалить тег из тикета
  Future<void> removeTag(String ticketId, String tag) async {
    try {
      await _firestore.collection('feedback_tickets').doc(ticketId).update({
        'tags': FieldValue.arrayRemove([tag]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Тег удален из тикета: $ticketId -> $tag');
    } catch (e) {
      debugPrint('❌ Ошибка удаления тега: $e');
      rethrow;
    }
  }

  /// Изменить приоритет тикета
  Future<void> updateTicketPriority(
      String ticketId, TicketPriority priority,) async {
    try {
      await _firestore.collection('feedback_tickets').doc(ticketId).update({
        'priority': priority.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Приоритет тикета обновлен: $ticketId -> $priority');
    } catch (e) {
      debugPrint('❌ Ошибка обновления приоритета: $e');
      rethrow;
    }
  }

  /// Получить статистику тикетов
  Future<Map<String, int>> getTicketStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Пользователь не авторизован');

      final query = await _firestore
          .collection('feedback_tickets')
          .where('userId', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total': 0,
        'open': 0,
        'inProgress': 0,
        'resolved': 0,
        'closed': 0,
      };

      for (final doc in query.docs) {
        final ticket = FeedbackTicket.fromDocument(doc);
        stats['total'] = (stats['total'] ?? 0) + 1;

        switch (ticket.status) {
          case TicketStatus.open:
            stats['open'] = (stats['open'] ?? 0) + 1;
          case TicketStatus.inProgress:
            stats['inProgress'] = (stats['inProgress'] ?? 0) + 1;
          case TicketStatus.resolved:
            stats['resolved'] = (stats['resolved'] ?? 0) + 1;
          case TicketStatus.closed:
            stats['closed'] = (stats['closed'] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Поиск тикетов
  Future<List<FeedbackTicket>> searchTickets(String query) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('Пользователь не авторизован');

      // Простой поиск по заголовку и описанию
      final titleQuery = await _firestore
          .collection('feedback_tickets')
          .where('userId', isEqualTo: userId)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '$query\uf8ff')
          .get();

      final descriptionQuery = await _firestore
          .collection('feedback_tickets')
          .where('userId', isEqualTo: userId)
          .where('description', isGreaterThanOrEqualTo: query)
          .where('description', isLessThan: '$query\uf8ff')
          .get();

      final allDocs = <DocumentSnapshot>[];
      allDocs.addAll(titleQuery.docs);
      allDocs.addAll(descriptionQuery.docs);

      // Удаляем дубликаты
      final uniqueDocs = <String, DocumentSnapshot>{};
      for (final doc in allDocs) {
        uniqueDocs[doc.id] = doc;
      }

      return uniqueDocs.values
          .map(FeedbackTicket.fromDocument)
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка поиска тикетов: $e');
      return [];
    }
  }
}
