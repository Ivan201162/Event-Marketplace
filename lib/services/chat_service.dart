import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ С‡Р°С‚Р°РјРё
class ChatService {
  factory ChatService() => _instance;
  ChatService._internal();
  static final ChatService _instance = ChatService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final String _messagesCollection = 'messages';
  final String _chatsCollection = 'chats';

  // РљСЌС€ РґР»СЏ Р»РѕРєР°Р»СЊРЅРѕРіРѕ С…СЂР°РЅРµРЅРёСЏ
  static const String _cacheKey = 'chat_cache';
  static const int _maxCachedMessages = 20;

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёСЏ С‡Р°С‚Р°
  Stream<List<ChatMessage>> getChatMessages(String chatId) => _firestore
      .collection(_messagesCollection)
      .where('chatId', isEqualTo: chatId)
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(ChatMessage.fromDocument).toList());

  /// РћС‚РїСЂР°РІРёС‚СЊ С‚РµРєСЃС‚РѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String?> sendTextMessage({
    required String chatId,
    required String senderId,
    required String text,
    String? senderName,
  }) async {
    try {
      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        type: MessageType.text,
        content: text,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

      // РћР±РЅРѕРІР»СЏРµРј РїРѕСЃР»РµРґРЅРµРµ СЃРѕРѕР±С‰РµРЅРёРµ РІ С‡Р°С‚Рµ
      await _updateLastMessage(chatId, message);

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ
      await _sendMessageNotification(chatId, senderId, text);

      // РЎРѕС…СЂР°РЅСЏРµРј РІ РєСЌС€
      await _saveToCache(chatId, message);

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё С‚РµРєСЃС‚РѕРІРѕРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      return null;
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ РёР·РѕР±СЂР°Р¶РµРЅРёРµ
  Future<String?> sendImageMessage({
    required String chatId,
    required String senderId,
    String? senderName,
  }) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Р—Р°РіСЂСѓР¶Р°РµРј РёР·РѕР±СЂР°Р¶РµРЅРёРµ РІ Storage
      final imageUrl = await _uploadFile(image, 'images');
      if (imageUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        type: MessageType.image,
        content: imageUrl,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё РёР·РѕР±СЂР°Р¶РµРЅРёСЏ: $e');
      return null;
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ РІРёРґРµРѕ
  Future<String?> sendVideoMessage({
    required String chatId,
    required String senderId,
    String? senderName,
  }) async {
    try {
      final video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5),
      );

      if (video == null) return null;

      // Р—Р°РіСЂСѓР¶Р°РµРј РІРёРґРµРѕ РІ Storage
      final videoUrl = await _uploadFile(video, 'videos');
      if (videoUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        type: MessageType.video,
        content: videoUrl,
        fileName: video.path.split('/').last,
        fileSize: await File(video.path).length(),
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

      // РћР±РЅРѕРІР»СЏРµРј РїРѕСЃР»РµРґРЅРµРµ СЃРѕРѕР±С‰РµРЅРёРµ РІ С‡Р°С‚Рµ
      await _updateLastMessage(chatId, message);

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ
      await _sendMessageNotification(chatId, senderId, 'Р’РёРґРµРѕ');

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё РІРёРґРµРѕ: $e');
      return null;
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ Р°СѓРґРёРѕ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<String?> sendAudioMessage({
    required String chatId,
    required String senderId,
    String? senderName,
    required File audioFile,
    int? duration,
  }) async {
    try {
      // Р—Р°РіСЂСѓР¶Р°РµРј Р°СѓРґРёРѕ РІ Storage
      final audioUrl = await _uploadFile(audioFile, 'audio');
      if (audioUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        type: MessageType.audio,
        content: audioUrl,
        fileName: audioFile.path.split('/').last,
        fileSize: await audioFile.length(),
        metadata: duration != null ? {'duration': duration} : null,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

      // РћР±РЅРѕРІР»СЏРµРј РїРѕСЃР»РµРґРЅРµРµ СЃРѕРѕР±С‰РµРЅРёРµ РІ С‡Р°С‚Рµ
      await _updateLastMessage(chatId, message);

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ
      await _sendMessageNotification(chatId, senderId, 'РђСѓРґРёРѕ СЃРѕРѕР±С‰РµРЅРёРµ');

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё Р°СѓРґРёРѕ: $e');
      return null;
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ РґРѕРєСѓРјРµРЅС‚
  Future<String?> sendDocumentMessage({
    required String chatId,
    required String senderId,
    required File file,
    String? senderName,
  }) async {
    try {
      // Р—Р°РіСЂСѓР¶Р°РµРј РґРѕРєСѓРјРµРЅС‚ РІ Storage
      final fileUrl = await _uploadFile(file, 'documents');
      if (fileUrl == null) return null;

      final message = ChatMessage(
        id: '',
        chatId: chatId,
        senderId: senderId,
        senderName: senderName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
        type: MessageType.document,
        content: fileUrl,
        fileName: file.path.split('/').last,
        status: MessageStatus.sent,
        createdAt: DateTime.now(),
        isFromCurrentUser: true,
      );

      final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё РґРѕРєСѓРјРµРЅС‚Р°: $e');
      return null;
    }
  }

  /// Р—Р°РіСЂСѓР·РёС‚СЊ С„Р°Р№Р» РІ Storage
  Future<String?> _uploadFile(file, String folder) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$fileName');

      UploadTask uploadTask;
      if (file is XFile) {
        uploadTask = ref.putFile(File(file.path));
      } else if (file is File) {
        uploadTask = ref.putFile(file);
      } else {
        throw Exception('РќРµРїРѕРґРґРµСЂР¶РёРІР°РµРјС‹Р№ С‚РёРї С„Р°Р№Р»Р°');
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё С„Р°Р№Р»Р°: $e');
      return null;
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РёР»Рё РїРѕР»СѓС‡РёС‚СЊ С‡Р°С‚ РјРµР¶РґСѓ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏРјРё
  Future<String?> getOrCreateChat(String userId1, String userId2) async {
    try {
      // РС‰РµРј СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ С‡Р°С‚
      final existingChat = await _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId1)
          .get();

      for (final doc in existingChat.docs) {
        final data = doc.data();
        final participantsData = data['participants'] as List<dynamic>? ?? [];
        final participants = List<String>.from(participantsData);
        if (participants.contains(userId2)) {
          return doc.id;
        }
      }

      // РЎРѕР·РґР°РµРј РЅРѕРІС‹Р№ С‡Р°С‚
      final chatData = {
        'participants': [userId1, userId2],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': null,
        'lastMessageAt': null,
      };

      final docRef = await _firestore.collection(_chatsCollection).add(chatData);
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ/РїРѕР»СѓС‡РµРЅРёСЏ С‡Р°С‚Р°: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРёСЃРѕРє С‡Р°С‚РѕРІ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<List<Map<String, dynamic>>> getUserChats(String userId) => _firestore
      .collection(_chatsCollection)
      .where('participants', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList(),
      );

  /// РћС‚РјРµС‚РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёСЏ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹Рµ
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final batch = _firestore.batch();

      final messages = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in messages.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РјРµС‚РєРё СЃРѕРѕР±С‰РµРЅРёР№ РєР°Рє РїСЂРѕС‡РёС‚Р°РЅРЅС‹С…: $e');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<bool> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      return false;
    }
  }

  /// Р РµРґР°РєС‚РёСЂРѕРІР°С‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ
  Future<bool> editMessage(String messageId, String newText) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).update({
        'text': newText,
        'editedAt': FieldValue.serverTimestamp(),
        'isEdited': true,
      });
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЂРµРґР°РєС‚РёСЂРѕРІР°РЅРёСЏ СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РєРѕР»РёС‡РµСЃС‚РІРѕ РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СЃРѕРѕР±С‰РµРЅРёР№
  Stream<int> getUnreadMessagesCount(String userId) => _firestore
      .collection(_messagesCollection)
      .where('receiverId', isEqualTo: userId)
      .where('isRead', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);

  /// РџРѕРёСЃРє СЃРѕРѕР±С‰РµРЅРёР№
  Future<List<ChatMessage>> searchMessages(String chatId, String query) async {
    try {
      final snapshot = await _firestore
          .collection(_messagesCollection)
          .where('chatId', isEqualTo: chatId)
          .where('content', isGreaterThanOrEqualTo: query)
          .where('content', isLessThan: '$query\uf8ff')
          .get();

      return snapshot.docs.map(ChatMessage.fromDocument).toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕРёСЃРєР° СЃРѕРѕР±С‰РµРЅРёР№: $e');
      return [];
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ РїРѕСЃР»РµРґРЅРµРµ СЃРѕРѕР±С‰РµРЅРёРµ РІ С‡Р°С‚Рµ
  Future<void> _updateLastMessage(String chatId, ChatMessage message) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'lastMessageContent': message.content,
        'lastMessageType': message.type.name,
        'lastMessageTime': message.timestamp != null
            ? Timestamp.fromDate(message.timestamp!)
            : Timestamp.fromDate(message.createdAt),
        'lastMessageSenderId': message.senderId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РїРѕСЃР»РµРґРЅРµРіРѕ СЃРѕРѕР±С‰РµРЅРёСЏ: $e');
    }
  }

  /// РћС‚РїСЂР°РІРёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёРµ Рѕ РЅРѕРІРѕРј СЃРѕРѕР±С‰РµРЅРёРё
  Future<void> _sendMessageNotification(
    String chatId,
    String senderId,
    String messageContent,
  ) async {
    try {
      // РџРѕР»СѓС‡Р°РµРј РёРЅС„РѕСЂРјР°С†РёСЋ Рѕ С‡Р°С‚Рµ
      final chatDoc = await _firestore.collection(_chatsCollection).doc(chatId).get();
      if (!chatDoc.exists) return;

      final chatData = chatDoc.data()!;
      final participantsData = chatData['participants'] as List<dynamic>? ?? [];
      final participants = List<String>.from(participantsData);

      // РќР°С…РѕРґРёРј РїРѕР»СѓС‡Р°С‚РµР»СЏ (РЅРµ РѕС‚РїСЂР°РІРёС‚РµР»СЏ)
      final receiverId = participants.firstWhere(
        (id) => id != senderId,
        orElse: () => participants.first,
      );

      // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ (Р·Р°РіР»СѓС€РєР°)
      debugPrint(
        'РћС‚РїСЂР°РІРєР° СѓРІРµРґРѕРјР»РµРЅРёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЋ $receiverId: РќРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
      );
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕС‚РїСЂР°РІРєРё СѓРІРµРґРѕРјР»РµРЅРёСЏ: $e');
    }
  }

  /// РЎРѕС…СЂР°РЅРёС‚СЊ СЃРѕРѕР±С‰РµРЅРёРµ РІ Р»РѕРєР°Р»СЊРЅС‹Р№ РєСЌС€
  Future<void> _saveToCache(String chatId, ChatMessage message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$chatId';

      // РџРѕР»СѓС‡Р°РµРј СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёР№ РєСЌС€
      final cachedData = prefs.getString(cacheKey);
      var messages = <Map<String, dynamic>>[];

      if (cachedData != null) {
        final dynamic decoded = json.decode(cachedData);
        if (decoded is List) {
          messages = decoded.cast<Map<String, dynamic>>();
        }
      }

      // Р”РѕР±Р°РІР»СЏРµРј РЅРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ
      messages.add(message.toMap());

      // РћРіСЂР°РЅРёС‡РёРІР°РµРј РєРѕР»РёС‡РµСЃС‚РІРѕ РєСЌС€РёСЂРѕРІР°РЅРЅС‹С… СЃРѕРѕР±С‰РµРЅРёР№
      if (messages.length > _maxCachedMessages) {
        messages = messages.sublist(messages.length - _maxCachedMessages);
      }

      // РЎРѕС…СЂР°РЅСЏРµРј РѕР±РЅРѕРІР»РµРЅРЅС‹Р№ РєСЌС€
      await prefs.setString(cacheKey, json.encode(messages));
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РІ РєСЌС€: $e');
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РєСЌС€РёСЂРѕРІР°РЅРЅС‹Рµ СЃРѕРѕР±С‰РµРЅРёСЏ
  Future<List<ChatMessage>> getCachedMessages(String chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '${_cacheKey}_$chatId';
      final cachedData = prefs.getString(cacheKey);

      if (cachedData == null) return [];

      final dynamic decoded = json.decode(cachedData);
      if (decoded is! List) return [];

      return decoded
          .map(
            (data) => ChatMessage.fromMap(data as Map<String, dynamic>),
          )
          .toList();
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РїРѕР»СѓС‡РµРЅРёСЏ РєСЌС€Р°: $e');
      return [];
    }
  }

  /// Р’С‹Р±СЂР°С‚СЊ С„Р°Р№Р» РґР»СЏ РѕС‚РїСЂР°РІРєРё
  Future<String?> pickAndSendFile({
    required String chatId,
    required String senderId,
    String? senderName,
  }) async {
    try {
      // Р—Р°РїСЂР°С€РёРІР°РµРј СЂР°Р·СЂРµС€РµРЅРёРµ РЅР° РґРѕСЃС‚СѓРї Рє С„Р°Р№Р»Р°Рј
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        debugPrint('РќРµС‚ СЂР°Р·СЂРµС€РµРЅРёСЏ РЅР° РґРѕСЃС‚СѓРї Рє С„Р°Р№Р»Р°Рј');
        return null;
      }

      final result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.first.path!);
        final fileName = result.files.first.name;
        final fileSize = result.files.first.size;

        // РћРїСЂРµРґРµР»СЏРµРј С‚РёРї С„Р°Р№Р»Р°
        MessageType messageType;
        if (fileName.toLowerCase().endsWith('.jpg') ||
            fileName.toLowerCase().endsWith('.jpeg') ||
            fileName.toLowerCase().endsWith('.png') ||
            fileName.toLowerCase().endsWith('.gif')) {
          messageType = MessageType.image;
        } else if (fileName.toLowerCase().endsWith('.mp4') ||
            fileName.toLowerCase().endsWith('.avi') ||
            fileName.toLowerCase().endsWith('.mov')) {
          messageType = MessageType.video;
        } else if (fileName.toLowerCase().endsWith('.mp3') ||
            fileName.toLowerCase().endsWith('.wav') ||
            fileName.toLowerCase().endsWith('.aac')) {
          messageType = MessageType.audio;
        } else {
          messageType = MessageType.document;
        }

        // Р—Р°РіСЂСѓР¶Р°РµРј С„Р°Р№Р» РІ Storage
        final fileUrl = await _uploadFile(file, 'documents');
        if (fileUrl == null) return null;

        final message = ChatMessage(
          id: '',
          chatId: chatId,
          senderId: senderId,
          senderName: senderName ?? 'РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ',
          type: messageType,
          content: fileUrl,
          fileUrl: fileUrl,
          fileName: fileName,
          fileSize: fileSize,
          status: MessageStatus.sent,
          createdAt: DateTime.now(),
          isFromCurrentUser: true,
        );

        final docRef = await _firestore.collection(_messagesCollection).add(message.toMap());

        // РћР±РЅРѕРІР»СЏРµРј РїРѕСЃР»РµРґРЅРµРµ СЃРѕРѕР±С‰РµРЅРёРµ РІ С‡Р°С‚Рµ
        await _updateLastMessage(chatId, message);

        // РћС‚РїСЂР°РІР»СЏРµРј СѓРІРµРґРѕРјР»РµРЅРёРµ
        await _sendMessageNotification(chatId, senderId, fileName);

        return docRef.id;
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РІС‹Р±РѕСЂР° Рё РѕС‚РїСЂР°РІРєРё С„Р°Р№Р»Р°: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ РєРѕР»РёС‡РµСЃС‚РІРѕ РЅРµРїСЂРѕС‡РёС‚Р°РЅРЅС‹С… СЃРѕРѕР±С‰РµРЅРёР№ РґР»СЏ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<int> getUnreadMessagesCountForUser(String userId) => _firestore
          .collection(_messagesCollection)
          .where('senderId', isNotEqualTo: userId)
          .where('readBy', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        // РџРѕРґСЃС‡РёС‚С‹РІР°РµРј СЃРѕРѕР±С‰РµРЅРёСЏ, РєРѕС‚РѕСЂС‹Рµ РЅРµ РїСЂРѕС‡РёС‚Р°РЅС‹ С‚РµРєСѓС‰РёРј РїРѕР»СЊР·РѕРІР°С‚РµР»РµРј
        var count = 0;
        for (final doc in snapshot.docs) {
          final data = doc.data();
          final readByData = data['readBy'] as List<dynamic>? ?? [];
          final readBy = List<String>.from(readByData);
          if (!readBy.contains(userId)) {
            count++;
          }
        }
        return count;
      });

  /// РџРѕР»СѓС‡РёС‚СЊ С‡Р°С‚С‹ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ РєР°Рє Stream
  Stream<List<Chat>> getUserChatsStream(String userId) {
    try {
      return _firestore
          .collection(_chatsCollection)
          .where('participants', arrayContains: userId)
          .orderBy('updatedAt', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs.map(Chat.fromDocument).toList());
    } on Exception {
      // Р’РѕР·РІСЂР°С‰Р°РµРј С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РІ СЃР»СѓС‡Р°Рµ РѕС€РёР±РєРё
      return Stream.value([]);
    }
  }

  /// РЎРѕР·РґР°С‚СЊ РЅРѕРІС‹Р№ С‡Р°С‚
  Future<String> createChat({
    required List<String> participants,
    required Map<String, String> participantNames,
    Map<String, String>? participantAvatars,
    String? name,
  }) async {
    try {
      final chat = Chat(
        id: '',
        customerId: participants.first,
        specialistId: participants.length > 1 ? participants[1] : participants.first,
        name: name ?? '',
        participants: participants,
        participantNames: participantNames,
        participantAvatars: participantAvatars ?? {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_chatsCollection).add(chat.toMap());
      return docRef.id;
    } on Exception catch (e) {
      throw Exception('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ С‡Р°С‚Р°: $e');
    }
  }

  /// РћР±РЅРѕРІРёС‚СЊ С‡Р°С‚
  Future<void> updateChat(String chatId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        ...updates,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } on Exception catch (e) {
      throw Exception('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ С‡Р°С‚Р°: $e');
    }
  }

  /// РЈРґР°Р»РёС‚СЊ С‡Р°С‚
  Future<void> deleteChat(String chatId) async {
    try {
      // РЈРґР°Р»СЏРµРј РІСЃРµ СЃРѕРѕР±С‰РµРЅРёСЏ С‡Р°С‚Р°
      final messagesSnapshot =
          await _firestore.collection(_messagesCollection).where('chatId', isEqualTo: chatId).get();

      final batch = _firestore.batch();
      for (final doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // РЈРґР°Р»СЏРµРј СЃР°Рј С‡Р°С‚
      batch.delete(_firestore.collection(_chatsCollection).doc(chatId));
      await batch.commit();
    } on Exception catch (e) {
      throw Exception('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ С‡Р°С‚Р°: $e');
    }
  }

  /// РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РґР»СЏ С‡Р°С‚РѕРІ
  List<Chat> _getTestChats(String userId) {
    final now = DateTime.now();
    return [
      Chat(
        id: '1',
        customerId: userId,
        specialistId: 'user2',
        name: '',
        participants: [userId, 'user2'],
        participantNames: {
          userId: 'Р’С‹',
          'user2': 'РђРЅРЅР° РџРµС‚СЂРѕРІР°',
        },
        participantAvatars: {
          'user2': 'https://placehold.co/100x100/4CAF50/white?text=AP',
        },
        lastMessageContent: 'РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р»РёС‡РЅСѓСЋ СЂР°Р±РѕС‚Сѓ!',
        lastMessageTime: now.subtract(const Duration(minutes: 30)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(minutes: 30)),
      ),
      Chat(
        id: '2',
        customerId: userId,
        specialistId: 'user3',
        name: '',
        participants: [userId, 'user3'],
        participantNames: {
          userId: 'Р’С‹',
          'user3': 'РњРёС…Р°РёР» РЎРѕРєРѕР»РѕРІ',
        },
        participantAvatars: {
          'user3': 'https://placehold.co/100x100/2196F3/white?text=MS',
        },
        lastMessageContent: 'РљРѕРіРґР° РјРѕР¶РµРј РІСЃС‚СЂРµС‚РёС‚СЊСЃСЏ?',
        lastMessageTime: now.subtract(const Duration(hours: 2)),
        unreadCount: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      Chat(
        id: '3',
        customerId: userId,
        specialistId: 'user4',
        name: '',
        participants: [userId, 'user4'],
        participantNames: {
          userId: 'Р’С‹',
          'user4': 'Р•Р»РµРЅР° РљРѕР·Р»РѕРІР°',
        },
        participantAvatars: {
          'user4': 'https://placehold.co/100x100/FF9800/white?text=EK',
        },
        lastMessageContent: 'РћС‚РїСЂР°РІР»СЋ С„РѕС‚Рѕ Р·Р°РІС‚СЂР°',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 1,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}

