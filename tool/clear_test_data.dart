import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Скрипт для удаления всех тестовых данных из Firestore
/// Запуск: dart tool/clear_test_data.dart
Future<void> main() async {
  print('🚀 Инициализация Firebase...');
  
  // Инициализация Firebase
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  print('🧹 Удаление тестовых данных...');
  
  try {
    // Удаляем тестовые данные из всех коллекций
    final collections = ['users', 'feed', 'orders', 'chats', 'ideas'];
    
    for (final collection in collections) {
      print('📂 Обработка коллекции: $collection');
      
      final querySnapshot = await firestore
          .collection(collection)
          .where('isTest', isEqualTo: true)
          .get();
      
      print('  Найдено ${querySnapshot.docs.length} тестовых документов');
      
      for (final doc in querySnapshot.docs) {
        if (collection == 'chats') {
          // Для чатов удаляем также сообщения
          final messagesSnapshot = await doc.reference
              .collection('messages')
              .get();
          
          print('    Удаление ${messagesSnapshot.docs.length} сообщений из чата ${doc.id}');
          
          for (final messageDoc in messagesSnapshot.docs) {
            await messageDoc.reference.delete();
          }
        }
        
        await doc.reference.delete();
        print('    Удален документ: ${doc.id}');
      }
      
      print('  ✅ Тестовые данные удалены из коллекции $collection');
    }
    
    print('✅ Все тестовые данные успешно удалены из Firestore!');
    
  } catch (e) {
    print('❌ Ошибка при удалении тестовых данных: $e');
    exit(1);
  }
  
  exit(0);
}

