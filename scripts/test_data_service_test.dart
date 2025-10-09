import 'package:event_marketplace_app/services/test_data_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_options.dart';

/// Скрипт для тестирования TestDataService
Future<void> main() async {
  print('🚀 Запуск тестирования TestDataService...');
  
  try {
    // Инициализация Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase инициализирован');
    
    final testDataService = TestDataService();
    
    // Проверяем текущую статистику
    print('\n📊 Текущая статистика:');
    final stats = await testDataService.getTestDataStats();
    stats.forEach((key, value) {
      print('  $key: $value');
    });
    
    // Проверяем, есть ли тестовые данные
    final hasData = await testDataService.hasTestData();
    print('\n🔍 Есть ли тестовые данные: $hasData');
    
    if (!hasData) {
      print('\n🔄 Создание тестовых данных...');
      await testDataService.populateAll();
      
      // Проверяем статистику после создания
      print('\n📊 Статистика после создания:');
      final newStats = await testDataService.getTestDataStats();
      newStats.forEach((key, value) {
        print('  $key: $value');
      });
    }
    
    print('\n✅ Тестирование завершено успешно!');
    
  } catch (e) {
    print('❌ Ошибка при тестировании: $e');
  }
}
