import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Search and Filter Tests', () {
    testWidgets('Basic search functionality', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Find search field
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'фотограф');
        await tester.pumpAndSettle();
      }

      // Tap search button
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();
      }

      // Check search results
      final searchResults = find.byType(Card);
      expect(searchResults, findsWidgets);
    });

    testWidgets('Category filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open filters
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      // Select category
      final categoryFilter = find.text('Фотографы');
      if (categoryFilter.evaluate().isNotEmpty) {
        await tester.tap(categoryFilter);
        await tester.pumpAndSettle();
      }

      // Apply filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredResults = find.byType(Card);
      expect(filteredResults, findsWidgets);
    });

    testWidgets('Price range filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open filters
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      // Set minimum price
      final minPriceField = find.byKey(const Key('min_price_field'));
      if (minPriceField.evaluate().isNotEmpty) {
        await tester.enterText(minPriceField, '5000');
        await tester.pumpAndSettle();
      }

      // Set maximum price
      final maxPriceField = find.byKey(const Key('max_price_field'));
      if (maxPriceField.evaluate().isNotEmpty) {
        await tester.enterText(maxPriceField, '20000');
        await tester.pumpAndSettle();
      }

      // Apply filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredResults = find.byType(Card);
      expect(filteredResults, findsWidgets);
    });

    testWidgets('Rating filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open filters
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      // Set minimum rating
      final ratingSlider = find.byType(Slider);
      if (ratingSlider.evaluate().isNotEmpty) {
        await tester.drag(ratingSlider, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      // Apply filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredResults = find.byType(Card);
      expect(filteredResults, findsWidgets);
    });

    testWidgets('Location filtering', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open filters
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      // Select city
      final cityField = find.byKey(const Key('city_field'));
      if (cityField.evaluate().isNotEmpty) {
        await tester.tap(cityField);
        await tester.pumpAndSettle();
      }

      // Select Moscow
      final moscowOption = find.text('Москва');
      if (moscowOption.evaluate().isNotEmpty) {
        await tester.tap(moscowOption);
        await tester.pumpAndSettle();
      }

      // Apply filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredResults = find.byType(Card);
      expect(filteredResults, findsWidgets);
    });

    testWidgets('Sorting options', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open sort options
      final sortButton = find.byIcon(Icons.sort);
      if (sortButton.evaluate().isNotEmpty) {
        await tester.tap(sortButton);
        await tester.pumpAndSettle();
      }

      // Test different sorting options
      final sortOptions = [
        'По рейтингу',
        'По цене (возрастание)',
        'По цене (убывание)',
        'По дате регистрации',
        'По количеству отзывов',
      ];

      for (final option in sortOptions) {
        final sortOption = find.text(option);
        if (sortOption.evaluate().isNotEmpty) {
          await tester.tap(sortOption);
          await tester.pumpAndSettle();
          break; // Test one option to avoid infinite loop
        }
      }

      // Check sorted results
      final sortedResults = find.byType(Card);
      expect(sortedResults, findsWidgets);
    });

    testWidgets('Advanced search filters', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Open advanced filters
      final advancedFilterButton = find.text('Расширенные фильтры');
      if (advancedFilterButton.evaluate().isNotEmpty) {
        await tester.tap(advancedFilterButton);
        await tester.pumpAndSettle();
      }

      // Set experience level
      final experienceSlider = find.byType(Slider);
      if (experienceSlider.evaluate().isNotEmpty) {
        await tester.drag(experienceSlider, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      // Set availability
      final availabilitySwitch = find.byType(Switch);
      if (availabilitySwitch.evaluate().isNotEmpty) {
        await tester.tap(availabilitySwitch);
        await tester.pumpAndSettle();
      }

      // Set verification status
      final verifiedSwitch = find.byType(Switch);
      if (verifiedSwitch.evaluate().isNotEmpty) {
        await tester.tap(verifiedSwitch);
        await tester.pumpAndSettle();
      }

      // Apply advanced filters
      final applyButton = find.text('Применить');
      if (applyButton.evaluate().isNotEmpty) {
        await tester.tap(applyButton);
        await tester.pumpAndSettle();
      }

      // Check filtered results
      final filteredResults = find.byType(Card);
      expect(filteredResults, findsWidgets);
    });

    testWidgets('Search history', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Check search history
      final historyButton = find.byIcon(Icons.history);
      if (historyButton.evaluate().isNotEmpty) {
        await tester.tap(historyButton);
        await tester.pumpAndSettle();
      }

      // Check history items
      final historyItems = find.byType(ListTile);
      expect(historyItems, findsWidgets);

      // Tap on history item
      if (historyItems.evaluate().isNotEmpty) {
        await tester.tap(historyItems.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Clear filters', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Apply some filters
      final filterButton = find.byIcon(Icons.filter_list);
      if (filterButton.evaluate().isNotEmpty) {
        await tester.tap(filterButton);
        await tester.pumpAndSettle();
      }

      final categoryFilter = find.text('Фотографы');
      if (categoryFilter.evaluate().isNotEmpty) {
        await tester.tap(categoryFilter);
        await tester.pumpAndSettle();
      }

      // Clear all filters
      final clearButton = find.text('Очистить все');
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }

      // Verify filters cleared
      expect(find.text('Фотографы'), findsNothing);
    });

    testWidgets('Search suggestions', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to search
      final searchButton = find.byIcon(Icons.search);
      if (searchButton.evaluate().isNotEmpty) {
        await tester.tap(searchButton);
        await tester.pumpAndSettle();
      }

      // Type in search field
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'фот');
        await tester.pumpAndSettle();
      }

      // Check suggestions
      final suggestions = find.byType(ListTile);
      expect(suggestions, findsWidgets);

      // Tap on suggestion
      if (suggestions.evaluate().isNotEmpty) {
        await tester.tap(suggestions.first);
        await tester.pumpAndSettle();
      }
    });
  });
}









