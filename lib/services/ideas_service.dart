import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/foundation.dart';

import '../models/idea.dart';
import 'package:flutter/foundation.dart';
import '../repositories/ideas_repository.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЂР°Р±РѕС‚С‹ СЃ РёРґРµСЏРјРё
class IdeasService {
  factory IdeasService() => _instance;
  IdeasService._internal();
  static final IdeasService _instance = IdeasService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final IdeasRepository _repository = IdeasRepository();

  /// РџРѕР»СѓС‡РµРЅРёРµ РІСЃРµС… РёРґРµР№ СЃ С„РёР»СЊС‚СЂР°С†РёРµР№
  Stream<List<Idea>> getIdeas({
    String? category,
    String? searchQuery,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) =>
      _repository.streamList(
        category: category,
        searchQuery: searchQuery,
        limit: limit,
        startAfter: startAfter,
      );

  /// РџРѕР»СѓС‡РµРЅРёРµ РёРґРµР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<List<Idea>> getUserIdeas(String userId) => _repository.getUserIdeas(userId);

  /// РџРѕР»СѓС‡РµРЅРёРµ СЃРѕС…СЂР°РЅРµРЅРЅС‹С… РёРґРµР№ РїРѕР»СЊР·РѕРІР°С‚РµР»СЏ
  Stream<List<Idea>> getSavedIdeas(String userId) => _repository.getSavedIdeas(userId);

  /// РџРѕР»СѓС‡РµРЅРёРµ РєРѕРЅРєСЂРµС‚РЅРѕР№ РёРґРµРё
  Future<Idea?> getIdea(String ideaId) async => _repository.getById(ideaId);

  /// РЎРѕР·РґР°РЅРёРµ РЅРѕРІРѕР№ РёРґРµРё
  Future<String?> createIdea({
    required String title,
    required String description,
    required String category,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required File mediaFile,
    required bool isVideo,
    List<String> tags = const [],
    String? location,
    double? price,
    String? priceCurrency,
    int? duration,
    List<String> requiredSkills = const [],
  }) async {
    try {
      // Р—Р°РіСЂСѓР·РєР° РјРµРґРёР° С„Р°Р№Р»Р°
      final mediaUrl = await _uploadMediaFile(mediaFile, isVideo);
      if (mediaUrl == null) {
        throw Exception('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РјРµРґРёР° С„Р°Р№Р»Р°');
      }

      // РЎРѕР·РґР°РЅРёРµ РґРѕРєСѓРјРµРЅС‚Р° РёРґРµРё
      final ideaData = {
        'title': title,
        'description': description,
        'category': category,
        'mediaUrl': mediaUrl,
        'isVideo': isVideo,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'commentsCount': 0,
        'savesCount': 0,
        'sharesCount': 0,
        'tags': tags,
        'likedBy': [],
        'savedBy': [],
        'sharedBy': [],
        'isPublic': true,
        'location': location,
        'price': price,
        'priceCurrency': priceCurrency,
        'duration': duration,
        'requiredSkills': requiredSkills,
      };

      final docRef = await _firestore.collection('ideas').add(ideaData);
      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕР·РґР°РЅРёСЏ РёРґРµРё: $e');
      return null;
    }
  }

  /// РћР±РЅРѕРІР»РµРЅРёРµ РёРґРµРё
  Future<bool> updateIdea(String ideaId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('ideas').doc(ideaId).update(updates);
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РѕР±РЅРѕРІР»РµРЅРёСЏ РёРґРµРё: $e');
      return false;
    }
  }

  /// РЈРґР°Р»РµРЅРёРµ РёРґРµРё
  Future<bool> deleteIdea(String ideaId) async {
    try {
      await _firestore.collection('ideas').doc(ideaId).delete();
      return true;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СѓРґР°Р»РµРЅРёСЏ РёРґРµРё: $e');
      return false;
    }
  }

