import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Провайдер для чатов (только реальные данные из Firestore)
final chatsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    yield [];
    return;
  }

  try {
    await for (final snapshot in FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()) {
      final chats = snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
          .toList();
      yield chats; // Только реальные данные, без fallback на тестовые
    }
  } catch (e) {
    yield []; // Пустой список при ошибке
  }
});
