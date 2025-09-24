import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Сервис для отслеживания онлайн-статуса пользователей
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _heartbeatTimer;
  bool _isOnline = false;

  /// Инициализация сервиса присутствия
  Future<void> initialize() async {
    if (_auth.currentUser != null) {
      await setOnline();
      _startHeartbeat();
    }
  }

  /// Установить статус "онлайн"
  Future<void> setOnline() async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore
          .collection('user_presence')
          .doc(_auth.currentUser!.uid)
          .set({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'userId': _auth.currentUser!.uid,
      });
      _isOnline = true;
    } catch (e) {
      print('Error setting online status: $e');
    }
  }

  /// Установить статус "оффлайн"
  Future<void> setOffline() async {
    if (_auth.currentUser == null) return;

    try {
      await _firestore
          .collection('user_presence')
          .doc(_auth.currentUser!.uid)
          .update({
        'isOnline': false,
        'lastSeen': FieldValue.serverTimestamp(),
      });
      _isOnline = false;
    } catch (e) {
      print('Error setting offline status: $e');
    }
  }

  /// Запустить heartbeat для поддержания онлайн-статуса
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isOnline) {
        setOnline();
      }
    });
  }

  /// Остановить heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Получить статус пользователя
  Stream<Map<String, dynamic>?> getUserPresence(String userId) {
    return _firestore
        .collection('user_presence')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  /// Получить статус нескольких пользователей
  Stream<List<Map<String, dynamic>>> getMultipleUsersPresence(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('user_presence')
        .where('userId', whereIn: userIds)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {
        'userId': doc.id,
        ...doc.data(),
      }).toList();
    });
  }

  /// Проверить, онлайн ли пользователь
  bool isUserOnline(Map<String, dynamic>? presence) {
    if (presence == null) return false;
    
    final isOnline = presence['isOnline'] as bool? ?? false;
    if (!isOnline) return false;

    // Проверяем, не прошло ли слишком много времени с последнего обновления
    final lastSeen = presence['lastSeen'] as Timestamp?;
    if (lastSeen == null) return false;

    final now = DateTime.now();
    final lastSeenDate = lastSeen.toDate();
    final difference = now.difference(lastSeenDate);

    // Считаем пользователя оффлайн, если не было активности более 2 минут
    return difference.inMinutes < 2;
  }

  /// Получить время последней активности
  DateTime? getLastSeen(Map<String, dynamic>? presence) {
    if (presence == null) return null;
    
    final lastSeen = presence['lastSeen'] as Timestamp?;
    return lastSeen?.toDate();
  }

  /// Форматировать время последней активности
  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Никогда';

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} мин назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ч назад';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дн назад';
    } else {
      return '${lastSeen.day}.${lastSeen.month}.${lastSeen.year}';
    }
  }

  /// Очистить ресурсы
  void dispose() {
    _stopHeartbeat();
    if (_isOnline) {
      setOffline();
    }
  }
}
