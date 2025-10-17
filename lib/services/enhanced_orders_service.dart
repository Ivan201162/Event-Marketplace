import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/enhanced_order.dart';

/// Сервис для работы с улучшенными заявками
class EnhancedOrdersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Получить заявки пользователя
  Future<List<EnhancedOrder>> getUserOrders(
    String userId, {
    OrderStatus? status,
  }) async {
    try {
      Query query = _firestore.collection('orders').where('customerId', isEqualTo: userId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map(
            (doc) => EnhancedOrder.fromMap({
              'id': doc.id,
              ...(doc.data()! as Map<String, dynamic>),
            }),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения заявок пользователя: $e');
      return [];
    }
  }

  /// Получить заявки специалиста
  Future<List<EnhancedOrder>> getSpecialistOrders(
    String specialistId, {
    OrderStatus? status,
  }) async {
    try {
      Query query = _firestore.collection('orders').where('specialistId', isEqualTo: specialistId);

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      final snapshot = await query.orderBy('createdAt', descending: true).get();

      return snapshot.docs
          .map(
            (doc) => EnhancedOrder.fromMap({
              'id': doc.id,
              ...(doc.data()! as Map<String, dynamic>),
            }),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения заявок специалиста: $e');
      return [];
    }
  }

  /// Создать новую заявку
  Future<String> createOrder(EnhancedOrder order) async {
    try {
      final docRef = await _firestore.collection('orders').add(order.toMap());

      // Добавить событие в таймлайн
      await _addTimelineEvent(
        docRef.id,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.created,
          title: 'Заявка создана',
          description: 'Заявка "${order.title}" была создана',
          createdAt: DateTime.now(),
          authorId: order.customerId,
        ),
      );

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('Ошибка создания заявки: $e');
      rethrow;
    }
  }

  /// Обновить заявку
  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка обновления заявки: $e');
      rethrow;
    }
  }

  /// Принять заявку
  Future<void> acceptOrder(String orderId, String specialistId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.accepted.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Добавить событие в таймлайн
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.accepted,
          title: 'Заявка принята',
          description: 'Специалист принял заявку к выполнению',
          createdAt: DateTime.now(),
          authorId: specialistId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка принятия заявки: $e');
      rethrow;
    }
  }

  /// Начать работу над заявкой
  Future<void> startOrder(String orderId, String specialistId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.inProgress.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Добавить событие в таймлайн
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.started,
          title: 'Работа начата',
          description: 'Специалист начал работу над заявкой',
          createdAt: DateTime.now(),
          authorId: specialistId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка начала работы над заявкой: $e');
      rethrow;
    }
  }

  /// Завершить заявку
  Future<void> completeOrder(String orderId, String specialistId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.completed.value,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Добавить событие в таймлайн
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.completed,
          title: 'Заявка завершена',
          description: 'Работа по заявке успешно завершена',
          createdAt: DateTime.now(),
          authorId: specialistId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка завершения заявки: $e');
      rethrow;
    }
  }

  /// Отменить заявку
  Future<void> cancelOrder(String orderId, String userId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.value,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Добавить событие в таймлайн
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.cancelled,
          title: 'Заявка отменена',
          description: 'Заявка была отменена. Причина: $reason',
          createdAt: DateTime.now(),
          authorId: userId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка отмены заявки: $e');
      rethrow;
    }
  }

  /// Добавить комментарий к заявке
  Future<void> addComment(String orderId, OrderComment comment) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Добавить событие в таймлайн
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.comment,
          title: 'Добавлен комментарий',
          description:
              comment.text.length > 50 ? '${comment.text.substring(0, 50)}...' : comment.text,
          createdAt: DateTime.now(),
          authorId: comment.authorId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('Ошибка добавления комментария: $e');
      rethrow;
    }
  }

  /// Добавить вложение к заявке
  Future<void> addAttachment(String orderId, OrderAttachment attachment) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'attachments': FieldValue.arrayUnion([attachment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления вложения: $e');
      rethrow;
    }
  }

  /// Добавить событие в таймлайн
  Future<void> _addTimelineEvent(
    String orderId,
    OrderTimelineEvent event,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'timeline': FieldValue.arrayUnion([event.toMap()]),
      });
    } on Exception catch (e) {
      debugPrint('Ошибка добавления события в таймлайн: $e');
    }
  }

  /// Получить шаблоны заявок
  Future<List<Map<String, dynamic>>> getOrderTemplates() async {
    try {
      final snapshot = await _firestore.collection('orderTemplates').get();

      return snapshot.docs
          .map(
            (doc) => {
              'id': doc.id,
              ...doc.data(),
            },
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('Ошибка получения шаблонов заявок: $e');
      return [];
    }
  }

  /// Создать заявку из шаблона
  Future<String> createOrderFromTemplate(
    String templateId,
    String customerId,
    String specialistId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      final templateDoc = await _firestore.collection('orderTemplates').doc(templateId).get();

      if (!templateDoc.exists) {
        throw Exception('Шаблон не найден');
      }

      final template = templateDoc.data()!;

      final order = EnhancedOrder(
        id: '', // Будет установлен при создании
        customerId: customerId,
        specialistId: specialistId,
        title: (customizations['title'] as String?) ?? (template['title'] as String),
        description:
            (customizations['description'] as String?) ?? (template['description'] as String),
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
        budget: (customizations['budget'] as double?) ?? (template['budget'] as double?),
        deadline: customizations['deadline'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                customizations['deadline'] as int,
              )
            : null,
        location: (customizations['location'] as String?) ?? (template['location'] as String?),
        category: (customizations['category'] as String?) ?? (template['category'] as String?),
        priority: OrderPriority.fromString(
          (customizations['priority'] as String?) ?? (template['priority'] as String?) ?? 'medium',
        ),
      );

      return await createOrder(order);
    } on Exception catch (e) {
      debugPrint('Ошибка создания заявки из шаблона: $e');
      rethrow;
    }
  }

  /// Подготовить к интеграции оплаты
  Future<Map<String, dynamic>> preparePayment(String orderId) async {
    try {
      // TODO(developer): Интеграция с платёжными системами
      return {
        'paymentUrl': 'https://payment.example.com/order/$orderId',
        'amount': 0.0,
        'currency': 'RUB',
        'status': 'pending',
      };
    } on Exception catch (e) {
      debugPrint('Ошибка подготовки оплаты: $e');
      rethrow;
    }
  }
}
