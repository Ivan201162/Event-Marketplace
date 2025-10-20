import 'package:event_marketplace_app/models/specialist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Filter Tests', () {
    late List<Specialist> testSpecialists;

    setUp(() {
      // Создаем тестовых специалистов
      final now = DateTime.now();
      testSpecialists = [
        Specialist(
          id: 'test_1',
          userId: 'user_1',
          name: 'Тестовый фотограф 1',
          category: SpecialistCategory.photographer,
          experienceLevel: ExperienceLevel.expert,
          yearsOfExperience: 5,
          hourlyRate: 5000,
          price: 5000,
          rating: 4.8,
          reviewCount: 100,
          createdAt: now,
          updatedAt: now,
          availableDates: [
            now.add(const Duration(days: 1)),
            now.add(const Duration(days: 2)),
            now.add(const Duration(days: 3)),
          ],
          busyDates: [
            now.add(const Duration(days: 4)),
            now.add(const Duration(days: 5)),
          ],
        ),
        Specialist(
          id: 'test_2',
          userId: 'user_2',
          name: 'Тестовый фотограф 2',
          category: SpecialistCategory.photographer,
          experienceLevel: ExperienceLevel.intermediate,
          yearsOfExperience: 3,
          hourlyRate: 3000,
          price: 3000,
          rating: 4.2,
          reviewCount: 50,
          createdAt: now,
          updatedAt: now,
          availableDates: [
            now.add(const Duration(days: 2)),
            now.add(const Duration(days: 4)),
            now.add(const Duration(days: 6)),
          ],
          busyDates: [
            now.add(const Duration(days: 1)),
            now.add(const Duration(days: 3)),
          ],
        ),
        Specialist(
          id: 'test_3',
          userId: 'user_3',
          name: 'Тестовый DJ',
          category: SpecialistCategory.dj,
          experienceLevel: ExperienceLevel.advanced,
          yearsOfExperience: 4,
          hourlyRate: 4000,
          price: 4000,
          rating: 4.5,
          reviewCount: 75,
          createdAt: now,
          updatedAt: now,
          availableDates: [
            now.add(const Duration(days: 1)),
            now.add(const Duration(days: 3)),
            now.add(const Duration(days: 5)),
          ],
          busyDates: [
            now.add(const Duration(days: 2)),
            now.add(const Duration(days: 4)),
          ],
        ),
      ];
    });

    test('Фильтр по минимальной цене', () async {
      // Мокаем метод getAllSpecialists
      // В реальном тесте нужно будет использовать моки

      // Тестируем фильтр по минимальной цене 4000
      final filtered = testSpecialists.where((specialist) => specialist.price >= 4000).toList();

      expect(filtered.length, 2);
      expect(filtered.every((s) => s.price >= 4000), true);
    });

    test('Фильтр по максимальной цене', () async {
      // Тестируем фильтр по максимальной цене 3500
      final filtered = testSpecialists.where((specialist) => specialist.price <= 3500).toList();

      expect(filtered.length, 1);
      expect(filtered.first.price, 3000);
    });

    test('Фильтр по минимальному рейтингу', () async {
      // Тестируем фильтр по минимальному рейтингу 4.5
      final filtered = testSpecialists.where((specialist) => specialist.rating >= 4.5).toList();

      expect(filtered.length, 2);
      expect(filtered.every((s) => s.rating >= 4.5), true);
    });

    test('Фильтр по дате доступности', () async {
      final testDate = DateTime.now().add(const Duration(days: 1));

      // Тестируем фильтр по дате доступности
      final filtered = testSpecialists
          .where(
            (specialist) =>
                !specialist.isDateBusy(testDate) && specialist.isAvailableOnDate(testDate),
          )
          .toList();

      expect(filtered.length, 2); // test_1 и test_3 доступны в день 1
    });

    test('Комбинированный фильтр (цена + рейтинг)', () async {
      // Тестируем комбинированный фильтр
      final filtered = testSpecialists
          .where(
            (specialist) => specialist.price >= 4000 && specialist.rating >= 4.5,
          )
          .toList();

      expect(filtered.length, 2);
      expect(filtered.every((s) => s.price >= 4000 && s.rating >= 4.5), true);
    });

    test('Фильтр по занятым датам', () async {
      final busyDate = DateTime.now().add(const Duration(days: 4));

      // Тестируем фильтр по занятым датам
      final filtered =
          testSpecialists.where((specialist) => !specialist.isDateBusy(busyDate)).toList();

      expect(
        filtered.length,
        1,
      ); // test_2 не занят в день 4 (test_1 занят, test_3 занят)
    });
  });
}
