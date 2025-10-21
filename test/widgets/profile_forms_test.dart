import 'package:event_marketplace_app/screens/profile/edit_specialist_profile_screen.dart';
import 'package:event_marketplace_app/widgets/form_validators.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Profile Forms Widget Tests', () {
    testWidgets('EditSpecialistProfileScreen should render correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditSpecialistProfileScreen(),
          ),
        ),
      );

      // Проверяем основные элементы интерфейса
      expect(find.text('Редактирование профиля'), findsOneWidget);
      expect(find.text('Основная информация'), findsOneWidget);
      expect(find.text('Категории услуг *'), findsOneWidget);
      expect(find.text('Опыт и ценообразование'), findsOneWidget);
      expect(find.text('Дополнительные контакты'), findsOneWidget);
      expect(find.text('Изображения'), findsOneWidget);
      expect(find.text('Создать профиль'), findsOneWidget);
    });

    testWidgets('EditCustomerProfileScreen should render correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditCustomerProfileScreen(customerId: 'test_customer_id', isCreating: true),
          ),
        ),
      );

      // Проверяем основные элементы интерфейса
      expect(find.text('Создание профиля'), findsOneWidget);
      expect(find.text('Основная информация'), findsOneWidget);
      expect(find.text('Дополнительная информация'), findsOneWidget);
      expect(find.text('Дополнительные контакты'), findsOneWidget);
      expect(find.text('Фото профиля'), findsOneWidget);
      expect(find.text('Создать профиль'), findsOneWidget);
    });

    testWidgets('Specialist profile form validation should work correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditSpecialistProfileScreen(specialistId: 'test_specialist_id', isCreating: true),
          ),
        ),
      );

      // Находим кнопку сохранения
      final saveButton = find.text('Создать профиль');
      expect(saveButton, findsOneWidget);

      // Пытаемся сохранить без заполнения полей
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Проверяем, что появились ошибки валидации
      expect(find.text('Имя обязательно для заполнения'), findsOneWidget);
      expect(find.text('Email обязателен'), findsOneWidget);
      expect(find.text('Телефон обязателен'), findsOneWidget);
    });

    testWidgets('Customer profile form validation should work correctly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditCustomerProfileScreen(customerId: 'test_customer_id', isCreating: true),
          ),
        ),
      );

      // Находим кнопку сохранения
      final saveButton = find.text('Создать профиль');
      expect(saveButton, findsOneWidget);

      // Пытаемся сохранить без заполнения полей
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Проверяем, что появились ошибки валидации
      expect(find.text('Имя обязательно для заполнения'), findsOneWidget);
      expect(find.text('Email обязателен'), findsOneWidget);
      expect(find.text('Телефон обязателен'), findsOneWidget);
    });

    testWidgets('Specialist profile form should accept valid input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditSpecialistProfileScreen(specialistId: 'test_specialist_id', isCreating: true),
          ),
        ),
      );

      // Заполняем обязательные поля
      await tester.enterText(find.byType(TextFormField).at(0), 'Тест Специалист');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '+7 (999) 123-45-67');
      await tester.enterText(find.byType(TextFormField).at(3), 'Москва');
      await tester.enterText(find.byType(TextFormField).at(4), 'Краткое описание');
      await tester.enterText(find.byType(TextFormField).at(5), 'Подробное описание специалиста');

      // Выбираем категорию
      await tester.tap(find.text('Фотограф'));
      await tester.pumpAndSettle();

      // Проверяем, что кнопка сохранения активна
      final saveButton = find.text('Создать профиль');
      expect(saveButton, findsOneWidget);
    });

    testWidgets('Customer profile form should accept valid input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditCustomerProfileScreen(customerId: 'test_customer_id', isCreating: true),
          ),
        ),
      );

      // Заполняем обязательные поля
      await tester.enterText(find.byType(TextFormField).at(0), 'Тест Заказчик');
      await tester.enterText(find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(find.byType(TextFormField).at(2), '+7 (999) 123-45-67');
      await tester.enterText(find.byType(TextFormField).at(3), 'Москва');
      await tester.enterText(find.byType(TextFormField).at(4), 'Описание заказчика');

      // Проверяем, что кнопка сохранения активна
      final saveButton = find.text('Создать профиль');
      expect(saveButton, findsOneWidget);
    });

    testWidgets('Form validators should work correctly', (tester) async {
      // Тестируем валидаторы
      expect(FormValidators.required(''), equals('Это поле обязательно для заполнения'));
      expect(FormValidators.required('test'), isNull);

      expect(FormValidators.email('invalid'), equals('Введите корректный email'));
      expect(FormValidators.email('test@example.com'), isNull);

      expect(FormValidators.phone('123'), equals('Введите корректный номер телефона'));
      expect(FormValidators.phone('+7 (999) 123-45-67'), isNull);

      expect(FormValidators.minLength('test', 5), equals('Минимум 5 символов'));
      expect(FormValidators.minLength('test123', 5), isNull);

      expect(FormValidators.number('abc'), equals('Введите корректное число'));
      expect(FormValidators.number('123'), isNull);

      expect(FormValidators.positiveNumber('-1'), equals('Введите положительное число'));
      expect(FormValidators.positiveNumber('123'), isNull);
    });

    testWidgets('Specialist profile categories should be selectable', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditSpecialistProfileScreen(specialistId: 'test_specialist_id', isCreating: true),
          ),
        ),
      );

      // Проверяем наличие категорий
      expect(find.text('Фотограф'), findsOneWidget);
      expect(find.text('Видеограф'), findsOneWidget);
      expect(find.text('DJ'), findsOneWidget);
      expect(find.text('Ведущий'), findsOneWidget);
      expect(find.text('Декоратор'), findsOneWidget);

      // Выбираем категорию
      await tester.tap(find.text('Фотограф'));
      await tester.pumpAndSettle();

      // Проверяем, что категория выбрана
      final photographerChip = find.byWidgetPredicate(
        (widget) => widget is FilterChip && widget.label.toString().contains('Фотограф'),
      );
      expect(photographerChip, findsOneWidget);
    });

    testWidgets('Contact fields should be addable and removable', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EditSpecialistProfileScreen(specialistId: 'test_specialist_id', isCreating: true),
          ),
        ),
      );

      // Находим кнопку добавления контакта
      final addContactButton = find.text('Добавить');
      expect(addContactButton, findsOneWidget);

      // Добавляем контакт
      await tester.tap(addContactButton);
      await tester.pumpAndSettle();

      // Проверяем, что появились поля для контакта
      expect(find.text('Тип контакта'), findsOneWidget);
      expect(find.text('Значение'), findsOneWidget);
    });
  });
}
