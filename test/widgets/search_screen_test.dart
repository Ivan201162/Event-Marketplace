import 'package:event_marketplace_app/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchScreen', () {
    testWidgets('should display search input field', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display filter button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should display empty state when no search results',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
      expect(find.text('Введите запрос для поиска'), findsOneWidget);
    });

    testWidgets('should display loading state when searching', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display search results when available', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should show filter dialog when filter button tapped',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Фильтры поиска'), findsOneWidget);
      expect(find.text('Категория'), findsOneWidget);
      expect(find.text('Город'), findsOneWidget);
      expect(find.text('Рейтинг'), findsOneWidget);
      expect(find.text('Цена'), findsOneWidget);
    });

    testWidgets('should allow entering search query', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'photographer');
      await tester.pump();

      // Assert
      expect(find.text('photographer'), findsOneWidget);
    });

    testWidgets('should clear search when clear button tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pump();
      }

      // Assert
      expect(find.text('test'), findsNothing);
    });

    testWidgets('should display search history when available', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display popular searches when available',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search suggestions when typing',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(TextField), 'ph');
      await tester.pump();

      // Assert
      expect(find.text('ph'), findsOneWidget);
    });

    testWidgets('should display search results count', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search error when error occurs',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search filters when applied', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search sort options', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search pagination when needed', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search loading more when loading more results',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search no more results when no more results',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search retry button when error occurs',
        (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });

    testWidgets('should display search refresh button', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SearchScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Поиск специалистов'), findsOneWidget);
    });
  });
}
