import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/enhanced_order.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ СѓР»СѓС‡С€РµРЅРЅС‹РјРё Р·Р°СЏРІРєР°РјРё
class EnhancedOrdersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// РџРѕР»СѓС‡РёС‚СЊ Р·Р°СЏРІРєРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°СЏРІРѕРє РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р·Р°СЏРІРєРё СЃРїРµС†РёР°Р»РёСЃС‚Р°
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ Р·Р°СЏРІРѕРє СЃРїРµС†РёР°Р»РёСЃС‚Р°: $e');
      return [];
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РЅРѕРІСѓСЋ Р·Р°СЏРІРєСѓ
  Future<String> createOrder(EnhancedOrder order) async {
    try {
      final docRef = await _firestore.collection('orders').add(order.toMap());

      // Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
      await _addTimelineEvent(
        docRef.id,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.created,
          title: 'Р—Р°СЏРІРєР° СЃРѕР·РґР°РЅР°',
          description: 'Р—Р°СЏРІРєР° "${order.title}" Р±С‹Р»Р° СЃРѕР·РґР°РЅР°',
          createdAt: DateTime.now(),
          authorId: order.customerId,
        ),
      );

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ Р·Р°СЏРІРєРё: $e');
      rethrow;
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ Р·Р°СЏРІРєСѓ
  Future<void> updateOrder(String orderId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ Р·Р°СЏРІРєРё: $e');
      rethrow;
    }
  }

  /// РџСЂРёРЅСЏС‚СЊ Р·Р°СЏРІРєСѓ
  Future<void> acceptOrder(String orderId, String specialistId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.accepted.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.accepted,
          title: 'Р—Р°СЏРІРєР° РїСЂРёРЅСЏС‚Р°',
          description: 'РЎРїРµС†РёР°Р»РёСЃС‚ РїСЂРёРЅСЏР» Р·Р°СЏРІРєСѓ Рє РІС‹РїРѕР»РЅРµРЅРёСЋ',
          createdAt: DateTime.now(),
          authorId: specialistId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїСЂРёРЅСЏС‚РёСЏ Р·Р°СЏРІРєРё: $e');
      rethrow;
    }
  }

  /// РќР°С‡Р°С‚СЊ СЂР°Р±РѕС‚Сѓ РЅР°Рґ Р·Р°СЏРІРєРѕР№
  Future<void> startOrder(String orderId, String specialistId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.inProgress.value,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.started,
          title: 'Р Р°Р±РѕС‚Р° РЅР°С‡Р°С‚Р°',
          description: 'РЎРїРµС†РёР°Р»РёСЃС‚ РЅР°С‡Р°Р» СЂР°Р±РѕС‚Сѓ РЅР°Рґ Р·Р°СЏРІРєРѕР№',
          createdAt: DateTime.now(),
          authorId: specialistId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РЅР°С‡Р°Р»Р° СЂР°Р±РѕС‚С‹ РЅР°Рґ Р·Р°СЏРІРєРѕР№: $e');
      rethrow;
    }
  }

  /// Р—Р°РІРµСЂС€РёС‚СЊ Р·Р°СЏРІРєСѓ
  Future<void> completeOrder(String orderId, String specialistId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.completed.value,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.completed,
          title: 'Р—Р°СЏРІРєР° Р·Р°РІРµСЂС€РµРЅР°',
          description: 'Р Р°Р±РѕС‚Р° РїРѕ Р·Р°СЏРІРєРµ СѓСЃРїРµС€РЅРѕ Р·Р°РІРµСЂС€РµРЅР°',
          createdAt: DateTime.now(),
          authorId: specialistId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РІРµСЂС€РµРЅРёСЏ Р·Р°СЏРІРєРё: $e');
      rethrow;
    }
  }

  /// РћС‚РјРµРЅРёС‚СЊ Р·Р°СЏРІРєСѓ
  Future<void> cancelOrder(String orderId, String userId, String reason) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': OrderStatus.cancelled.value,
        'cancelledAt': FieldValue.serverTimestamp(),
        'cancellationReason': reason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.cancelled,
          title: 'Р—Р°СЏРІРєР° РѕС‚РјРµРЅРµРЅР°',
          description: 'Р—Р°СЏРІРєР° Р±С‹Р»Р° РѕС‚РјРµРЅРµРЅР°. РџСЂРёС‡РёРЅР°: $reason',
          createdAt: DateTime.now(),
          authorId: userId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РјРµРЅС‹ Р·Р°СЏРІРєРё: $e');
      rethrow;
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РєРѕРјРјРµРЅС‚Р°СЂРёР№ Рє Р·Р°СЏРІРєРµ
  Future<void> addComment(String orderId, OrderComment comment) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'comments': FieldValue.arrayUnion([comment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
      await _addTimelineEvent(
        orderId,
        OrderTimelineEvent(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: OrderTimelineEventType.comment,
          title: 'Р”РѕР±Р°РІР»РµРЅ РєРѕРјРјРµРЅС‚Р°СЂРёР№',
          description:
              comment.text.length > 50 ? '${comment.text.substring(0, 50)}...' : comment.text,
          createdAt: DateTime.now(),
          authorId: comment.authorId,
        ),
      );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РєРѕРјРјРµРЅС‚Р°СЂРёСЏ: $e');
      rethrow;
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РІР»РѕР¶РµРЅРёРµ Рє Р·Р°СЏРІРєРµ
  Future<void> addAttachment(String orderId, OrderAttachment attachment) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'attachments': FieldValue.arrayUnion([attachment.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РІР»РѕР¶РµРЅРёСЏ: $e');
      rethrow;
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ СЃРѕР±С‹С‚РёРµ РІ С‚Р°Р№РјР»Р°Р№РЅ
  Future<void> _addTimelineEvent(
    String orderId,
    OrderTimelineEvent event,
  ) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'timeline': FieldValue.arrayUnion([event.toMap()]),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ СЃРѕР±С‹С‚РёСЏ РІ С‚Р°Р№РјР»Р°Р№РЅ: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С€Р°Р±Р»РѕРЅС‹ Р·Р°СЏРІРѕРє
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
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ С€Р°Р±Р»РѕРЅРѕРІ Р·Р°СЏРІРѕРє: $e');
      return [];
    }
  }

  /// РЎРѕР·РґР°С‚СЊ Р·Р°СЏРІРєСѓ РёР· С€Р°Р±Р»РѕРЅР°
  Future<String> createOrderFromTemplate(
    String templateId,
    String customerId,
    String specialistId,
    Map<String, dynamic> customizations,
  ) async {
    try {
      final templateDoc = await _firestore.collection('orderTemplates').doc(templateId).get();

      if (!templateDoc.exists) {
        throw Exception('РЁР°Р±Р»РѕРЅ РЅРµ РЅР°Р№РґРµРЅ');
      }

      final template = templateDoc.data()!;

      final order = EnhancedOrder(
        id: '', // Р‘СѓРґРµС‚ СѓСЃС‚Р°РЅРѕРІР»РµРЅ РїСЂРё СЃРѕР·РґР°РЅРёРё
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
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ Р·Р°СЏРІРєРё РёР· С€Р°Р±Р»РѕРЅР°: $e');
      rethrow;
    }
  }

  /// РџРѕРґРіРѕС‚РѕРІРёС‚СЊ Рє РёРЅС‚РµРіСЂР°С†РёРё РѕРїР»Р°С‚С‹
  Future<Map<String, dynamic>> preparePayment(String orderId) async {
    try {
      // TODO(developer): РРЅС‚РµРіСЂР°С†РёСЏ СЃ РїР»Р°С‚С‘Р¶РЅС‹РјРё СЃРёСЃС‚РµРјР°РјРё
      return {
        'paymentUrl': 'https://payment.example.com/order/$orderId',
        'amount': 0.0,
        'currency': 'RUB',
        'status': 'pending',
      };
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРґРіРѕС‚РѕРІРєРё РѕРїР»Р°С‚С‹: $e');
      rethrow;
    }
  }
}

