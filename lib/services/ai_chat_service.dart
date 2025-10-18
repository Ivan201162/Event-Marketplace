import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_chat.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist.dart';
import 'package:flutter/foundation.dart';
import '../services/specialist_service.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ AI-С‡Р°С‚РѕРј
class AiChatService {
  static const String _sessionsCollection = 'aiChatSessions';
  static const String _messagesCollection = 'aiChatMessages';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SpecialistService _specialistService = SpecialistService();

  /// РЎРѕР·РґР°С‚СЊ РЅРѕРІСѓСЋ СЃРµСЃСЃРёСЋ С‡Р°С‚Р°
  Future<String?> createChatSession(String userId) async {
    try {
      final session = ChatSession(
        id: '${userId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: 'РќРѕРІС‹Р№ С‡Р°С‚',
        createdAt: DateTime.now(),
        lastMessageAt: DateTime.now(),
        messageIds: [],
        context: const UserContext().toJson(),
      );

      await _firestore.collection(_sessionsCollection).doc(session.id).set(session.toFirestore());

      return session.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ СЃРµСЃСЃРёРё С‡Р°С‚Р°: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРµСЃСЃРёРё РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<List<ChatSession>> getUserSessions(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('lastMessageAt', descending: true)
          .get();

      return querySnapshot.docs.map(ChatSession.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРµСЃСЃРёР№: $e');
      return [];
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёСЏ СЃРµСЃСЃРёРё
  Future<List<ChatMessage>> getSessionMessages(String sessionId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .orderBy('timestamp')
          .get();

      return querySnapshot.docs.map(ChatMessage.fromFirestore).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ СЃРѕРѕР±С‰РµРЅРёР№: $e');
      return [];
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<ChatMessage?> sendUserMessage(
    String sessionId,
    String userId,
    String content,
  ) async {
    try {
      final message = ChatMessage(
        id: '${sessionId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
        messageType: MessageType.text.value,
      );

      await _firestore.collection(_messagesCollection).doc(message.id).set({
        ...message.toFirestore(),
        'sessionId': sessionId,
      });

      // РћР±РЅРѕРІРёС‚СЊ РІСЂРµРјСЏ РїРѕСЃР»РµРґРЅРµРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ РІ СЃРµСЃСЃРёРё
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'lastMessageAt': Timestamp.now(),
      });

      return message;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РѕС‚РІРµС‚ РѕС‚ AI
  Future<ChatMessage?> getAiResponse(
    String sessionId,
    String userId,
    String userMessage,
  ) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РєРѕРЅС‚РµРєСЃС‚ СЃРµСЃСЃРёРё
      final sessionDoc = await _firestore.collection(_sessionsCollection).doc(sessionId).get();

      if (!sessionDoc.exists) {
        return null;
      }

      final session = ChatSession.fromFirestore(sessionDoc);
      final context = UserContext.fromJson(session.context ?? {});

      // РћР±СЂР°Р±Р°С‚С‹РІР°РµРј СЃРѕРѕР±С‰РµРЅРёРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
      final response = await _processUserMessage(userMessage, context);

      // РЎРѕР·РґР°РµРј РѕС‚РІРµС‚РЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
      final aiMessage = ChatMessage(
        id: '${sessionId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        content: response['content'],
        isUser: false,
        timestamp: DateTime.now(),
        messageType: response['type'],
        metadata: response['metadata'],
      );

      await _firestore.collection(_messagesCollection).doc(aiMessage.id).set({
        ...aiMessage.toFirestore(),
        'sessionId': sessionId,
      });

      // РћР±РЅРѕРІР»СЏРµРј РєРѕРЅС‚РµРєСЃС‚ СЃРµСЃСЃРёРё
      await _updateSessionContext(sessionId, response['newContext']);

      return aiMessage;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РѕС‚РІРµС‚Р° AI: $e');
      return null;
    }
  }

  /// РћР±СЂР°Р±РѕС‚РєР° СЃРѕРѕР±С‰РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<Map<String, dynamic>> _processUserMessage(
    String message,
    UserContext context,
  ) async {
    final lowerMessage = message.toLowerCase();

    // РџСЂРёРІРµС‚СЃС‚РІРёРµ
    if (_isGreeting(lowerMessage)) {
      return {
        'content':
            'РџСЂРёРІРµС‚! РЇ AI-РїРѕРјРѕС‰РЅРёРє Event Marketplace. РџРѕРјРѕРіСѓ РїРѕРґРѕР±СЂР°С‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РґР»СЏ РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ. Р Р°СЃСЃРєР°Р¶РёС‚Рµ, РєР°РєРѕРµ СЃРѕР±С‹С‚РёРµ РїР»Р°РЅРёСЂСѓРµС‚Рµ?',
        'type': MessageType.greeting.value,
        'metadata': {
          'quickReplies': [
            const QuickReply(
              text: 'РЎРІР°РґСЊР±Р°',
              value: 'wedding',
              icon: Icons.favorite,
            ).toJson(),
            const QuickReply(
              text: 'РљРѕСЂРїРѕСЂР°С‚РёРІ',
              value: 'corporate',
              icon: Icons.business,
            ).toJson(),
            const QuickReply(
              text: 'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
              value: 'birthday',
              icon: Icons.cake,
            ).toJson(),
            const QuickReply(text: 'Р”СЂСѓРіРѕРµ', value: 'other', icon: Icons.event).toJson(),
          ],
        },
        'newContext': context,
      };
    }

    // РћРїСЂРµРґРµР»РµРЅРёРµ С‚РёРїР° СЃРѕР±С‹С‚РёСЏ
    if (_isEventType(lowerMessage)) {
      final eventType = _extractEventType(lowerMessage);
      final newContext = context.copyWith(eventType: eventType);

      return {
        'content':
            'РћС‚Р»РёС‡РЅРѕ! ${_getEventTypeDescription(eventType)} Р’ РєР°РєРѕРј РіРѕСЂРѕРґРµ РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
        'type': MessageType.question.value,
        'metadata': {
          'quickReplies': [
            const QuickReply(text: 'РњРѕСЃРєРІР°', value: 'moscow').toJson(),
            const QuickReply(text: 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі', value: 'spb').toJson(),
            const QuickReply(text: 'Р”СЂСѓРіРѕР№ РіРѕСЂРѕРґ', value: 'other_city').toJson(),
          ],
        },
        'newContext': newContext,
      };
    }

    // РћРїСЂРµРґРµР»РµРЅРёРµ РіРѕСЂРѕРґР°
    if (_isCity(lowerMessage)) {
      final city = _extractCity(lowerMessage);
      final newContext = context.copyWith(city: city);

      return {
        'content': 'РџРѕРЅСЏС‚РЅРѕ, РјРµСЂРѕРїСЂРёСЏС‚РёРµ РІ $city. РљРѕРіРґР° РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ СЃРѕР±С‹С‚РёРµ?',
        'type': MessageType.question.value,
        'metadata': {
          'quickReplies': [
            const QuickReply(text: 'Р’ СЌС‚РѕРј РјРµСЃСЏС†Рµ', value: 'this_month').toJson(),
            const QuickReply(text: 'Р’ СЃР»РµРґСѓСЋС‰РµРј РјРµСЃСЏС†Рµ', value: 'next_month').toJson(),
            const QuickReply(text: 'Р§РµСЂРµР· 3+ РјРµСЃСЏС†РµРІ', value: 'later').toJson(),
          ],
        },
        'newContext': newContext,
      };
    }

    // РћРїСЂРµРґРµР»РµРЅРёРµ Р±СЋРґР¶РµС‚Р°
    if (_isBudget(lowerMessage)) {
      final budget = _extractBudget(lowerMessage);
      final newContext = context.copyWith(budget: budget);

      return {
        'content': 'Р‘СЋРґР¶РµС‚ $budget в‚Ѕ СѓС‡С‚РµРЅ. РўРµРїРµСЂСЊ РїРѕРґР±РµСЂСѓ РїРѕРґС…РѕРґСЏС‰РёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ...',
        'type': MessageType.text.value,
        'metadata': {},
        'newContext': newContext,
      };
    }

    // РџРѕРёСЃРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
    if (_isSearchRequest(lowerMessage) || context.eventType != null) {
      return _searchSpecialists(context);
    }

    // РћР±С‰РёРµ РІРѕРїСЂРѕСЃС‹
    if (_isGeneralQuestion(lowerMessage)) {
      return {
        'content': _getGeneralAnswer(lowerMessage),
        'type': MessageType.text.value,
        'metadata': {},
        'newContext': context,
      };
    }

    // РќРµРїРѕРЅСЏС‚РЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
    return {
      'content':
          'РР·РІРёРЅРёС‚Рµ, РЅРµ СЃРѕРІСЃРµРј РїРѕРЅСЏР». РњРѕР¶РµС‚Рµ СѓС‚РѕС‡РЅРёС‚СЊ? РЇ РїРѕРјРѕРіСѓ РїРѕРґРѕР±СЂР°С‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РґР»СЏ РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ.',
      'type': MessageType.question.value,
      'metadata': {
        'quickReplies': [
          const QuickReply(text: 'РџРѕРґРѕР±СЂР°С‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ', value: 'search').toJson(),
          const QuickReply(text: 'РџРѕРјРѕС‰СЊ', value: 'help').toJson(),
        ],
      },
      'newContext': context,
    };
  }

  /// РџРѕРёСЃРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РЅР° РѕСЃРЅРѕРІРµ РєРѕРЅС‚РµРєСЃС‚Р°
  Future<Map<String, dynamic>> _searchSpecialists(UserContext context) async {
    try {
      final specialists = await _specialistService.getAllSpecialists();

      // Р¤РёР»СЊС‚СЂСѓРµРј СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РєРѕРЅС‚РµРєСЃС‚Сѓ
      final filteredSpecialists = specialists.where((specialist) {
        var matches = true;

        if (context.city != null && specialist.city != context.city) {
          matches = false;
        }

        if (context.budget != null && specialist.price > context.budget!) {
          matches = false;
        }

        if (context.eventType != null) {
          // РџСЂРѕСЃС‚Р°СЏ Р»РѕРіРёРєР° СЃРѕРїРѕСЃС‚Р°РІР»РµРЅРёСЏ С‚РёРїР° СЃРѕР±С‹С‚РёСЏ Рё РєР°С‚РµРіРѕСЂРёРё СЃРїРµС†РёР°Р»РёСЃС‚Р°
          final eventType = context.eventType!;
          final category = specialist.category.name;

          if (eventType == 'wedding' &&
              !['photographer', 'videographer', 'host', 'dj'].contains(category)) {
            matches = false;
          } else if (eventType == 'corporate' && !['host', 'dj', 'caterer'].contains(category)) {
            matches = false;
          } else if (eventType == 'birthday' &&
              !['photographer', 'host', 'dj'].contains(category)) {
            matches = false;
          }
        }

        return matches;
      }).toList();

      // РЎРѕСЂС‚РёСЂСѓРµРј РїРѕ СЂРµР№С‚РёРЅРіСѓ
      filteredSpecialists.sort((a, b) => b.rating.compareTo(a.rating));

      // Р‘РµСЂРµРј С‚РѕРї-3
      final topSpecialists = filteredSpecialists.take(3).toList();

      if (topSpecialists.isEmpty) {
        return {
          'content':
              'Рљ СЃРѕР¶Р°Р»РµРЅРёСЋ, РЅРµ РЅР°С€РµР» РїРѕРґС…РѕРґСЏС‰РёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РїРѕ РІР°С€РёРј РєСЂРёС‚РµСЂРёСЏРј. РџРѕРїСЂРѕР±СѓР№С‚Рµ РёР·РјРµРЅРёС‚СЊ РїР°СЂР°РјРµС‚СЂС‹ РїРѕРёСЃРєР°.',
          'type': MessageType.text.value,
          'metadata': {
            'quickReplies': [
              const QuickReply(
                text: 'РР·РјРµРЅРёС‚СЊ РєСЂРёС‚РµСЂРёРё',
                value: 'change_criteria',
              ).toJson(),
              const QuickReply(text: 'РџРѕРєР°Р·Р°С‚СЊ РІСЃРµС…', value: 'show_all').toJson(),
            ],
          },
          'newContext': context,
        };
      }

      return {
        'content': 'РќР°С€РµР» ${topSpecialists.length} РїРѕРґС…РѕРґСЏС‰РёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ:',
        'type': MessageType.specialistCard.value,
        'metadata': {
          'specialists': topSpecialists
              .map(
                (s) => {
                  'id': s.id,
                  'name': s.name,
                  'category': s.category.displayName,
                  'rating': s.rating,
                  'price': s.price,
                  'city': s.city,
                  'photoUrl': s.photoUrl,
                },
              )
              .toList(),
          'quickReplies': [
            const QuickReply(text: 'РџРѕРєР°Р·Р°С‚СЊ Р±РѕР»СЊС€Рµ', value: 'show_more').toJson(),
            const QuickReply(text: 'РќРѕРІС‹Р№ РїРѕРёСЃРє', value: 'new_search').toJson(),
          ],
        },
        'newContext': context,
      };
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: $e');
      return {
        'content': 'РџСЂРѕРёР·РѕС€Р»Р° РѕС€РёР±РєР° РїСЂРё РїРѕРёСЃРєРµ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ. РџРѕРїСЂРѕР±СѓР№С‚Рµ РїРѕР·Р¶Рµ.',
        'type': MessageType.text.value,
        'metadata': {},
        'newContext': context,
      };
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РєРѕРЅС‚РµРєСЃС‚ СЃРµСЃСЃРёРё
  Future<void> _updateSessionContext(
    String sessionId,
    UserContext? newContext,
  ) async {
    if (newContext == null) return;

    try {
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'context': newContext.toJson(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РєРѕРЅС‚РµРєСЃС‚Р°: $e');
    }
  }

  // Р’СЃРїРѕРјРѕРіР°С‚РµР»СЊРЅС‹Рµ РјРµС‚РѕРґС‹ РґР»СЏ Р°РЅР°Р»РёР·Р° СЃРѕРѕР±С‰РµРЅРёР№

  bool _isGreeting(String message) {
    final greetings = [
      'РїСЂРёРІРµС‚',
      'Р·РґСЂР°РІСЃС‚РІСѓР№С‚Рµ',
      'РґРѕР±СЂС‹Р№ РґРµРЅСЊ',
      'РґРѕР±СЂС‹Р№ РІРµС‡РµСЂ',
      'РґРѕР±СЂРѕРµ СѓС‚СЂРѕ',
      'hi',
      'hello',
    ];
    return greetings.any((greeting) => message.contains(greeting));
  }

  bool _isEventType(String message) {
    final eventTypes = [
      'СЃРІР°РґСЊР±Р°',
      'РєРѕСЂРїРѕСЂР°С‚РёРІ',
      'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
      'СЋР±РёР»РµР№',
      'РїСЂР°Р·РґРЅРёРє',
      'РјРµСЂРѕРїСЂРёСЏС‚РёРµ',
    ];
    return eventTypes.any((type) => message.contains(type));
  }

  String _extractEventType(String message) {
    if (message.contains('СЃРІР°РґСЊР±')) return 'wedding';
    if (message.contains('РєРѕСЂРїРѕСЂР°С‚РёРІ')) return 'corporate';
    if (message.contains('РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ') || message.contains('РґСЂ')) {
      return 'birthday';
    }
    if (message.contains('СЋР±РёР»РµР№')) return 'anniversary';
    return 'other';
  }

  String _getEventTypeDescription(String eventType) {
    switch (eventType) {
      case 'wedding':
        return 'РЎРІР°РґСЊР±Р° - СЌС‚Рѕ РѕСЃРѕР±РµРЅРЅС‹Р№ РґРµРЅСЊ!';
      case 'corporate':
        return 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ - РѕС‚Р»РёС‡РЅС‹Р№ РІС‹Р±РѕСЂ!';
      case 'birthday':
        return 'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ - Р·Р°РјРµС‡Р°С‚РµР»СЊРЅС‹Р№ РїРѕРІРѕРґ РґР»СЏ РїСЂР°Р·РґРЅРёРєР°!';
      case 'anniversary':
        return 'Р®Р±РёР»РµР№ - РІР°Р¶РЅРѕРµ СЃРѕР±С‹С‚РёРµ!';
      default:
        return 'РРЅС‚РµСЂРµСЃРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ!';
    }
  }

  bool _isCity(String message) {
    final cities = [
      'РјРѕСЃРєРІР°',
      'СЃР°РЅРєС‚-РїРµС‚РµСЂР±СѓСЂРі',
      'СЃРїР±',
      'РµРєР°С‚РµСЂРёРЅР±СѓСЂРі',
      'РЅРѕРІРѕСЃРёР±РёСЂСЃРє',
    ];
    return cities.any((city) => message.contains(city));
  }

  String _extractCity(String message) {
    if (message.contains('РјРѕСЃРєРІ')) return 'РњРѕСЃРєРІР°';
    if (message.contains('СЃР°РЅРєС‚-РїРµС‚РµСЂР±СѓСЂРі') || message.contains('СЃРїР±')) {
      return 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі';
    }
    if (message.contains('РµРєР°С‚РµСЂРёРЅР±СѓСЂРі')) return 'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі';
    if (message.contains('РЅРѕРІРѕСЃРёР±РёСЂСЃРє')) return 'РќРѕРІРѕСЃРёР±РёСЂСЃРє';
    return 'Р”СЂСѓРіРѕР№ РіРѕСЂРѕРґ';
  }

  bool _isBudget(String message) =>
      message.contains('Р±СЋРґР¶РµС‚') ||
      message.contains('в‚Ѕ') ||
      message.contains('СЂСѓР±') ||
      RegExp(r'\d+').hasMatch(message);

  int _extractBudget(String message) {
    final regex = RegExp(r'(\d+)');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.parse(match.group(1)!);
    }
    return 50000; // Р”РµС„РѕР»С‚РЅС‹Р№ Р±СЋРґР¶РµС‚
  }

  bool _isSearchRequest(String message) {
    final searchWords = ['РЅР°Р№С‚Рё', 'РїРѕРґРѕР±СЂР°С‚СЊ', 'РїРѕРёСЃРє', 'СЃРїРµС†РёР°Р»РёСЃС‚', 'РїРѕРјРѕС‰СЊ'];
    return searchWords.any((word) => message.contains(word));
  }

  bool _isGeneralQuestion(String message) {
    final questions = ['С‡С‚Рѕ', 'РєР°Рє', 'РіРґРµ', 'РєРѕРіРґР°', 'РїРѕС‡РµРјСѓ', 'Р·Р°С‡РµРј'];
    return questions.any((question) => message.contains(question));
  }

  String _getGeneralAnswer(String message) {
    if (message.contains('С‡С‚Рѕ С‚Р°РєРѕРµ') || message.contains('С‡С‚Рѕ СЌС‚Рѕ')) {
      return 'Event Marketplace - СЌС‚Рѕ РїР»Р°С‚С„РѕСЂРјР° РґР»СЏ РїРѕРёСЃРєР° Рё Р±СЂРѕРЅРёСЂРѕРІР°РЅРёСЏ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ РґР»СЏ РјРµСЂРѕРїСЂРёСЏС‚РёР№. РЇ РїРѕРјРѕРіСѓ РЅР°Р№С‚Рё С„РѕС‚РѕРіСЂР°С„РѕРІ, РІРµРґСѓС‰РёС…, DJ, РґРµРєРѕСЂР°С‚РѕСЂРѕРІ Рё РґСЂСѓРіРёС… РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»РѕРІ.';
    }
    if (message.contains('РєР°Рє СЂР°Р±РѕС‚Р°РµС‚') || message.contains('РєР°Рє РїРѕР»СЊР·РѕРІР°С‚СЊСЃСЏ')) {
      return 'РџСЂРѕСЃС‚Рѕ СЂР°СЃСЃРєР°Р¶РёС‚Рµ РјРЅРµ Рѕ РІР°С€РµРј РјРµСЂРѕРїСЂРёСЏС‚РёРё: С‚РёРї СЃРѕР±С‹С‚РёСЏ, РіРѕСЂРѕРґ, РґР°С‚Сѓ Рё Р±СЋРґР¶РµС‚. РЇ РїРѕРґР±РµСЂСѓ РїРѕРґС…РѕРґСЏС‰РёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ Рё РїРѕРјРѕРіСѓ СЃ Р±СЂРѕРЅРёСЂРѕРІР°РЅРёРµРј.';
    }
    if (message.contains('СЃРєРѕР»СЊРєРѕ СЃС‚РѕРёС‚') || message.contains('С†РµРЅР°')) {
      return 'Р¦РµРЅС‹ Р·Р°РІРёСЃСЏС‚ РѕС‚ С‚РёРїР° СѓСЃР»СѓРіРё Рё СЃРїРµС†РёР°Р»РёСЃС‚Р°. РћР±С‹С‡РЅРѕ С„РѕС‚РѕРіСЂР°С„С‹ СЃС‚РѕСЏС‚ РѕС‚ 15 000 в‚Ѕ, РІРµРґСѓС‰РёРµ РѕС‚ 20 000 в‚Ѕ, DJ РѕС‚ 10 000 в‚Ѕ. Р Р°СЃСЃРєР°Р¶РёС‚Рµ Рѕ РІР°С€РµРј Р±СЋРґР¶РµС‚Рµ, Рё СЏ РїРѕРґР±РµСЂСѓ РѕРїС‚РёРјР°Р»СЊРЅС‹Рµ РІР°СЂРёР°РЅС‚С‹.';
    }
    return 'РЇ РіРѕС‚РѕРІ РїРѕРјРѕС‡СЊ СЃ РѕСЂРіР°РЅРёР·Р°С†РёРµР№ РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ! Р Р°СЃСЃРєР°Р¶РёС‚Рµ РїРѕРґСЂРѕР±РЅРµРµ Рѕ С‚РѕРј, С‡С‚Рѕ РїР»Р°РЅРёСЂСѓРµС‚Рµ.';
  }
}

