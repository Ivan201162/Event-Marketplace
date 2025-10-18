import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/smart_specialist.dart';
import 'package:flutter/foundation.dart';
import '../models/specialist.dart';
import 'package:flutter/foundation.dart';
import 'smart_search_service.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ AI-РїРѕРјРѕС‰РЅРёРєР° РґР»СЏ РїРѕРґР±РѕСЂР° СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
class AIAssistantService {
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();
  static final AIAssistantService _instance = AIAssistantService._internal();

  final SmartSearchService _smartSearchService = SmartSearchService();
  final List<AIConversation> _conversations = [];
  final Map<String, List<AIMessage>> _conversationHistory = {};

  /// РќР°С‡Р°С‚СЊ РЅРѕРІСѓСЋ Р±РµСЃРµРґСѓ СЃ AI-РїРѕРјРѕС‰РЅРёРєРѕРј
  Future<AIConversation> startConversation({String? userId}) async {
    final conversation = AIConversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      messages: [],
      context: {},
      createdAt: DateTime.now(),
    );

    _conversations.add(conversation);

    // Р”РѕР±Р°РІР»СЏРµРј РїСЂРёРІРµС‚СЃС‚РІРµРЅРЅРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
    final welcomeMessage = AIMessage(
      id: 'welcome_${conversation.id}',
      text:
          'РџСЂРёРІРµС‚! РЇ РїРѕРјРѕРіСѓ РІР°Рј РЅР°Р№С‚Рё РёРґРµР°Р»СЊРЅРѕРіРѕ СЃРїРµС†РёР°Р»РёСЃС‚Р° РґР»СЏ РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ. Р Р°СЃСЃРєР°Р¶РёС‚Рµ, С‡С‚Рѕ РІС‹ РїР»Р°РЅРёСЂСѓРµС‚Рµ?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );

    conversation.messages.add(welcomeMessage);
    _conversationHistory[conversation.id] = [welcomeMessage];

    return conversation;
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ AI-РїРѕРјРѕС‰РЅРёРєСѓ
  Future<AIMessage> sendMessage({
    required String conversationId,
    required String message,
    String? userId,
  }) async {
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => throw Exception('Conversation not found'),
    );

    // РЎРѕР·РґР°РµРј СЃРѕРѕР±С‰РµРЅРёРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
    final userMessage = AIMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: message,
      isFromUser: true,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );

    conversation.messages.add(userMessage);
    _conversationHistory[conversationId]?.add(userMessage);

    // РћР±СЂР°Р±Р°С‚С‹РІР°РµРј СЃРѕРѕР±С‰РµРЅРёРµ Рё РіРµРЅРµСЂРёСЂСѓРµРј РѕС‚РІРµС‚
    final aiResponse = await _processUserMessage(conversation, message, userId);

    conversation.messages.add(aiResponse);
    _conversationHistory[conversationId]?.add(aiResponse);

