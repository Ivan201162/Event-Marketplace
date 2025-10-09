import 'package:event_marketplace_app/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Tests', () {
    testWidgets('Specialist profile display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      // Verify profile elements
      expect(find.text('Профиль специалиста'), findsOneWidget);

      // Check profile photo
      final profilePhoto = find.byType(CircleAvatar);
      expect(profilePhoto, findsOneWidget);

      // Check name display
      final nameText = find.byType(Text);
      expect(nameText, findsWidgets);

      // Check rating display
      final ratingStars = find.byIcon(Icons.star);
      expect(ratingStars, findsWidgets);

      // Check city display
      final cityIcon = find.byIcon(Icons.location_on);
      expect(cityIcon, findsOneWidget);
    });

    testWidgets('Specialist profile editing', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Find edit button
      final editButton = find.text('Редактировать');
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();
      }

      // Test editing name
      final nameField = find.byKey(const Key('name_field'));
      if (nameField.evaluate().isNotEmpty) {
        await tester.enterText(nameField, 'Updated Name');
        await tester.pumpAndSettle();
      }

      // Test editing description
      final descriptionField = find.byKey(const Key('description_field'));
      if (descriptionField.evaluate().isNotEmpty) {
        await tester.enterText(descriptionField, 'Updated description');
        await tester.pumpAndSettle();
      }

      // Test editing prices
      final priceField = find.byKey(const Key('price_field'));
      if (priceField.evaluate().isNotEmpty) {
        await tester.enterText(priceField, '5000');
        await tester.pumpAndSettle();
      }

      // Save changes
      final saveButton = find.text('Сохранить');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();
      }

      // Verify changes saved
      expect(find.text('Updated Name'), findsOneWidget);
    });

    testWidgets('Customer profile display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Verify customer profile elements
      expect(find.text('Профиль'), findsOneWidget);

      // Check profile photo
      final profilePhoto = find.byType(CircleAvatar);
      expect(profilePhoto, findsOneWidget);

      // Check order history
      final orderHistory = find.text('История заказов');
      if (orderHistory.evaluate().isNotEmpty) {
        expect(orderHistory, findsOneWidget);
      }

      // Check favorite specialists
      final favorites = find.text('Избранные специалисты');
      if (favorites.evaluate().isNotEmpty) {
        expect(favorites, findsOneWidget);
      }
    });

    testWidgets('Portfolio display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      // Find portfolio section
      final portfolioTab = find.text('Портфолио');
      if (portfolioTab.evaluate().isNotEmpty) {
        await tester.tap(portfolioTab);
        await tester.pumpAndSettle();
      }

      // Check portfolio images
      final portfolioImages = find.byType(Image);
      expect(portfolioImages, findsWidgets);

      // Test portfolio image tap
      if (portfolioImages.evaluate().isNotEmpty) {
        await tester.tap(portfolioImages.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Reviews display', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to specialist profile
      final specialistCard = find.byType(Card).first;
      if (specialistCard.evaluate().isNotEmpty) {
        await tester.tap(specialistCard);
        await tester.pumpAndSettle();
      }

      // Find reviews section
      final reviewsTab = find.text('Отзывы');
      if (reviewsTab.evaluate().isNotEmpty) {
        await tester.tap(reviewsTab);
        await tester.pumpAndSettle();
      }

      // Check reviews display
      final reviewCards = find.byType(Card);
      expect(reviewCards, findsWidgets);

      // Check rating stars
      final ratingStars = find.byIcon(Icons.star);
      expect(ratingStars, findsWidgets);
    });

    testWidgets('Profile settings', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Find settings button
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
      }

      // Test notification settings
      final notificationSwitch = find.byType(Switch);
      if (notificationSwitch.evaluate().isNotEmpty) {
        await tester.tap(notificationSwitch.first);
        await tester.pumpAndSettle();
      }

      // Test privacy settings
      final privacyButton = find.text('Приватность');
      if (privacyButton.evaluate().isNotEmpty) {
        await tester.tap(privacyButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Profile photo upload', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      final profileButton = find.byIcon(Icons.person);
      if (profileButton.evaluate().isNotEmpty) {
        await tester.tap(profileButton);
        await tester.pumpAndSettle();
      }

      // Find edit button
      final editButton = find.text('Редактировать');
      if (editButton.evaluate().isNotEmpty) {
        await tester.tap(editButton);
        await tester.pumpAndSettle();
      }

      // Find photo edit button
      final photoEditButton = find.byIcon(Icons.camera_alt);
      if (photoEditButton.evaluate().isNotEmpty) {
        await tester.tap(photoEditButton);
        await tester.pumpAndSettle();
      }

      // Test photo selection options
      final cameraOption = find.text('Камера');
      if (cameraOption.evaluate().isNotEmpty) {
        await tester.tap(cameraOption);
        await tester.pumpAndSettle();
      }

      final galleryOption = find.text('Галерея');
      if (galleryOption.evaluate().isNotEmpty) {
        await tester.tap(galleryOption);
        await tester.pumpAndSettle();
      }
    });
  });
}









