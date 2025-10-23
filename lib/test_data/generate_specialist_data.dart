import 'package:flutter/material.dart';
import 'specialist_test_data.dart';

/// Скрипт для генерации тестовых данных специалистов
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Начинаем генерацию тестовых данных специалистов...');

  try {
    // Очищаем старые данные
    print('🧹 Очищаем старые тестовые данные...');
    await SpecialistTestData.clearTestData();

    // Создаем новые данные
    print('📝 Создаем новых специалистов...');
    await SpecialistTestData.createTestSpecialists();

    // Получаем статистику
    print('📊 Получаем статистику...');
    final stats = await SpecialistTestData.getTestDataStats();

    print('\n✅ Генерация завершена успешно!');
    print('\n📈 Статистика:');
    print('   Всего специалистов: ${stats['totalCount']}');
    print(
        '   Средний рейтинг: ${(stats['averageRating'] as double).toStringAsFixed(1)}');
    print('   Средняя цена: ${(stats['averagePrice'] as double).toInt()}₽');
    print('   Верифицированных: ${stats['verifiedCount']}');
    print('   Онлайн: ${stats['onlineCount']}');

    print('\n🏷️ Категории:');
    final categories = stats['categories'] as Map<String, int>;
    categories.forEach((category, count) {
      print('   $category: $count');
    });

    print('\n🏙️ Города:');
    final cities = stats['cities'] as Map<String, int>;
    cities.forEach((city, count) {
      print('   $city: $count');
    });
  } catch (e) {
    print('❌ Ошибка генерации данных: $e');
  }
}
