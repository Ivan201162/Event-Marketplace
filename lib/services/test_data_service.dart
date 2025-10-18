import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// РЎРµСЂРІРёСЃ РґР»СЏ СЃРѕР·РґР°РЅРёСЏ Рё СѓРїСЂР°РІР»РµРЅРёСЏ С‚РµСЃС‚РѕРІС‹РјРё РґР°РЅРЅС‹РјРё РІ Firestore
class TestDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // РљРѕРЅСЃС‚Р°РЅС‚С‹ РґР»СЏ Р±Р°С‚С‡РµРІС‹С… РѕРїРµСЂР°С†РёР№
  static const int _batchSize = 500;

  // РўРµСЃС‚РѕРІС‹Рµ РїСЂРѕРјРѕР°РєС†РёРё
  final List<Map<String, dynamic>> _testPromotions = [
    {
      'id': 'promo_1',
      'title': 'РЎРєРёРґРєР° 20% РЅР° СЃРІР°РґРµР±РЅСѓСЋ С„РѕС‚РѕСЃСЉРµРјРєСѓ',
      'description':
          'РЎРїРµС†РёР°Р»СЊРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ РґР»СЏ РјРѕР»РѕРґРѕР¶РµРЅРѕРІ! РЎРєРёРґРєР° 20% РЅР° РїРѕР»РЅС‹Р№ РїР°РєРµС‚ СЃРІР°РґРµР±РЅРѕР№ С„РѕС‚РѕСЃСЉРµРјРєРё.',
      'discount': 20,
      'category': 'photographer',
      'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
      'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
      'endDate': '2024-12-31',
      'participants': 15,
      'isParticipating': false,
      'color': Colors.pink,
      'conditions':
          'РђРєС†РёСЏ РґРµР№СЃС‚РІСѓРµС‚ РїСЂРё Р·Р°РєР°Р·Рµ РЅР° СЃСѓРјРјСѓ РѕС‚ 50 000 СЂСѓР±Р»РµР№. РќРµ СЃСѓРјРјРёСЂСѓРµС‚СЃСЏ СЃ РґСЂСѓРіРёРјРё СЃРєРёРґРєР°РјРё.',
      'image': 'https://picsum.photos/400/300?random=101',
    },
    {
      'id': 'promo_2',
      'title': 'Р‘РµСЃРїР»Р°С‚РЅС‹Р№ DJ РЅР° РєРѕСЂРїРѕСЂР°С‚РёРІ',
      'description':
          'РџСЂРё Р·Р°РєР°Р·Рµ РІРµРґСѓС‰РµРіРѕ РЅР° РєРѕСЂРїРѕСЂР°С‚РёРІ - DJ РІ РїРѕРґР°СЂРѕРє! РЎРѕР·РґР°Р№С‚Рµ РЅРµР·Р°Р±С‹РІР°РµРјСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ РґР»СЏ РІР°С€РµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ.',
      'discount': 100,
      'category': 'dj',
      'specialistName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
      'city': 'РњРѕСЃРєРІР°',
      'endDate': '2024-11-30',
      'participants': 8,
      'isParticipating': false,
      'color': Colors.blue,
      'conditions':
          'РњРёРЅРёРјР°Р»СЊРЅС‹Р№ Р·Р°РєР°Р· РІРµРґСѓС‰РµРіРѕ - 40 000 СЂСѓР±Р»РµР№. РђРєС†РёСЏ РґРµР№СЃС‚РІСѓРµС‚ С‚РѕР»СЊРєРѕ РІ Р±СѓРґРЅРёРµ РґРЅРё.',
      'image': 'https://picsum.photos/400/300?random=102',
    },
    {
      'id': 'promo_3',
      'title': 'РЎРµР·РѕРЅРЅР°СЏ СЃРєРёРґРєР° РЅР° РґРµРєРѕСЂР°С†РёРё',
      'description':
          'РћСЃРµРЅРЅСЏСЏ СЃРєРёРґРєР° 30% РЅР° РІСЃРµ РІРёРґС‹ РґРµРєРѕСЂР°С†РёР№ РґР»СЏ РјРµСЂРѕРїСЂРёСЏС‚РёР№. РЈРєСЂР°СЃСЊС‚Рµ РІР°С€ РїСЂР°Р·РґРЅРёРє СЃРѕ СЃРєРёРґРєРѕР№!',
      'discount': 30,
      'category': 'decorator',
      'specialistName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
      'city': 'РњРѕСЃРєРІР°',
      'endDate': '2024-10-31',
      'participants': 23,
      'isParticipating': true,
      'color': Colors.orange,
      'conditions':
          'РЎРєРёРґРєР° СЂР°СЃРїСЂРѕСЃС‚СЂР°РЅСЏРµС‚СЃСЏ РЅР° РІСЃРµ РІРёРґС‹ РґРµРєРѕСЂР°С†РёР№. РњРёРЅРёРјР°Р»СЊРЅС‹Р№ Р·Р°РєР°Р· - 20 000 СЂСѓР±Р»РµР№.',
      'image': 'https://picsum.photos/400/300?random=103',
    },
  ];

  // РўРµСЃС‚РѕРІС‹Рµ СЃРїРµС†РёР°Р»РёСЃС‚С‹
  final List<Map<String, dynamic>> _testSpecialists = [
    {
      'id': 'specialist_1',
      'userId': 'user_1',
      'name': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
      'category': 'host',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.8,
      'priceRange': 'РѕС‚ 30 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=1',
      'description':
          'РћРїС‹С‚ Р±РѕР»РµРµ 7 Р»РµС‚. Р’РµРґСѓ СЃРІР°РґСЊР±С‹ Рё РєРѕСЂРїРѕСЂР°С‚РёРІС‹ СЃ РґСѓС€РѕР№. РЎРѕР·РґР°СЋ РЅРµР·Р°Р±С‹РІР°РµРјСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ РґР»СЏ РІР°С€РµРіРѕ РїСЂР°Р·РґРЅРёРєР°.',
      'about':
          'РћРїС‹С‚ Р±РѕР»РµРµ 7 Р»РµС‚. Р’РµРґСѓ СЃРІР°РґСЊР±С‹ Рё РєРѕСЂРїРѕСЂР°С‚РёРІС‹ СЃ РґСѓС€РѕР№. РЎРѕР·РґР°СЋ РЅРµР·Р°Р±С‹РІР°РµРјСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ РґР»СЏ РІР°С€РµРіРѕ РїСЂР°Р·РґРЅРёРєР°.',
      'availableDates': ['2025-10-10', '2025-10-17', '2025-10-24'],
      'portfolioImages': [
        'https://picsum.photos/400?random=11',
        'https://picsum.photos/400?random=12',
        'https://picsum.photos/400?random=13',
      ],
      'phone': '+7 (999) 123-45-67',
      'email': 'alexey.smirnov@example.com',
      'hourlyRate': 30000.0,
      'price': 30000.0,
      'yearsOfExperience': 7,
      'experienceLevel': 'intermediate',
      'reviewCount': 45,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 365)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_2',
      'userId': 'user_2',
      'name': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
      'category': 'photographer',
      'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
      'rating': 4.9,
      'priceRange': 'РѕС‚ 25 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=2',
      'description':
          'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ С„РѕС‚РѕРіСЂР°С„ СЃ 5-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРїРµС†РёР°Р»РёР·РёСЂСѓСЋСЃСЊ РЅР° СЃРІР°РґРµР±РЅРѕР№ Рё РїРѕСЂС‚СЂРµС‚РЅРѕР№ С„РѕС‚РѕРіСЂР°С„РёРё.',
      'about':
          'РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ С„РѕС‚РѕРіСЂР°С„ СЃ 5-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРїРµС†РёР°Р»РёР·РёСЂСѓСЋСЃСЊ РЅР° СЃРІР°РґРµР±РЅРѕР№ Рё РїРѕСЂС‚СЂРµС‚РЅРѕР№ С„РѕС‚РѕРіСЂР°С„РёРё.',
      'availableDates': ['2025-10-12', '2025-10-19', '2025-10-26'],
      'portfolioImages': [
        'https://picsum.photos/400?random=21',
        'https://picsum.photos/400?random=22',
        'https://picsum.photos/400?random=23',
      ],
      'phone': '+7 (999) 234-56-78',
      'email': 'anna.lebedeva@example.com',
      'hourlyRate': 25000.0,
      'price': 25000.0,
      'yearsOfExperience': 5,
      'experienceLevel': 'intermediate',
      'reviewCount': 32,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 200)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_3',
      'userId': 'user_3',
      'name': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
      'category': 'dj',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.7,
      'priceRange': 'РѕС‚ 20 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=3',
      'description':
          'DJ СЃ 8-Р»РµС‚РЅРёРј СЃС‚Р°Р¶РµРј. РРіСЂР°СЋ РЅР° СЃРІР°РґСЊР±Р°С…, РєРѕСЂРїРѕСЂР°С‚РёРІР°С… Рё С‡Р°СЃС‚РЅС‹С… РІРµС‡РµСЂРёРЅРєР°С…. РЎРѕРІСЂРµРјРµРЅРЅРѕРµ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ.',
      'about':
          'DJ СЃ 8-Р»РµС‚РЅРёРј СЃС‚Р°Р¶РµРј. РРіСЂР°СЋ РЅР° СЃРІР°РґСЊР±Р°С…, РєРѕСЂРїРѕСЂР°С‚РёРІР°С… Рё С‡Р°СЃС‚РЅС‹С… РІРµС‡РµСЂРёРЅРєР°С…. РЎРѕРІСЂРµРјРµРЅРЅРѕРµ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ.',
      'availableDates': ['2025-10-11', '2025-10-18', '2025-10-25'],
      'portfolioImages': [
        'https://picsum.photos/400?random=31',
        'https://picsum.photos/400?random=32',
        'https://picsum.photos/400?random=33',
      ],
      'phone': '+7 (999) 345-67-89',
      'email': 'dmitry.kozlov@example.com',
      'hourlyRate': 20000.0,
      'price': 20000.0,
      'yearsOfExperience': 8,
      'experienceLevel': 'advanced',
      'reviewCount': 28,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 300)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_4',
      'userId': 'user_4',
      'name': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
      'category': 'videographer',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.6,
      'priceRange': 'РѕС‚ 35 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=4',
      'description':
          'Р’РёРґРµРѕРіСЂР°С„ СЃ РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Рј РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµРј. РЎРѕР·РґР°СЋ РєСЂР°СЃРёРІС‹Рµ СЃРІР°РґРµР±РЅС‹Рµ С„РёР»СЊРјС‹ Рё РєРѕСЂРїРѕСЂР°С‚РёРІРЅС‹Рµ СЂРѕР»РёРєРё.',
      'about':
          'Р’РёРґРµРѕРіСЂР°С„ СЃ РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Рј РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµРј. РЎРѕР·РґР°СЋ РєСЂР°СЃРёРІС‹Рµ СЃРІР°РґРµР±РЅС‹Рµ С„РёР»СЊРјС‹ Рё РєРѕСЂРїРѕСЂР°С‚РёРІРЅС‹Рµ СЂРѕР»РёРєРё.',
      'availableDates': ['2025-10-13', '2025-10-20', '2025-10-27'],
      'portfolioImages': [
        'https://picsum.photos/400?random=41',
        'https://picsum.photos/400?random=42',
        'https://picsum.photos/400?random=43',
      ],
      'phone': '+7 (999) 456-78-90',
      'email': 'elena.petrova@example.com',
      'hourlyRate': 35000.0,
      'price': 35000.0,
      'yearsOfExperience': 6,
      'experienceLevel': 'intermediate',
      'reviewCount': 24,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 180)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_5',
      'userId': 'user_5',
      'name': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
      'category': 'decorator',
      'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
      'rating': 4.8,
      'priceRange': 'РѕС‚ 15 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=5',
      'description':
          'Р”РµРєРѕСЂР°С‚РѕСЂ СЃ 6-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРѕР·РґР°СЋ СѓРЅРёРєР°Р»СЊРЅС‹Рµ РёРЅС‚РµСЂСЊРµСЂС‹ РґР»СЏ Р»СЋР±С‹С… РјРµСЂРѕРїСЂРёСЏС‚РёР№.',
      'about': 'Р”РµРєРѕСЂР°С‚РѕСЂ СЃ 6-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРѕР·РґР°СЋ СѓРЅРёРєР°Р»СЊРЅС‹Рµ РёРЅС‚РµСЂСЊРµСЂС‹ РґР»СЏ Р»СЋР±С‹С… РјРµСЂРѕРїСЂРёСЏС‚РёР№.',
      'availableDates': ['2025-10-14', '2025-10-21', '2025-10-28'],
      'portfolioImages': [
        'https://picsum.photos/400?random=51',
        'https://picsum.photos/400?random=52',
        'https://picsum.photos/400?random=53',
      ],
      'phone': '+7 (999) 567-89-01',
      'email': 'mikhail.volkov@example.com',
      'hourlyRate': 15000.0,
      'price': 15000.0,
      'yearsOfExperience': 6,
      'experienceLevel': 'intermediate',
      'reviewCount': 36,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 220)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_6',
      'userId': 'user_6',
      'name': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
      'category': 'host',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.9,
      'priceRange': 'РѕС‚ 40 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=6',
      'description':
          'Event-РјРµРЅРµРґР¶РµСЂ СЃ 10-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РћСЂРіР°РЅРёР·СѓСЋ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ Р»СЋР±РѕР№ СЃР»РѕР¶РЅРѕСЃС‚Рё РѕС‚ Рђ РґРѕ РЇ.',
      'about':
          'Event-РјРµРЅРµРґР¶РµСЂ СЃ 10-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РћСЂРіР°РЅРёР·СѓСЋ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ Р»СЋР±РѕР№ СЃР»РѕР¶РЅРѕСЃС‚Рё РѕС‚ Рђ РґРѕ РЇ.',
      'availableDates': ['2025-10-15', '2025-10-22', '2025-10-29'],
      'portfolioImages': [
        'https://picsum.photos/400?random=61',
        'https://picsum.photos/400?random=62',
        'https://picsum.photos/400?random=63',
      ],
      'phone': '+7 (999) 678-90-12',
      'email': 'olga.morozova@example.com',
      'hourlyRate': 40000.0,
      'price': 40000.0,
      'yearsOfExperience': 10,
      'experienceLevel': 'expert',
      'reviewCount': 52,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 400)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_7',
      'userId': 'user_7',
      'name': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
      'category': 'musician',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.7,
      'priceRange': 'РѕС‚ 25 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=7',
      'description':
          'Р“РёС‚Р°СЂРёСЃС‚ Рё РІРѕРєР°Р»РёСЃС‚. РРіСЂР°СЋ РЅР° СЃРІР°РґСЊР±Р°С… Рё РєРѕСЂРїРѕСЂР°С‚РёРІР°С…. Р РµРїРµСЂС‚СѓР°СЂ РѕС‚ РєР»Р°СЃСЃРёРєРё РґРѕ СЃРѕРІСЂРµРјРµРЅРЅРѕР№ РјСѓР·С‹РєРё.',
      'about':
          'Р“РёС‚Р°СЂРёСЃС‚ Рё РІРѕРєР°Р»РёСЃС‚. РРіСЂР°СЋ РЅР° СЃРІР°РґСЊР±Р°С… Рё РєРѕСЂРїРѕСЂР°С‚РёРІР°С…. Р РµРїРµСЂС‚СѓР°СЂ РѕС‚ РєР»Р°СЃСЃРёРєРё РґРѕ СЃРѕРІСЂРµРјРµРЅРЅРѕР№ РјСѓР·С‹РєРё.',
      'availableDates': ['2025-10-16', '2025-10-23', '2025-10-30'],
      'portfolioImages': [
        'https://picsum.photos/400?random=71',
        'https://picsum.photos/400?random=72',
        'https://picsum.photos/400?random=73',
      ],
      'phone': '+7 (999) 789-01-23',
      'email': 'sergey.novikov@example.com',
      'hourlyRate': 25000.0,
      'price': 25000.0,
      'yearsOfExperience': 9,
      'experienceLevel': 'advanced',
      'reviewCount': 31,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 350)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_8',
      'userId': 'user_8',
      'name': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
      'category': 'florist',
      'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
      'rating': 4.8,
      'priceRange': 'РѕС‚ 12 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=8',
      'description':
          'Р¤Р»РѕСЂРёСЃС‚-РґРµРєРѕСЂР°С‚РѕСЂ СЃ 4-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРѕР·РґР°СЋ СѓРЅРёРєР°Р»СЊРЅС‹Рµ С†РІРµС‚РѕС‡РЅС‹Рµ РєРѕРјРїРѕР·РёС†РёРё РґР»СЏ Р»СЋР±С‹С… СЃРѕР±С‹С‚РёР№.',
      'about':
          'Р¤Р»РѕСЂРёСЃС‚-РґРµРєРѕСЂР°С‚РѕСЂ СЃ 4-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРѕР·РґР°СЋ СѓРЅРёРєР°Р»СЊРЅС‹Рµ С†РІРµС‚РѕС‡РЅС‹Рµ РєРѕРјРїРѕР·РёС†РёРё РґР»СЏ Р»СЋР±С‹С… СЃРѕР±С‹С‚РёР№.',
      'availableDates': ['2025-10-17', '2025-10-24', '2025-10-31'],
      'portfolioImages': [
        'https://picsum.photos/400?random=81',
        'https://picsum.photos/400?random=82',
        'https://picsum.photos/400?random=83',
      ],
      'phone': '+7 (999) 890-12-34',
      'email': 'tatyana.sokolova@example.com',
      'hourlyRate': 12000.0,
      'price': 12000.0,
      'yearsOfExperience': 4,
      'experienceLevel': 'intermediate',
      'reviewCount': 19,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 150)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_9',
      'userId': 'user_9',
      'name': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
      'category': 'caterer',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.6,
      'priceRange': 'РѕС‚ 50 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=9',
      'description':
          'РЁРµС„-РїРѕРІР°СЂ СЃ 12-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РћСЂРіР°РЅРёР·СѓСЋ РєРµР№С‚РµСЂРёРЅРі РґР»СЏ РјРµСЂРѕРїСЂРёСЏС‚РёР№ Р»СЋР±РѕРіРѕ РјР°СЃС€С‚Р°Р±Р°.',
      'about': 'РЁРµС„-РїРѕРІР°СЂ СЃ 12-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РћСЂРіР°РЅРёР·СѓСЋ РєРµР№С‚РµСЂРёРЅРі РґР»СЏ РјРµСЂРѕРїСЂРёСЏС‚РёР№ Р»СЋР±РѕРіРѕ РјР°СЃС€С‚Р°Р±Р°.',
      'availableDates': ['2025-10-18', '2025-10-25', '2025-11-01'],
      'portfolioImages': [
        'https://picsum.photos/400?random=91',
        'https://picsum.photos/400?random=92',
        'https://picsum.photos/400?random=93',
      ],
      'phone': '+7 (999) 901-23-45',
      'email': 'andrey.fedorov@example.com',
      'hourlyRate': 50000.0,
      'price': 50000.0,
      'yearsOfExperience': 12,
      'experienceLevel': 'expert',
      'reviewCount': 67,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 500)),
      'updatedAt': DateTime.now(),
    },
    {
      'id': 'specialist_10',
      'userId': 'user_10',
      'name': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
      'category': 'makeup',
      'city': 'РњРѕСЃРєРІР°',
      'rating': 4.9,
      'priceRange': 'РѕС‚ 18 000 в‚Ѕ',
      'avatarUrl': 'https://picsum.photos/200?random=10',
      'description':
          'Р’РёР·Р°Р¶РёСЃС‚ Рё СЃС‚РёР»РёСЃС‚ СЃ 6-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРїРµС†РёР°Р»РёР·РёСЂСѓСЋСЃСЊ РЅР° СЃРІР°РґРµР±РЅС‹С… РѕР±СЂР°Р·Р°С… Рё РјР°РєРёСЏР¶Рµ.',
      'about':
          'Р’РёР·Р°Р¶РёСЃС‚ Рё СЃС‚РёР»РёСЃС‚ СЃ 6-Р»РµС‚РЅРёРј РѕРїС‹С‚РѕРј. РЎРїРµС†РёР°Р»РёР·РёСЂСѓСЋСЃСЊ РЅР° СЃРІР°РґРµР±РЅС‹С… РѕР±СЂР°Р·Р°С… Рё РјР°РєРёСЏР¶Рµ.',
      'availableDates': ['2025-10-19', '2025-10-26', '2025-11-02'],
      'portfolioImages': [
        'https://picsum.photos/400?random=101',
        'https://picsum.photos/400?random=102',
        'https://picsum.photos/400?random=103',
      ],
      'phone': '+7 (999) 012-34-56',
      'email': 'maria.kuznetsova@example.com',
      'hourlyRate': 18000.0,
      'price': 18000.0,
      'yearsOfExperience': 6,
      'experienceLevel': 'intermediate',
      'reviewCount': 43,
      'isAvailable': true,
      'isVerified': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 250)),
      'updatedAt': DateTime.now(),
    },
  ];

  // РўРµСЃС‚РѕРІС‹Рµ С‡Р°С‚С‹
  final List<Map<String, dynamic>> _testChats = [
    {
      'specialistId': 'specialist_1',
      'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
      'customerId': 'customer_1',
      'customerName': 'РћР»СЊРіР° РРІР°РЅРѕРІР°',
      'messages': [
        {
          'senderId': 'customer_1',
          'senderName': 'РћР»СЊРіР° РРІР°РЅРѕРІР°',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РРЅС‚РµСЂРµСЃСѓРµС‚ СЃРІР°РґСЊР±Р° 10 РѕРєС‚СЏР±СЂСЏ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_1',
          'senderName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
          'content':
              'Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ! Р”Р°, 10 РѕРєС‚СЏР±СЂСЏ СЃРІРѕР±РѕРґРµРЅ. Р Р°СЃСЃРєР°Р¶РёС‚Рµ РїРѕРґСЂРѕР±РЅРµРµ Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРё.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_1',
          'senderName': 'РћР»СЊРіР° РРІР°РЅРѕРІР°',
          'content': 'РЎРІР°РґСЊР±Р° РЅР° 80 С‡РµР»РѕРІРµРє РІ Р·Р°РіРѕСЂРѕРґРЅРѕРј РєР»СѓР±Рµ. РќСѓР¶РµРЅ РІРµРґСѓС‰РёР№ РЅР° 6 С‡Р°СЃРѕРІ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_1',
          'senderName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
          'content': 'РћС‚Р»РёС‡РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 30 000 в‚Ѕ Р·Р° 6 С‡Р°СЃРѕРІ. Р’РєР»СЋС‡Р°РµС‚ СЃС†РµРЅР°СЂРёР№, РёРіСЂС‹ Рё РєРѕРЅРєСѓСЂСЃС‹.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
          'type': 'text',
        },
        {
          'senderId': 'customer_1',
          'senderName': 'РћР»СЊРіР° РРІР°РЅРѕРІР°',
          'content': 'РџРѕРґС…РѕРґРёС‚! РњРѕР¶РµРј РІСЃС‚СЂРµС‚РёС‚СЊСЃСЏ РґР»СЏ РѕР±СЃСѓР¶РґРµРЅРёСЏ РґРµС‚Р°Р»РµР№?',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_2',
      'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
      'customerId': 'customer_2',
      'customerName': 'РРіРѕСЂСЊ РџРµС‚СЂРѕРІ',
      'messages': [
        {
          'senderId': 'customer_2',
          'senderName': 'РРіРѕСЂСЊ РџРµС‚СЂРѕРІ',
          'content': 'РџСЂРёРІРµС‚! РќСѓР¶РЅР° С„РѕС‚РѕСЃРµСЃСЃРёСЏ РґР»СЏ РєРѕСЂРїРѕСЂР°С‚РёРІР°.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_2',
          'senderName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РљРѕРіРґР° РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_2',
          'senderName': 'РРіРѕСЂСЊ РџРµС‚СЂРѕРІ',
          'content': '12 РѕРєС‚СЏР±СЂСЏ, РІ РѕС„РёСЃРµ РЅР° 50 С‡РµР»РѕРІРµРє.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_2',
          'senderName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
          'content': 'РџРѕРЅСЏС‚РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 25 000 в‚Ѕ Р·Р° 4 С‡Р°СЃР° СЃСЉРµРјРєРё + РѕР±СЂР°Р±РѕС‚РєР° РІСЃРµС… С„РѕС‚Рѕ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_3',
      'specialistName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
      'customerId': 'customer_3',
      'customerName': 'РњР°СЂРёСЏ РЎРёРґРѕСЂРѕРІР°',
      'messages': [
        {
          'senderId': 'customer_3',
          'senderName': 'РњР°СЂРёСЏ РЎРёРґРѕСЂРѕРІР°',
          'content': 'РџСЂРёРІРµС‚! РќСѓР¶РµРЅ DJ РЅР° СЃРІР°РґСЊР±Сѓ 11 РѕРєС‚СЏР±СЂСЏ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_3',
          'senderName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! 11 РѕРєС‚СЏР±СЂСЏ СЃРІРѕР±РѕРґРµРЅ. Р Р°СЃСЃРєР°Р¶РёС‚Рµ Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРё.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_3',
          'senderName': 'РњР°СЂРёСЏ РЎРёРґРѕСЂРѕРІР°',
          'content': 'РЎРІР°РґСЊР±Р° РЅР° 120 С‡РµР»РѕРІРµРє РІ СЂРµСЃС‚РѕСЂР°РЅРµ. РќСѓР¶РЅРѕ РЅР° 6 С‡Р°СЃРѕРІ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_3',
          'senderName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
          'content': 'РћС‚Р»РёС‡РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 20 000 в‚Ѕ Р·Р° 6 С‡Р°СЃРѕРІ. Р’РєР»СЋС‡Р°РµС‚ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ Рё РјСѓР·С‹РєСѓ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_4',
      'specialistName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
      'customerId': 'customer_4',
      'customerName': 'РђР»РµРєСЃР°РЅРґСЂ РљРѕР·Р»РѕРІ',
      'messages': [
        {
          'senderId': 'customer_4',
          'senderName': 'РђР»РµРєСЃР°РЅРґСЂ РљРѕР·Р»РѕРІ',
          'content': 'Р”РѕР±СЂС‹Р№ РґРµРЅСЊ! РќСѓР¶РЅР° РІРёРґРµРѕСЃСЉРµРјРєР° РєРѕСЂРїРѕСЂР°С‚РёРІР°.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_4',
          'senderName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РљРѕРіРґР° РїР»Р°РЅРёСЂСѓРµС‚СЃСЏ РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_4',
          'senderName': 'РђР»РµРєСЃР°РЅРґСЂ РљРѕР·Р»РѕРІ',
          'content': '13 РѕРєС‚СЏР±СЂСЏ, РІ РєРѕРЅС„РµСЂРµРЅС†-Р·Р°Р»Рµ РЅР° 80 С‡РµР»РѕРІРµРє.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_4',
          'senderName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
          'content': 'РџРѕРЅСЏС‚РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 35 000 в‚Ѕ Р·Р° 4 С‡Р°СЃР° СЃСЉРµРјРєРё + РјРѕРЅС‚Р°Р¶ СЂРѕР»РёРєР°.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_5',
      'specialistName': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
      'customerId': 'customer_5',
      'customerName': 'Р•РєР°С‚РµСЂРёРЅР° РњРѕСЂРѕР·РѕРІР°',
      'messages': [
        {
          'senderId': 'customer_5',
          'senderName': 'Р•РєР°С‚РµСЂРёРЅР° РњРѕСЂРѕР·РѕРІР°',
          'content': 'РџСЂРёРІРµС‚! РќСѓР¶РЅРѕ РѕС„РѕСЂРјРёС‚СЊ СЃРІР°РґСЊР±Сѓ РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_5',
          'senderName': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РћС‚Р»РёС‡РЅС‹Р№ РІС‹Р±РѕСЂ СЃС‚РёР»СЏ! РљРѕРіРґР° РјРµСЂРѕРїСЂРёСЏС‚РёРµ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_5',
          'senderName': 'Р•РєР°С‚РµСЂРёРЅР° РњРѕСЂРѕР·РѕРІР°',
          'content': '14 РѕРєС‚СЏР±СЂСЏ, РІ Р·Р°РіРѕСЂРѕРґРЅРѕРј РєР»СѓР±Рµ. РќСѓР¶РЅРѕ РѕС„РѕСЂРјРёС‚СЊ Р·Р°Р» Рё С„РѕС‚РѕР·РѕРЅСѓ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_5',
          'senderName': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
          'content': 'РџРѕРЅСЏС‚РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 15 000 в‚Ѕ Р·Р° РїРѕР»РЅРѕРµ РѕС„РѕСЂРјР»РµРЅРёРµ РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_6',
      'specialistName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
      'customerId': 'customer_6',
      'customerName': 'Р”РјРёС‚СЂРёР№ РЎРѕРєРѕР»РѕРІ',
      'messages': [
        {
          'senderId': 'customer_6',
          'senderName': 'Р”РјРёС‚СЂРёР№ РЎРѕРєРѕР»РѕРІ',
          'content': 'Р”РѕР±СЂС‹Р№ РґРµРЅСЊ! РќСѓР¶РЅР° РѕСЂРіР°РЅРёР·Р°С†РёСЏ РґРµС‚СЃРєРѕРіРѕ РґРЅСЏ СЂРѕР¶РґРµРЅРёСЏ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_6',
          'senderName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РЎ СѓРґРѕРІРѕР»СЊСЃС‚РІРёРµРј РїРѕРјРѕРіСѓ! Р Р°СЃСЃРєР°Р¶РёС‚Рµ РїРѕРґСЂРѕР±РЅРµРµ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_6',
          'senderName': 'Р”РјРёС‚СЂРёР№ РЎРѕРєРѕР»РѕРІ',
          'content': '15 РѕРєС‚СЏР±СЂСЏ, РґР»СЏ 20 РґРµС‚РµР№ 5-7 Р»РµС‚. РўРµРјР°: РїРёСЂР°С‚СЃРєР°СЏ РІРµС‡РµСЂРёРЅРєР°.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_6',
          'senderName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
          'content': 'РћС‚Р»РёС‡РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 40 000 в‚Ѕ Р·Р° РїРѕР»РЅСѓСЋ РѕСЂРіР°РЅРёР·Р°С†РёСЋ РїРёСЂР°С‚СЃРєРѕР№ РІРµС‡РµСЂРёРЅРєРё.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_7',
      'specialistName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
      'customerId': 'customer_7',
      'customerName': 'РђРЅРЅР° Р¤РµРґРѕСЂРѕРІР°',
      'messages': [
        {
          'senderId': 'customer_7',
          'senderName': 'РђРЅРЅР° Р¤РµРґРѕСЂРѕРІР°',
          'content': 'РџСЂРёРІРµС‚! РќСѓР¶РµРЅ РјСѓР·С‹РєР°РЅС‚ РЅР° СЂРѕРјР°РЅС‚РёС‡РµСЃРєРёР№ СѓР¶РёРЅ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_7',
          'senderName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РљР°РєРѕР№ СЂРµРїРµСЂС‚СѓР°СЂ РїСЂРµРґРїРѕС‡РёС‚Р°РµС‚Рµ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_7',
          'senderName': 'РђРЅРЅР° Р¤РµРґРѕСЂРѕРІР°',
          'content': '16 РѕРєС‚СЏР±СЂСЏ, СЂРѕРјР°РЅС‚РёС‡РµСЃРєРёРµ Р±Р°Р»Р»Р°РґС‹ Рё РґР¶Р°Р·. 2 С‡Р°СЃР°.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_7',
          'senderName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
          'content': 'РџРѕРЅСЏС‚РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 25 000 в‚Ѕ Р·Р° 2 С‡Р°СЃР° СЂРѕРјР°РЅС‚РёС‡РµСЃРєРѕР№ РјСѓР·С‹РєРё.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 7, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_8',
      'specialistName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
      'customerId': 'customer_8',
      'customerName': 'РРіРѕСЂСЊ Р›РµР±РµРґРµРІ',
      'messages': [
        {
          'senderId': 'customer_8',
          'senderName': 'РРіРѕСЂСЊ Р›РµР±РµРґРµРІ',
          'content': 'Р”РѕР±СЂС‹Р№ РґРµРЅСЊ! РќСѓР¶РЅС‹ С†РІРµС‚С‹ РґР»СЏ СЃРІР°РґРµР±РЅРѕР№ С†РµСЂРµРјРѕРЅРёРё.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_8',
          'senderName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РљР°РєРѕР№ СЃС‚РёР»СЊ Рё С†РІРµС‚РѕРІР°СЏ РіР°РјРјР°?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_8',
          'senderName': 'РРіРѕСЂСЊ Р›РµР±РµРґРµРІ',
          'content': '17 РѕРєС‚СЏР±СЂСЏ, Р±РµР»С‹Рµ Рё СЂРѕР·РѕРІС‹Рµ СЂРѕР·С‹, РєР»Р°СЃСЃРёС‡РµСЃРєРёР№ СЃС‚РёР»СЊ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_8',
          'senderName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
          'content': 'РћС‚Р»РёС‡РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 12 000 в‚Ѕ Р·Р° РїРѕР»РЅРѕРµ С†РІРµС‚РѕС‡РЅРѕРµ РѕС„РѕСЂРјР»РµРЅРёРµ.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 8, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_9',
      'specialistName': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
      'customerId': 'customer_9',
      'customerName': 'РќР°С‚Р°Р»СЊСЏ РљРѕР·Р»РѕРІР°',
      'messages': [
        {
          'senderId': 'customer_9',
          'senderName': 'РќР°С‚Р°Р»СЊСЏ РљРѕР·Р»РѕРІР°',
          'content': 'РџСЂРёРІРµС‚! РќСѓР¶РµРЅ РєРµР№С‚РµСЂРёРЅРі РґР»СЏ РєРѕСЂРїРѕСЂР°С‚РёРІР°.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_9',
          'senderName': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РЎРєРѕР»СЊРєРѕ С‡РµР»РѕРІРµРє Рё РєР°РєРёРµ РїСЂРµРґРїРѕС‡С‚РµРЅРёСЏ РїРѕ РјРµРЅСЋ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_9',
          'senderName': 'РќР°С‚Р°Р»СЊСЏ РљРѕР·Р»РѕРІР°',
          'content': '18 РѕРєС‚СЏР±СЂСЏ, 100 С‡РµР»РѕРІРµРє, РµРІСЂРѕРїРµР№СЃРєР°СЏ РєСѓС…РЅСЏ, С„СѓСЂС€РµС‚.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_9',
          'senderName': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
          'content': 'РџРѕРЅСЏС‚РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 50 000 в‚Ѕ Р·Р° С„СѓСЂС€РµС‚ РЅР° 100 С‡РµР»РѕРІРµРє.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 9, minutes: 15)),
          'type': 'text',
        },
      ],
    },
    {
      'specialistId': 'specialist_10',
      'specialistName': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
      'customerId': 'customer_10',
      'customerName': 'Р’Р»Р°РґРёРјРёСЂ РџРµС‚СЂРѕРІ',
      'messages': [
        {
          'senderId': 'customer_10',
          'senderName': 'Р’Р»Р°РґРёРјРёСЂ РџРµС‚СЂРѕРІ',
          'content': 'Р”РѕР±СЂС‹Р№ РґРµРЅСЊ! РќСѓР¶РµРЅ РјР°РєРёСЏР¶ РґР»СЏ РЅРµРІРµСЃС‚С‹.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 11)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_10',
          'senderName': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
          'content': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ! РљР°РєРѕР№ СЃС‚РёР»СЊ РјР°РєРёСЏР¶Р° РїСЂРµРґРїРѕС‡РёС‚Р°РµС‚Рµ?',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10, minutes: 45)),
          'type': 'text',
        },
        {
          'senderId': 'customer_10',
          'senderName': 'Р’Р»Р°РґРёРјРёСЂ РџРµС‚СЂРѕРІ',
          'content': '19 РѕРєС‚СЏР±СЂСЏ, РЅР°С‚СѓСЂР°Р»СЊРЅС‹Р№ РјР°РєРёСЏР¶ РґР»СЏ СЃРІР°РґСЊР±С‹.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10, minutes: 30)),
          'type': 'text',
        },
        {
          'senderId': 'specialist_10',
          'senderName': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
          'content': 'РћС‚Р»РёС‡РЅРѕ! РњРѕР№ С‚Р°СЂРёС„ 18 000 в‚Ѕ Р·Р° СЃРІР°РґРµР±РЅС‹Р№ РјР°РєРёСЏР¶.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 10, minutes: 15)),
          'type': 'text',
        },
      ],
    },
  ];

  // РўРµСЃС‚РѕРІС‹Рµ Р·Р°СЏРІРєРё
  final List<Map<String, dynamic>> _testBookings = [
    {
      'eventName': 'РЎРІР°РґСЊР±Р° РћР»СЊРіРё Рё РРіРѕСЂСЏ',
      'date': '2025-10-15',
      'budget': 80000,
      'specialistId': 'specialist_1',
      'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
      'customerId': 'customer_1',
      'customerName': 'РћР»СЊРіР° РРІР°РЅРѕРІР°',
      'status': 'РћР¶РёРґР°РµС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ',
      'description': 'РЎРІР°РґСЊР±Р° РЅР° 80 С‡РµР»РѕРІРµРє РІ Р·Р°РіРѕСЂРѕРґРЅРѕРј РєР»СѓР±Рµ. РќСѓР¶РµРЅ РІРµРґСѓС‰РёР№ РЅР° 6 С‡Р°СЃРѕРІ.',
      'createdAt': DateTime.now().subtract(const Duration(days: 2)),
    },
    {
      'eventName': 'РљРѕСЂРїРѕСЂР°С‚РёРІ IT-РєРѕРјРїР°РЅРёРё',
      'date': '2025-10-12',
      'budget': 50000,
      'specialistId': 'specialist_2',
      'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
      'customerId': 'customer_2',
      'customerName': 'РРіРѕСЂСЊ РџРµС‚СЂРѕРІ',
      'status': 'РџРѕРґС‚РІРµСЂР¶РґРµРЅРѕ',
      'description': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ РІ РѕС„РёСЃРµ РЅР° 50 С‡РµР»РѕРІРµРє.',
      'createdAt': DateTime.now().subtract(const Duration(days: 1)),
    },
    {
      'eventName': 'РЎРІР°РґСЊР±Р° РњР°СЂРёРё Рё Р”РјРёС‚СЂРёСЏ',
      'date': '2025-10-11',
      'budget': 60000,
      'specialistId': 'specialist_3',
      'specialistName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
      'customerId': 'customer_3',
      'customerName': 'РњР°СЂРёСЏ РЎРёРґРѕСЂРѕРІР°',
      'status': 'РџРѕРґС‚РІРµСЂР¶РґРµРЅРѕ',
      'description': 'РЎРІР°РґСЊР±Р° РЅР° 120 С‡РµР»РѕРІРµРє РІ СЂРµСЃС‚РѕСЂР°РЅРµ. РќСѓР¶РµРЅ DJ РЅР° 6 С‡Р°СЃРѕРІ.',
      'createdAt': DateTime.now().subtract(const Duration(days: 3)),
    },
    {
      'eventName': 'РљРѕСЂРїРѕСЂР°С‚РёРІ IT-РєРѕРјРїР°РЅРёРё',
      'date': '2025-10-13',
      'budget': 70000,
      'specialistId': 'specialist_4',
      'specialistName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
      'customerId': 'customer_4',
      'customerName': 'РђР»РµРєСЃР°РЅРґСЂ РљРѕР·Р»РѕРІ',
      'status': 'РћР¶РёРґР°РµС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ',
      'description': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ РІ РєРѕРЅС„РµСЂРµРЅС†-Р·Р°Р»Рµ РЅР° 80 С‡РµР»РѕРІРµРє.',
      'createdAt': DateTime.now().subtract(const Duration(days: 4)),
    },
    {
      'eventName': 'РЎРІР°РґСЊР±Р° РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ',
      'date': '2025-10-14',
      'budget': 45000,
      'specialistId': 'specialist_5',
      'specialistName': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
      'customerId': 'customer_5',
      'customerName': 'Р•РєР°С‚РµСЂРёРЅР° РњРѕСЂРѕР·РѕРІР°',
      'status': 'РџРѕРґС‚РІРµСЂР¶РґРµРЅРѕ',
      'description': 'РЎРІР°РґСЊР±Р° РІ Р·Р°РіРѕСЂРѕРґРЅРѕРј РєР»СѓР±Рµ. РќСѓР¶РЅРѕ РѕС„РѕСЂРјРёС‚СЊ Р·Р°Р» Рё С„РѕС‚РѕР·РѕРЅСѓ РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ.',
      'createdAt': DateTime.now().subtract(const Duration(days: 5)),
    },
    {
      'eventName': 'РџРёСЂР°С‚СЃРєР°СЏ РІРµС‡РµСЂРёРЅРєР°',
      'date': '2025-10-15',
      'budget': 80000,
      'specialistId': 'specialist_6',
      'specialistName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
      'customerId': 'customer_6',
      'customerName': 'Р”РјРёС‚СЂРёР№ РЎРѕРєРѕР»РѕРІ',
      'status': 'РћР¶РёРґР°РµС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ',
      'description': 'Р”РµС‚СЃРєРёР№ РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ РґР»СЏ 20 РґРµС‚РµР№ 5-7 Р»РµС‚. РўРµРјР°: РїРёСЂР°С‚СЃРєР°СЏ РІРµС‡РµСЂРёРЅРєР°.',
      'createdAt': DateTime.now().subtract(const Duration(days: 6)),
    },
    {
      'eventName': 'Р РѕРјР°РЅС‚РёС‡РµСЃРєРёР№ СѓР¶РёРЅ',
      'date': '2025-10-16',
      'budget': 50000,
      'specialistId': 'specialist_7',
      'specialistName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
      'customerId': 'customer_7',
      'customerName': 'РђРЅРЅР° Р¤РµРґРѕСЂРѕРІР°',
      'status': 'РџРѕРґС‚РІРµСЂР¶РґРµРЅРѕ',
      'description': 'Р РѕРјР°РЅС‚РёС‡РµСЃРєРёР№ СѓР¶РёРЅ СЃ Р¶РёРІРѕР№ РјСѓР·С‹РєРѕР№. Р РѕРјР°РЅС‚РёС‡РµСЃРєРёРµ Р±Р°Р»Р»Р°РґС‹ Рё РґР¶Р°Р· РЅР° 2 С‡Р°СЃР°.',
      'createdAt': DateTime.now().subtract(const Duration(days: 7)),
    },
    {
      'eventName': 'РЎРІР°РґРµР±РЅР°СЏ С†РµСЂРµРјРѕРЅРёСЏ',
      'date': '2025-10-17',
      'budget': 30000,
      'specialistId': 'specialist_8',
      'specialistName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
      'customerId': 'customer_8',
      'customerName': 'РРіРѕСЂСЊ Р›РµР±РµРґРµРІ',
      'status': 'РћР¶РёРґР°РµС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ',
      'description':
          'Р¦РІРµС‚РѕС‡РЅРѕРµ РѕС„РѕСЂРјР»РµРЅРёРµ СЃРІР°РґРµР±РЅРѕР№ С†РµСЂРµРјРѕРЅРёРё. Р‘РµР»С‹Рµ Рё СЂРѕР·РѕРІС‹Рµ СЂРѕР·С‹, РєР»Р°СЃСЃРёС‡РµСЃРєРёР№ СЃС‚РёР»СЊ.',
      'createdAt': DateTime.now().subtract(const Duration(days: 8)),
    },
    {
      'eventName': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅС‹Р№ С„СѓСЂС€РµС‚',
      'date': '2025-10-18',
      'budget': 100000,
      'specialistId': 'specialist_9',
      'specialistName': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
      'customerId': 'customer_9',
      'customerName': 'РќР°С‚Р°Р»СЊСЏ РљРѕР·Р»РѕРІР°',
      'status': 'РџРѕРґС‚РІРµСЂР¶РґРµРЅРѕ',
      'description': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅС‹Р№ С„СѓСЂС€РµС‚ РЅР° 100 С‡РµР»РѕРІРµРє. Р•РІСЂРѕРїРµР№СЃРєР°СЏ РєСѓС…РЅСЏ.',
      'createdAt': DateTime.now().subtract(const Duration(days: 9)),
    },
    {
      'eventName': 'РЎРІР°РґРµР±РЅС‹Р№ РјР°РєРёСЏР¶',
      'date': '2025-10-19',
      'budget': 36000,
      'specialistId': 'specialist_10',
      'specialistName': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
      'customerId': 'customer_10',
      'customerName': 'Р’Р»Р°РґРёРјРёСЂ РџРµС‚СЂРѕРІ',
      'status': 'РћР¶РёРґР°РµС‚ РїРѕРґС‚РІРµСЂР¶РґРµРЅРёСЏ',
      'description': 'РЎРІР°РґРµР±РЅС‹Р№ РјР°РєРёСЏР¶ РґР»СЏ РЅРµРІРµСЃС‚С‹. РќР°С‚СѓСЂР°Р»СЊРЅС‹Р№ СЃС‚РёР»СЊ.',
      'createdAt': DateTime.now().subtract(const Duration(days: 10)),
    },
  ];

  // РўРµСЃС‚РѕРІС‹Рµ РїРѕСЃС‚С‹
  final List<Map<String, dynamic>> _testPosts = [
    {
      'authorId': 'specialist_2',
      'authorName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
      'authorAvatar': 'https://picsum.photos/200?random=2',
      'imageUrl': 'https://picsum.photos/400?random=30',
      'caption': 'РџСЂР°Р·РґРЅРёРє РЅР° Р±РµСЂРµРіСѓ РјРѕСЂСЏ рџЊЉ Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ РґР»СЏ РјРѕР»РѕРґРѕР¶РµРЅРѕРІ РІ РЎРѕС‡Рё',
      'timestamp': DateTime.now().subtract(const Duration(days: 1)),
      'likes': 24,
      'comments': 5,
    },
    {
      'authorId': 'specialist_1',
      'authorName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
      'authorAvatar': 'https://picsum.photos/200?random=1',
      'imageUrl': 'https://picsum.photos/400?random=31',
      'caption': 'РЎРІР°РґСЊР±Р° РІ СЃС‚РёР»Рµ "Р’РµР»РёРєРёР№ Р“СЌС‚СЃР±Рё" вњЁ РќРµР·Р°Р±С‹РІР°РµРјС‹Р№ РІРµС‡РµСЂ!',
      'timestamp': DateTime.now().subtract(const Duration(days: 2)),
      'likes': 18,
      'comments': 3,
    },
    {
      'authorId': 'specialist_3',
      'authorName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
      'authorAvatar': 'https://picsum.photos/200?random=3',
      'imageUrl': 'https://picsum.photos/400?random=32',
      'caption': 'РћС‚Р»РёС‡РЅР°СЏ СЃРІР°РґСЊР±Р° РІС‡РµСЂР°! рџЋµ РњСѓР·С‹РєР° РёРіСЂР°Р»Р° РІСЃСЋ РЅРѕС‡СЊ, РіРѕСЃС‚Рё С‚Р°РЅС†РµРІР°Р»Рё РґРѕ СѓС‚СЂР°!',
      'timestamp': DateTime.now().subtract(const Duration(days: 3)),
      'likes': 31,
      'comments': 7,
    },
    {
      'authorId': 'specialist_4',
      'authorName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
      'authorAvatar': 'https://picsum.photos/200?random=4',
      'imageUrl': 'https://picsum.photos/400?random=33',
      'caption': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅР°СЏ РІРёРґРµРѕСЃСЉРµРјРєР° рџ“№ РЎРѕР·РґР°РµРј РєСЂСѓС‚РѕР№ СЂРѕР»РёРє РґР»СЏ РєРѕРјРїР°РЅРёРё!',
      'timestamp': DateTime.now().subtract(const Duration(days: 4)),
      'likes': 19,
      'comments': 4,
    },
    {
      'authorId': 'specialist_5',
      'authorName': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
      'authorAvatar': 'https://picsum.photos/200?random=5',
      'imageUrl': 'https://picsum.photos/400?random=34',
      'caption': 'РЎРІР°РґСЊР±Р° РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ рџЊё Р¤СЂР°РЅС†СѓР·СЃРєР°СЏ СЂРѕРјР°РЅС‚РёРєР° РІ РєР°Р¶РґРѕРј СЌР»РµРјРµРЅС‚Рµ!',
      'timestamp': DateTime.now().subtract(const Duration(days: 5)),
      'likes': 42,
      'comments': 9,
    },
    {
      'authorId': 'specialist_6',
      'authorName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
      'authorAvatar': 'https://picsum.photos/200?random=6',
      'imageUrl': 'https://picsum.photos/400?random=35',
      'caption': 'РџРёСЂР°С‚СЃРєР°СЏ РІРµС‡РµСЂРёРЅРєР° РґР»СЏ РґРµС‚РµР№ рџЏґвЂЌв пёЏ Р”РµС‚Рё Р±С‹Р»Рё РІ РІРѕСЃС‚РѕСЂРіРµ РѕС‚ РїСЂРёРєР»СЋС‡РµРЅРёР№!',
      'timestamp': DateTime.now().subtract(const Duration(days: 6)),
      'likes': 28,
      'comments': 6,
    },
    {
      'authorId': 'specialist_7',
      'authorName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
      'authorAvatar': 'https://picsum.photos/200?random=7',
      'imageUrl': 'https://picsum.photos/400?random=36',
      'caption': 'Р РѕРјР°РЅС‚РёС‡РµСЃРєРёР№ РІРµС‡РµСЂ рџЋё Р”Р¶Р°Р· Рё Р±Р°Р»Р»Р°РґС‹ СЃРѕР·РґР°Р»Рё РЅРµР·Р°Р±С‹РІР°РµРјСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ!',
      'timestamp': DateTime.now().subtract(const Duration(days: 7)),
      'likes': 35,
      'comments': 8,
    },
    {
      'authorId': 'specialist_8',
      'authorName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
      'authorAvatar': 'https://picsum.photos/200?random=8',
      'imageUrl': 'https://picsum.photos/400?random=37',
      'caption': 'Р¦РІРµС‚РѕС‡РЅРѕРµ РѕС„РѕСЂРјР»РµРЅРёРµ СЃРІР°РґСЊР±С‹ рџЊ№ Р‘РµР»С‹Рµ Рё СЂРѕР·РѕРІС‹Рµ СЂРѕР·С‹ - РєР»Р°СЃСЃРёРєР° Р¶Р°РЅСЂР°!',
      'timestamp': DateTime.now().subtract(const Duration(days: 8)),
      'likes': 26,
      'comments': 5,
    },
    {
      'authorId': 'specialist_9',
      'authorName': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
      'authorAvatar': 'https://picsum.photos/200?random=9',
      'imageUrl': 'https://picsum.photos/400?random=38',
      'caption': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅС‹Р№ С„СѓСЂС€РµС‚ рџЌЅпёЏ Р•РІСЂРѕРїРµР№СЃРєР°СЏ РєСѓС…РЅСЏ РЅР° РІС‹СЃС€РµРј СѓСЂРѕРІРЅРµ!',
      'timestamp': DateTime.now().subtract(const Duration(days: 9)),
      'likes': 33,
      'comments': 7,
    },
    {
      'authorId': 'specialist_10',
      'authorName': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
      'authorAvatar': 'https://picsum.photos/200?random=10',
      'imageUrl': 'https://picsum.photos/400?random=39',
      'caption': 'РЎРІР°РґРµР±РЅС‹Р№ РјР°РєРёСЏР¶ рџ’„ РќР°С‚СѓСЂР°Р»СЊРЅР°СЏ РєСЂР°СЃРѕС‚Р° - Р»СѓС‡С€РёР№ РІС‹Р±РѕСЂ РґР»СЏ РЅРµРІРµСЃС‚С‹!',
      'timestamp': DateTime.now().subtract(const Duration(days: 10)),
      'likes': 29,
      'comments': 6,
    },
  ];

  /// Р—Р°РїРѕР»РЅРёС‚СЊ РІСЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ
  Future<void> populateAll() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('рџљЂ РќР°С‡Р°Р»Рѕ Р·Р°РїРѕР»РЅРµРЅРёСЏ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…...');

      // РџСЂРѕРІРµСЂСЏРµРј, РµСЃС‚СЊ Р»Рё СѓР¶Рµ РґР°РЅРЅС‹Рµ
      if (await hasTestData()) {
        debugPrint('вљ пёЏ РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ СѓР¶Рµ СЃСѓС‰РµСЃС‚РІСѓСЋС‚. РџСЂРѕРїСѓСЃРєР°РµРј СЃРѕР·РґР°РЅРёРµ.');
        return;
      }

      // Р—Р°РїРѕР»РЅСЏРµРј РґР°РЅРЅС‹Рµ РїР°СЂР°Р»Р»РµР»СЊРЅРѕ РіРґРµ РІРѕР·РјРѕР¶РЅРѕ
      await Future.wait([
        _populateSpecialists(),
        _populateChats(),
        _populateBookings(),
      ]);

      await Future.wait([
        _populatePosts(),
        _populateIdeas(),
        _populateNotifications(),
      ]);

      await Future.wait([
        createTestPromotions(),
        _populateReviews(),
      ]);

      stopwatch.stop();
      debugPrint(
        'вњ… РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ СѓСЃРїРµС€РЅРѕ СЃРѕР·РґР°РЅС‹ Р·Р° ${stopwatch.elapsedMilliseconds}ms',
      );
    } on FirebaseException catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° Firebase РїСЂРё Р·Р°РїРѕР»РЅРµРЅРёРё РґР°РЅРЅС‹С…: ${e.message}');
      rethrow;
    } on Exception catch (e) {
      debugPrint('вќЊ РћР±С‰Р°СЏ РѕС€РёР±РєР° РїСЂРё Р·Р°РїРѕР»РЅРµРЅРёРё РґР°РЅРЅС‹С…: $e');
      rethrow;
    }
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  Future<void> _populateSpecialists() async {
    debugPrint('рџ‘Ґ РЎРѕР·РґР°РЅРёРµ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ...');

    try {
      // РСЃРїРѕР»СЊР·СѓРµРј Р±Р°С‚С‡РµРІС‹Рµ РѕРїРµСЂР°С†РёРё РґР»СЏ Р»СѓС‡С€РµР№ РїСЂРѕРёР·РІРѕРґРёС‚РµР»СЊРЅРѕСЃС‚Рё
      final batches = <WriteBatch>[];
      WriteBatch? currentBatch = _firestore.batch();
      var batchCount = 0;

      for (var i = 0; i < _testSpecialists.length; i++) {
        final specialist = _testSpecialists[i];
        final docRef = _firestore.collection('specialists').doc('specialist_${i + 1}');

        currentBatch!.set(docRef, {
          ...specialist,
          'id': 'specialist_${i + 1}',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        batchCount++;

        // РЎРѕР·РґР°РµРј РЅРѕРІС‹Р№ Р±Р°С‚С‡ РєР°Р¶РґС‹Рµ _batchSize РѕРїРµСЂР°С†РёР№
        if (batchCount >= _batchSize) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Р”РѕР±Р°РІР»СЏРµРј РїРѕСЃР»РµРґРЅРёР№ Р±Р°С‚С‡ РµСЃР»Рё РѕРЅ РЅРµ РїСѓСЃС‚РѕР№
      if (batchCount > 0) {
        batches.add(currentBatch!);
      }

      // Р’С‹РїРѕР»РЅСЏРµРј РІСЃРµ Р±Р°С‚С‡Рё
      for (final batch in batches) {
        await batch.commit();
      }

      debugPrint('вњ… РЎРѕР·РґР°РЅРѕ ${_testSpecialists.length} СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ');
    } on FirebaseException catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РїСЂРё СЃРѕР·РґР°РЅРёРё СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ: ${e.message}');
      rethrow;
    }
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ С‡Р°С‚С‹
  Future<void> _populateChats() async {
    for (var i = 0; i < _testChats.length; i++) {
      final chat = _testChats[i];
      final chatId = 'chat_${i + 1}';

      // РЎРѕР·РґР°РµРј С‡Р°С‚
      await _firestore.collection('chats').doc(chatId).set({
        'id': chatId,
        'specialistId': chat['specialistId'],
        'specialistName': chat['specialistName'],
        'customerId': chat['customerId'],
        'customerName': chat['customerName'],
        'lastMessage': chat['messages'].last['content'],
        'lastMessageAt': chat['messages'].last['timestamp'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Р”РѕР±Р°РІР»СЏРµРј СЃРѕРѕР±С‰РµРЅРёСЏ
      final messages = chat['messages'] as List;
      for (var j = 0; j < messages.length; j++) {
        final message = messages[j];
        await _firestore.collection('chats').doc(chatId).collection('messages').add({
          'senderId': message['senderId'],
          'senderName': message['senderName'],
          'content': message['content'],
          'type': message['type'],
          'timestamp': message['timestamp'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${_testChats.length} С‡Р°С‚РѕРІ');
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ Р·Р°СЏРІРєРё
  Future<void> _populateBookings() async {
    for (var i = 0; i < _testBookings.length; i++) {
      final booking = _testBookings[i];
      await _firestore.collection('bookings').add({
        ...booking,
        'createdAt': booking['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${_testBookings.length} Р·Р°СЏРІРѕРє');
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ РїРѕСЃС‚С‹
  Future<void> _populatePosts() async {
    for (var i = 0; i < _testPosts.length; i++) {
      final post = _testPosts[i];
      await _firestore.collection('posts').add({
        ...post,
        'createdAt': post['timestamp'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${_testPosts.length} РїРѕСЃС‚РѕРІ');
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃРїРёСЃРѕРє СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ
  List<Map<String, dynamic>> getSpecialists() => _testSpecialists;

  /// РЎРѕР·РґР°С‚СЊ С‚РµСЃС‚РѕРІС‹С… СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ (РґР»СЏ СЃРѕРІРјРµСЃС‚РёРјРѕСЃС‚Рё)
  Future<void> createTestSpecialists() async {
    await _populateSpecialists();
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ РёРґРµРё
  Future<void> _populateIdeas() async {
    final testIdeas = [
      {
        'title': 'РЎРІР°РґСЊР±Р° РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ',
        'description':
            'Р РѕРјР°РЅС‚РёС‡РµСЃРєР°СЏ СЃРІР°РґСЊР±Р° СЃ С„СЂР°РЅС†СѓР·СЃРєРёРј С€Р°СЂРјРѕРј. Р›Р°РІР°РЅРґРѕРІС‹Рµ РѕС‚С‚РµРЅРєРё, РІРёРЅС‚Р°Р¶РЅС‹Рµ РґРµС‚Р°Р»Рё Рё СѓСЋС‚РЅР°СЏ Р°С‚РјРѕСЃС„РµСЂР°.',
        'imageUrl': 'https://picsum.photos/400?random=100',
        'authorId': 'specialist_5',
        'authorName': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ',
        'authorAvatar': 'https://picsum.photos/200?random=5',
        'likeCount': 42,
        'commentCount': 8,
        'isLiked': false,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'title': 'РљРѕСЂРїРѕСЂР°С‚РёРІ РІ СЃС‚РёР»Рµ 80-С…',
        'description':
            'РЇСЂРєРёР№ Рё СЌРЅРµСЂРіРёС‡РЅС‹Р№ РєРѕСЂРїРѕСЂР°С‚РёРІ СЃ РЅРµРѕРЅРѕРІС‹РјРё С†РІРµС‚Р°РјРё, РґРёСЃРєРѕ-РјСѓР·С‹РєРѕР№ Рё СЂРµС‚СЂРѕ-Р°С‚РјРѕСЃС„РµСЂРѕР№.',
        'imageUrl': 'https://picsum.photos/400?random=101',
        'authorId': 'specialist_3',
        'authorName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
        'authorAvatar': 'https://picsum.photos/200?random=3',
        'likeCount': 28,
        'commentCount': 5,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'title': 'Р”РµС‚СЃРєР°СЏ РІРµС‡РµСЂРёРЅРєР° "РџРёСЂР°С‚С‹"',
        'description':
            'РџСЂРёРєР»СЋС‡РµРЅС‡РµСЃРєР°СЏ РІРµС‡РµСЂРёРЅРєР° РґР»СЏ РґРµС‚РµР№ СЃ РїРѕРёСЃРєРѕРј СЃРѕРєСЂРѕРІРёС‰, РєРѕСЃС‚СЋРјР°РјРё РїРёСЂР°С‚РѕРІ Рё РјРѕСЂСЃРєРёРјРё РёРіСЂР°РјРё.',
        'imageUrl': 'https://picsum.photos/400?random=102',
        'authorId': 'specialist_6',
        'authorName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200?random=6',
        'likeCount': 35,
        'commentCount': 12,
        'isLiked': false,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
      },
      {
        'title': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ РІ Р·Р°РєР°С‚РЅРѕРј СЃРІРµС‚Рµ',
        'description':
            'Р РѕРјР°РЅС‚РёС‡РµСЃРєР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РЅР° РїСЂРёСЂРѕРґРµ СЃ РјСЏРіРєРёРј Р·Р°РєР°С‚РЅС‹Рј РѕСЃРІРµС‰РµРЅРёРµРј Рё РµСЃС‚РµСЃС‚РІРµРЅРЅС‹РјРё РїРѕР·Р°РјРё.',
        'imageUrl': 'https://picsum.photos/400?random=103',
        'authorId': 'specialist_2',
        'authorName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
        'authorAvatar': 'https://picsum.photos/200?random=2',
        'likeCount': 56,
        'commentCount': 15,
        'isLiked': true,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
      },
      {
        'title': 'РЎРІР°РґРµР±РЅС‹Р№ РјР°РєРёСЏР¶ "РќР°С‚СѓСЂР°Р»СЊРЅР°СЏ РєСЂР°СЃРѕС‚Р°"',
        'description':
            'Р”РµР»РёРєР°С‚РЅС‹Р№ РјР°РєРёСЏР¶, РїРѕРґС‡РµСЂРєРёРІР°СЋС‰РёР№ РµСЃС‚РµСЃС‚РІРµРЅРЅСѓСЋ РєСЂР°СЃРѕС‚Сѓ РЅРµРІРµСЃС‚С‹. РЎРІРµС‚Р»С‹Рµ С‚РѕРЅР° Рё РЅРµР¶РЅС‹Рµ Р°РєС†РµРЅС‚С‹.',
        'imageUrl': 'https://picsum.photos/400?random=104',
        'authorId': 'specialist_10',
        'authorName': 'РњР°СЂРёСЏ РљСѓР·РЅРµС†РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200?random=10',
        'likeCount': 31,
        'commentCount': 7,
        'isLiked': false,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
      },
      {
        'title': 'РљРµР№С‚РµСЂРёРЅРі "Р¤СЂР°РЅС†СѓР·СЃРєР°СЏ РєСѓС…РЅСЏ"',
        'description':
            'РР·С‹СЃРєР°РЅРЅРѕРµ РјРµРЅСЋ СЃ С„СЂР°РЅС†СѓР·СЃРєРёРјРё РґРµР»РёРєР°С‚РµСЃР°РјРё: С„СѓР°-РіСЂР°, СѓР»РёС‚РєРё, СЂР°С‚Р°С‚СѓР№ Рё РєР»Р°СЃСЃРёС‡РµСЃРєРёРµ РґРµСЃРµСЂС‚С‹.',
        'imageUrl': 'https://picsum.photos/400?random=105',
        'authorId': 'specialist_9',
        'authorName': 'РђРЅРґСЂРµР№ Р¤РµРґРѕСЂРѕРІ',
        'authorAvatar': 'https://picsum.photos/200?random=9',
        'likeCount': 48,
        'commentCount': 9,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 6)),
      },
      {
        'title': 'Р¦РІРµС‚РѕС‡РЅРѕРµ РѕС„РѕСЂРјР»РµРЅРёРµ "Р’РµСЃРµРЅРЅРёР№ СЃР°Рґ"',
        'description':
            'РЎРІРµР¶РёРµ РІРµСЃРµРЅРЅРёРµ С†РІРµС‚С‹: С‚СЋР»СЊРїР°РЅС‹, РЅР°СЂС†РёСЃСЃС‹, РіРёР°С†РёРЅС‚С‹. РЎРѕР·РґР°РµРј Р°С‚РјРѕСЃС„РµСЂСѓ РїСЂРѕР±СѓР¶РґР°СЋС‰РµР№СЃСЏ РїСЂРёСЂРѕРґС‹.',
        'imageUrl': 'https://picsum.photos/400?random=106',
        'authorId': 'specialist_8',
        'authorName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
        'authorAvatar': 'https://picsum.photos/200?random=8',
        'likeCount': 39,
        'commentCount': 6,
        'isLiked': false,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
      },
      {
        'title': 'Р–РёРІР°СЏ РјСѓР·С‹РєР° "Р”Р¶Р°Р· Рё Р±Р»СЋР·"',
        'description':
            'РђС‚РјРѕСЃС„РµСЂРЅРѕРµ РІС‹СЃС‚СѓРїР»РµРЅРёРµ СЃ РґР¶Р°Р·РѕРІС‹РјРё СЃС‚Р°РЅРґР°СЂС‚Р°РјРё Рё Р±Р»СЋР·РѕРІС‹РјРё РёРјРїСЂРѕРІРёР·Р°С†РёСЏРјРё РґР»СЏ РѕСЃРѕР±РµРЅРЅРѕРіРѕ РІРµС‡РµСЂР°.',
        'imageUrl': 'https://picsum.photos/400?random=107',
        'authorId': 'specialist_7',
        'authorName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
        'authorAvatar': 'https://picsum.photos/200?random=7',
        'likeCount': 44,
        'commentCount': 11,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 8)),
      },
      {
        'title': 'Р’РёРґРµРѕСЃСЉРµРјРєР° "РЎРІР°РґРµР±РЅС‹Р№ С„РёР»СЊРј"',
        'description':
            'РљРёРЅРµРјР°С‚РѕРіСЂР°С„РёС‡РЅР°СЏ СЃСЉРµРјРєР° СЃРІР°РґСЊР±С‹ СЃ РєСЂР°СЃРёРІС‹РјРё РїР»Р°РЅР°РјРё, СЌРјРѕС†РёРѕРЅР°Р»СЊРЅС‹РјРё РјРѕРјРµРЅС‚Р°РјРё Рё РєР°С‡РµСЃС‚РІРµРЅРЅС‹Рј РјРѕРЅС‚Р°Р¶РѕРј.',
        'imageUrl': 'https://picsum.photos/400?random=108',
        'authorId': 'specialist_4',
        'authorName': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°',
        'authorAvatar': 'https://picsum.photos/200?random=4',
        'likeCount': 52,
        'commentCount': 13,
        'isLiked': false,
        'isSaved': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 9)),
      },
      {
        'title': 'Р’РµРґСѓС‰РёР№ "РРЅС‚РµСЂР°РєС‚РёРІРЅР°СЏ СЃРІР°РґСЊР±Р°"',
        'description':
            'РЎРѕРІСЂРµРјРµРЅРЅС‹Р№ РїРѕРґС…РѕРґ Рє РїСЂРѕРІРµРґРµРЅРёСЋ СЃРІР°РґСЊР±С‹ СЃ РёРЅС‚РµСЂР°РєС‚РёРІРЅС‹РјРё РёРіСЂР°РјРё, РєРІРµСЃС‚Р°РјРё Рё РІРѕРІР»РµС‡РµРЅРёРµРј РІСЃРµС… РіРѕСЃС‚РµР№.',
        'imageUrl': 'https://picsum.photos/400?random=109',
        'authorId': 'specialist_1',
        'authorName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'authorAvatar': 'https://picsum.photos/200?random=1',
        'likeCount': 37,
        'commentCount': 8,
        'isLiked': true,
        'isSaved': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
      },
    ];

    for (var i = 0; i < testIdeas.length; i++) {
      final idea = testIdeas[i];
      await _firestore.collection('ideas').add({
        ...idea,
        'createdAt': idea['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testIdeas.length} РёРґРµР№');
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ СѓРІРµРґРѕРјР»РµРЅРёСЏ
  Future<void> _populateNotifications() async {
    final testNotifications = [
      {
        'userId': 'current_user',
        'title': 'РќРѕРІС‹Р№ Р»Р°Р№Рє!',
        'body': 'РђРЅРЅР° Р›РµР±РµРґРµРІР° РїРѕСЃС‚Р°РІРёР»Р° Р»Р°Р№Рє РІР°С€РµРјСѓ РїРѕСЃС‚Сѓ',
        'type': 'like',
        'data': 'post_1',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІС‹Р№ РєРѕРјРјРµРЅС‚Р°СЂРёР№',
        'body': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ РїСЂРѕРєРѕРјРјРµРЅС‚РёСЂРѕРІР°Р» РІР°С€Сѓ РёРґРµСЋ',
        'type': 'comment',
        'data': 'idea_2',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 15)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІР°СЏ РїРѕРґРїРёСЃРєР°',
        'body': 'РњРёС…Р°РёР» Р’РѕР»РєРѕРІ РїРѕРґРїРёСЃР°Р»СЃСЏ РЅР° РІР°СЃ',
        'type': 'follow',
        'data': 'specialist_5',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 1)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІР°СЏ Р·Р°СЏРІРєР°',
        'body': 'РџРѕСЃС‚СѓРїРёР»Р° Р·Р°СЏРІРєР° РЅР° С„РѕС‚РѕСЃСЉРµРјРєСѓ СЃРІР°РґСЊР±С‹',
        'type': 'request',
        'data': 'booking_1',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІРѕРµ СЃРѕРѕР±С‰РµРЅРёРµ',
        'body': 'Р•Р»РµРЅР° РџРµС‚СЂРѕРІР°: РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р»РёС‡РЅСѓСЋ СЂР°Р±РѕС‚Сѓ!',
        'type': 'message',
        'data': 'chat_1',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 3)),
      },
      {
        'userId': 'current_user',
        'title': 'РџРѕРґС‚РІРµСЂР¶РґРµРЅРёРµ Р·Р°СЏРІРєРё',
        'body': 'Р’Р°С€Р° Р·Р°СЏРІРєР° РЅР° РІРёРґРµРѕСЃСЉРµРјРєСѓ РїРѕРґС‚РІРµСЂР¶РґРµРЅР°',
        'type': 'booking',
        'data': 'booking_2',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
      {
        'userId': 'current_user',
        'title': 'РЎРёСЃС‚РµРјРЅРѕРµ СѓРІРµРґРѕРјР»РµРЅРёРµ',
        'body': 'Р”РѕР±СЂРѕ РїРѕР¶Р°Р»РѕРІР°С‚СЊ РІ Event Marketplace!',
        'type': 'system',
        'data': null,
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІС‹Р№ Р»Р°Р№Рє!',
        'body': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР° РїРѕСЃС‚Р°РІРёР»Р° Р»Р°Р№Рє РІР°С€РµР№ РёРґРµРµ',
        'type': 'like',
        'data': 'idea_3',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІС‹Р№ РєРѕРјРјРµРЅС‚Р°СЂРёР№',
        'body': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ РїСЂРѕРєРѕРјРјРµРЅС‚РёСЂРѕРІР°Р» РІР°С€ РїРѕСЃС‚',
        'type': 'comment',
        'data': 'post_2',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      },
      {
        'userId': 'current_user',
        'title': 'РќРѕРІР°СЏ РїРѕРґРїРёСЃРєР°',
        'body': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР° РїРѕРґРїРёСЃР°Р»СЃСЏ РЅР° РІР°СЃ',
        'type': 'follow',
        'data': 'specialist_8',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 2, hours: 1)),
      },
    ];

    for (var i = 0; i < testNotifications.length; i++) {
      final notification = testNotifications[i];
      await _firestore.collection('notifications').add({
        ...notification,
        'createdAt': notification['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testNotifications.length} СѓРІРµРґРѕРјР»РµРЅРёР№');
  }

  /// РЎРѕР·РґР°С‚СЊ С‚РµСЃС‚РѕРІС‹Рµ Р°РєС†РёРё
  Future<void> createTestPromotions() async {
    debugPrint('РЎРѕР·РґР°РЅРёРµ С‚РµСЃС‚РѕРІС‹С… Р°РєС†РёР№...');

    final testPromotions = [
      {
        'title': 'РЎРІР°РґРµР±РЅС‹Р№ РїР°РєРµС‚ -15%',
        'description':
            'РЎРїРµС†РёР°Р»СЊРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ РґР»СЏ СЃРІР°РґРµР±РЅС‹С… РјРµСЂРѕРїСЂРёСЏС‚РёР№. Р’РєР»СЋС‡Р°РµС‚ РІРµРґСѓС‰РµРіРѕ, С„РѕС‚РѕРіСЂР°С„Р° Рё РґРµРєРѕСЂР°С†РёРё.',
        'category': 'host',
        'discount': 15,
        'startDate': DateTime.now().subtract(const Duration(days: 5)),
        'endDate': DateTime.now().add(const Duration(days: 30)),
        'imageUrl': 'https://picsum.photos/400?random=101',
        'specialistId': 'specialist_1',
        'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'city': 'РњРѕСЃРєРІР°',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ -20%',
        'description': 'РЎРєРёРґРєР° РЅР° РІСЃРµ РІРёРґС‹ С„РѕС‚РѕСЃРµСЃСЃРёР№. РЎС‚СѓРґРёР№РЅР°СЏ, РІС‹РµР·РґРЅР°СЏ, СЃРІР°РґРµР±РЅР°СЏ С„РѕС‚РѕРіСЂР°С„РёСЏ.',
        'category': 'photographer',
        'discount': 20,
        'startDate': DateTime.now().subtract(const Duration(days: 3)),
        'endDate': DateTime.now().add(const Duration(days: 20)),
        'imageUrl': 'https://picsum.photos/400?random=102',
        'specialistId': 'specialist_2',
        'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
        'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 3)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'РќРѕРІРѕРіРѕРґРЅРёРµ РїСЂР°Р·РґРЅРёРєРё -25%',
        'description': 'РЎРµР·РѕРЅРЅРѕРµ РїСЂРµРґР»РѕР¶РµРЅРёРµ РЅР° РЅРѕРІРѕРіРѕРґРЅРёРµ РєРѕСЂРїРѕСЂР°С‚РёРІС‹ Рё С‡Р°СЃС‚РЅС‹Рµ РІРµС‡РµСЂРёРЅРєРё.',
        'category': 'seasonal',
        'discount': 25,
        'startDate': DateTime.now().subtract(const Duration(days: 1)),
        'endDate': DateTime.now().add(const Duration(days: 45)),
        'imageUrl': 'https://picsum.photos/400?random=103',
        'specialistId': 'specialist_3',
        'specialistName': 'РњРёС…Р°РёР» РџРµС‚СЂРѕРІ',
        'city': 'РњРѕСЃРєРІР°',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'DJ-СѓСЃР»СѓРіРё -10%',
        'description':
            'РЎРєРёРґРєР° РЅР° РјСѓР·С‹РєР°Р»СЊРЅРѕРµ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ РјРµСЂРѕРїСЂРёСЏС‚РёР№. РЎРѕРІСЂРµРјРµРЅРЅРѕРµ РѕР±РѕСЂСѓРґРѕРІР°РЅРёРµ Рё РєР°С‡РµСЃС‚РІРµРЅРЅС‹Р№ Р·РІСѓРє.',
        'category': 'dj',
        'discount': 10,
        'startDate': DateTime.now(),
        'endDate': DateTime.now().add(const Duration(days: 15)),
        'imageUrl': 'https://picsum.photos/400?random=104',
        'specialistId': 'specialist_4',
        'specialistName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
        'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'РџРѕРґР°СЂРѕРє: Р±РµСЃРїР»Р°С‚РЅР°СЏ РєРѕРЅСЃСѓР»СЊС‚Р°С†РёСЏ',
        'description':
            'Р‘РµСЃРїР»Р°С‚РЅР°СЏ РєРѕРЅСЃСѓР»СЊС‚Р°С†РёСЏ РїРѕ РѕСЂРіР°РЅРёР·Р°С†РёРё РјРµСЂРѕРїСЂРёСЏС‚РёСЏ. РџРѕРјРѕР¶РµРј СЃРѕСЃС‚Р°РІРёС‚СЊ РїР»Р°РЅ Рё РїРѕРґРѕР±СЂР°С‚СЊ СЃРїРµС†РёР°Р»РёСЃС‚РѕРІ.',
        'category': 'gift',
        'discount': 0,
        'startDate': DateTime.now().subtract(const Duration(days: 2)),
        'endDate': DateTime.now().add(const Duration(days: 60)),
        'imageUrl': 'https://picsum.photos/400?random=105',
        'specialistId': 'specialist_5',
        'specialistName': 'Р•Р»РµРЅР° Р’РѕР»РєРѕРІР°',
        'city': 'РњРѕСЃРєРІР°',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'РџСЂРѕРјРѕРєРѕРґ WEDDING2024 -30%',
        'description':
            'РСЃРїРѕР»СЊР·СѓР№С‚Рµ РїСЂРѕРјРѕРєРѕРґ WEDDING2024 Рё РїРѕР»СѓС‡РёС‚Рµ РјР°РєСЃРёРјР°Р»СЊРЅСѓСЋ СЃРєРёРґРєСѓ РЅР° СЃРІР°РґРµР±РЅС‹Рµ СѓСЃР»СѓРіРё.',
        'category': 'promoCode',
        'discount': 30,
        'startDate': DateTime.now().subtract(const Duration(days: 7)),
        'endDate': DateTime.now().add(const Duration(days: 25)),
        'imageUrl': 'https://picsum.photos/400?random=106',
        'specialistId': 'specialist_6',
        'specialistName': 'РћР»СЊРіР° РњРѕСЂРѕР·РѕРІР°',
        'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 7)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'Р”РµРєРѕСЂР°С†РёРё -18%',
        'description': 'РЎРєРёРґРєР° РЅР° РѕС„РѕСЂРјР»РµРЅРёРµ Р·Р°Р»РѕРІ Рё СЃРѕР·РґР°РЅРёРµ РїСЂР°Р·РґРЅРёС‡РЅРѕР№ Р°С‚РјРѕСЃС„РµСЂС‹.',
        'category': 'decorator',
        'discount': 18,
        'startDate': DateTime.now().subtract(const Duration(days: 4)),
        'endDate': DateTime.now().add(const Duration(days: 35)),
        'imageUrl': 'https://picsum.photos/400?random=107',
        'specialistId': 'specialist_7',
        'specialistName': 'РЎРµСЂРіРµР№ РќРѕРІРёРєРѕРІ',
        'city': 'РњРѕСЃРєРІР°',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 4)),
        'updatedAt': DateTime.now(),
      },
      {
        'title': 'РљРµР№С‚РµСЂРёРЅРі -12%',
        'description': 'РЎРїРµС†РёР°Р»СЊРЅС‹Рµ С†РµРЅС‹ РЅР° РѕСЂРіР°РЅРёР·Р°С†РёСЋ РїРёС‚Р°РЅРёСЏ РґР»СЏ РІР°С€РёС… РјРµСЂРѕРїСЂРёСЏС‚РёР№.',
        'category': 'caterer',
        'discount': 12,
        'startDate': DateTime.now().subtract(const Duration(days: 6)),
        'endDate': DateTime.now().add(const Duration(days: 40)),
        'imageUrl': 'https://picsum.photos/400?random=108',
        'specialistId': 'specialist_8',
        'specialistName': 'РўР°С‚СЊСЏРЅР° РЎРѕРєРѕР»РѕРІР°',
        'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'isActive': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 6)),
        'updatedAt': DateTime.now(),
      },
    ];

    for (var i = 0; i < testPromotions.length; i++) {
      final promotion = testPromotions[i];
      await _firestore.collection('promotions').add({
        ...promotion,
        'startDate': Timestamp.fromDate(promotion['startDate']! as DateTime),
        'endDate': Timestamp.fromDate(promotion['endDate']! as DateTime),
        'createdAt': Timestamp.fromDate(promotion['createdAt']! as DateTime),
        'updatedAt': Timestamp.fromDate(promotion['updatedAt']! as DateTime),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testPromotions.length} Р°РєС†РёР№');
  }

  /// РћС‡РёСЃС‚РёС‚СЊ РІСЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ
  Future<void> clearAllTestData() async {
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('рџ§№ РќР°С‡Р°Р»Рѕ РѕС‡РёСЃС‚РєРё С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…...');

      // РЈРґР°Р»СЏРµРј РІСЃРµ РєРѕР»Р»РµРєС†РёРё
      final collections = [
        'specialists',
        'chats',
        'bookings',
        'posts',
        'ideas',
        'notifications',
        'promotions',
        'reviews',
        'transactions',
        'premium_profiles',
        'subscriptions',
        'promoted_posts',
      ];

      var totalDeleted = 0;

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).get();

          if (snapshot.docs.isNotEmpty) {
            // РСЃРїРѕР»СЊР·СѓРµРј Р±Р°С‚С‡РµРІРѕРµ СѓРґР°Р»РµРЅРёРµ РґР»СЏ Р»СѓС‡С€РµР№ РїСЂРѕРёР·РІРѕРґРёС‚РµР»СЊРЅРѕСЃС‚Рё
            final batches = <WriteBatch>[];
            WriteBatch? currentBatch = _firestore.batch();
            var batchCount = 0;

            for (final doc in snapshot.docs) {
              currentBatch!.delete(doc.reference);
              batchCount++;

              if (batchCount >= _batchSize) {
                batches.add(currentBatch);
                currentBatch = _firestore.batch();
                batchCount = 0;
              }
            }

            if (batchCount > 0) {
              batches.add(currentBatch!);
            }

            for (final batch in batches) {
              await batch.commit();
            }

            totalDeleted += snapshot.docs.length;
            debugPrint(
              '  вњ… РЈРґР°Р»РµРЅРѕ ${snapshot.docs.length} РґРѕРєСѓРјРµРЅС‚РѕРІ РёР· $collection',
            );
          }
        } on FirebaseException catch (e) {
          debugPrint('  вљ пёЏ РћС€РёР±РєР° РїСЂРё СѓРґР°Р»РµРЅРёРё РёР· $collection: ${e.message}');
        }
      }

      stopwatch.stop();
      debugPrint(
        'вњ… РћС‡РёСЃС‚РєР° Р·Р°РІРµСЂС€РµРЅР°. РЈРґР°Р»РµРЅРѕ $totalDeleted РґРѕРєСѓРјРµРЅС‚РѕРІ Р·Р° ${stopwatch.elapsedMilliseconds}ms',
      );
    } on Exception catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РїСЂРё СѓРґР°Р»РµРЅРёРё С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…: $e');
      rethrow;
    }
  }

  /// РџСЂРѕРІРµСЂРёС‚СЊ, РµСЃС‚СЊ Р»Рё СѓР¶Рµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ
  Future<bool> hasTestData() async {
    try {
      final specialistsSnapshot = await _firestore.collection('specialists').limit(1).get();
      return specialistsSnapshot.docs.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  /// РџРѕР»СѓС‡РёС‚СЊ СЃС‚Р°С‚РёСЃС‚РёРєСѓ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…
  Future<Map<String, int>> getTestDataStats() async {
    try {
      debugPrint('рџ“Љ РџРѕР»СѓС‡РµРЅРёРµ СЃС‚Р°С‚РёСЃС‚РёРєРё С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…...');

      final collections = [
        'specialists',
        'chats',
        'bookings',
        'posts',
        'ideas',
        'notifications',
        'promotions',
        'reviews',
      ];

      final stats = <String, int>{};

      for (final collection in collections) {
        try {
          final snapshot = await _firestore.collection(collection).get();
          stats[collection] = snapshot.docs.length;
        } on FirebaseException catch (e) {
          debugPrint(
            'вљ пёЏ РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СЃС‚Р°С‚РёСЃС‚РёРєРё РґР»СЏ $collection: ${e.message}',
          );
          stats[collection] = 0;
        }
      }

      final total = stats.values.fold(0, (sum, count) => sum + count);
      stats['total'] = total;

      debugPrint('рџ“Љ РЎС‚Р°С‚РёСЃС‚РёРєР° С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С…: $stats');
      return stats;
    } on Exception catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РїСЂРё РїРѕР»СѓС‡РµРЅРёРё СЃС‚Р°С‚РёСЃС‚РёРєРё: $e');
      return {};
    }
  }

  /// Р—Р°РїРѕР»РЅРёС‚СЊ РѕС‚Р·С‹РІС‹
  Future<void> _populateReviews() async {
    final testReviews = [
      // РћС‚Р·С‹РІС‹ РґР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р° 1 (РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ)
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_1',
        'customerName': 'РћР»СЊРіР° РРІР°РЅРѕРІР°',
        'rating': 5.0,
        'text':
            'РђР»РµРєСЃРµР№ - РїРѕС‚СЂСЏСЃР°СЋС‰РёР№ РІРµРґСѓС‰РёР№! РќР°С€Р° СЃРІР°РґСЊР±Р° РїСЂРѕС€Р»Р° РЅР° РІС‹СЃС€РµРј СѓСЂРѕРІРЅРµ. РћРЅ СЃРѕР·РґР°Р» РЅРµР·Р°Р±С‹РІР°РµРјСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ, РІСЃРµ РіРѕСЃС‚Рё Р±С‹Р»Рё РІ РІРѕСЃС‚РѕСЂРіРµ. РћС‡РµРЅСЊ СЂРµРєРѕРјРµРЅРґСѓСЋ!',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'photos': [
          'https://picsum.photos/400?random=201',
          'https://picsum.photos/400?random=202',
        ],
        'likes': 12,
        'responses': [
          {
            'authorId': 'specialist_1',
            'authorName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
            'text': 'РЎРїР°СЃРёР±Рѕ Р±РѕР»СЊС€РѕРµ Р·Р° РѕС‚Р·С‹РІ! Р‘С‹Р»Рѕ РѕС‡РµРЅСЊ РїСЂРёСЏС‚РЅРѕ СЂР°Р±РѕС‚Р°С‚СЊ СЃ РІР°РјРё!',
            'date': DateTime.now().subtract(const Duration(days: 4)),
          }
        ],
        'bookingId': 'booking_1',
        'eventTitle': 'РЎРІР°РґСЊР±Р° РћР»СЊРіРё Рё РРіРѕСЂСЏ',
        'customerAvatar': 'https://picsum.photos/200?random=301',
        'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_2',
        'customerName': 'РњР°СЂРёСЏ РџРµС‚СЂРѕРІР°',
        'rating': 4.5,
        'text':
            'РҐРѕСЂРѕС€РёР№ РІРµРґСѓС‰РёР№, РЅРѕ РЅРµРјРЅРѕРіРѕ Р·Р°С‚СЏРЅСѓР» РїСЂРѕРіСЂР°РјРјСѓ. Р’ С†РµР»РѕРј РІСЃРµ РїСЂРѕС€Р»Рѕ С…РѕСЂРѕС€Рѕ, РіРѕСЃС‚Рё РѕСЃС‚Р°Р»РёСЃСЊ РґРѕРІРѕР»СЊРЅС‹.',
        'date': DateTime.now().subtract(const Duration(days: 10)),
        'photos': ['https://picsum.photos/400?random=203'],
        'likes': 5,
        'responses': [],
        'bookingId': 'booking_2',
        'eventTitle': 'РљРѕСЂРїРѕСЂР°С‚РёРІ IT-РєРѕРјРїР°РЅРёРё',
        'customerAvatar': 'https://picsum.photos/200?random=302',
        'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_3',
        'customerName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
        'rating': 5.0,
        'text':
            'РћС‚Р»РёС‡РЅС‹Р№ РІРµРґСѓС‰РёР№! РџСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ РїРѕРґС…РѕРґ, РёРЅС‚РµСЂРµСЃРЅР°СЏ РїСЂРѕРіСЂР°РјРјР°, РІСЃРµ Р±С‹Р»Рѕ РЅР° РІС‹СЃРѕС‚Рµ. Р РµРєРѕРјРµРЅРґСѓСЋ РІСЃРµРј!',
        'date': DateTime.now().subtract(const Duration(days: 15)),
        'photos': [],
        'likes': 8,
        'responses': [
          {
            'authorId': 'specialist_1',
            'authorName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
            'text': 'Р‘Р»Р°РіРѕРґР°СЂСЋ Р·Р° РѕС‚Р·С‹РІ! Р Р°Рґ, С‡С‚Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРµ РїРѕРЅСЂР°РІРёР»РѕСЃСЊ!',
            'date': DateTime.now().subtract(const Duration(days: 14)),
          }
        ],
        'bookingId': 'booking_3',
        'eventTitle': 'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'customerAvatar': 'https://picsum.photos/200?random=303',
        'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_4',
        'customerName': 'РђРЅРЅР° РЎРёРґРѕСЂРѕРІР°',
        'rating': 4.0,
        'text':
            'РќРµРїР»РѕС…РѕР№ РІРµРґСѓС‰РёР№, РЅРѕ РѕР¶РёРґР°Р»Р° Р±РѕР»СЊС€Рµ РёРЅС‚РµСЂР°РєС‚РёРІР°. Р’ С†РµР»РѕРј СЃРїСЂР°РІРёР»СЃСЏ СЃРѕ СЃРІРѕРµР№ Р·Р°РґР°С‡РµР№.',
        'date': DateTime.now().subtract(const Duration(days: 20)),
        'photos': [
          'https://picsum.photos/400?random=204',
          'https://picsum.photos/400?random=205',
        ],
        'likes': 3,
        'responses': [],
        'bookingId': 'booking_4',
        'eventTitle': 'Р®Р±РёР»РµР№',
        'customerAvatar': 'https://picsum.photos/200?random=304',
        'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_1',
        'customerId': 'customer_5',
        'customerName': 'РЎРµСЂРіРµР№ Р’РѕР»РєРѕРІ',
        'rating': 5.0,
        'text':
            'РђР»РµРєСЃРµР№ - РјР°СЃС‚РµСЂ СЃРІРѕРµРіРѕ РґРµР»Р°! РЎРѕР·РґР°Р» РЅРµР·Р°Р±С‹РІР°РµРјСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ РЅР° РЅР°С€РµР№ СЃРІР°РґСЊР±Рµ. Р’СЃРµ РіРѕСЃС‚Рё РґРѕ СЃРёС… РїРѕСЂ РІСЃРїРѕРјРёРЅР°СЋС‚ СЌС‚РѕС‚ РґРµРЅСЊ СЃ СѓР»С‹Р±РєРѕР№!',
        'date': DateTime.now().subtract(const Duration(days: 25)),
        'photos': ['https://picsum.photos/400?random=206'],
        'likes': 15,
        'responses': [
          {
            'authorId': 'specialist_1',
            'authorName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
            'text': 'РЎРїР°СЃРёР±Рѕ Р·Р° С‚РµРїР»С‹Рµ СЃР»РѕРІР°! Р‘С‹Р»Рѕ РѕС‡РµРЅСЊ РїСЂРёСЏС‚РЅРѕ СЂР°Р±РѕС‚Р°С‚СЊ СЃ РІР°РјРё!',
            'date': DateTime.now().subtract(const Duration(days: 24)),
          }
        ],
        'bookingId': 'booking_5',
        'eventTitle': 'РЎРІР°РґСЊР±Р° РЎРµСЂРіРµСЏ Рё РђРЅРЅС‹',
        'customerAvatar': 'https://picsum.photos/200?random=305',
        'specialistName': 'РђР»РµРєСЃРµР№ РЎРјРёСЂРЅРѕРІ',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },

      // РћС‚Р·С‹РІС‹ РґР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р° 2 (РђРЅРЅР° Р›РµР±РµРґРµРІР°)
      {
        'specialistId': 'specialist_2',
        'customerId': 'customer_6',
        'customerName': 'Р•Р»РµРЅР° РњРѕСЂРѕР·РѕРІР°',
        'rating': 5.0,
        'text':
            'РђРЅРЅР° - С‚Р°Р»Р°РЅС‚Р»РёРІС‹Р№ С„РѕС‚РѕРіСЂР°С„! РЎРЅРёРјРєРё РїРѕР»СѓС‡РёР»РёСЃСЊ РїСЂРѕСЃС‚Рѕ РїРѕС‚СЂСЏСЃР°СЋС‰РёРµ. РћС‡РµРЅСЊ РІРЅРёРјР°С‚РµР»СЊРЅР°СЏ Рє РґРµС‚Р°Р»СЏРј, РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ РїРѕРґС…РѕРґ.',
        'date': DateTime.now().subtract(const Duration(days: 3)),
        'photos': [
          'https://picsum.photos/400?random=207',
          'https://picsum.photos/400?random=208',
        ],
        'likes': 18,
        'responses': [
          {
            'authorId': 'specialist_2',
            'authorName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
            'text': 'РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р·С‹РІ! Р Р°РґР°, С‡С‚Рѕ С„РѕС‚Рѕ РїРѕРЅСЂР°РІРёР»РёСЃСЊ!',
            'date': DateTime.now().subtract(const Duration(days: 2)),
          }
        ],
        'bookingId': 'booking_6',
        'eventTitle': 'РЎРІР°РґРµР±РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ',
        'customerAvatar': 'https://picsum.photos/200?random=306',
        'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_2',
        'customerId': 'customer_7',
        'customerName': 'РРіРѕСЂСЊ РџРµС‚СЂРѕРІ',
        'rating': 4.5,
        'text':
            'РҐРѕСЂРѕС€Р°СЏ СЂР°Р±РѕС‚Р°, РєР°С‡РµСЃС‚РІРµРЅРЅС‹Рµ С„РѕС‚Рѕ. Р•РґРёРЅСЃС‚РІРµРЅРЅРѕРµ - РЅРµРјРЅРѕРіРѕ Р·Р°С‚СЏРЅСѓР»Р° РїСЂРѕС†РµСЃСЃ СЃСЉРµРјРєРё, РЅРѕ СЂРµР·СѓР»СЊС‚Р°С‚ РѕРїСЂР°РІРґР°Р» РѕР¶РёРґР°РЅРёСЏ.',
        'date': DateTime.now().subtract(const Duration(days: 8)),
        'photos': ['https://picsum.photos/400?random=209'],
        'likes': 7,
        'responses': [],
        'bookingId': 'booking_7',
        'eventTitle': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ',
        'customerAvatar': 'https://picsum.photos/200?random=307',
        'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_2',
        'customerId': 'customer_8',
        'customerName': 'РўР°С‚СЊСЏРЅР° РљРѕР·Р»РѕРІР°',
        'rating': 5.0,
        'text':
            'РђРЅРЅР° - РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р» РІС‹СЃС€РµРіРѕ РєР»Р°СЃСЃР°! РЎРѕР·РґР°Р»Р° РЅРµРІРµСЂРѕСЏС‚РЅС‹Рµ СЃРЅРёРјРєРё РЅР°С€РµР№ СЃРІР°РґСЊР±С‹. РљР°Р¶РґС‹Р№ РєР°РґСЂ - РїСЂРѕРёР·РІРµРґРµРЅРёРµ РёСЃРєСѓСЃСЃС‚РІР°!',
        'date': DateTime.now().subtract(const Duration(days: 12)),
        'photos': [
          'https://picsum.photos/400?random=210',
          'https://picsum.photos/400?random=211',
        ],
        'likes': 22,
        'responses': [
          {
            'authorId': 'specialist_2',
            'authorName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
            'text': 'Р‘Р»Р°РіРѕРґР°СЂСЋ Р·Р° С‚Р°РєРёРµ С‚РµРїР»С‹Рµ СЃР»РѕРІР°! Р‘С‹Р»Рѕ РѕС‡РµРЅСЊ РїСЂРёСЏС‚РЅРѕ СЂР°Р±РѕС‚Р°С‚СЊ СЃ РІР°РјРё!',
            'date': DateTime.now().subtract(const Duration(days: 11)),
          }
        ],
        'bookingId': 'booking_8',
        'eventTitle': 'РЎРІР°РґСЊР±Р° РІ СЃС‚РёР»Рµ РїСЂРѕРІР°РЅСЃ',
        'customerAvatar': 'https://picsum.photos/200?random=308',
        'specialistName': 'РђРЅРЅР° Р›РµР±РµРґРµРІР°',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },

      // РћС‚Р·С‹РІС‹ РґР»СЏ СЃРїРµС†РёР°Р»РёСЃС‚Р° 3 (Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ)
      {
        'specialistId': 'specialist_3',
        'customerId': 'customer_9',
        'customerName': 'РђР»РµРєСЃР°РЅРґСЂ РќРѕРІРёРєРѕРІ',
        'rating': 4.0,
        'text':
            'РҐРѕСЂРѕС€РёР№ DJ, РЅРѕ РјСѓР·С‹РєР°Р»СЊРЅС‹Р№ РІРєСѓСЃ РЅРµ СЃРѕРІСЃРµРј СЃРѕРІРїР°Р» СЃ РЅР°С€РёРјРё РїСЂРµРґРїРѕС‡С‚РµРЅРёСЏРјРё. Р’ С†РµР»РѕРј СЃРїСЂР°РІРёР»СЃСЏ СЃ Р·Р°РґР°С‡РµР№.',
        'date': DateTime.now().subtract(const Duration(days: 6)),
        'photos': [],
        'likes': 4,
        'responses': [
          {
            'authorId': 'specialist_3',
            'authorName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
            'text': 'РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р·С‹РІ! РЈС‡С‚Сѓ РІР°С€Рё РїРѕР¶РµР»Р°РЅРёСЏ РЅР° Р±СѓРґСѓС‰РµРµ.',
            'date': DateTime.now().subtract(const Duration(days: 5)),
          }
        ],
        'bookingId': 'booking_9',
        'eventTitle': 'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'customerAvatar': 'https://picsum.photos/200?random=309',
        'specialistName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
        'isVerified': false,
        'reportCount': 0,
        'isReported': false,
      },
      {
        'specialistId': 'specialist_3',
        'customerId': 'customer_10',
        'customerName': 'РќР°С‚Р°Р»СЊСЏ Р¤РµРґРѕСЂРѕРІР°',
        'rating': 5.0,
        'text':
            'Р”РјРёС‚СЂРёР№ - РѕС‚Р»РёС‡РЅС‹Р№ DJ! РЎРѕР·РґР°Р» РїРѕС‚СЂСЏСЃР°СЋС‰СѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ РЅР° РЅР°С€РµР№ СЃРІР°РґСЊР±Рµ. Р’СЃРµ С‚Р°РЅС†РµРІР°Р»Рё РґРѕ СѓС‚СЂР°!',
        'date': DateTime.now().subtract(const Duration(days: 14)),
        'photos': ['https://picsum.photos/400?random=212'],
        'likes': 11,
        'responses': [
          {
            'authorId': 'specialist_3',
            'authorName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
            'text': 'РЎРїР°СЃРёР±Рѕ! Р Р°Рґ, С‡С‚Рѕ РјСѓР·С‹РєР° РїРѕРЅСЂР°РІРёР»Р°СЃСЊ РІСЃРµРј!',
            'date': DateTime.now().subtract(const Duration(days: 13)),
          }
        ],
        'bookingId': 'booking_10',
        'eventTitle': 'РЎРІР°РґСЊР±Р° РќР°С‚Р°Р»СЊРё Рё РњРёС…Р°РёР»Р°',
        'customerAvatar': 'https://picsum.photos/200?random=310',
        'specialistName': 'Р”РјРёС‚СЂРёР№ РљРѕР·Р»РѕРІ',
        'isVerified': true,
        'reportCount': 0,
        'isReported': false,
      },
    ];

    for (var i = 0; i < testReviews.length; i++) {
      final review = testReviews[i];
      await _firestore.collection('reviews').add({
        ...review,
        'date': Timestamp.fromDate(review['date']! as DateTime),
        'responses': (review['responses']! as List<dynamic>)
            .map(
              (response) => {
                ...response as Map<String, dynamic>,
                'date': Timestamp.fromDate(response['date'] as DateTime),
              },
            )
            .toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testReviews.length} РѕС‚Р·С‹РІРѕРІ');
  }

  // РЎРѕР·РґР°РЅРёРµ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С… РґР»СЏ РјРѕРЅРµС‚РёР·Р°С†РёРё
  Future<void> createMonetizationTestData() async {
    debugPrint('РЎРѕР·РґР°РЅРёРµ С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С… РјРѕРЅРµС‚РёР·Р°С†РёРё...');

    await _createTestTransactions();
    await _createTestPremiumProfiles();
    await _createTestSubscriptions();
    await _createTestPromotedPosts();

    debugPrint('РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РјРѕРЅРµС‚РёР·Р°С†РёРё СЃРѕР·РґР°РЅС‹ СѓСЃРїРµС€РЅРѕ!');
  }

  // РўРµСЃС‚РѕРІС‹Рµ С‚СЂР°РЅР·Р°РєС†РёРё
  Future<void> _createTestTransactions() async {
    final testTransactions = [
      {
        'id': 'transaction_1',
        'userId': 'user_1',
        'type': 'promotion',
        'amount': 299.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 5)),
        'description': 'РџСЂРѕРґРІРёР¶РµРЅРёРµ РїСЂРѕС„РёР»СЏ - 7_days',
        'targetUserId': null,
        'postId': null,
        'metadata': {'plan': '7_days'},
      },
      {
        'id': 'transaction_2',
        'userId': 'user_2',
        'type': 'subscription',
        'amount': 499.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 10)),
        'description': 'РџРѕРґРїРёСЃРєР° pro',
        'targetUserId': null,
        'postId': null,
        'metadata': {'plan': 'pro'},
      },
      {
        'id': 'transaction_3',
        'userId': 'demo_user_123',
        'type': 'donation',
        'amount': 500.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 3)),
        'description': 'Р”РѕРЅР°С‚ СЃРїРµС†РёР°Р»РёСЃС‚Сѓ',
        'targetUserId': 'user_1',
        'postId': null,
        'metadata': {'message': 'РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р»РёС‡РЅСѓСЋ СЂР°Р±РѕС‚Сѓ!'},
      },
      {
        'id': 'transaction_4',
        'userId': 'user_3',
        'type': 'boostPost',
        'amount': 999.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 2)),
        'description': 'РџСЂРѕРґРІРёР¶РµРЅРёРµ РїРѕСЃС‚Р° РЅР° 7 РґРЅРµР№',
        'targetUserId': null,
        'postId': 'post_1',
        'metadata': {'days': 7},
      },
      {
        'id': 'transaction_5',
        'userId': 'user_4',
        'type': 'subscription',
        'amount': 999.0,
        'currency': 'RUB',
        'status': 'success',
        'timestamp': DateTime.now().subtract(const Duration(days: 15)),
        'description': 'РџРѕРґРїРёСЃРєР° elite',
        'targetUserId': null,
        'postId': null,
        'metadata': {'plan': 'elite'},
      },
    ];

    for (final transaction in testTransactions) {
      await _firestore.collection('transactions').doc(transaction['id']! as String).set({
        ...transaction,
        'timestamp': Timestamp.fromDate(transaction['timestamp']! as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testTransactions.length} С‚СЂР°РЅР·Р°РєС†РёР№');
  }

  // РўРµСЃС‚РѕРІС‹Рµ РїСЂРµРјРёСѓРј-РїСЂРѕС„РёР»Рё
  Future<void> _createTestPremiumProfiles() async {
    final testPremiumProfiles = [
      {
        'userId': 'user_1',
        'activeUntil': DateTime.now().add(const Duration(days: 2)),
        'type': 'highlight',
        'region': 'РњРѕСЃРєРІР°',
        'createdAt': DateTime.now().subtract(const Duration(days: 5)),
        'isActive': true,
      },
      {
        'userId': 'user_2',
        'activeUntil': DateTime.now().add(const Duration(days: 20)),
        'type': 'prioritySearch',
        'region': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'createdAt': DateTime.now().subtract(const Duration(days: 10)),
        'isActive': true,
      },
    ];

    for (final profile in testPremiumProfiles) {
      await _firestore.collection('premiumProfiles').doc(profile['userId']! as String).set({
        ...profile,
        'activeUntil': Timestamp.fromDate(profile['activeUntil']! as DateTime),
        'createdAt': Timestamp.fromDate(profile['createdAt']! as DateTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testPremiumProfiles.length} РїСЂРµРјРёСѓРј-РїСЂРѕС„РёР»РµР№');
  }

  // РўРµСЃС‚РѕРІС‹Рµ РїРѕРґРїРёСЃРєРё
  Future<void> _createTestSubscriptions() async {
    final testSubscriptions = [
      {
        'userId': 'user_2',
        'plan': 'pro',
        'startedAt': DateTime.now().subtract(const Duration(days: 10)),
        'expiresAt': DateTime.now().add(const Duration(days: 20)),
        'autoRenew': true,
        'isActive': true,
        'monthlyPrice': 499.0,
      },
      {
        'userId': 'user_4',
        'plan': 'elite',
        'startedAt': DateTime.now().subtract(const Duration(days: 15)),
        'expiresAt': DateTime.now().add(const Duration(days: 15)),
        'autoRenew': true,
        'isActive': true,
        'monthlyPrice': 999.0,
      },
    ];

    for (final subscription in testSubscriptions) {
      await _firestore.collection('subscriptions').doc(subscription['userId']! as String).set({
        ...subscription,
        'startedAt': Timestamp.fromDate(subscription['startedAt']! as DateTime),
        'expiresAt': Timestamp.fromDate(subscription['expiresAt']! as DateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testSubscriptions.length} РїРѕРґРїРёСЃРѕРє');
  }

  // РўРµСЃС‚РѕРІС‹Рµ РїСЂРѕРґРІРёРіР°РµРјС‹Рµ РїРѕСЃС‚С‹
  Future<void> _createTestPromotedPosts() async {
    final testPromotedPosts = [
      {
        'postId': 'post_1',
        'userId': 'user_3',
        'startDate': DateTime.now().subtract(const Duration(days: 2)),
        'endDate': DateTime.now().add(const Duration(days: 5)),
        'priority': 1,
        'budget': 999.0,
        'isActive': true,
        'impressions': 1250,
        'clicks': 45,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'postId': 'post_2',
        'userId': 'user_1',
        'startDate': DateTime.now().subtract(const Duration(days: 1)),
        'endDate': DateTime.now().add(const Duration(days: 6)),
        'priority': 1,
        'budget': 499.0,
        'isActive': true,
        'impressions': 850,
        'clicks': 32,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    for (final post in testPromotedPosts) {
      await _firestore.collection('promotedPosts').doc(post['postId']! as String).set({
        ...post,
        'startDate': Timestamp.fromDate(post['startDate']! as DateTime),
        'endDate': Timestamp.fromDate(post['endDate']! as DateTime),
        'createdAt': Timestamp.fromDate(post['createdAt']! as DateTime),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint('Р”РѕР±Р°РІР»РµРЅРѕ ${testPromotedPosts.length} РїСЂРѕРґРІРёРіР°РµРјС‹С… РїРѕСЃС‚РѕРІ');
  }

  // РЎРѕР·РґР°РЅРёРµ С‚РµСЃС‚РѕРІС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ СЃ РјРѕРЅРµС‚РёР·Р°С†РёРµР№
  Future<void> createMonetizationUsers() async {
    final monetizationUsers = [
      {
        'id': 'premium_user_1',
        'name': 'Р•Р»РµРЅР° РџСЂРµРјРёСѓРј',
        'email': 'elena.premium@example.com',
        'avatarUrl': 'https://picsum.photos/200?random=101',
        'subscription': 'pro',
        'premiumUntil': DateTime.now().add(const Duration(days: 25)),
        'totalEarnings': 15000.0,
        'donationCount': 12,
      },
      {
        'id': 'elite_user_1',
        'name': 'РњР°РєСЃРёРј Р­Р»РёС‚',
        'email': 'maxim.elite@example.com',
        'avatarUrl': 'https://picsum.photos/200?random=102',
        'subscription': 'elite',
        'premiumUntil': DateTime.now().add(const Duration(days: 15)),
        'totalEarnings': 25000.0,
        'donationCount': 8,
      },
      {
        'id': 'donor_user_1',
        'name': 'РђРЅРЅР° Р”РѕРЅР°С‚РѕСЂ',
        'email': 'anna.donor@example.com',
        'avatarUrl': 'https://picsum.photos/200?random=103',
        'subscription': 'standard',
        'totalDonations': 3500.0,
        'donationCount': 7,
      },
    ];

    for (final user in monetizationUsers) {
      await _firestore.collection('users').doc(user['id']! as String).set({
        ...user,
        'premiumUntil': user['premiumUntil'] != null
            ? Timestamp.fromDate(user['premiumUntil']! as DateTime)
            : null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    debugPrint(
      'Р”РѕР±Р°РІР»РµРЅРѕ ${monetizationUsers.length} РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ СЃ РјРѕРЅРµС‚РёР·Р°С†РёРµР№',
    );
  }

  /// РџРѕР»СѓС‡РёС‚СЊ С‚РµСЃС‚РѕРІС‹Рµ РїСЂРѕРјРѕР°РєС†РёРё
  List<Map<String, dynamic>> getPromotions() => List.from(_testPromotions);

  // ===== РњР•РўРћР”Р« Р”Р›РЇ Р РђР‘РћРўР« РЎ FIRESTORE =====

  /// Р”РѕР±Р°РІРёС‚СЊ С‚РµСЃС‚РѕРІС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ РІ Firestore
  Future<void> addTestUsersToFirestore() async {
    debugPrint('рџ‘Ґ Р”РѕР±Р°РІР»РµРЅРёРµ С‚РµСЃС‚РѕРІС‹С… РїРѕР»СЊР·РѕРІР°С‚РµР»РµР№ РІ Firestore...');

    final users = [
      {
        'uid': 'user_1',
        'name': 'РђР»РµРєСЃР°РЅРґСЂ РРІР°РЅРѕРІ',
        'city': 'РњРѕСЃРєРІР°',
        'avatarUrl': 'https://i.pravatar.cc/150?img=1',
        'role': 'specialist',
        'email': 'alex.ivanov@example.com',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'user_2',
        'name': 'РњР°СЂРёСЏ РЎРјРёСЂРЅРѕРІР°',
        'city': 'РЎР°РЅРєС‚-РџРµС‚РµСЂР±СѓСЂРі',
        'avatarUrl': 'https://i.pravatar.cc/150?img=2',
        'role': 'customer',
        'email': 'maria.smirnova@example.com',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'user_3',
        'name': 'РРіРѕСЂСЊ РљСѓР·РЅРµС†РѕРІ',
        'city': 'РљР°Р·Р°РЅСЊ',
        'avatarUrl': 'https://i.pravatar.cc/150?img=3',
        'role': 'specialist',
        'email': 'igor.kuznetsov@example.com',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'user_4',
        'name': 'РђРЅРЅР° РЎРµСЂРіРµРµРІР°',
        'city': 'РќРѕРІРѕСЃРёР±РёСЂСЃРє',
        'avatarUrl': 'https://i.pravatar.cc/150?img=4',
        'role': 'customer',
        'email': 'anna.sergeeva@example.com',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'uid': 'user_5',
        'name': 'Р”РјРёС‚СЂРёР№ РћСЂР»РѕРІ',
        'city': 'Р•РєР°С‚РµСЂРёРЅР±СѓСЂРі',
        'avatarUrl': 'https://i.pravatar.cc/150?img=5',
        'role': 'specialist',
        'email': 'dmitry.orlov@example.com',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final user in users) {
      await _firestore.collection('users').doc(user['uid']! as String).set(user);
      debugPrint('  вњ… РџРѕР»СЊР·РѕРІР°С‚РµР»СЊ ${user['name']} РґРѕР±Р°РІР»РµРЅ');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РїРѕСЃС‚С‹ РІ Р»РµРЅС‚Сѓ Firestore
  Future<void> addFeedPostsToFirestore() async {
    debugPrint('рџ“ў Р”РѕР±Р°РІР»РµРЅРёРµ РїРѕСЃС‚РѕРІ РІ Р»РµРЅС‚Сѓ Firestore...');

    final posts = [
      {
        'id': 'feed_1',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/300?random=1',
        'text': 'РџРѕРґРµР»РёР»СЃСЏ РєР°РґСЂРѕРј СЃ РїРѕСЃР»РµРґРЅРµРіРѕ РјРµСЂРѕРїСЂРёСЏС‚РёСЏ рџЋ¤',
        'likesCount': 25,
        'commentsCount': 6,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_2',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/300?random=2',
        'text': 'РќРѕРІР°СЏ С„РѕС‚РѕР·РѕРЅР° РґР»СЏ СЃРІР°РґРµР± РіРѕС‚РѕРІР°! рџЊё',
        'likesCount': 18,
        'commentsCount': 4,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_3',
        'authorId': 'user_5',
        'imageUrl': 'https://picsum.photos/400/300?random=3',
        'text': 'РћС‚Р»РёС‡РЅС‹Р№ РґРµРЅСЊ РґР»СЏ С„РѕС‚РѕСЃРµСЃСЃРёРё РЅР° РїСЂРёСЂРѕРґРµ рџ“ё',
        'likesCount': 32,
        'commentsCount': 8,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_4',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/300?random=4',
        'text': 'РЎРІР°РґРµР±РЅР°СЏ С†РµСЂРµРјРѕРЅРёСЏ РІ СЃС‚РёР»Рµ РІРёРЅС‚Р°Р¶ рџ’Ќ',
        'likesCount': 41,
        'commentsCount': 12,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_5',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/300?random=5',
        'text': 'Р”РµС‚СЃРєРёР№ РїСЂР°Р·РґРЅРёРє СЃ Р°РЅРёРјР°С‚РѕСЂР°РјРё рџЋ€',
        'likesCount': 15,
        'commentsCount': 3,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_6',
        'authorId': 'user_5',
        'imageUrl': 'https://picsum.photos/400/300?random=6',
        'text': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ РїСЂРѕС€Р»Рѕ РЅР° СѓСЂР°! рџЋ‰',
        'likesCount': 28,
        'commentsCount': 7,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_7',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/300?random=7',
        'text': 'РќРѕРІС‹Р№ СЂРµРєРІРёР·РёС‚ РґР»СЏ С„РѕС‚РѕСЃРµСЃСЃРёР№ рџ“·',
        'likesCount': 22,
        'commentsCount': 5,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_8',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/300?random=8',
        'text': 'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ РІ СЃС‚РёР»Рµ РїРёСЂР°С‚СЃРєРѕР№ РІРµС‡РµСЂРёРЅРєРё рџЏґвЂЌв пёЏ',
        'likesCount': 19,
        'commentsCount': 4,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_9',
        'authorId': 'user_5',
        'imageUrl': 'https://picsum.photos/400/300?random=9',
        'text': 'РЎРµРјРµР№РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РІ РїР°СЂРєРµ рџ‘ЁвЂЌрџ‘©вЂЌрџ‘§вЂЌрџ‘¦',
        'likesCount': 35,
        'commentsCount': 9,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'feed_10',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/300?random=10',
        'text': 'Р’С‹РїСѓСЃРєРЅРѕР№ РІРµС‡РµСЂ РІ С€РєРѕР»Рµ рџЋ“',
        'likesCount': 27,
        'commentsCount': 6,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final post in posts) {
      await _firestore.collection('feed').doc(post['id']! as String).set(post);
      debugPrint('  вњ… РџРѕСЃС‚ ${post['id']} РґРѕР±Р°РІР»РµРЅ');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ Р·Р°СЏРІРєРё РІ Firestore
  Future<void> addOrdersToFirestore() async {
    debugPrint('рџ“ќ Р”РѕР±Р°РІР»РµРЅРёРµ Р·Р°СЏРІРѕРє РІ Firestore...');

    final orders = [
      {
        'id': 'order_1',
        'customerId': 'user_2',
        'specialistId': 'user_1',
        'title': 'РЎРІР°РґСЊР±Р° 14 РѕРєС‚СЏР±СЂСЏ',
        'description': 'РќСѓР¶РµРЅ РІРµРґСѓС‰РёР№ СЃ СЋРјРѕСЂРѕРј Рё РґРёРґР¶РµР№ РЅР° СЃРІР°РґСЊР±Сѓ РЅР° 40 С‡РµР»РѕРІРµРє.',
        'status': 'pending',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_2',
        'customerId': 'user_4',
        'specialistId': 'user_3',
        'title': 'Р”РµС‚СЃРєРёР№ РґРµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ',
        'description': 'РћСЂРіР°РЅРёР·Р°С†РёСЏ РїСЂР°Р·РґРЅРёРєР° РґР»СЏ 8-Р»РµС‚РЅРµРіРѕ СЂРµР±РµРЅРєР°. РќСѓР¶РЅС‹ Р°РЅРёРјР°С‚РѕСЂС‹ Рё С„РѕС‚РѕРіСЂР°С„.',
        'status': 'accepted',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_3',
        'customerId': 'user_2',
        'specialistId': 'user_5',
        'title': 'РљРѕСЂРїРѕСЂР°С‚РёРІРЅРѕРµ РјРµСЂРѕРїСЂРёСЏС‚РёРµ',
        'description':
            'РќРѕРІРѕРіРѕРґРЅРёР№ РєРѕСЂРїРѕСЂР°С‚РёРІ РЅР° 50 СЃРѕС‚СЂСѓРґРЅРёРєРѕРІ. РќСѓР¶РµРЅ РІРµРґСѓС‰РёР№ Рё РјСѓР·С‹РєР°Р»СЊРЅРѕРµ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ.',
        'status': 'completed',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_4',
        'customerId': 'user_4',
        'specialistId': 'user_1',
        'title': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ РґР»СЏ РїР°СЂС‹',
        'description': 'Р РѕРјР°РЅС‚РёС‡РµСЃРєР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РІ РїР°СЂРєРµ. РќСѓР¶РµРЅ РїСЂРѕС„РµСЃСЃРёРѕРЅР°Р»СЊРЅС‹Р№ С„РѕС‚РѕРіСЂР°С„.',
        'status': 'pending',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_5',
        'customerId': 'user_2',
        'specialistId': 'user_3',
        'title': 'Р’С‹РїСѓСЃРєРЅРѕР№ РІРµС‡РµСЂ',
        'description': 'РћСЂРіР°РЅРёР·Р°С†РёСЏ РІС‹РїСѓСЃРєРЅРѕРіРѕ РґР»СЏ 11 РєР»Р°СЃСЃР°. РќСѓР¶РµРЅ РІРµРґСѓС‰РёР№ Рё РґРёРґР¶РµР№.',
        'status': 'accepted',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_6',
        'customerId': 'user_4',
        'specialistId': 'user_5',
        'title': 'РЎРµРјРµР№РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ',
        'description': 'Р¤РѕС‚РѕСЃРµСЃСЃРёСЏ СЃРµРјСЊРё РёР· 4 С‡РµР»РѕРІРµРє. РќСѓР¶РµРЅ С„РѕС‚РѕРіСЂР°С„ СЃ РѕРїС‹С‚РѕРј СЂР°Р±РѕС‚С‹ СЃ РґРµС‚СЊРјРё.',
        'status': 'completed',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_7',
        'customerId': 'user_2',
        'specialistId': 'user_1',
        'title': 'Р®Р±РёР»РµР№ Р±Р°Р±СѓС€РєРё',
        'description': 'РџСЂР°Р·РґРЅРѕРІР°РЅРёРµ 70-Р»РµС‚РёСЏ. РќСѓР¶РµРЅ РІРµРґСѓС‰РёР№ Рё РјСѓР·С‹РєР°Р»СЊРЅРѕРµ СЃРѕРїСЂРѕРІРѕР¶РґРµРЅРёРµ.',
        'status': 'canceled',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'order_8',
        'customerId': 'user_4',
        'specialistId': 'user_3',
        'title': 'Р”РµРЅСЊ СЂРѕР¶РґРµРЅРёСЏ СЂРµР±РµРЅРєР°',
        'description': 'РџСЂР°Р·РґРЅРёРє РґР»СЏ 5-Р»РµС‚РЅРµР№ РґРµРІРѕС‡РєРё. РќСѓР¶РЅС‹ Р°РЅРёРјР°С‚РѕСЂС‹ РІ РєРѕСЃС‚СЋРјР°С… РїСЂРёРЅС†РµСЃСЃ.',
        'status': 'pending',
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final order in orders) {
      await _firestore.collection('orders').doc(order['id']! as String).set(order);
      debugPrint('  вњ… Р—Р°СЏРІРєР° ${order['id']} РґРѕР±Р°РІР»РµРЅР°');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ С‡Р°С‚С‹ Рё СЃРѕРѕР±С‰РµРЅРёСЏ РІ Firestore
  Future<void> addChatsToFirestore() async {
    debugPrint('рџ’¬ Р”РѕР±Р°РІР»РµРЅРёРµ С‡Р°С‚РѕРІ Рё СЃРѕРѕР±С‰РµРЅРёР№ РІ Firestore...');

    final chats = [
      {
        'id': 'chat_1',
        'members': ['user_1', 'user_2'],
        'lastMessage': 'Р”РѕР±СЂС‹Р№ РґРµРЅСЊ! РЈС‚РѕС‡РЅРёС‚Рµ РґР°С‚Сѓ?',
        'isTest': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'chat_2',
        'members': ['user_3', 'user_4'],
        'lastMessage': 'РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚Р»РёС‡РЅСѓСЋ СЂР°Р±РѕС‚Сѓ!',
        'isTest': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'chat_3',
        'members': ['user_5', 'user_2'],
        'lastMessage': 'РљРѕРіРґР° РјРѕР¶РµРј РІСЃС‚СЂРµС‚РёС‚СЊСЃСЏ?',
        'isTest': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'chat_4',
        'members': ['user_1', 'user_4'],
        'lastMessage': 'Р¤РѕС‚Рѕ РіРѕС‚РѕРІС‹, РѕС‚РїСЂР°РІР»СЏСЋ СЃСЃС‹Р»РєСѓ',
        'isTest': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'chat_5',
        'members': ['user_3', 'user_2'],
        'lastMessage': 'Р”Рѕ РІСЃС‚СЂРµС‡Рё Р·Р°РІС‚СЂР°!',
        'isTest': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];

    // РЎРѕР·РґР°РµРј С‡Р°С‚С‹
    for (final chat in chats) {
      await _firestore.collection('chats').doc(chat['id']! as String).set(chat);
      debugPrint('  вњ… Р§Р°С‚ ${chat['id']} РґРѕР±Р°РІР»РµРЅ');

      // РЎРѕР·РґР°РµРј СЃРѕРѕР±С‰РµРЅРёСЏ РґР»СЏ РєР°Р¶РґРѕРіРѕ С‡Р°С‚Р°
      final chatId = chat['id']! as String;
      final members = chat['members']! as List<String>;

      final messages = [
        {
          'id': 'msg_${chatId}_1',
          'senderId': members[0],
          'text': 'Р—РґСЂР°РІСЃС‚РІСѓР№С‚Рµ, СЂР°Рґ Р·РЅР°РєРѕРјСЃС‚РІСѓ рџ‘‹',
          'isTest': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'msg_${chatId}_2',
          'senderId': members[1],
          'text': 'РџСЂРёРІРµС‚! РЎРїР°СЃРёР±Рѕ Р·Р° РѕС‚РєР»РёРє',
          'isTest': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'msg_${chatId}_3',
          'senderId': members[0],
          'text': 'Р Р°СЃСЃРєР°Р¶РёС‚Рµ РїРѕРґСЂРѕР±РЅРµРµ Рѕ РјРµСЂРѕРїСЂРёСЏС‚РёРё',
          'isTest': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'msg_${chatId}_4',
          'senderId': members[1],
          'text': 'РљРѕРЅРµС‡РЅРѕ! Р­С‚Рѕ Р±СѓРґРµС‚ СЃРІР°РґСЊР±Р° РЅР° 40 С‡РµР»РѕРІРµРє',
          'isTest': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
        {
          'id': 'msg_${chatId}_5',
          'senderId': members[0],
          'text': 'РћС‚Р»РёС‡РЅРѕ! РљРѕРіРґР° РїР»Р°РЅРёСЂСѓРµС‚Рµ?',
          'isTest': true,
          'createdAt': FieldValue.serverTimestamp(),
        },
      ];

      for (final message in messages) {
        await _firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(message['id']! as String)
            .set(message);
      }
      debugPrint('    вњ… 5 СЃРѕРѕР±С‰РµРЅРёР№ РґРѕР±Р°РІР»РµРЅРѕ РІ С‡Р°С‚ $chatId');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РёРґРµРё РІ Firestore
  Future<void> addIdeasToFirestore() async {
    debugPrint('рџ’Ў Р”РѕР±Р°РІР»РµРЅРёРµ РёРґРµР№ РІ Firestore...');

    final ideas = [
      {
        'id': 'idea_1',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/400?random=21',
        'title': 'РќРµРѕР±С‹С‡РЅР°СЏ С„РѕС‚РѕР·РѕРЅР° рџЊё',
        'description':
            'РћС‚Р»РёС‡РЅР°СЏ РёРґРµСЏ РґР»СЏ Р»РµС‚РЅРёС… СЃРІР°РґРµР±. РСЃРїРѕР»СЊР·СѓР№С‚Рµ Р¶РёРІС‹Рµ С†РІРµС‚С‹ Рё РЅР°С‚СѓСЂР°Р»СЊРЅС‹Рµ РјР°С‚РµСЂРёР°Р»С‹.',
        'likesCount': 12,
        'commentsCount': 3,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_2',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/400?random=22',
        'title': 'Р’РёРЅС‚Р°Р¶РЅР°СЏ СЃРІР°РґРµР±РЅР°СЏ С†РµСЂРµРјРѕРЅРёСЏ рџ’Ќ',
        'description':
            'РЎРѕР·РґР°Р№С‚Рµ Р°С‚РјРѕСЃС„РµСЂСѓ РїСЂРѕС€Р»РѕРіРѕ РІРµРєР° СЃ РїРѕРјРѕС‰СЊСЋ СЂРµС‚СЂРѕ-СЂРµРєРІРёР·РёС‚Р° Рё РєР»Р°СЃСЃРёС‡РµСЃРєРѕР№ РјСѓР·С‹РєРё.',
        'likesCount': 28,
        'commentsCount': 7,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_3',
        'authorId': 'user_5',
        'imageUrl': 'https://picsum.photos/400/400?random=23',
        'title': 'РџРёРєРЅРёРє РЅР° РїСЂРёСЂРѕРґРµ рџ§є',
        'description':
            'РћСЂРіР°РЅРёР·СѓР№С‚Рµ СЂРѕРјР°РЅС‚РёС‡РµСЃРєРёР№ РїРёРєРЅРёРє СЃ РєСЂР°СЃРёРІРѕР№ СЃРµСЂРІРёСЂРѕРІРєРѕР№ Рё РїСЂРёСЂРѕРґРЅС‹Рј РґРµРєРѕСЂРѕРј.',
        'likesCount': 19,
        'commentsCount': 5,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_4',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/400?random=24',
        'title': 'Р”РµС‚СЃРєРёР№ РїСЂР°Р·РґРЅРёРє РІ СЃС‚РёР»Рµ РїРёСЂР°С‚РѕРІ рџЏґвЂЌв пёЏ',
        'description':
            'РЎРѕР·РґР°Р№С‚Рµ РЅРµР·Р°Р±С‹РІР°РµРјРѕРµ РїСЂРёРєР»СЋС‡РµРЅРёРµ РґР»СЏ РґРµС‚РµР№ СЃ РєРѕСЃС‚СЋРјР°РјРё Рё С‚РµРјР°С‚РёС‡РµСЃРєРёРјРё РёРіСЂР°РјРё.',
        'likesCount': 15,
        'commentsCount': 4,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_5',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/400?random=25',
        'title': 'РЎРµРјРµР№РЅР°СЏ С„РѕС‚РѕСЃРµСЃСЃРёСЏ РІ РїР°СЂРєРµ рџ‘ЁвЂЌрџ‘©вЂЌрџ‘§вЂЌрџ‘¦',
        'description': 'Р—Р°РїРµС‡Р°С‚Р»РµР№С‚Рµ СЃС‡Р°СЃС‚Р»РёРІС‹Рµ РјРѕРјРµРЅС‚С‹ СЃРµРјСЊРё РЅР° С„РѕРЅРµ РєСЂР°СЃРёРІРѕР№ РїСЂРёСЂРѕРґС‹.',
        'likesCount': 24,
        'commentsCount': 6,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_6',
        'authorId': 'user_5',
        'imageUrl': 'https://picsum.photos/400/400?random=26',
        'title': 'РљРѕСЂРїРѕСЂР°С‚РёРІ РІ СЃС‚РёР»Рµ 80-С… рџ•є',
        'description': 'Р’РµСЂРЅРёС‚РµСЃСЊ РІ СЌРїРѕС…Сѓ РґРёСЃРєРѕ СЃ СЏСЂРєРёРјРё РєРѕСЃС‚СЋРјР°РјРё Рё Р·Р°Р¶РёРіР°С‚РµР»СЊРЅРѕР№ РјСѓР·С‹РєРѕР№.',
        'likesCount': 21,
        'commentsCount': 8,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_7',
        'authorId': 'user_3',
        'imageUrl': 'https://picsum.photos/400/400?random=27',
        'title': 'Р РѕРјР°РЅС‚РёС‡РµСЃРєРёР№ СѓР¶РёРЅ РїСЂРё СЃРІРµС‡Р°С… рџ•ЇпёЏ',
        'description': 'РЎРѕР·РґР°Р№С‚Рµ РёРЅС‚РёРјРЅСѓСЋ Р°С‚РјРѕСЃС„РµСЂСѓ СЃ РєСЂР°СЃРёРІРѕР№ СЃРµСЂРІРёСЂРѕРІРєРѕР№ Рё РјСЏРіРєРёРј РѕСЃРІРµС‰РµРЅРёРµРј.',
        'likesCount': 17,
        'commentsCount': 3,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'id': 'idea_8',
        'authorId': 'user_1',
        'imageUrl': 'https://picsum.photos/400/400?random=28',
        'title': 'Р’С‹РїСѓСЃРєРЅРѕР№ РІ СЃС‚РёР»Рµ Р“Р°СЂСЂРё РџРѕС‚С‚РµСЂР° рџ§™вЂЌв™‚пёЏ',
        'description': 'РћРєСѓРЅРёС‚РµСЃСЊ РІ РјРёСЂ РјР°РіРёРё СЃ С‚РµРјР°С‚РёС‡РµСЃРєРёРјРё РґРµРєРѕСЂР°С†РёСЏРјРё Рё РєРѕСЃС‚СЋРјР°РјРё.',
        'likesCount': 31,
        'commentsCount': 9,
        'isTest': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (final idea in ideas) {
      await _firestore.collection('ideas').doc(idea['id']! as String).set(idea);
      debugPrint('  вњ… РРґРµСЏ ${idea['id']} РґРѕР±Р°РІР»РµРЅР°');
    }
  }

  /// Р”РѕР±Р°РІРёС‚СЊ РІСЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РІ Firestore
  Future<void> addAllTestDataToFirestore() async {
    debugPrint('рџљЂ РќР°С‡РёРЅР°РµРј РґРѕР±Р°РІР»РµРЅРёРµ РІСЃРµС… С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С… РІ Firestore...');

    try {
      await addTestUsersToFirestore();
      await addFeedPostsToFirestore();
      await addOrdersToFirestore();
      await addChatsToFirestore();
      await addIdeasToFirestore();

      debugPrint('вњ… Р’СЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ СѓСЃРїРµС€РЅРѕ РґРѕР±Р°РІР»РµРЅС‹ РІ Firestore!');
    } catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РїСЂРё РґРѕР±Р°РІР»РµРЅРёРё РґР°РЅРЅС‹С…: $e');
      rethrow;
    }
  }

  /// РћС‡РёСЃС‚РёС‚СЊ РІСЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РёР· Firestore
  Future<void> clearTestDataFromFirestore() async {
    debugPrint('рџ§№ РћС‡РёСЃС‚РєР° С‚РµСЃС‚РѕРІС‹С… РґР°РЅРЅС‹С… РёР· Firestore...');

    try {
      // РЈРґР°Р»СЏРµРј С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РёР· РІСЃРµС… РєРѕР»Р»РµРєС†РёР№
      final collections = ['users', 'feed', 'orders', 'chats', 'ideas'];

      for (final collection in collections) {
        final querySnapshot =
            await _firestore.collection(collection).where('isTest', isEqualTo: true).get();

        for (final doc in querySnapshot.docs) {
          if (collection == 'chats') {
            // Р”Р»СЏ С‡Р°С‚РѕРІ СѓРґР°Р»СЏРµРј С‚Р°РєР¶Рµ СЃРѕРѕР±С‰РµРЅРёСЏ
            final messagesSnapshot = await doc.reference.collection('messages').get();

            for (final messageDoc in messagesSnapshot.docs) {
              await messageDoc.reference.delete();
            }
          }
          await doc.reference.delete();
        }

        debugPrint('  вњ… РўРµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ СѓРґР°Р»РµРЅС‹ РёР· РєРѕР»Р»РµРєС†РёРё $collection');
      }

      debugPrint('вњ… Р’СЃРµ С‚РµСЃС‚РѕРІС‹Рµ РґР°РЅРЅС‹Рµ РѕС‡РёС‰РµРЅС‹ РёР· Firestore!');
    } catch (e) {
      debugPrint('вќЊ РћС€РёР±РєР° РїСЂРё РѕС‡РёСЃС‚РєРµ РґР°РЅРЅС‹С…: $e');
      rethrow;
    }
  }
}