    return aiResponse;
  }

  /// РћР±СЂР°Р±РѕС‚Р°С‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Future<AIMessage> _processUserMessage(
    AIConversation conversation,
    String message,
    String? userId,
  ) async {
    final messageLower = message.toLowerCase();

    // РђРЅР°Р»РёР·РёСЂСѓРµРј СЃРѕРѕР±С‰РµРЅРёРµ Рё РѕР±РЅРѕРІР»СЏРµРј РєРѕРЅС‚РµРєСЃС‚
    _updateConversationContext(conversation, message);

    // РћРїСЂРµРґРµР»СЏРµРј С‚РёРї РѕС‚РІРµС‚Р°
    if (_isGreeting(messageLower)) {
      return _generateGreetingResponse(conversation);
    } else if (_isAskingForHelp(messageLower)) {
      return _generateHelpResponse(conversation);
    } else if (_isProvidingEventInfo(messageLower)) {
      return _generateEventInfoResponse(conversation);
    } else if (_isProvidingBudget(messageLower)) {
      return _generateBudgetResponse(conversation);
    } else if (_isProvidingDate(messageLower)) {
      return _generateDateResponse(conversation);
    } else if (_isProvidingLocation(messageLower)) {
      return _generateLocationResponse(conversation);
    } else if (_isAskingForRecommendations(messageLower)) {
      return _generateRecommendationsResponse(conversation, userId);
    } else if (_isAskingForMoreInfo(messageLower)) {
      return _generateMoreInfoResponse(conversation);
    } else {
      return _generateDefaultResponse(conversation);
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РєРѕРЅС‚РµРєСЃС‚ Р±РµСЃРµРґС‹
  void _updateConversationContext(AIConversation conversation, String message) {
    final messageLower = message.toLowerCase();

    // РР·РІР»РµРєР°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРё
    if (_containsEventType(messageLower)) {
      final eventType = _extractEventType(messageLower);
      if (eventType != null) {
        conversation.context['eventType'] = eventType;
      }
    }

    // РР·РІР»РµРєР°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р±СЋРґР¶РµС‚Рµ
    if (_containsBudget(messageLower)) {
      final budget = _extractBudget(messageLower);
      if (budget != null) {
        conversation.context['budget'] = budget;
      }
    }

    // РР·РІР»РµРєР°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РґР°С‚Рµ
    if (_containsDate(messageLower)) {
      final date = _extractDate(messageLower);
      if (date != null) {
        conversation.context['eventDate'] = date;
      }
    }

    // РР·РІР»РµРєР°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р»РѕРєР°С†РёРё
    if (_containsLocation(messageLower)) {
      final location = _extractLocation(messageLower);
      if (location != null) {
        conversation.context['location'] = location;
      }
    }

    // РР·РІР»РµРєР°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ СЃС‚РёР»Рµ
    if (_containsStyle(messageLower)) {
      final style = _extractStyle(messageLower);
      if (style != null) {
        conversation.context['style'] = style;
      }
    }
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, СЏРІР»СЏРµС‚СЃСЏ Р»Рё СЃРѕРѕР±С‰РµРЅРёРµ РїСЂРёРІРµС‚СЃС‚РІРёРµРј
  bool _isGreeting(String message) {
    final greetings = [
      'РїСЂРёРІРµС‚',
      'Р·РґСЂР°РІСЃС‚РІСѓР№С‚Рµ',
      'РґРѕР±СЂС‹Р№ РґРµРЅСЊ',
      'РґРѕР±СЂС‹Р№ РІРµС‡РµСЂ',
      'РґРѕР±СЂРѕРµ СѓС‚СЂРѕ',
    ];
    return greetings.any((greeting) => message.contains(greeting));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРѕСЃРёС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РїРѕРјРѕС‰Рё
  bool _isAskingForHelp(String message) {
    final helpWords = ['РїРѕРјРѕС‰СЊ', 'РїРѕРјРѕРіРё', 'РєР°Рє', 'С‡С‚Рѕ', 'СЂР°СЃСЃРєР°Р¶Рё'];
    return helpWords.any((word) => message.contains(word));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРµРґРѕСЃС‚Р°РІР»СЏРµС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРё
  bool _isProvidingEventInfo(String message) {
    final eventWords = [
      'СЃРІР°РґСЊР±Р°',
      'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
      'РєРѕСЂРїРѕСЂР°С‚РёРІ',
      'СЋР±РёР»РµР№',
      'РІРµС‡РµСЂРёРЅРєР°',
      'РјРµСЂРѕРїСЂРёСЏС‚РёРµ',
    ];
    return eventWords.any((word) => message.contains(word));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРµРґРѕСЃС‚Р°РІР»СЏРµС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р±СЋРґР¶РµС‚Рµ
  bool _isProvidingBudget(String message) {
    final budgetWords = ['Р±СЋРґР¶РµС‚', 'СЃС‚РѕРёРјРѕСЃС‚СЊ', 'С†РµРЅР°', 'СЂСѓР±Р»РµР№', 'СЂСѓР±', 'в‚Ѕ'];
    return budgetWords.any((word) => message.contains(word));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРµРґРѕСЃС‚Р°РІР»СЏРµС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РґР°С‚Рµ
  bool _isProvidingDate(String message) {
    final dateWords = ['РґР°С‚Р°', 'С‡РёСЃР»Рѕ', 'РјРµСЃСЏС†', 'РіРѕРґ', 'РґРµРЅСЊ'];
    return dateWords.any((word) => message.contains(word));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРµРґРѕСЃС‚Р°РІР»СЏРµС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р»РѕРєР°С†РёРё
  bool _isProvidingLocation(String message) {
    final locationWords = ['РіРѕСЂРѕРґ', 'РјРµСЃС‚Рѕ', 'Р°РґСЂРµСЃ', 'Р»РѕРєР°С†РёСЏ'];
    return locationWords.any((word) => message.contains(word));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРѕСЃРёС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ СЂРµРєРѕРјРµРЅРґР°С†РёРё
  bool _isAskingForRecommendations(String message) {
    final recommendationWords = [
      'РЅР°Р№РґРё',
      'РїРѕРґР±РµСЂРё',
      'СЂРµРєРѕРјРµРЅРґСѓР№',
      'РїРѕРєР°Р¶Рё',
      'РґР°Р№',
    ];
    return recommendationWords.any((word) => message.contains(word));
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РїСЂРѕСЃРёС‚ Р»Рё РїРѕР»СЊР·РѕРІР°С‚РµР»СЊ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅСѓСЋ РёРЅС„РѕСЂРјР°С†РёСЋ
  bool _isAskingForMoreInfo(String message) {
    final infoWords = ['СЂР°СЃСЃРєР°Р¶Рё', 'РїРѕРґСЂРѕР±РЅРµРµ', 'Р±РѕР»СЊС€Рµ', 'РµС‰Рµ'];
    return infoWords.any((word) => message.contains(word));
  }

  /// РЎРѕРґРµСЂР¶РёС‚ Р»Рё СЃРѕРѕР±С‰РµРЅРёРµ С‚РёРї РјРµСЂРѕРїСЂРёСЏС‚РёСЏ
  bool _containsEventType(String message) {
    final eventTypes = [
      'СЃРІР°РґСЊР±Р°',
      'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
      'РєРѕСЂРїРѕСЂР°С‚РёРІ',
      'СЋР±РёР»РµР№',
      'РІРµС‡РµСЂРёРЅРєР°',
      'С„РѕС‚РѕСЃРµСЃСЃРёСЏ',
    ];
    return eventTypes.any((type) => message.contains(type));
  }

  /// РЎРѕРґРµСЂР¶РёС‚ Р»Рё СЃРѕРѕР±С‰РµРЅРёРµ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р±СЋРґР¶РµС‚Рµ
  bool _containsBudget(String message) {
    final budgetPattern = RegExp(r'\d+.*(?:СЂСѓР±|в‚Ѕ|С‚С‹СЃСЏС‡|С‚С‹СЃ)');
    return budgetPattern.hasMatch(message);
  }

  /// РЎРѕРґРµСЂР¶РёС‚ Р»Рё СЃРѕРѕР±С‰РµРЅРёРµ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РґР°С‚Рµ
  bool _containsDate(String message) {
    final datePattern = RegExp(r'\d{1,2}[./]\d{1,2}[./]\d{2,4}');
    return datePattern.hasMatch(message);
  }

  /// РЎРѕРґРµСЂР¶РёС‚ Р»Рё СЃРѕРѕР±С‰РµРЅРёРµ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р»РѕРєР°С†РёРё
  bool _containsLocation(String message) {
    final cities = [
      'РјРѕСЃРєРІР°',
      'СЃР°РЅРєС‚-РїРµС‚РµСЂР±СѓСЂРі',
      'РµРєР°С‚РµСЂРёРЅР±СѓСЂРі',
      'РЅРѕРІРѕСЃРёР±РёСЂСЃРє',
      'РєР°Р·Р°РЅСЊ',
      'РЅРёР¶РЅРёР№ РЅРѕРІРіРѕСЂРѕРґ',
    ];
    return cities.any((city) => message.contains(city));
  }

  /// РЎРѕРґРµСЂР¶РёС‚ Р»Рё СЃРѕРѕР±С‰РµРЅРёРµ РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ СЃС‚РёР»Рµ
  bool _containsStyle(String message) {
    final styles = [
      'РєР»Р°СЃСЃРёРєР°',
      'СЃРѕРІСЂРµРјРµРЅРЅС‹Р№',
      'СЋРјРѕСЂ',
      'РёРЅС‚РµСЂР°РєС‚РёРІ',
      'СЂРѕРјР°РЅС‚РёС‡РЅС‹Р№',
      'РѕС„РёС†РёР°Р»СЊРЅС‹Р№',
    ];
    return styles.any((style) => message.contains(style));
  }

  /// РР·РІР»РµС‡СЊ С‚РёРї РјРµСЂРѕРїСЂРёСЏС‚РёСЏ
  String? _extractEventType(String message) {
    final eventTypes = {
      'СЃРІР°РґСЊР±Р°': 'СЃРІР°РґСЊР±Р°',
      'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ': 'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
      'РєРѕСЂРїРѕСЂР°С‚РёРІ': 'РєРѕСЂРїРѕСЂР°С‚РёРІ',
      'СЋР±РёР»РµР№': 'СЋР±РёР»РµР№',
      'РІРµС‡РµСЂРёРЅРєР°': 'РІРµС‡РµСЂРёРЅРєР°',
      'С„РѕС‚РѕСЃРµСЃСЃРёСЏ': 'С„РѕС‚РѕСЃРµСЃСЃРёСЏ',
    };

    for (final entry in eventTypes.entries) {
      if (message.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// РР·РІР»РµС‡СЊ Р±СЋРґР¶РµС‚
  double? _extractBudget(String message) {
    final budgetPattern = RegExp(r'(\d+).*(?:СЂСѓР±|в‚Ѕ|С‚С‹СЃСЏС‡|С‚С‹СЃ)');
    final match = budgetPattern.firstMatch(message);
    if (match != null) {
      var amount = double.tryParse(match.group(1) ?? '');
      if (amount != null) {
        // Р•СЃР»Рё СѓРїРѕРјРёРЅР°СЋС‚СЃСЏ С‚С‹СЃСЏС‡Рё, СѓРјРЅРѕР¶Р°РµРј РЅР° 1000
        if (message.contains('С‚С‹СЃСЏС‡') || message.contains('С‚С‹СЃ')) {
          amount *= 1000;
        }
        return amount;
      }
    }
    return null;
  }

  /// РР·РІР»РµС‡СЊ РґР°С‚Сѓ
  DateTime? _extractDate(String message) {
    final datePattern = RegExp(r'(\d{1,2})[./](\d{1,2})[./](\d{2,4})');
    final match = datePattern.firstMatch(message);
    if (match != null) {
      final day = int.tryParse(match.group(1) ?? '');
      final month = int.tryParse(match.group(2) ?? '');
      final year = int.tryParse(match.group(3) ?? '');

      if (day != null && month != null && year != null) {
        final fullYear = year < 100 ? 2000 + year : year;
        return DateTime(fullYear, month, day);
      }
    }
    return null;
  }

  /// РР·РІР»РµС‡СЊ Р»РѕРєР°С†РёСЋ
  String? _extractLocation(String message) {
    final cities = [
      'РјРѕСЃРєРІР°',
      'СЃР°РЅРєС‚-РїРµС‚РµСЂР±СѓСЂРі',
      'РµРєР°С‚РµСЂРёРЅР±СѓСЂРі',
      'РЅРѕРІРѕСЃРёР±РёСЂСЃРє',
      'РєР°Р·Р°РЅСЊ',
      'РЅРёР¶РЅРёР№ РЅРѕРІРіРѕСЂРѕРґ',
    ];
    for (final city in cities) {
      if (message.contains(city)) {
        return city;
      }
    }
    return null;
  }

  /// РР·РІР»РµС‡СЊ СЃС‚РёР»СЊ
  String? _extractStyle(String message) {
    final styles = [
      'РєР»Р°СЃСЃРёРєР°',
      'СЃРѕРІСЂРµРјРµРЅРЅС‹Р№',
      'СЋРјРѕСЂ',
      'РёРЅС‚РµСЂР°РєС‚РёРІ',
      'СЂРѕРјР°РЅС‚РёС‡РЅС‹Р№',
      'РѕС„РёС†РёР°Р»СЊРЅС‹Р№',
    ];
    for (final style in styles) {
      if (message.contains(style)) {
        return style;
      }
    }
    return null;
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ РЅР° РїСЂРёРІРµС‚СЃС‚РІРёРµ
  AIMessage _generateGreetingResponse(AIConversation conversation) {
    final responses = [
      'РћС‚Р»РёС‡РЅРѕ! Р”Р°РІР°Р№С‚Рµ РЅР°Р№РґРµРј РёРґРµР°Р»СЊРЅРѕРіРѕ СЃРїРµС†РёР°Р»РёСЃС‚Р° РґР»СЏ РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ. РљР°РєРѕР№ С‚РёРї СЃРѕР±С‹С‚РёСЏ РІС‹ РїР»Р°РЅРёСЂСѓРµС‚Рµ?',
      'РџСЂРёСЏС‚РЅРѕ РїРѕР·РЅР°РєРѕРјРёС‚СЊСЃСЏ! Р Р°СЃСЃРєР°Р¶РёС‚Рµ, С‡С‚Рѕ Сѓ РІР°СЃ Р·Р° РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
      'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РЇ РїРѕРјРѕРіСѓ РїРѕРґРѕР±СЂР°С‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°. Р§С‚Рѕ РІС‹ РѕСЂРіР°РЅРёР·СѓРµС‚Рµ?',
    ];

    final response = responses[DateTime.now().millisecond % responses.length];

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ СЃ РїРѕРјРѕС‰СЊСЋ
  AIMessage _generateHelpResponse(AIConversation conversation) => AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: 'РЇ РїРѕРјРѕРіСѓ РІР°Рј РЅР°Р№С‚Рё СЃРїРµС†РёР°Р»РёСЃС‚Р°! Р Р°СЃСЃРєР°Р¶РёС‚Рµ РјРЅРµ:\n\n'
            'вЂў РљР°РєРѕР№ С‚РёРї РјРµСЂРѕРїСЂРёСЏС‚РёСЏ РІС‹ РїР»Р°РЅРёСЂСѓРµС‚Рµ?\n'
            'вЂў Р’ РєР°РєРѕРј РіРѕСЂРѕРґРµ?\n'
            'вЂў РќР° РєР°РєСѓСЋ РґР°С‚Сѓ?\n'
            'вЂў РљР°РєРѕР№ Сѓ РІР°СЃ Р±СЋРґР¶РµС‚?\n'
            'вЂў РљР°РєРѕР№ СЃС‚РёР»СЊ РїСЂРµРґРїРѕС‡РёС‚Р°РµС‚Рµ?\n\n'
            'Р§РµРј Р±РѕР»СЊС€Рµ РґРµС‚Р°Р»РµР№, С‚РµРј С‚РѕС‡РЅРµРµ РїРѕРґР±РѕСЂ!',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ РЅР° РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРё
  AIMessage _generateEventInfoResponse(AIConversation conversation) {
    final eventType = conversation.context['eventType'] as String?;

    if (eventType != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'РџРѕРЅСЏС‚РЅРѕ, Сѓ РІР°СЃ $eventType! РћС‚Р»РёС‡РЅС‹Р№ РІС‹Р±РѕСЂ. РўРµРїРµСЂСЊ СЂР°СЃСЃРєР°Р¶РёС‚Рµ, РІ РєР°РєРѕРј РіРѕСЂРѕРґРµ Р±СѓРґРµС‚ РїСЂРѕС…РѕРґРёС‚СЊ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'РРЅС‚РµСЂРµСЃРЅРѕ! Рђ РєР°РєРѕР№ СЌС‚Рѕ Р±СѓРґРµС‚ С‚РёРї РјРµСЂРѕРїСЂРёСЏС‚РёСЏ? РЎРІР°РґСЊР±Р°, РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ, РєРѕСЂРїРѕСЂР°С‚РёРІ?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ РЅР° РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р±СЋРґР¶РµС‚Рµ
  AIMessage _generateBudgetResponse(AIConversation conversation) {
    final budget = conversation.context['budget'] as double?;

    if (budget != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'РћС‚Р»РёС‡РЅРѕ, Р±СЋРґР¶РµС‚ ${budget.toStringAsFixed(0)} в‚Ѕ. РўРµРїРµСЂСЊ СЃРєР°Р¶РёС‚Рµ, РЅР° РєР°РєСѓСЋ РґР°С‚Сѓ РїР»Р°РЅРёСЂСѓРµС‚Рµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'РҐРѕСЂРѕС€Рѕ! Рђ РєР°РєРѕР№ Сѓ РІР°СЃ РїСЂРёРјРµСЂРЅС‹Р№ Р±СЋРґР¶РµС‚ РЅР° СЃРїРµС†РёР°Р»РёСЃС‚Р°?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ РЅР° РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ РґР°С‚Рµ
  AIMessage _generateDateResponse(AIConversation conversation) {
    final date = conversation.context['eventDate'] as DateTime?;

    if (date != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'РџРѕРЅСЏС‚РЅРѕ, ${date.day}.${date.month}.${date.year}. РўРµРїРµСЂСЊ СЂР°СЃСЃРєР°Р¶РёС‚Рµ, РєР°РєРѕР№ СЃС‚РёР»СЊ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ РІС‹ РїСЂРµРґРїРѕС‡РёС‚Р°РµС‚Рµ? РљР»Р°СЃСЃРёС‡РµСЃРєРёР№, СЃРѕРІСЂРµРјРµРЅРЅС‹Р№, СЃ СЋРјРѕСЂРѕРј?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'РҐРѕСЂРѕС€Рѕ! Рђ РЅР° РєР°РєСѓСЋ РґР°С‚Сѓ РїР»Р°РЅРёСЂСѓРµС‚Рµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ РЅР° РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ Р»РѕРєР°С†РёРё
  AIMessage _generateLocationResponse(AIConversation conversation) {
    final location = conversation.context['location'] as String?;

    if (location != null) {
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: 'РћС‚Р»РёС‡РЅРѕ, $location! РўРµРїРµСЂСЊ СЃРєР°Р¶РёС‚Рµ, РєР°РєРѕР№ Сѓ РІР°СЃ Р±СЋРґР¶РµС‚ РЅР° СЃРїРµС†РёР°Р»РёСЃС‚Р°?',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: 'РҐРѕСЂРѕС€Рѕ! Рђ РІ РєР°РєРѕРј РіРѕСЂРѕРґРµ Р±СѓРґРµС‚ РїСЂРѕС…РѕРґРёС‚СЊ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ СЃ СЂРµРєРѕРјРµРЅРґР°С†РёСЏРјРё
  Future<AIMessage> _generateRecommendationsResponse(
    AIConversation conversation,
    String? userId,
  ) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РєРѕРЅС‚РµРєСЃС‚ Р±РµСЃРµРґС‹
      final eventType = conversation.context['eventType'] as String?;
      final budget = conversation.context['budget'] as double?;
      final date = conversation.context['eventDate'] as DateTime?;
      final location = conversation.context['location'] as String?;
      final style = conversation.context['style'] as String?;

      // РћРїСЂРµРґРµР»СЏРµРј РєР°С‚РµРіРѕСЂРёСЋ СЃРїРµС†РёР°Р»РёСЃС‚Р° РЅР° РѕСЃРЅРѕРІРµ С‚РёРїР° РјРµСЂРѕРїСЂРёСЏС‚РёСЏ
      SpecialistCategory? category;
      if (eventType != null) {
        switch (eventType) {
          case 'СЃРІР°РґСЊР±Р°':
            category = SpecialistCategory.host;
            break;
          case 'РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ':
            category = SpecialistCategory.host;
            break;
          case 'РєРѕСЂРїРѕСЂР°С‚РёРІ':
            category = SpecialistCategory.host;
            break;
          case 'С„РѕС‚РѕСЃРµСЃСЃРёСЏ':
            category = SpecialistCategory.photographer;
            break;
          default:
            category = SpecialistCategory.host;
        }
      }

      // РС‰РµРј СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
      final specialists = await _smartSearchService.smartSearch(
        category: category,
        city: location,
        minPrice: budget != null ? budget * 0.8 : null,
        maxPrice: budget != null ? budget * 1.2 : null,
        eventDate: date,
        styles: style != null ? [style] : null,
        userId: userId,
      );

      if (specialists.isNotEmpty) {
        final topSpecialists = specialists.take(3).toList();

        final responseText =
            'РћС‚Р»РёС‡РЅРѕ! РЇ РЅР°С€РµР» РґР»СЏ РІР°СЃ ${specialists.length} РїРѕРґС…РѕРґСЏС‰РёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ. Р’РѕС‚ С‚РѕРї-3:\n\n${topSpecialists.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final specialist = entry.value;
          return '$index. ${specialist.name} - ${specialist.category.displayName}\n'
              '   в­ђ Р РµР№С‚РёРЅРі: ${specialist.rating.toStringAsFixed(1)}\n'
              '   рџ’° Р¦РµРЅР°: ${specialist.priceRangeString}\n'
              '   рџ“Ќ Р“РѕСЂРѕРґ: ${specialist.city ?? 'РќРµ СѓРєР°Р·Р°РЅ'}\n'
              '   рџЋЇ РЎРѕРІРјРµСЃС‚РёРјРѕСЃС‚СЊ: ${(specialist.compatibilityScore * 100).toStringAsFixed(0)}%';
        }).join('\n\n')}\n\nРҐРѕС‚РёС‚Рµ РїРѕСЃРјРѕС‚СЂРµС‚СЊ РїРѕРґСЂРѕР±РЅРµРµ РёР»Рё РЅР°Р№С‚Рё РґСЂСѓРіРёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ?';

        return AIMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: responseText,
          isFromUser: false,
          timestamp: DateTime.now(),
          messageType: AIMessageType.recommendations,
          recommendations: topSpecialists,
        );
      } else {
        return AIMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text:
              'Рљ СЃРѕР¶Р°Р»РµРЅРёСЋ, РїРѕ РІР°С€РёРј РєСЂРёС‚РµСЂРёСЏРј РЅРµ РЅР°Р№РґРµРЅРѕ РїРѕРґС…РѕРґСЏС‰РёС… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ. РџРѕРїСЂРѕР±СѓР№С‚Рµ РёР·РјРµРЅРёС‚СЊ РїР°СЂР°РјРµС‚СЂС‹ РїРѕРёСЃРєР° РёР»Рё СЂР°СЃСЃРєР°Р¶РёС‚Рµ Р±РѕР»СЊС€Рµ Рѕ РІР°С€РёС… РїСЂРµРґРїРѕС‡С‚РµРЅРёСЏС….',
          isFromUser: false,
          timestamp: DateTime.now(),
          messageType: AIMessageType.text,
        );
      }
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РіРµРЅРµСЂР°С†РёРё СЂРµРєРѕРјРµРЅРґР°С†РёР№: $e');
      return AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: 'РџСЂРѕРёР·РѕС€Р»Р° РѕС€РёР±РєР° РїСЂРё РїРѕРёСЃРєРµ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ. РџРѕРїСЂРѕР±СѓР№С‚Рµ РµС‰Рµ СЂР°Р·.',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );
    }
  }

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ СЃ РґРѕРїРѕР»РЅРёС‚РµР»СЊРЅРѕР№ РёРЅС„РѕСЂРјР°С†РёРµР№
  AIMessage _generateMoreInfoResponse(AIConversation conversation) => AIMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text:
            'РљРѕРЅРµС‡РЅРѕ! Р Р°СЃСЃРєР°Р¶РёС‚Рµ РїРѕРґСЂРѕР±РЅРµРµ Рѕ РІР°С€РµРј РјРµСЂРѕРїСЂРёСЏС‚РёРё. Р§РµРј Р±РѕР»СЊС€Рµ РґРµС‚Р°Р»РµР№, С‚РµРј С‚РѕС‡РЅРµРµ СЏ СЃРјРѕРіСѓ РїРѕРґРѕР±СЂР°С‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚Р°.',
        isFromUser: false,
        timestamp: DateTime.now(),
        messageType: AIMessageType.text,
      );

  /// РЎРіРµРЅРµСЂРёСЂРѕРІР°С‚СЊ РѕС‚РІРµС‚ РїРѕ СѓРјРѕР»С‡Р°РЅРёСЋ
  AIMessage _generateDefaultResponse(AIConversation conversation) {
    final responses = [
      'РџРѕРЅСЏС‚РЅРѕ! Р Р°СЃСЃРєР°Р¶РёС‚Рµ РµС‰Рµ С‡С‚Рѕ-РЅРёР±СѓРґСЊ Рѕ РІР°С€РµРј РјРµСЂРѕРїСЂРёСЏС‚РёРё.',
      'РРЅС‚РµСЂРµСЃРЅРѕ! Рђ С‡С‚Рѕ РµС‰Рµ РІС‹ РјРѕР¶РµС‚Рµ СЂР°СЃСЃРєР°Р·Р°С‚СЊ?',
      'РҐРѕСЂРѕС€Рѕ! Р”Р°РІР°Р№С‚Рµ РїСЂРѕРґРѕР»Р¶РёРј. Р§С‚Рѕ РµС‰Рµ РІР°Р¶РЅРѕ СѓС‡РµСЃС‚СЊ?',
    ];

    final response = responses[DateTime.now().millisecond % responses.length];

    return AIMessage(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      text: response,
      isFromUser: false,
      timestamp: DateTime.now(),
      messageType: AIMessageType.text,
    );
  }

  /// РџРѕР»СѓС‡РёС‚СЊ Р±РµСЃРµРґСѓ РїРѕ ID
  AIConversation? getConversation(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } on Exception {
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РёСЃС‚РѕСЂРёСЋ СЃРѕРѕР±С‰РµРЅРёР№
  List<AIMessage> getConversationHistory(String conversationId) =>
      _conversationHistory[conversationId] ?? [];

  /// РћС‡РёСЃС‚РёС‚СЊ РёСЃС‚РѕСЂРёСЋ Р±РµСЃРµРґС‹
  void clearConversationHistory(String conversationId) {
    _conversationHistory.remove(conversationId);
    _conversations.removeWhere((c) => c.id == conversationId);
  }
}

/// РњРѕРґРµР»СЊ Р±РµСЃРµРґС‹ СЃ AI-РїРѕРјРѕС‰РЅРёРєРѕРј
class AIConversation {
  const AIConversation({
    required this.id,
    this.userId,
    required this.messages,
    required this.context,
    required this.createdAt,
  });

  final String id;
  final String? userId;
  final List<AIMessage> messages;
  final Map<String, dynamic> context;
  final DateTime createdAt;
}

/// РњРѕРґРµР»СЊ СЃРѕРѕР±С‰РµРЅРёСЏ AI-РїРѕРјРѕС‰РЅРёРєР°
class AIMessage {
  const AIMessage({
    required this.id,
    required this.text,
    required this.isFromUser,
    required this.timestamp,
    required this.messageType,
    this.recommendations,
    this.metadata,
  });

  final String id;
  final String text;
  final bool isFromUser;
  final DateTime timestamp;
  final AIMessageType messageType;
  final List<SmartSpecialist>? recommendations;
  final Map<String, dynamic>? metadata;
}

/// РўРёРїС‹ СЃРѕРѕР±С‰РµРЅРёР№ AI-РїРѕРјРѕС‰РЅРёРєР°
enum AIMessageType {
  text,
  recommendations,
  options,
  error,
}

