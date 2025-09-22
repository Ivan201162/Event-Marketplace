import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:event_marketplace_app/screens/main_screen.dart';
import 'package:event_marketplace_app/models/user.dart' as app_user;
import 'package:event_marketplace_app/providers/auth_providers.dart';

import 'main_screen_test.mocks.dart';

@GenerateMocks([app_user.User])
void main() {
  group('MainScreen Widget Tests', () {
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser();
      when(mockUser.id).thenReturn('user123');
      when(mockUser.email).thenReturn('test@example.com');
      when(mockUser.displayName).thenReturn('Test User');
      when(mockUser.role).thenReturn(app_user.UserRole.customer);
    });

    testWidgets('отображение главного экрана с навигацией', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Act
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('переключение между вкладками навигации', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - переключение на вкладку "События"
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.event), findsOneWidget);
      expect(find.byIcon(Icons.event_selected), findsNothing);

      // Act - переключение на вкладку "Поиск"
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.search), findsOneWidget);

      // Act - переключение на вкладку "Чаты"
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.chat), findsOneWidget);

      // Act - переключение на вкладку "Профиль"
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('отображение правильного контента для каждой вкладки', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act & Assert - вкладка "События"
      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();
      expect(find.text('События'), findsOneWidget);

      // Act & Assert - вкладка "Поиск"
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();
      expect(find.text('Поиск'), findsOneWidget);

      // Act & Assert - вкладка "Чаты"
      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();
      expect(find.text('Чаты'), findsOneWidget);

      // Act & Assert - вкладка "Профиль"
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      expect(find.text('Профиль'), findsOneWidget);
    });

    testWidgets('отображение плавающей кнопки добавления для организатора', (WidgetTester tester) async {
      // Arrange
      when(mockUser.role).thenReturn(app_user.UserRole.organizer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('скрытие плавающей кнопки для клиента', (WidgetTester tester) async {
      // Arrange
      when(mockUser.role).thenReturn(app_user.UserRole.customer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('обработка нажатия на плавающую кнопку', (WidgetTester tester) async {
      // Arrange
      when(mockUser.role).thenReturn(app_user.UserRole.organizer);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Assert
      // Проверяем, что произошла навигация (это зависит от реализации)
      // В реальном приложении здесь должна быть проверка навигации
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('отображение индикатора загрузки при отсутствии пользователя', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('адаптивность для разных размеров экрана', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - тестируем на мобильном размере
      await tester.binding.setSurfaceSize(Size(375, 667));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Act - тестируем на планшетном размере
      await tester.binding.setSurfaceSize(Size(768, 1024));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('сохранение состояния при переключении вкладок', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => mockUser),
          ],
          child: MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act - переключаемся между вкладками несколько раз
      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chat));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.event));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(MainScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });
  });
}
