import 'package:cloud_firestore/cloud_firestore.dart';

/// Сервис для управления индикатором "печатает"
class TypingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _typingCollection = 'typing_indicators';

  /// Начать индикацию печатания
  Future<void> startTyping({
    required String chatId,
    required String userId,
    required String userName,
  }) async {
    try {
      await _firestore
          .collection(_typingCollection)
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({
            'userId': userId,
            'userName': userName,
            'isTyping': true,
            'startedAt': Timestamp.fromDate(DateTime.now()),
            'lastActivity': Timestamp.fromDate(DateTime.now()),
          });
    } catch (e) {
      debugPrint('Ошибка начала индикации печатания: $e');
    }
  }

  /// Остановить индикацию печатания
  Future<void> stopTyping({required String chatId, required String userId}) async {
    try {
      await _firestore
          .collection(_typingCollection)
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .delete();
    } catch (e) {
      debugPrint('Ошибка остановки индикации печатания: $e');
    }
  }

  /// Получить поток пользователей, которые печатают
  Stream<List<TypingUser>> getTypingUsers(String chatId) => _firestore
      .collection(_typingCollection)
      .doc(chatId)
      .collection('typing')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(TypingUser.fromDocument).where((user) => user.isTyping).toList(),
      );

  /// Обновить активность печатания (для поддержания индикации)
  Future<void> updateTypingActivity({required String chatId, required String userId}) async {
    try {
      await _firestore
          .collection(_typingCollection)
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .update({'lastActivity': Timestamp.fromDate(DateTime.now())});
    } catch (e) {
      debugPrint('Ошибка обновления активности печатания: $e');
    }
  }

  /// Очистить старые записи о печатании (старше 30 секунд)
  Future<void> cleanupOldTypingIndicators(String chatId) async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(seconds: 30));
      final oldTypingSnapshot = await _firestore
          .collection(_typingCollection)
          .doc(chatId)
          .collection('typing')
          .where('lastActivity', isLessThan: Timestamp.fromDate(cutoffTime))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldTypingSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Ошибка очистки старых индикаторов печатания: $e');
    }
  }

  /// Автоматически остановить печатание через определенное время
  Future<void> scheduleStopTyping({
    required String chatId,
    required String userId,
    Duration delay = const Duration(seconds: 3),
  }) async {
    Future.delayed(delay, () {
      stopTyping(chatId: chatId, userId: userId);
    });
  }
}

/// Модель пользователя, который печатает
class TypingUser {
  const TypingUser({
    required this.userId,
    required this.userName,
    required this.isTyping,
    required this.startedAt,
    required this.lastActivity,
  });

  factory TypingUser.fromDocument(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return TypingUser(
      userId: data['userId'] as String,
      userName: data['userName'] as String,
      isTyping: data['isTyping'] as bool,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      lastActivity: (data['lastActivity'] as Timestamp).toDate(),
    );
  }

  final String userId;
  final String userName;
  final bool isTyping;
  final DateTime startedAt;
  final DateTime lastActivity;

  /// Проверить, активен ли пользователь (печатает ли он)
  bool get isActive {
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(lastActivity);
    return timeSinceLastActivity.inSeconds < 30;
  }

  /// Получить время с начала печатания
  Duration get typingDuration => DateTime.now().difference(startedAt);
}