  /// Р›Р°Р№Рє/Р°РЅР»Р°Р№Рє РёРґРµРё
  Future<bool> toggleLike(String ideaId, String userId) async {
    try {
      final docRef = _firestore.collection('ideas').doc(ideaId);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final idea = Idea.fromFirestore(doc);
        final isLiked = idea.isLiked;

        final newLikedBy = <String>[];
        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(docRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р»Р°Р№РєР° РёРґРµРё: $e');
      return false;
    }
  }

  /// РЎРѕС…СЂР°РЅРµРЅРёРµ/СѓРґР°Р»РµРЅРёРµ РёР· СЃРѕС…СЂР°РЅРµРЅРЅС‹С…
  Future<bool> toggleSave(String ideaId, String userId) async {
    try {
      final docRef = _firestore.collection('ideas').doc(ideaId);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final idea = Idea.fromFirestore(doc);
        final isSaved = idea.isSaved;

        final newSavedBy = <String>[];
        if (isSaved) {
          newSavedBy.remove(userId);
        } else {
          newSavedBy.add(userId);
        }

        transaction.update(docRef, {
          'savedBy': newSavedBy,
          'savesCount': newSavedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЃРѕС…СЂР°РЅРµРЅРёСЏ РёРґРµРё: $e');
      return false;
    }
  }

  /// РџРѕРґРµР»РёС‚СЊСЃСЏ РёРґРµРµР№
  Future<bool> shareIdea(String ideaId, String userId) async {
    try {
      final docRef = _firestore.collection('ideas').doc(ideaId);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final idea = Idea.fromFirestore(doc);
        final newSharedBy = <String>[];

        if (!newSharedBy.contains(userId)) {
          newSharedBy.add(userId);
        }

        transaction.update(docRef, {
          'sharedBy': newSharedBy,
          'sharesCount': newSharedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° СЂРµРїРѕСЃС‚Р° РёРґРµРё: $e');
      return false;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ РєРѕРјРјРµРЅС‚Р°СЂРёРµРІ Рє РёРґРµРµ
  Stream<List<Map<String, dynamic>>> getIdeaComments(String ideaId) => _firestore
      .collection('idea_comments')
      .where('ideaId', isEqualTo: ideaId)
      .where('parentCommentId', isNull: true) // С‚РѕР»СЊРєРѕ РѕСЃРЅРѕРІРЅС‹Рµ РєРѕРјРјРµРЅС‚Р°СЂРёРё
      .orderBy('createdAt', descending: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());

  /// Р”РѕР±Р°РІР»РµРЅРёРµ РєРѕРјРјРµРЅС‚Р°СЂРёСЏ
  Future<String?> addComment({
    required String ideaId,
    required String authorId,
    required String authorName,
    String? authorAvatar,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final commentData = {
        'ideaId': ideaId,
        'authorId': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'likesCount': 0,
        'likedBy': [],
        'parentCommentId': parentCommentId,
        'replies': [],
      };

      final docRef = await _firestore.collection('idea_comments').add(commentData);

      // РћР±РЅРѕРІР»СЏРµРј СЃС‡РµС‚С‡РёРє РєРѕРјРјРµРЅС‚Р°СЂРёРµРІ РІ РёРґРµРµ
      await _firestore.collection('ideas').doc(ideaId).update({
        'commentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РґРѕР±Р°РІР»РµРЅРёСЏ РєРѕРјРјРµРЅС‚Р°СЂРёСЏ: $e');
      return null;
    }
  }

  /// Р›Р°Р№Рє РєРѕРјРјРµРЅС‚Р°СЂРёСЏ
  Future<bool> toggleCommentLike(String commentId, String userId) async {
    try {
      final docRef = _firestore.collection('idea_comments').doc(commentId);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists) return false;

        final comment = doc.data();
        const isLiked = false;

        final newLikedBy = <String>[];
        if (isLiked) {
          newLikedBy.remove(userId);
        } else {
          newLikedBy.add(userId);
        }

        transaction.update(docRef, {
          'likedBy': newLikedBy,
          'likesCount': newLikedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р»Р°Р№РєР° РєРѕРјРјРµРЅС‚Р°СЂРёСЏ: $e');
      return false;
    }
  }

  /// Р’С‹Р±РѕСЂ РјРµРґРёР° С„Р°Р№Р»Р°
  Future<File?> pickMediaFile({required bool isVideo}) async {
    try {
      final file = await _imagePicker.pickMedia();

      if (file != null) {
        return File(file.path);
      }
      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РІС‹Р±РѕСЂР° РјРµРґРёР° С„Р°Р№Р»Р°: $e');
      return null;
    }
  }

  /// Р—Р°РіСЂСѓР·РєР° РјРµРґРёР° С„Р°Р№Р»Р° РІ Firebase Storage
  Future<String?> _uploadMediaFile(File file, bool isVideo) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final path = isVideo ? 'ideas/videos/$fileName' : 'ideas/images/$fileName';

      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° Р·Р°РіСЂСѓР·РєРё РјРµРґРёР° С„Р°Р№Р»Р°: $e');
      return null;
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ РїСЂРµРІСЊСЋ РґР»СЏ РІРёРґРµРѕ
  Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await Directory.systemTemp.createTemp()).path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 75,
      );

      if (thumbnailPath != null) {
        final thumbnailFile = File(thumbnailPath);
        return await _uploadMediaFile(thumbnailFile, false);
      }

      return null;
    } on Exception catch (e) {
      debugPrint('РћС€РёР±РєР° РіРµРЅРµСЂР°С†РёРё РїСЂРµРІСЊСЋ РІРёРґРµРѕ: $e');
      return null;
    }
  }

  /// РџРѕР»СѓС‡РµРЅРёРµ С‚СЂРµРЅРґРѕРІС‹С… РёРґРµР№
  Stream<List<Idea>> getTrendingIdeas({int limit = 10}) => _firestore
      .collection('ideas')
      .where('isPublic', isEqualTo: true)
      .orderBy('likesCount', descending: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Idea.fromFirestore).toList());

  /// РџРѕРёСЃРє РёРґРµР№ РїРѕ С‚РµРіР°Рј
  Stream<List<Idea>> searchIdeasByTags(List<String> tags, {int limit = 20}) => _firestore
      .collection('ideas')
      .where('isPublic', isEqualTo: true)
      .where('tags', arrayContainsAny: tags)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Idea.fromFirestore).toList());
}

