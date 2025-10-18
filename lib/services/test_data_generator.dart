import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ РіРµРЅРµСЂР°С†РёРё С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…
class TestDataGenerator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Р“РµРЅРµСЂР°С†РёСЏ РІСЃРµС… С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…
  static Future<void> generateAllTestData() async {
    try {
      debugPrint('рџљЂ РќР°С‡РёРЅР°РµРј РіРµРЅРµСЂР°С†РёСЋ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…...');

      // РћС‡РёСЃС‚РєР° СЃСѓС‰РµСЃС‚РІСѓСЋС‰РёС… РґР°РЅРЅС‹С…
      await _clearTestData();

      // Р“РµРЅРµСЂР°С†РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ Рё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
      await _generateUsersAndSpecialists();

      // Р“РµРЅРµСЂР°С†РёСЏ РїРѕСЃС‚РѕРІ Р»РµРЅС‚С‹
      await _generateFeedPosts();

      // Р“РµРЅРµСЂР°С†РёСЏ РёРґРµР№
      await _generateIdeas();

      // Р“РµРЅРµСЂР°С†РёСЏ СѓРІРµРґРѕРјР»РµРЅРёР№
      await _generateNotifications();

      // Р“РµРЅРµСЂР°С†РёСЏ С‡Р°С‚РѕРІ
      await _generateChats();

      // Р“РµРЅРµСЂР°С†РёСЏ Р·Р°СЏРІРѕРє
      await _generateRequests();

      debugPrint('вњ… Р’СЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ СѓСЃРїРµС€РЅРѕ СЃРіРµРЅРµСЂРёСЂРѕРІР°РЅС‹!');
    } on Exception catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РіРµРЅРµСЂР°С†РёРё С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…: $e');
    }
  }

  /// РћС‡РёСЃС‚РєР° С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…
  static Future<void> _clearTestData() async {
    final collections = [
      'users',
      'specialists',
      'feed',
      'ideas',
      'notifications',
      'chats',
      'requests',
    ];

    for (final collection in collections) {
      try {
        final snapshot = await _firestore.collection(collection).get();
        final batch = _firestore.batch();

        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();
        debugPrint('рџ§№ РћС‡РёС‰РµРЅР° РєРѕР»Р»РµРєС†РёСЏ: $collection');
      } on Exception catch (e) {
        debugPrint('вљ пёЏ РћС€РёР±РєР° РѕС‡РёСЃС‚РєРё РєРѕР»Р»РµРєС†РёРё $collection: $e');
      }
    }
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ Рё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  static Future<void> _generateUsersAndSpecialists() async {
    final users = [
      {
        'id': 'user_1',
        'name': 'РђРЅРЅР° РџРµС‚СЂРѕРІР°',
        'email': 'anna@example.com',
        'avatar': 'https://picsum.photos/200/200?random=1',
        'city': 'РњРѕСЃРєРІР°',
        'isSpecialist': true,
        'category': 'Р¤РѕС‚РѕРіСЂР°С„',
        'rating': 4.8,
        'pricePerHour': 2500,
        'description':
            'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ С„РѕС‚РѕРіСЂР°С„ СЃ 5-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРїРµС†РёР°Р»РёР·РёСЂСѓСЋСЃСЊ РЅР° СЃРІР°РґРµР±РЅРѕР№ Рё РїРѕСЂС‚СЂРµС‚РЅРѕР№ С„РѕС‚РѕРіСЂР°С„РёРё.',
      },
      {
        'id': 'user_2',
        'name': 'РњРёС…Р°РёР» РЎРѕРєРѕР»РѕРІ',
        'email': 'mikhail@example.com',
        'avatar': 'https://picsum.photos/200/200?random=2',
        'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'isSpecialist': true,
        'category': 'Р’РёРґРµРѕРіСЂР°С„',
        'rating': 4.9,
        'pricePerHour': 3000,
        'description': 'РљСЂРµР°С‚РёРІРЅС‹Р№ РІРёРґРµРѕРіСЂР°С„, СЃРѕР·РґР°СЋ РЅРµР·Р°Р±С‹РІР°РµРјС‹Рµ РІРёРґРµРѕ РґР»СЏ Р»СЋР±С‹С… СЃРѕР±С‹С‚РёР№.',
      },
      {
        'id': 'user_3',
        'name': 'Р•Р»РµРЅР° РљРѕР·Р»РѕРІР°',
        'email': 'elena@example.com',
        'avatar': 'https://picsum.photos/200/200?random=3',
        'city': 'РњРѕСЃРєРІР°',
        'isSpecialist': true,
        'category': 'РћСЂРіР°РЅРёР·Р°С‚РѕСЂ',
        'rating': 4.7,
        'pricePerHour': 2000,
        'description': 'РћРїС‹С‚РЅС‹Р№ РѕСЂРіР°РЅРёР·Р°С‚РѕСЂ РјРµСЂРѕРїСЂРёСЏС‚РёР№. РџРѕРјРѕРіСѓ СЃРґРµР»Р°С‚СЊ РІР°С€Рµ СЃРѕР±С‹С‚РёРµ РЅРµР·Р°Р±С‹РІР°РµРјС‹Рј!',
      },
      {
        'id': 'user_4',
        'name': 'Р”РјРёС‚СЂРёР№ Р’РѕР»РєРѕРІ',
        'email': 'dmitry@example.com',
        'avatar': 'https://picsum.photos/200/200?random=4',
        'city': 'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
        'isSpecialist': true,
        'category': 'Р”РёРґР¶РµР№',
        'rating': 4.6,
        'pricePerHour': 1500,
        'description':
            'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ РґРёРґР¶РµР№ СЃ РѕС‚Р»РёС‡РЅРѕР№ РјСѓР·С‹РєР°Р»СЊРЅРѕР№ РєРѕР»Р»РµРєС†РёРµР№ Рё РєР°С‡РµСЃС‚РІРµРЅРЅС‹Рј РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµРј.',
      },
      {
        'id': 'user_5',
        'name': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
        'email': 'olga@example.com',
        'avatar': 'https://picsum.photos/200/200?random=5',
        'city': 'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
        'isSpecialist': true,
        'category': 'Р”РµРєРѕСЂР°С‚РѕСЂ',
        'rating': 4.8,
        'pricePerHour': 1800,
        'description': 'РўР°Р»Р°РЅС‚Р»РёРІС‹Р№ РґРµРєРѕСЂР°С‚РѕСЂ, СЃРѕР·РґР°СЋ СѓРЅРёРєР°Р»СЊРЅС‹Рµ РёРЅС‚РµСЂСЊРµСЂС‹ РґР»СЏ РІР°С€РёС… РјРµСЂРѕРїСЂРёСЏС‚РёР№.',
      },
    ];

    for (final userData in users) {
      await _firestore.collection('users').doc(userData['id']! as String).set({
        'name': userData['name'],
        'email': userData['email'],
        'avatar': userData['avatar'],
        'city': userData['city'],
        'isSpecialist': userData['isSpecialist'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (userData['isSpecialist'] == true) {
        await _firestore.collection('specialists').doc(userData['id']! as String).set({
          'name': userData['name'],
          'email': userData['email'],
          'imageUrl': userData['avatar'],
          'city': userData['city'],
          'category': userData['category'],
          'rating': userData['rating'],
          'pricePerHour': userData['pricePerHour'],
          'description': userData['description'],
          'isVerified': true,
          'reviewCount': 25,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    debugPrint('рџ‘Ґ РЎРѕР·РґР°РЅРѕ ${users.length} РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ Рё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ');
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ РїРѕСЃС‚РѕРІ Р»РµРЅС‚С‹
  static Future<void> _generateFeedPosts() async {
    final posts = [
      {
        'authorId': 'user_1',
        'authorName': 'РђРЅРЅР° РџРµС‚СЂРѕРІР°',
        'authorAvatar': 'https://picsum.photos/200/200?random=1',
        'description': 'РљСЂР°СЃРёРІР°СЏ СЃРІР°РґРµР±РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РІ РїР°СЂРєРµ рџЊё #СЃРІР°РґСЊР±Р° #С„РѕС‚РѕРіСЂР°С„ #Р»СЋР±РѕРІСЊ',
        'imageUrl': 'https://picsum.photos/400/400?random=10',
        'location': 'РњРѕСЃРєРІР°',
        'likeCount': 45,
        'commentCount': 8,
      },
      {
        'authorId': 'user_2',
        'authorName': 'РњРёС…Р°РёР» РЎРѕРєРѕР»РѕРІ',
        'authorAvatar': 'https://picsum.photos/200/200?random=2',
        'description': 'РќРѕРІС‹Р№ РєР»РёРї РіРѕС‚РѕРІ! РЎРїР°СЃРёР±Рѕ Р·Р° РґРѕРІРµСЂРёРµ рџЋ¬ #РІРёРґРµРѕРіСЂР°С„ #РєР»РёРї #С‚РІРѕСЂС‡РµСЃС‚РІРѕ',
        'imageUrl': 'https://picsum.photos/400/400?random=11',
        'location': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'likeCount': 32,
        'commentCount': 5,
      },
      {
        'authorId': 'user_3',
        'authorName': 'Р•Р»РµРЅР° РљРѕР·Р»РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200/200?random=3',
        'description':
            'РћСЂРіР°РЅРёР·РѕРІР°Р»Р° РєРѕСЂРїРѕСЂР°С‚РёРІ РЅР° 100 С‡РµР»РѕРІРµРє. Р’СЃРµ РїСЂРѕС€Р»Рѕ РёРґРµР°Р»СЊРЅРѕ! рџЋ‰ #РєРѕСЂРїРѕСЂР°С‚РёРІ #РѕСЂРіР°РЅРёР·Р°С‚РѕСЂ',
        'imageUrl': 'https://picsum.photos/400/400?random=12',
        'location': 'РњРѕСЃРєРІР°',
        'likeCount': 28,
        'commentCount': 3,
      },
      {
        'authorId': 'user_4',
        'authorName': 'Р”РјРёС‚СЂРёР№ Р’РѕР»РєРѕРІ',
        'authorAvatar': 'https://picsum.photos/200/200?random=4',
        'description': 'РћС‚Р»РёС‡РЅР°СЏ РІРµС‡РµСЂРёРЅРєР°! РњСѓР·С‹РєР° Р±С‹Р»Р° РЅР° РІС‹СЃРѕС‚Рµ рџЋµ #РґРёРґР¶РµР№ #РІРµС‡РµСЂРёРЅРєР° #РјСѓР·С‹РєР°',
        'imageUrl': 'https://picsum.photos/400/400?random=13',
        'location': 'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
        'likeCount': 19,
        'commentCount': 2,
      },
      {
        'authorId': 'user_5',
        'authorName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200/200?random=5',
        'description': 'Р”РµРєРѕСЂ РґР»СЏ РґРµС‚СЃРєРѕРіРѕ РґРЅСЏ СЂРѕР¶РґРµРЅРёСЏ РіРѕС‚РѕРІ! рџЋ€ #РґРµРєРѕСЂ #РґРµРЅСЊСЂРѕР¶РґРµРЅРёСЏ #РґРµС‚Рё',
        'imageUrl': 'https://picsum.photos/400/400?random=14',
        'location': 'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
        'likeCount': 36,
        'commentCount': 7,
      },
    ];

    for (final postData in posts) {
      await _firestore.collection('feed').add({
        'authorId': postData['authorId'],
        'authorName': postData['authorName'],
        'authorAvatar': postData['authorAvatar'],
        'description': postData['description'],
        'imageUrl': postData['imageUrl'],
        'location': postData['location'],
        'likeCount': postData['likeCount'],
        'commentCount': postData['commentCount'],
        'isLiked': false,
        'isSaved': false,
        'isFollowing': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('рџ“± РЎРѕР·РґР°РЅРѕ ${posts.length} РїРѕСЃС‚РѕРІ РІ Р»РµРЅС‚Рµ');
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ РёРґРµР№
  static Future<void> _generateIdeas() async {
    final ideas = [
      {
        'title': 'РЎРІР°РґРµР±РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РІ СЃС‚РёР»Рµ СЂРµС‚СЂРѕ',
        'description':
            'РРґРµСЏ РґР»СЏ СЃРѕР·РґР°РЅРёСЏ Р°С‚РјРѕСЃС„РµСЂРЅС‹С… С„РѕС‚РѕРіСЂР°С„РёР№ РІ РІРёРЅС‚Р°Р¶РЅРѕРј СЃС‚РёР»Рµ СЃ РёСЃРїРѕР»СЊР·РѕРІР°РЅРёРµРј СЃС‚Р°СЂРёРЅРЅС‹С… Р°РІС‚РѕРјРѕР±РёР»РµР№ Рё РєРѕСЃС‚СЋРјРѕРІ.',
        'imageUrl': 'https://picsum.photos/300/400?random=20',
        'authorId': 'user_1',
        'authorName': 'РђРЅРЅР° РџРµС‚СЂРѕРІР°',
        'authorAvatar': 'https://picsum.photos/200/200?random=1',
        'likeCount': 15,
        'commentCount': 3,
      },
      {
        'title': 'РљРѕСЂРїРѕСЂР°С‚РёРІ РІ СЃС‚РёР»Рµ 80-С…',
        'description':
            'РћСЂРіР°РЅРёР·Р°С†РёСЏ С‚РµРјР°С‚РёС‡РµСЃРєРѕРіРѕ РєРѕСЂРїРѕСЂР°С‚РёРІР° СЃ РјСѓР·С‹РєРѕР№, РєРѕСЃС‚СЋРјР°РјРё Рё РґРµРєРѕСЂРѕРј РІ СЃС‚РёР»Рµ РґРёСЃРєРѕ.',
        'imageUrl': 'https://picsum.photos/300/400?random=21',
        'authorId': 'user_3',
        'authorName': 'Р•Р»РµРЅР° РљРѕР·Р»РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200/200?random=3',
        'likeCount': 22,
        'commentCount': 5,
      },
      {
        'title': 'Р”РµС‚СЃРєРёР№ РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ СЃ РєР»РѕСѓРЅР°РјРё',
        'description':
            'Р’РµСЃРµР»Р°СЏ РїСЂРѕРіСЂР°РјРјР° СЃ Р°РЅРёРјР°С‚РѕСЂР°РјРё, РєР»РѕСѓРЅР°РјРё Рё РєРѕРЅРєСѓСЂСЃР°РјРё РґР»СЏ РґРµС‚РµР№ РѕС‚ 5 РґРѕ 10 Р»РµС‚.',
        'imageUrl': 'https://picsum.photos/300/400?random=22',
        'authorId': 'user_5',
        'authorName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200/200?random=5',
        'likeCount': 18,
        'commentCount': 4,
      },
      {
        'title': 'Р’РёРґРµРѕ-РєР»РёРї РІ СЃС‚РёР»Рµ РєРёР±РµСЂРїР°РЅРє',
        'description':
            'РЎРѕР·РґР°РЅРёРµ С„СѓС‚СѓСЂРёСЃС‚РёС‡РµСЃРєРѕРіРѕ РІРёРґРµРѕ СЃ РЅРµРѕРЅРѕРІС‹РјРё СЌС„С„РµРєС‚Р°РјРё Рё СЃРѕРІСЂРµРјРµРЅРЅРѕР№ РјСѓР·С‹РєРѕР№.',
        'imageUrl': 'https://picsum.photos/300/400?random=23',
        'authorId': 'user_2',
        'authorName': 'РњРёС…Р°РёР» РЎРѕРєРѕР»РѕРІ',
        'authorAvatar': 'https://picsum.photos/200/200?random=2',
        'likeCount': 31,
        'commentCount': 8,
      },
      {
        'title': 'Р’РµС‡РµСЂРёРЅРєР° РїРѕРґ РѕС‚РєСЂС‹С‚С‹Рј РЅРµР±РѕРј',
        'description':
            'РћСЂРіР°РЅРёР·Р°С†РёСЏ Р»РµС‚РЅРµР№ РІРµС‡РµСЂРёРЅРєРё СЃ Р¶РёРІРѕР№ РјСѓР·С‹РєРѕР№, Р±Р°СЂР±РµРєСЋ Рё С‚Р°РЅС†Р°РјРё РїРѕРґ Р·РІРµР·РґР°РјРё.',
        'imageUrl': 'https://picsum.photos/300/400?random=24',
        'authorId': 'user_4',
        'authorName': 'Р”РјРёС‚СЂРёР№ Р’РѕР»РєРѕРІ',
        'authorAvatar': 'https://picsum.photos/200/200?random=4',
        'likeCount': 27,
        'commentCount': 6,
      },
    ];

    for (final ideaData in ideas) {
      await _firestore.collection('ideas').add({
        'title': ideaData['title'],
        'description': ideaData['description'],
        'imageUrl': ideaData['imageUrl'],
        'authorId': ideaData['authorId'],
        'authorName': ideaData['authorName'],
        'authorAvatar': ideaData['authorAvatar'],
        'likeCount': ideaData['likeCount'],
        'commentCount': ideaData['commentCount'],
        'isLiked': false,
        'isSaved': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('рџ’Ў РЎРѕР·РґР°РЅРѕ ${ideas.length} РёРґРµР№');
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ СѓРІРµРґРѕРјР»РµРЅРёР№
  static Future<void> _generateNotifications() async {
    final notifications = [
      {
        'userId': 'user_1',
        'title': 'РќРѕРІС‹Р№ Р»Р°Р№Рє',
        'body': 'РђРЅРЅР° РџРµС‚СЂРѕРІР° РїРѕСЃС‚Р°РІРёР»Р° Р»Р°Р№Рє РІР°С€РµРјСѓ РїРѕСЃС‚Сѓ',
        'type': 'like',
        'data': 'post_1',
      },
      {
        'userId': 'user_2',
        'title': 'РќРѕРІС‹Р№ РєРѕРјРјРµРЅС‚Р°СЂРёР№',
        'body': 'РњРёС…Р°РёР» РЎРѕРєРѕР»РѕРІ РїСЂРѕРєРѕРјРјРµРЅС‚РёСЂРѕРІР°Р» РІР°С€Сѓ РёРґРµСЋ',
        'type': 'comment',
        'data': 'idea_1',
      },
      {
        'userId': 'user_3',
        'title': 'РќРѕРІР°СЏ РїРѕРґРїРёСЃРєР°',
        'body': 'Р•Р»РµРЅР° РљРѕР·Р»РѕРІР° РїРѕРґРїРёСЃР°Р»Р°СЃСЊ РЅР° РІР°СЃ',
        'type': 'follow',
        'data': 'user_3',
      },
      {
        'userId': 'user_4',
        'title': 'РќРѕРІР°СЏ Р·Р°СЏРІРєР°',
        'body': 'РЈ РІР°СЃ РЅРѕРІР°СЏ Р·Р°СЏРІРєР° РЅР° СѓСЃР»СѓРіРё РґРёРґР¶РµСЏ',
        'type': 'request',
        'data': 'request_1',
      },
      {
        'userId': 'user_5',
        'title': 'РќРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
        'body': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР° РЅР°РїРёСЃР°Р»Р° РІР°Рј СЃРѕРѕР±С‰РµРЅРёРµ',
        'type': 'message',
        'data': 'chat_1',
      },
    ];

    for (final notificationData in notifications) {
      await _firestore.collection('notifications').add({
        'userId': notificationData['userId'],
        'title': notificationData['title'],
        'body': notificationData['body'],
        'type': notificationData['type'],
        'data': notificationData['data'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('рџ”” РЎРѕР·РґР°РЅРѕ ${notifications.length} СѓРІРµРґРѕРјР»РµРЅРёР№');
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ С‡Р°С‚РѕРІ
  static Future<void> _generateChats() async {
    final chats = [
      {
        'id': 'chat_1',
        'members': ['user_1', 'user_2'],
        'lastMessage': 'РџСЂРёРІРµС‚! РљРѕРіРґР° РјРѕР¶РµРј РІСЃС‚СЂРµС‚РёС‚СЊСЃСЏ?',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 2,
      },
      {
        'id': 'chat_2',
        'members': ['user_3', 'user_4'],
        'lastMessage': 'РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р»РёС‡РЅСѓСЋ СЂР°Р±РѕС‚Сѓ!',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      },
    ];

    for (final chatData in chats) {
      await _firestore.collection('chats').doc(chatData['id']! as String).set({
        'members': chatData['members'],
        'lastMessage': chatData['lastMessage'],
        'lastMessageTime': chatData['lastMessageTime'],
        'unreadCount': chatData['unreadCount'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('рџ’¬ РЎРѕР·РґР°РЅРѕ ${chats.length} С‡Р°С‚РѕРІ');
  }

  /// Р“РµРЅРµСЂР°С†РёСЏ Р·Р°СЏРІРѕРє
  static Future<void> _generateRequests() async {
    final requests = [
      {
        'customerId': 'user_1',
        'specialistId': 'user_2',
        'title': 'РЎСЉРµРјРєР° РєРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРіРѕ РІРёРґРµРѕ',
        'description': 'РќСѓР¶РЅРѕ СЃРЅСЏС‚СЊ РїСЂРѕРјРѕ-СЂРѕР»РёРє РґР»СЏ РєРѕРјРїР°РЅРёРё',
        'status': 'pending',
        'price': 15000,
        'eventDate': FieldValue.serverTimestamp(),
      },
      {
        'customerId': 'user_3',
        'specialistId': 'user_4',
        'title': 'Р”РёРґР¶РµР№ РЅР° СЃРІР°РґСЊР±Сѓ',
        'description': 'РС‰РµРј РґРёРґР¶РµСЏ РЅР° СЃРІР°РґРµР±РЅРѕРµ С‚РѕСЂР¶РµСЃС‚РІРѕ',
        'status': 'accepted',
        'price': 8000,
        'eventDate': FieldValue.serverTimestamp(),
      },
    ];

    for (final requestData in requests) {
      await _firestore.collection('requests').add({
        'customerId': requestData['customerId'],
        'specialistId': requestData['specialistId'],
        'title': requestData['title'],
        'description': requestData['description'],
        'status': requestData['status'],
        'price': requestData['price'],
        'eventDate': requestData['eventDate'],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    debugPrint('рџ“‹ РЎРѕР·РґР°РЅРѕ ${requests.length} Р·Р°СЏРІРѕРє');
  }
}

